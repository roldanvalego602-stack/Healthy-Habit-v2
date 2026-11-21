const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore("default");

exports.adjustHabitCoins = onCall(
  {
    region: "us-central1",
    enforceAppCheck: false,
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth || request.auth.token.admin !== true) {
      throw new HttpsError(
        "permission-denied",
        "Solo los administradores pueden ajustar Habit Coins."
      );
    }

    const data = request.data || {};
    const { userId, operation, amount, reason, operationId } = data;

    if (
      typeof userId !== "string" ||
      !/^[A-Za-z0-9_-]{1,128}$/.test(userId)
    ) {
      throw new HttpsError("invalid-argument", "Usuario no válido.");
    }

    if (operation !== "grant" && operation !== "deduct") {
      throw new HttpsError("invalid-argument", "Operación no válida.");
    }

    if (!Number.isInteger(amount) || amount < 1 || amount > 10000) {
      throw new HttpsError(
        "invalid-argument",
        "La cantidad debe estar entre 1 y 10000."
      );
    }

    if (
      typeof reason !== "string" ||
      reason.trim().length < 10 ||
      reason.trim().length > 500
    ) {
      throw new HttpsError(
        "invalid-argument",
        "El motivo debe contener entre 10 y 500 caracteres."
      );
    }

    if (
      typeof operationId !== "string" ||
      !/^[A-Za-z0-9_-]{16,128}$/.test(operationId)
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Identificador de operación no válido."
      );
    }

    const userRef = db.collection("users").doc(userId);
    const movementRef = db.collection("habit_coin_movements").doc(operationId);

    return db.runTransaction(async (transaction) => {
      const existingMovement = await transaction.get(movementRef);

      if (existingMovement.exists) {
        const previous = existingMovement.data();

        if (
          previous.userId !== userId ||
          previous.adminId !== request.auth.uid ||
          previous.operation !== operation ||
          previous.amount !== amount ||
          previous.reason !== reason.trim()
        ) {
          throw new HttpsError(
            "already-exists",
            "El identificador pertenece a otra operación."
          );
        }

        return {
          success: true,
          alreadyProcessed: true,
          previousBalance: previous.previousBalance,
          newBalance: previous.newBalance,
          operationId,
        };
      }

      const userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists) {
        throw new HttpsError("not-found", "El usuario no existe.");
      }

      const rawBalance = userSnapshot.data().habitCoins ?? 0;

      if (
        typeof rawBalance !== "number" ||
        !Number.isSafeInteger(rawBalance) ||
        rawBalance < 0
      ) {
        throw new HttpsError(
          "failed-precondition",
          "El saldo actual del usuario no es válido."
        );
      }

      const delta = operation === "grant" ? amount : -amount;
      const newBalance = rawBalance + delta;

      if (newBalance < 0) {
        throw new HttpsError(
          "failed-precondition",
          "El usuario no tiene suficientes Habit Coins."
        );
      }

      const timestamp = require("firebase-admin/firestore")
        .FieldValue.serverTimestamp();

      transaction.update(userRef, {
        habitCoins: newBalance,
      });

      transaction.create(movementRef, {
        userId,
        adminId: request.auth.uid,
        operation,
        amount,
        delta,
        reason: reason.trim(),
        previousBalance: rawBalance,
        newBalance,
        createdAt: timestamp,
        source: "admin_adjustment",
      });

      return {
        success: true,
        alreadyProcessed: false,
        previousBalance: rawBalance,
        newBalance,
        operationId,
      };
    });
  }
);


const { classifyIntent } = require("./intent_classifier");
// Solo interpreta texto: no modifica XP, monedas ni habitos.
exports.interpretMrHealthyIntent = onCall(
  {region:"us-central1", enforceAppCheck:false, maxInstances:10},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Inicia sesion para usar Mr. Healthy.");
    }
    try {
      return classifyIntent(request.data?.text);
    } catch (error) {
      if (error instanceof TypeError) {
        throw new HttpsError("invalid-argument", error.message);
      }
      throw error;
    }
  }
);


// Desafíos de evidencia: solo gestionan códigos de sesión.
// No verifican fotografías ni modifican XP o Habit Coins.
const {
  ChallengeError,
  startEvidenceChallenge,
  checkEvidenceChallengeCode,
} = require("./evidence_challenge");

