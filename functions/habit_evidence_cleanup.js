"use strict";

const {Timestamp, FieldValue} = require("firebase-admin/firestore");

// Utilidad ADMINISTRATIVA, nunca callable del cliente. Ejecutar exclusivamente
// en emuladores o con una migración explícitamente revisada.
async function purgeExpiredEvidence({db, bucket, now = new Date(), limit = 50}) {
  if (process.env.GCLOUD_PROJECT !== "demo-healthy-habit" ||
      !process.env.FIRESTORE_EMULATOR_HOST ||
      !process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
    throw new Error("La limpieza solo funciona en emuladores demo.");
  }
  if (!(now instanceof Date) || !Number.isFinite(now.getTime()) ||
      !Number.isSafeInteger(limit) || limit < 1 || limit > 100) {
    throw new TypeError("Fecha o lote inválido.");
  }
  const expired = await db.collectionGroup("habit_evidence_reservations")
    .where("expiresAt", "<=", Timestamp.fromDate(now))
    .limit(limit).get();
  let removed = 0;
  for (const snapshot of expired.docs) {
    const reservation = snapshot.data();
    const userRef = snapshot.ref.parent.parent;
    if (!userRef || userRef.parent.id !== "users" ||
        reservation.uid !== userRef.id ||
        reservation.operationId !== snapshot.id ||
        typeof reservation.attemptId !== "string" ||
        typeof reservation.habitId !== "string") {
      // Un documento corrupto se deja para revisión administrativa.
      continue;
    }
    const expectedPath = `habit-evidence/${userRef.id}/${reservation.attemptId}/${snapshot.id}`;
    if (reservation.storagePath !== expectedPath) continue;
    const file = bucket.file(expectedPath);
    try {
      await file.delete({ignoreNotFound: true});
    } catch (error) {
      if (error.code !== 404) throw error;
    }
    const logRef = userRef.collection("user_habits")
      .doc(reservation.habitId).collection("attempts")
      .doc(reservation.attemptId).collection("logs").doc(snapshot.id);
    await db.runTransaction(async (tx) => {
      const [current, log] = await Promise.all([
        tx.get(snapshot.ref), tx.get(logRef),
      ]);
      if (!current.exists) return;
      const currentReservation = current.data();
      if (currentReservation.storagePath !== expectedPath ||
          currentReservation.expiresAt?.toMillis?.() > now.getTime()) return;
      if (log.exists && log.data().evidencePath === expectedPath) {
        tx.update(logRef, {
          hasEvidence: false,
          evidencePath: FieldValue.delete(),
          evidenceContentType: FieldValue.delete(),
          evidenceSize: FieldValue.delete(),
          evidenceVerified: false,
          evidenceExpiredAt: FieldValue.serverTimestamp(),
        });
      }
      tx.delete(snapshot.ref);
    });
    removed++;
  }
  return {scanned: expired.size, removed};
}

module.exports = {purgeExpiredEvidence};
