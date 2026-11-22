#!/usr/bin/env python3
"""Regresiones de estado conversacional sin conexión con Flutter."""
import json
import unittest

from chat_intent_session import DialogueSession
from chat_intent_train import ROOT


class SessionChecks(unittest.TestCase):
    def test_huevo_followups_without_repeating_subject(self):
        session = DialogueSession()
        first = session.step("Háblame del huevo", "consultar_nutricion")
        second = session.step("¿Y si lo preparo con jamón?",
                              "ambiguo_necesita_aclaracion")
        third = session.step("¿Es peligroso comerlo crudo?",
                             "ambiguo_necesita_aclaracion")
        self.assertEqual(first["topic"], "huevo")
        self.assertEqual(second["context_intent"], "consultar_nutricion")
        self.assertEqual(third["topic"], "huevo")
        self.assertEqual(third["outcome"], "knowledge_lookup")
        self.assertFalse(third["may_execute_action"])

    def test_change_to_balance_clears_food_context(self):
        session = DialogueSession()
        session.step("¿Qué nutrientes aporta el huevo?", "consultar_nutricion")
        answer = session.step("¿Y mis monedas?", "consultar_saldo")
        self.assertIsNone(answer["topic"])
        self.assertIsNone(answer["context_intent"])
        self.assertEqual(answer["recognized_intent"], "consultar_saldo")
        self.assertIsNone(answer["message"])

    def test_ambiguous_delete_never_inherits_account_operation(self):
        session = DialogueSession()
        session.step("Quiero borrar mi cuenta", "eliminar_cuenta")
        answer = session.step("Hazlo ya", "ambiguo_necesita_aclaracion")
        self.assertIsNone(answer["context_intent"])
        self.assertFalse(answer["may_execute_action"])
        self.assertIsNone(answer["route_hint"])

    def test_habit_followup_keeps_pending_intent_but_no_action(self):
        session = DialogueSession()
        session.step("Quiero eliminar un hábito", "eliminar_habito")
        follow = session.step("Ese hábito de caminar",
                              "ambiguo_necesita_aclaracion")
        self.assertEqual(follow["context_intent"], "eliminar_habito")
        self.assertEqual(follow["outcome"], "clarify")
        self.assertTrue(follow["needs_confirmation"])
        self.assertFalse(follow["may_execute_action"])
        self.assertIsNone(follow["route_hint"])

    def test_cancel_clears_pending(self):
        session = DialogueSession()
        session.step("Quiero quitar un hábito", "eliminar_habito")
        answer = session.step("No, mejor cancela",
                              "ambiguo_necesita_aclaracion")
        self.assertEqual(answer["outcome"], "cancel_pending")
        self.assertIsNone(session.state.pending_intent)
        self.assertFalse(answer["may_execute_action"])

    def test_reset_clears_every_reference(self):
        session = DialogueSession()
        session.step("Háblame del huevo", "consultar_nutricion")
        session.reset()
        answer = session.step("¿Y si le pongo jamón?",
                              "ambiguo_necesita_aclaracion")
        self.assertIsNone(answer["topic"])
        self.assertIsNone(answer["context_intent"])
        self.assertEqual(answer["outcome"], "clarify")

    def test_no_cross_session_state(self):
        first = DialogueSession()
        second = DialogueSession()
        first.step("¿Qué es el huevo?", "consultar_nutricion")
        answer = second.step("¿Y si lo preparo con jamón?",
                             "ambiguo_necesita_aclaracion")
        self.assertIsNone(answer["topic"])
        self.assertFalse(answer["may_execute_action"])

    def test_existing_20_scenarios_preserve_stated_labels(self):
        scenes = json.loads((ROOT / "datasets/chat_dialogues_es_v1.json")
                            .read_text(encoding="utf-8"))["scenarios"]
        self.assertEqual(len(scenes), 20)
        count = 0
        for scene in scenes:
            session = DialogueSession()
            for turn in scene["turns"]:
                result = session.step(turn["text"], turn["expectedIntent"])
                self.assertEqual(result["recognized_intent"],
                                 turn["expectedIntent"])
                self.assertFalse(result["may_execute_action"])
                count += 1
        self.assertEqual(count, 42)


if __name__ == "__main__":
    unittest.main(verbosity=2)
