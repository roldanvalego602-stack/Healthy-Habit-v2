#!/usr/bin/env python3
"""Capa experimental de abstención para predicciones de intención.

No autoriza acciones: únicamente puede conservar una clasificación o
devolver 'abstenerse'. No usa datos de evaluación para aprender parámetros.
"""
from __future__ import annotations

import re
from chat_intent_train import normalize

DELETE_WORDS = re.compile(
    r"\b(borra(r|me)?|elimin(ar|a|ame)?|suprimir|suprime|cerrar|cierra|"
    r"dar(me|se)? de baja|doy de baja|desactivar|desactiva|cancelar|cancela|"
    r"quitar|quita|retirar|retira|abandona(r)?)\b"
)
ACCOUNT_OBJECT = re.compile(
    r"\b(cuenta|perfil|usuario|registro personal|datos personales)\b"
)
HABIT_OBJECT = re.compile(
    r"\b(habito|habitos|actividad|actividades|rutina|rutinas)\b"
)
ADD_WORDS = re.compile(
    r"\b(agreg(ar|a)|anad(ir|e)|cre(ar|a)|empezar|comenzar|"
    r"activar|iniciar|incorporar|adoptar)\b"
)


def safe_prediction(message: str, prediction: dict) -> dict:
    """Filtra acciones sensibles; nunca crea un intent que el ML no predijo."""
    candidate = prediction.get("intent", "abstenerse")
    value = normalize(message)
    destructive = bool(DELETE_WORDS.search(value))
    account = bool(ACCOUNT_OBJECT.search(value))
    habit = bool(HABIT_OBJECT.search(value))
    allowed = True
    reason = "unchanged"
    if candidate == "eliminar_cuenta":
        allowed = destructive and account and not habit
        reason = "account_target_not_explicit" if not allowed else reason
    elif candidate == "eliminar_habito":
        allowed = destructive and habit and not account
        reason = "habit_target_not_explicit" if not allowed else reason
    elif candidate == "agregar_habito":
        allowed = bool(ADD_WORDS.search(value)) and habit
        reason = "add_habit_target_not_explicit" if not allowed else reason

    # Conflictos de alcance: mejor solicitar aclaración que adivinar.
    if candidate in {"eliminar_cuenta", "eliminar_habito"} and account and habit:
        allowed = False
        reason = "conflicting_targets"
    return {
        **prediction,
        "intent": candidate if allowed else "abstenerse",
        "safety_status": "accepted_as_suggestion" if allowed else "needs_clarification",
        "safety_reason": reason,
        "may_execute_action": False,
    }
