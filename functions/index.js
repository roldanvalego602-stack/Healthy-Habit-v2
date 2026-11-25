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
        "Solo los administradores pueden revisar estadísticas."
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
    // MODO SEGURO: estos estados son editables por el cliente bajo las
    // reglas actuales; no son una fuente de métricas verificadas.
    // No publicar ni marcar verified:true hasta trasladar las
    // transiciones de estado a una operación confiable del servidor.
    return {
      published: false,
      reason: "untrusted-client-writable-habit-state",
      candidateHabits: aggregated.length,
      checkedDocuments: snapshot.size,
      minimumUsersPerPublishedHabit: 5,
    };
  }
);


// Validación de registro en servidor, solo lectura: no concede XP, monedas
// ni acepta fotografías como evidencia verificada.
const {
  validateRegistrationRequest,
  registrationEligibility,
  RegistrationPolicyError,
} = require("./habit_registration_policy");

exports.previewOfficialHabitRegistration = onCall(
  {
    region: "us-central1",
    enforceAppCheck: false,
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Inicia sesión para continuar.");
    }
    let ids;
    try {
      ids = validateRegistrationRequest(request.data);
    } catch (error) {
      if (error instanceof RegistrationPolicyError) {
        throw new HttpsError(error.code, error.message);
      }
      throw error;
    }
    const ref = db.collection("users").doc(request.auth.uid)
      .collection("user_habits").doc(ids.habitId);
    const attemptRef = ref.collection("attempts").doc(ids.attemptId);
    const [habitSnapshot, attemptSnapshot] = await Promise.all([
      ref.get(), attemptRef.get(),
    ]);
    try {
      return registrationEligibility({
        habit: habitSnapshot.exists ? habitSnapshot.data() : null,
        attempt: attemptSnapshot.exists ? attemptSnapshot.data() : null,
        attemptId: ids.attemptId,
      });
    } catch (error) {
      if (error instanceof RegistrationPolicyError) {
        throw new HttpsError(error.code, error.message);
      }
      throw error;
    }
  }
);


// PILOTO SEPARADO: registro atómico solo en emulador y proyecto demo.
// No sustituye a Flutter ni permite escrituras en el proyecto real.
const {registerDemoHabit} = require("./habit_registration_transaction");

exports.registerDemoOfficialHabit = onCall(
  {region: "us-central1", enforceAppCheck: false, maxInstances: 3},
  async (request) => {
    if (process.env.FUNCTIONS_EMULATOR !== "true" ||
        process.env.GCLOUD_PROJECT !== "demo-healthy-habit") {
      throw new HttpsError(
        "failed-precondition",
        "El registro de prueba solo funciona en el emulador demo."
      );
    }
    if (!request.auth?.uid) {
      throw new HttpsError(
        "unauthenticated", "Inicia sesión de prueba para continuar."
      );
    }
    try {
      return await registerDemoHabit({
        db, uid: request.auth.uid, data: request.data,
      });
    } catch (error) {
      if (error instanceof RegistrationPolicyError) {
        throw new HttpsError(error.code, error.message);
      }
      throw error;
    }
  }
);


// Fija el calendario de un intento NUEVO. Solo emulador demo:
// esta operación no migra intentos con registros o recompensas.
const {lockDemoHabitCalendar} = require("./habit_calendar_activation");

exports.lockDemoHabitCalendar = onCall(
  {region: "us-central1", enforceAppCheck: false, maxInstances: 3},
  async (request) => {
    if (process.env.FUNCTIONS_EMULATOR !== "true" ||
        process.env.GCLOUD_PROJECT !== "demo-healthy-habit") {
      throw new HttpsError(
        "failed-precondition", "Solo disponible en el emulador demo."
      );
    }
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Inicia sesión de prueba.");
    }
    try {
      return await lockDemoHabitCalendar({
        db, uid: request.auth.uid, data: request.data,
      });
    } catch (error) {
      if (error instanceof RegistrationPolicyError) {
        throw new HttpsError(error.code, error.message);
      }
      throw error;
    }
  }
);


// Activación piloto protegida por Admin SDK; exclusiva del emulador demo.
// No despliega ni reemplaza la activación actual de Flutter.
const {activateDemoHabit} = require("./habit_activation_transaction");

exports.activateDemoOfficialHabit = onCall(
  {region: "us-central1", enforceAppCheck: false, maxInstances: 3},
  async (request) => {
    if (process.env.FUNCTIONS_EMULATOR !== "true" ||
        process.env.GCLOUD_PROJECT !== "demo-healthy-habit") {
      throw new HttpsError(
        "failed-precondition", "La activación solo existe en el emulador demo."
      );
    }
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Inicia sesión de prueba.");
    }
    try {
      return await activateDemoHabit({
        db, uid: request.auth.uid, data: request.data,
      });
    } catch (error) {
      if (error instanceof RegistrationPolicyError) {
        throw new HttpsError(error.code, error.message);
      }
      throw error;
    }
  }
);


