"use strict";

const {RegistrationPolicyError} = require("./habit_registration_policy");
const {validImage} = require("./habit_evidence_attachment");
const {Timestamp} = require("firebase-admin/firestore");

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
  const [reservationSnap, operationSnap] = await Promise.all([
    reservationRef.get(), operationRef.get(),
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
  if (saved.status !== "pending" ||
      !saved.expiresAt?.toMillis ||
      saved.expiresAt.toMillis() <= now.getTime()) {
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

  // Escritura de una sola vez. Un reintento tras respuesta perdida puede
  // detectar que el objeto existe y reutilizarlo SOLO si sus bytes coinciden.
  const file = bucket.file(path);
  try {
    await file.save(bytes, {
      resumable: false,
      contentType: data.contentType,
      preconditionOpts: {ifGenerationMatch: 0},
      metadata: {cacheControl: "private, no-store"},
    });
    return {storagePath: path, alreadyUploaded: false, verified: false};
  } catch (error) {
    const code = Number(error.code);
    if (code !== 412 && code !== 409) throw error;
    const [storedMetadata] = await file.getMetadata();
    if (Number(storedMetadata.size) !== bytes.length ||
        storedMetadata.contentType !== data.contentType) {
      throw new RegistrationPolicyError(
        "already-exists", "El archivo ya existe con datos diferentes."
      );
    }
    const [existingBytes] = await file.download();
    if (!existingBytes.equals(bytes)) {
      throw new RegistrationPolicyError(
        "already-exists", "El archivo ya existe con datos diferentes."
      );
    }
    return {storagePath: path, alreadyUploaded: true, verified: false};
  }
}

module.exports = {uploadReservedEvidence};
