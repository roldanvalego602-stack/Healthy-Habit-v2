"use strict";

// Inspección NO destructiva. Un huérfano no se borra automáticamente:
// podría provenir de una subida interrumpida o de datos legados.
const ID = /^[A-Za-z0-9_-]{16,128}$/;
const PREFIX = "habit-evidence/";

async function auditOrphanEvidence({db, bucket, now = new Date(), limit = 100, pageToken}) {
  if (process.env.GCLOUD_PROJECT !== "demo-healthy-habit" ||
      !process.env.FIRESTORE_EMULATOR_HOST ||
      !process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
    throw new Error("Auditoría permitida únicamente en emuladores demo.");
  }
  if (!(now instanceof Date) || !Number.isFinite(now.getTime()) ||
      !Number.isSafeInteger(limit) || limit < 1 || limit > 500 ||
      (pageToken !== undefined &&
        (typeof pageToken !== "string" || pageToken.length > 2048))) {
    throw new TypeError("Fecha o límite inválido.");
  }

  // autoPaginate:false garantiza que un lote tiene un límite explícito.
  const [files, nextQuery] = await bucket.getFiles({
    prefix: PREFIX, maxResults: limit, autoPaginate: false,
    ...(pageToken ? {pageToken} : {}),
  });
  const findings = [];
  const counts = {
    valid: 0, orphan: 0, inconsistent: 0, expired: 0,
    recentUnreserved: 0, invalidPath: 0,
  };
  for (const file of files) {
    const path = file.name;
    const parts = path.split("/");
    if (parts.length !== 4 || parts[0] !== "habit-evidence" ||
        !parts.slice(1).every((id) => ID.test(id))) {
      counts.invalidPath++;
      findings.push({path, status: "invalidPath"});
      continue;
    }
    const [, uid, attemptId, operationId] = parts;
    const reservationRef = db.collection("users").doc(uid)
      .collection("habit_evidence_reservations").doc(operationId);
    const reservation = await reservationRef.get();
    if (!reservation.exists) {
      // La edad se evalúa con metadata del objeto, no reloj del cliente.
      const metadata = file.metadata?.timeCreated ?
        file.metadata : (await file.getMetadata())[0];
      const createdAt = Date.parse(metadata.timeCreated || "");
      if (!Number.isFinite(createdAt) ||
          createdAt > now.getTime() - 5 * 60 * 1000) {
        counts.recentUnreserved++;
        findings.push({path, status: "recentUnreserved"});
      } else {
        counts.orphan++;
        findings.push({path, status: "orphan"});
      }
      continue;
    }
    const record = reservation.data();
    if (record.uid !== uid || record.attemptId !== attemptId ||
        record.operationId !== operationId || record.storagePath !== path ||
        typeof record.habitId !== "string" ||
        !["pending", "uploading", "recovering", "uploaded", "attached"]
          .includes(record.status) ||
        typeof record.expiresAt?.toMillis !== "function") {
      counts.inconsistent++;
      findings.push({path, status: "inconsistent"});
    } else if (record.expiresAt?.toMillis?.() <= now.getTime()) {
      counts.expired++;
      findings.push({path, status: "expired"});
    } else {
      counts.valid++;
    }
  }
  // Nunca reportar revisión completa cuando existe otra página.
  return {
    scanned: files.length, counts, findings,
    hasMore: Boolean(nextQuery?.pageToken),
    nextPageToken: nextQuery?.pageToken ?? null,
  };
}

module.exports = {auditOrphanEvidence};
