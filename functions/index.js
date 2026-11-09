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