// Cancelación piloto: descuento confirmado y operación idempotente.
// Existen cero permisos de despliegue real; se limita al emulador demo.
const {cancelDemoHabit} = require("./habit_cancellation_transaction");

exports.cancelDemoOfficialHabit = onCall(
  {region: "us-central1", enforceAppCheck: false, maxInstances: 3},
  async (request) => {
    if (process.env.FUNCTIONS_EMULATOR !== "true" ||
        process.env.GCLOUD_PROJECT !== "demo-healthy-habit") {
      throw new HttpsError(
        "failed-precondition", "La cancelación solo existe en el emulador demo."
      );
    }
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Inicia sesión de prueba.");
    }
    try {
      return await cancelDemoHabit({
        db, uid: request.auth.uid, data: request.data,
      });
    } catch (error) {
      if (error instanceof RegistrationPolicyError) {
        throw new HttpsError(error.code, error.message);
      }
      throw error;
    }
  }
);


// Easter egg de pruebas: nunca habilitado en Firebase de producción.
const {isSecretTestEnvironment, claimSecretTestBonus} =
  require("./secret_test_bonus");

exports.claimSecretTestBonus = onCall(
  {region: "us-central1", enforceAppCheck: false, maxInstances: 3},
  async (request) => {
    if (!isSecretTestEnvironment(process.env)) {
      throw new HttpsError("failed-precondition",
        "La bonificación secreta solo existe en el emulador demo.");
    }
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated",
        "Debes iniciar sesión en el entorno de prueba.");
    }
    try {
      return await claimSecretTestBonus({db, uid: request.auth.uid});
    } catch (error) {
      throw new HttpsError("failed-precondition",
        error.message || "No fue posible entregar la bonificación.");
    }
  }
);

// Piloto de compra de cosméticos desde Admin SDK (solo emulador demo).
// No modifica ShopService de Flutter ni permite compras en producción.
const {purchaseDemoShopItem} = require("./shop_purchase_transaction");

exports.purchaseDemoShopItem = onCall(
  {region: "us-central1", enforceAppCheck: false, maxInstances: 3},
  async (request) => {
    if (process.env.FUNCTIONS_EMULATOR !== "true" ||
        process.env.GCLOUD_PROJECT !== "demo-healthy-habit") {
      throw new HttpsError(
        "failed-precondition", "Las compras de prueba solo funcionan en el emulador demo."
      );
    }
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Inicia sesión de prueba.");
    }
    try {
      return await purchaseDemoShopItem({
        db, uid: request.auth.uid, data: request.data,
      });
    } catch (error) {
      if (error instanceof RegistrationPolicyError) {
        throw new HttpsError(error.code, error.message);
      }
      throw error;
    }
  }
);


// Puente experimental de los 36 hábitos: ÚNICAMENTE Emulator + proyecto demo.
// No cambiar esta barrera para Spark/Blaze; el cliente normal nunca
// debe invocar estas operaciones mientras la economía siga migrándose.
const {registerOfficialHabitTransaction} =
  require("./habit_registration_transaction");
const {activateOfficialHabitTransaction} =
  require("./habit_activation_transaction");
const {cancelOfficialHabitTransaction} =
  require("./habit_cancellation_transaction");

function requireIsolatedOfficialDemo(request) {
  if (process.env.FUNCTIONS_EMULATOR !== "true" ||
      process.env.GCLOUD_PROJECT !== "demo-healthy-habit") {
    throw new HttpsError(
      "failed-precondition",
      "Las operaciones oficiales experimentales solo existen en demo-healthy-habit Emulator."
    );
  }
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Inicia sesión en Auth Emulator.");
  }
}

function officialDemoCallable(operation) {
  return onCall(
    {region: "us-central1", enforceAppCheck: false, maxInstances: 3},
    async (request) => {
      requireIsolatedOfficialDemo(request);
      try {
        return await operation({
          db, uid: request.auth.uid, data: request.data,
        });
      } catch (error) {
        if (error instanceof RegistrationPolicyError) {
          throw new HttpsError(error.code, error.message);
        }
        // Errores inesperados (Admin SDK, consultas, índices, etc.)
        // normalmente se muestran al cliente solo como "internal".
        // El log se emite exclusivamente en el emulador demo.
        console.error("[official-demo-callable] Error inesperado:", {
          operation: operation.name || "anonymous",
          code: error?.code ?? null,
          message: error?.message ?? String(error),
          stack: error?.stack ?? null,
        });
        throw new HttpsError(
          "internal",
          "Error interno del servidor de pruebas. Revisa el registro de "
            + "Functions Emulator: [official-demo-callable]."
        );
      }
    }
  );
}

exports.activateOfficialHabitDemo = officialDemoCallable(
  activateOfficialHabitTransaction
);
exports.cancelOfficialHabitDemo = officialDemoCallable(
  cancelOfficialHabitTransaction
);
exports.registerOfficialHabitDemo = officialDemoCallable(
  registerOfficialHabitTransaction
);

