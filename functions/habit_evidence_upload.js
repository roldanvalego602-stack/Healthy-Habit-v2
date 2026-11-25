"use strict";

const {RegistrationPolicyError} = require("./habit_registration_policy");
const {validImage} = require("./habit_evidence_attachment");
const {FieldValue} = require("firebase-admin/firestore");

const ID = /^[A-Za-z0-9_-]{16,128}$/;
const HABIT = /^(?:alim|hidr|ener|bien)_00[1-9]$/;
const MAX_SIZE = 250 * 1024;

async function uploadReservedEvidence({db, bucket, uid, data, now = new Date()}) {
  if (typeof uid !== "string" || !ID.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Sesión inválida.");
  }
  if (!data || typeof data !== "object" || Array.isArray(data) ||
      Object.keys(data).some((field) =>
        !["habitId", "attemptId", "operationId", "imageBase64", "contentType"]
          .includes(field)) ||
      typeof data.habitId !== "string" || !HABIT.test(data.habitId) ||
      typeof data.attemptId !== "string" || !ID.test(data.attemptId) ||
      typeof data.operationId !== "string" || !ID.test(data.operationId) ||
      typeof data.imageBase64 !== "string" ||
      data.imageBase64.length > 350000 ||
      data.imageBase64.length < 16 ||
      !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/
        .test(data.imageBase64) ||
      !["image/jpeg", "image/png", "image/webp"].includes(data.contentType)) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Fotografía o identificadores inválidos."
    );
  }
  const bytes = Buffer.from(data.imageBase64, "base64");
  if (bytes.length > MAX_SIZE || !validImage(bytes, data.contentType) ||
      bytes.toString("base64") !== data.imageBase64) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Archivo inválido o contenido no admitido."
    );
  }
  if (!(now instanceof Date) || !Number.isFinite(now.getTime())) {
    throw new TypeError("Fecha inválida.");
  }

  const userRef = db.collection("users").doc(uid);
  const reservationRef = userRef.collection("habit_evidence_reservations")
    .doc(data.operationId);
  const operationRef = userRef.collection("registration_operations")
    .doc(data.operationId);
  const path = `habit-evidence/${uid}/${data.attemptId}/${data.operationId}`;

  // Firestore es el árbitro de concurrencia: una sola petición adquiere
  // el derecho temporal de escribir el archivo. Nunca confiamos en que
  // Storage Emulator implemente precondiciones de generación.
  const lease = await db.runTransaction(async (tx) => {
    const [reservationSnap, operationSnap] = await Promise.all([
      tx.get(reservationRef), tx.get(operationRef),
    ]);
    if (!reservationSnap.exists) {
      throw new RegistrationPolicyError(
        "failed-precondition", "Primero reserva una ruta para este registro."
      );
    }
    const saved = reservationSnap.data();
    if (saved.uid !== uid || saved.habitId !== data.habitId ||
        saved.attemptId !== data.attemptId ||
        saved.operationId !== data.operationId ||
        saved.storagePath !== path) {
      throw new RegistrationPolicyError(
        "permission-denied", "La reserva no pertenece al registro."
      );
    }
    if (!saved.expiresAt?.toMillis ||
        saved.expiresAt.toMillis() <= now.getTime() ||
        !["pending", "uploading", "uploaded"].includes(saved.status)) {
      throw new RegistrationPolicyError(
        "failed-precondition", "La reserva venció o ya fue cerrada."
      );
    }
    if (operationSnap.exists) {
      const op = operationSnap.data();
      if (op.habitId !== data.habitId || op.attemptId !== data.attemptId) {
        throw new RegistrationPolicyError(
          "already-exists", "La operación pertenece a otro registro."
        );
      }
    }
    if (saved.status === "uploading") {
      const started = saved.uploadStartedAt?.toMillis?.();
      if (typeof started !== "number" ||
          started > now.getTime() - 300000) {
        throw new RegistrationPolicyError(
          "aborted", "Otra subida sigue en curso; vuelve a intentarlo."
        );
      }
      // Reclamar exclusivamente la inspección del archivo abandonado.
      // Nunca volver a escribir a ciegas sobre el mismo objeto.
      tx.update(reservationRef, {
        status: "recovering", recoveryStartedAt: FieldValue.serverTimestamp(),
      });
      return "recover";
    }
    if (saved.status === "uploaded") return false;
    tx.update(reservationRef, {
      status: "uploading", uploadStartedAt: FieldValue.serverTimestamp(),
    });
    return true;
  });

  const file = bucket.file(path);
  async function compareStored() {
    const [exists] = await file.exists();
    if (!exists) {
      throw new RegistrationPolicyError(
        "failed-precondition", "El archivo reservado no está disponible."
      );
    }
    const [metadata] = await file.getMetadata();
    if (Number(metadata.size) !== bytes.length ||
        metadata.contentType !== data.contentType) {
      throw new RegistrationPolicyError(
        "already-exists", "El archivo ya existe con datos diferentes."
      );
    }
    const [existing] = await file.download();
    if (!existing.equals(bytes)) {
      throw new RegistrationPolicyError(
        "already-exists", "El archivo ya existe con datos diferentes."
      );
    }
  }
  if (!lease) {
    await compareStored();
    return {storagePath: path, alreadyUploaded: true, verified: false};
  }
  if (lease === "recover") {
    // Una sola llamada obtiene el derecho de recuperación mediante tx.
    // Si existe un archivo diferente, mantener el bloqueo para revisión
    // y evitar que pueda ser sustituido por otro cliente.
    const [exists] = await file.exists();
    if (exists) await compareStored();
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(reservationRef);
      if (!snap.exists || snap.data().status !== "recovering" ||
          snap.data().storagePath !== path ||
          snap.data().expiresAt?.toMillis?.() <= now.getTime()) {
        throw new RegistrationPolicyError(
          "aborted", "La reserva cambió durante la recuperación."
        );
      }
      tx.update(reservationRef, exists ? {
        status: "uploaded", uploadedAt: FieldValue.serverTimestamp(),
      } : {
        status: "pending", uploadStartedAt: FieldValue.delete(),
      });
    });
    if (!exists) {
      throw new RegistrationPolicyError(
        "aborted", "No se encontró el archivo; repite la subida."
      );
    }
    return {storagePath: path, alreadyUploaded: true, verified: false};
  }

  try {
    const [alreadyExists] = await file.exists();
    if (alreadyExists) {
      // Recuperación de una escritura previa cuyo ACK no llegó a Firestore.
      await compareStored();
    } else {
      try {
        await file.save(bytes, {
          resumable: false,
          contentType: data.contentType,
          preconditionOpts: {ifGenerationMatch: 0},
          metadata: {cacheControl: "private, no-store"},
        });
      } catch (error) {
        if (![409, 412].includes(Number(error.code))) throw error;
        await compareStored();
      }
    }
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(reservationRef);
      if (!snap.exists || snap.data().status !== "uploading" ||
          snap.data().storagePath !== path) {
        throw new RegistrationPolicyError(
          "aborted", "La reserva cambió durante la subida."
        );
      }
      tx.update(reservationRef, {
        status: "uploaded", uploadedAt: FieldValue.serverTimestamp(),
      });
    });
    return {storagePath: path, alreadyUploaded: alreadyExists, verified: false};
  } catch (error) {
    // Solo liberar si el archivo todavía no existe. Si la subida pudo
    // completarse, conservar uploading para revisión administrativa;
    // nunca autorizar una posible sobrescritura en un reintento.
    const [exists] = await file.exists().catch(() => [true]);
    if (!exists) {
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(reservationRef);
        if (snap.exists && snap.data().status === "uploading" &&
            snap.data().storagePath === path) {
          tx.update(reservationRef, {status: "pending"});
        }
      });
    }
    throw error;
  }
}

module.exports = {uploadReservedEvidence};
