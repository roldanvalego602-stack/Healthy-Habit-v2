#!/usr/bin/env python3
"""Orquestación conversacional experimental: comprender != autorizar.

Recibe una intención inferida externamente y la resolución del filtro de
seguridad. Solo propone texto de aclaración o una ruta informativa de UI.
No abre pantallas, no contiene credenciales y no escribe en Firebase.
"""
from __future__ import annotations

from chat_intent_safety import safe_prediction

SENSITIVE = frozenset({"eliminar_cuenta", "eliminar_habito", "agregar_habito"})


def guide(message: str, prediction: dict) -> dict:
    """Devolver intención original, propuesta de conversación y cero permisos."""
    original = prediction.get("intent", "abstenerse")
    screened = safe_prediction(message, prediction)
    safe = screened["intent"]
    outcome = "respond"
    route_hint = None

    if original in SENSITIVE:
        if safe == "abstenerse":
            outcome = "clarify"
            response = (
                "¿Quieres modificar tu cuenta o un hábito? "
                "Especifica qué deseas hacer; no cambiaré nada "
                "sin que lo revises."
            )
        elif original == "eliminar_cuenta":
            outcome = "explain_only"
            response = (
                "Entiendo que preguntas por eliminar tu cuenta. "
                "La eliminación completa todavía no está habilitada. "
                "No se ha borrado ningún dato."
            )
        elif original == "eliminar_habito":
            outcome = "open_review"
            route_hint = "habits_review"
            response = (
                "Entiendo que quieres abandonar un hábito. "
                "¿Cuál hábito activo deseas revisar? "
                "La eliminación requiere validación y confirmación "
                "en la pantalla de hábitos."
            )
        else:
            outcome = "open_review"
            route_hint = "habits_catalog"
            response = (
                "Entiendo que quieres agregar un hábito. "
                "Puedes escogerlo en el catálogo y confirmar "
                "sus condiciones y cupos."
            )
    elif original == "abstenerse":
        outcome = "clarify"
        response = "¿Puedes especificar qué deseas consultar o modificar?"
    elif original == "ambiguo_necesita_aclaracion":
        outcome = "clarify"
        response = "¿A qué te refieres exactamente? Dame un poco más de contexto."
    else:
        # Para las demás intenciones solo conservar una sugerencia de ruta.
        # Su información y respuesta real se obtendría del módulo existente.
        response = None

    return {
        "recognized_intent": original,
        "eligible_intent": safe,
        "outcome": outcome,
        "route_hint": route_hint,
        "message": response,
        "needs_confirmation": original in SENSITIVE,
        "may_execute_action": False,
        "safety_reason": screened["safety_reason"],
        "experimental": True,
    }