// Reservar una ruta de fotografía SOLO para el intento oficial en curso.
// No adjunta imágenes al log y jamás acredita XP.
const {reserveHabitEvidence} = require("./habit_evidence_reservation");
exports.reserveHabitEvidenceDemo = officialDemoCallable(reserveHabitEvidence);

// Inspecciona bytes desde Storage Emulator y vincula la imagen únicamente
// a un registro económico YA confirmado; no cambia XP ni Habit Coins.
const {attachHabitEvidence} = require("./habit_evidence_attachment");
// Subida exclusiva de Admin SDK: Storage Rules prohíben escritura directa.
const {uploadReservedEvidence} = require("./habit_evidence_upload");
exports.uploadReservedEvidenceDemo = officialDemoCallable(async (args) => {
  if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Storage Emulator no está disponible."
    );
  }
  const {getStorage} = require("firebase-admin/storage");
  return uploadReservedEvidence({
    ...args,
    bucket: getStorage().bucket("demo-healthy-habit.firebasestorage.app"),
  });
});

exports.attachHabitEvidenceDemo = officialDemoCallable(async (args) => {
  if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Storage Emulator no está disponible."
    );
  }
  const {getStorage} = require("firebase-admin/storage");
  const bucket = getStorage().bucket(
    "demo-healthy-habit.firebasestorage.app"
  );
  return attachHabitEvidence({...args, bucket});
});



// Reclamo de premios habilitado únicamente en el emulador aislado.
// No exponerlo en producción hasta finalizar la migración de hábitos
// y publicar reglas económicas seguras en una entrega coordinada.
const {
  claimDailyStreakRewardTransaction, DailyStreakClaimError,
} = require("./streak_claim_transaction");

exports.claimDailyStreakReward = onCall(
  {region: "us-central1", enforceAppCheck: false, maxInstances: 3},
  async (request) => {
    if (process.env.FUNCTIONS_EMULATOR !== "true" ||
        process.env.GCLOUD_PROJECT !== "demo-healthy-habit") {
      throw new HttpsError("failed-precondition",
        "Los premios diarios siguen en pruebas aisladas.");
    }
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Inicia sesión.");
    }
    const data = request.data ?? {};
    if (!data || typeof data !== "object" ||
        Array.isArray(data) ||
        Object.keys(data).length !== 1) {
      throw new HttpsError("invalid-argument", "Solicitud inválida.");
    }
    try {
      return await claimDailyStreakRewardTransaction({
        db, uid: request.auth.uid, day: data.day,
      });
    } catch (error) {
      if (error instanceof DailyStreakClaimError) {
        throw new HttpsError(error.code, error.message);
      }
      throw error;
    }
  }
);


// LABORATORIO: análisis visual sin escrituras ni recompensas.
// Se permite exclusivamente en el proyecto demo y Functions Emulator.
// La llamada usa Vision API solo cuando está configurada en el emulador.
const {
  EvidencePreviewError,
  analyzeEvidencePreview,
} = require("./evidence_preview");

exports.analyzeEvidencePreview = onCall(
  {region: "us-central1", enforceAppCheck: false, maxInstances: 2,
    memory: "512MiB", timeoutSeconds: 30},
  async (request) => {
    if (process.env.FUNCTIONS_EMULATOR !== "true" ||
        process.env.GCLOUD_PROJECT !== "demo-healthy-habit") {
      throw new HttpsError("failed-precondition",
          "Análisis disponible exclusivamente en el emulador demo.");
    }
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Inicia sesión de prueba.");
    }
    // Evita llamadas involuntarias a una API facturable:
    // la sesión local debe habilitar el proveedor explícitamente.
    if (process.env.HEALTHY_VISION_LIVE_DEMO !== "enabled") {
      throw new HttpsError("failed-precondition",
          "Activa HEALTHY_VISION_LIVE_DEMO=enabled solo para probar Vision.");
    }
    try {
      return await analyzeEvidencePreview(request.data || {});
    } catch (error) {
      if (error instanceof EvidencePreviewError) {
        throw new HttpsError(error.code, error.message);
      }
      if (error?.code === "MODULE_NOT_FOUND" ||
          String(error?.message).includes("Could not load the default credentials")) {
        throw new HttpsError("failed-precondition",
            "Configura Cloud Vision y credenciales de prueba en el emulador.");
      }
      if (String(error?.message || "").includes("HEALTHY_VISION_GCP_PROJECT")) {
        throw new HttpsError("failed-precondition",
            "Configura HEALTHY_VISION_GCP_PROJECT para el proveedor de pruebas.");
      }
      // Diagnostico exclusivamente en el servidor local, sin incluir
      // imagenes, tokens, solicitudes o datos personales en la salida.
      const safeCode = typeof error?.code === "number" ? error.code : "unknown";
      const safeMessage = String(error?.message || "Sin detalle")
          .replace(/[\r\n]+/g, " ").slice(0, 220);
      console.error("Evidence preview provider failure", safeCode, safeMessage);
      throw new HttpsError("unavailable",
          "No se pudo analizar la imagen. Revisa los logs del emulador.");
    }
  },
);

