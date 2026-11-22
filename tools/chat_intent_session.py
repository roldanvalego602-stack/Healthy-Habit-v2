#!/usr/bin/env python3
"""Estado conversacional de corta duración para el prototipo de Mr. Healthy.

La intención se aporta desde un clasificador o del oráculo del test: este
módulo NO afirma reconocerla por sí solo. No consulta historial, Firebase,
saldo, salud personal ni ejecuta acciones. El estado NO se persiste.
"""
from __future__ import annotations

from dataclasses import dataclass
import re

from chat_intent_train import normalize
from chat_intent_dialogue import guide

TOPICS = {
    "huevo": "huevo",
    "huevos": "huevo",
    "fibra": "fibra",
    "avena": "avena",
    "lentejas": "lentejas",
}
ACCOUNT = re.compile(r"\b(cuenta|perfil|usuario)\b")
HABIT = re.compile(r"\b(habito|habitos|actividad|actividades|rutina)\b")
FOOD = re.compile(r"\b(huevo|huevos|jamon|crudo|cocinarlo|cocido)\b")
FOLLOWUP = re.compile(
    r"\b(y si|si lo|si le|con jamon|prepararlo|comerlo|cocinarlo|"
    r"eso|este|esa|lo preparo|lo cocino|le agrego|le pongo)\b"
)
CANCEL = re.compile(r"\b(cancela|cancelar|olvidalo|mejor no|no hagas nada)\b")
COINS = re.compile(r"\b(monedas|habitcoins|habit coins|coins|saldo)\b")
XP = re.compile(r"\b(xp|experiencia|nivel)\b")
MAX_IDLE_TURNS = 2


@dataclass
class SessionState:
    topic: str | None = None
    pending_intent: str | None = None
    pending_target: str | None = None
    age: int = 0

    def reset(self):
        self.topic = None
        self.pending_intent = None
        self.pending_target = None
        self.age = 0


class DialogueSession:
    def __init__(self):
        self.state = SessionState()

    def reset(self):
        self.state.reset()

    @staticmethod
    def _topic(text: str) -> str | None:
        tokens = set(normalize(text).split())
        for word, topic in TOPICS.items():
            if word in tokens:
                return topic
        return None

    def step(self, text: str, predicted_intent: str) -> dict:
        """Procesar un turno; no heredar permisos o contexto destructivo."""
        q = normalize(text)
        previous = self.state
        previous_topic = previous.topic
        pending = previous.pending_intent if previous.age < MAX_IDLE_TURNS else None
        # Una orden de cancelación sólo cierra la solicitud pendiente.
        if CANCEL.search(q) and pending and not ACCOUNT.search(q) and not HABIT.search(q):
            self.state.reset()
            return {
                "recognized_intent": predicted_intent,
                "context_intent": None,
                "topic": None,
                "outcome": "cancel_pending",
                "message": "Cancelé la solicitud pendiente; no se modificó ningún dato.",
                "route_hint": None,
                "needs_confirmation": False,
                "may_execute_action": False,
                "experimental": True,
            }

        context_intent = None
        topic = self._topic(text)
        # La referencia educativa solo se hereda si NO hay otro tema explícito,
        # y NO si el usuario cambia a monedas/XP, cuenta o hábitos.
        if (not topic and previous_topic and FOLLOWUP.search(q)
                and not (COINS.search(q) or XP.search(q) or ACCOUNT.search(q)
                         or HABIT.search(q))):
            topic = previous_topic
            if predicted_intent in ("ambiguo_necesita_aclaracion", "abstenerse"):
                context_intent = "consultar_nutricion"

        # El seguimiento de una solicitud sensible puede aportar un objeto,
        # pero jamás autoriza aplicar el cambio. Solo se ofrece revisión.
        if pending in {"agregar_habito", "eliminar_habito"} and HABIT.search(q):
            # No convertir una consulta explícita diferente en una operación.
            if predicted_intent in {"abstenerse", "ambiguo_necesita_aclaracion"}:
                context_intent = pending
        if (pending == "eliminar_cuenta" and ACCOUNT.search(q)
                and predicted_intent in {"abstenerse", "ambiguo_necesita_aclaracion"}):
            context_intent = "eliminar_cuenta"

        # El contexto es auxiliar y nunca reemplaza la intención explícita.
        effective = context_intent or predicted_intent
        if context_intent in {"agregar_habito", "eliminar_habito", "eliminar_cuenta"}:
            # No inyectar un verbo de borrado para superar el filtro: pedir
            # confirmación/revisión manual, sin invocar la acción operacional.
            reply = {
                "outcome": "clarify",
                "route_hint": None,
                "message": "Entiendo el contexto. Indica exactamente qué quieres "
                           "revisar; no realizaré cambios automáticamente.",
                "needs_confirmation": True,
            }
        else:
            reply = guide(text, {
                "intent": effective,
                "candidate": effective,
                "similarity": 1.0, "margin": 1.0,
            })

        if effective == "consultar_nutricion" and topic:
            # No dar fichas nutricionales sin pasar por el recuperador existente.
            reply["outcome"] = "knowledge_lookup"
            reply["message"] = None
            reply["route_hint"] = None

        explicit_change = predicted_intent not in {
            "ambiguo_necesita_aclaracion", "abstenerse"
        }
        # Evitar contaminación por temas anteriores.
        if effective != "consultar_nutricion":
            topic = None
        self.state.topic = topic
        self.state.pending_target = None
        if explicit_change and predicted_intent in {
            "eliminar_cuenta", "agregar_habito", "eliminar_habito"
        }:
            self.state.pending_intent = predicted_intent
            self.state.age = 0
        elif context_intent and pending:
            self.state.pending_intent = pending
            self.state.age += 1
        else:
            self.state.pending_intent = None
            self.state.age = 0

        return {
            "recognized_intent": predicted_intent,
            "context_intent": context_intent,
            "topic": topic,
            "outcome": reply["outcome"],
            "message": reply.get("message"),
            "route_hint": reply.get("route_hint"),
            "needs_confirmation": reply.get("needs_confirmation", False),
            "pending_intent": self.state.pending_intent,
            "may_execute_action": False,
            "experimental": True,
        }