function challengeHandler(operation) {
  return async (request) => {
    // Endpoints experimentales: no publicarlos como verificadores de evidencia.
    if (process.env.FUNCTIONS_EMULATOR !== "true") {
      throw new HttpsError(
        "failed-precondition",
        "Los desafíos de prueba solo están habilitados en el emulador.",
      );
    }
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Inicia sesión para continuar.");
    }
    try {
      return await operation({
        db,
        uid: request.auth.uid,
        ...{
          habitId: request.data?.habitId,
          attemptId: request.data?.attemptId,
          objectId: request.data?.objectId,
          challengeId: request.data?.challengeId,
          code: request.data?.code,
        },
      });
    } catch (error) {
      if (error instanceof ChallengeError) {
        throw new HttpsError(error.code, error.message);
      }
      throw error;
    }
  };
}

exports.startEvidenceChallenge = onCall(
  {region: "us-central1", enforceAppCheck: false, maxInstances: 10},
  challengeHandler(startEvidenceChallenge),
);

// Exclusivamente para comprobar el ciclo de vida en el emulador.
// No se acepta como prueba visual ni concede recompensas.
exports.checkEvidenceChallengeCode = onCall(
  {region: "us-central1", enforceAppCheck: false, maxInstances: 10},
  challengeHandler(checkEvidenceChallengeCode),
);


// Datos mínimos para la demostración móvil. Solo en emulador y proyecto demo.
// No hay acceso al perfil real ni cambios en el sistema de XP.
exports.prepareEvidenceDemo = onCall(
  {region: "us-central1", enforceAppCheck: false, maxInstances: 10},
  async (request) => {
    if (process.env.FUNCTIONS_EMULATOR !== "true" ||
        process.env.GCLOUD_PROJECT !== "demo-healthy-habit") {
      throw new HttpsError(
        "failed-precondition",
        "La demostración solo está disponible en los emuladores del proyecto demo.",
      );
    }
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Inicia sesión de prueba.");
    }
    const habitId = "demo-water";
    const attemptId = "demo-attempt";
    const habitRef = db.collection("users").doc(request.auth.uid)
      .collection("user_habits").doc(habitId);
    const attemptRef = habitRef.collection("attempts").doc(attemptId);
    await db.runTransaction(async (tx) => {
      const attempt = await tx.get(attemptRef);
      if (!attempt.exists) {
        tx.set(habitRef, {title: "Beber agua (prueba)", category: "Hidratación"});
        tx.set(attemptRef, {status: "inProgress", progress: 0, target: 1});
      }
    });
    return {habitId, attemptId, title: "Beber agua (prueba)", xpAwarded: 0};
  },
);


// Publicación administrativa de estadísticas globales. No es un trigger
// automático: ejecutar solo tras desplegar reglas que impidan escrituras
// desde el cliente y permitan lectura de agregados autorizados.
const {
  aggregateActiveHabits,
} = require("./habit_popularity_aggregator");

exports.rebuildPublicHabitPopularity = onCall(
  {
    region: "us-central1",
    enforceAppCheck: false,
    maxInstances: 1,
    timeoutSeconds: 180,
    memory: "512MiB",
  },
  async (request) => {
    if (!request.auth || request.auth.token.admin !== true) {
      throw new HttpsError(
        "permission-denied",
        "Solo los administradores pueden publicar estadísticas."
      );
    }
    // Evitar rankings parciales si aumenta el tamaño de la colección.
    const snapshot = await db.collectionGroup("user_habits")
      .limit(10001).get();
    if (snapshot.size >= 10001) {
      throw new HttpsError(
        "resource-exhausted",
        "Hay demasiados documentos; requiere paginación antes de publicar."
      );
    }
    const aggregated = aggregateActiveHabits(
      snapshot.docs.map((doc) => ({
        path: doc.ref.path,
        data: doc.data(),
      }))
    );
    const destination = db.collection("public_habit_popularity");
    const previous = await destination.get();
    const batch = db.batch();
    const activeIds = new Set(aggregated.map((entry) => entry.habitId));
    for (const doc of previous.docs) {
      if (!activeIds.has(doc.id)) batch.delete(doc.ref);
    }
    const {FieldValue} = require("firebase-admin/firestore");
    for (const item of aggregated) {
      batch.set(destination.doc(item.habitId), {
        activeUsers: item.activeUsers,
        verified: true,
        verifiedAt: FieldValue.serverTimestamp(),
      });
    }
    // El catálogo contiene 36 hábitos: el lote se mantiene < 500 escrituras.
    await batch.commit();
    return {
      publishedHabits: aggregated.length,
      checkedDocuments: snapshot.size,
      minimumUsersPerPublishedHabit: 5,
    };
  }
);
