#!/usr/bin/env python3
"""Pruebas de diálogo: clasificación retenida, confirmación siempre externa."""
import unittest

from chat_intent_dialogue import guide


class DialogueChecks(unittest.TestCase):
    @staticmethod
    def prediction(intent):
        return {"intent": intent, "candidate": intent,
                "similarity": 0.91, "margin": 0.70}

    def test_valid_habit_add_is_review_not_execution(self):
        answer = guide("Quiero agregar un hábito", self.prediction("agregar_habito"))
        self.assertEqual(answer["recognized_intent"], "agregar_habito")
        self.assertEqual(answer["eligible_intent"], "agregar_habito")
        self.assertEqual(answer["route_hint"], "habits_catalog")
        self.assertTrue(answer["needs_confirmation"])
        self.assertFalse(answer["may_execute_action"])

    def test_valid_habit_remove_requests_target(self):
        answer = guide("Quiero eliminar un hábito",
                       self.prediction("eliminar_habito"))
        self.assertEqual(answer["outcome"], "open_review")
        self.assertIn("¿Cuál hábito", answer["message"])
        self.assertFalse(answer["may_execute_action"])

    def test_account_delete_explains_unavailable_action(self):
        answer = guide("Quiero eliminar mi cuenta",
                       self.prediction("eliminar_cuenta"))
        self.assertEqual(answer["outcome"], "explain_only")
        self.assertIn("no está habilitada", answer["message"])
        self.assertIsNone(answer["route_hint"])

    def test_ambiguous_delete_keeps_candidate_but_asks_question(self):
        answer = guide("Bórralo", self.prediction("eliminar_cuenta"))
        self.assertEqual(answer["recognized_intent"], "eliminar_cuenta")
        self.assertEqual(answer["eligible_intent"], "abstenerse")
        self.assertEqual(answer["outcome"], "clarify")
        self.assertIsNone(answer["route_hint"])
        self.assertFalse(answer["may_execute_action"])

    def test_unrelated_question_never_opens_delete_ui(self):
        answer = guide("Necesito calcular una integral",
                       self.prediction("eliminar_habito"))
        self.assertEqual(answer["eligible_intent"], "abstenerse")
        self.assertEqual(answer["outcome"], "clarify")

    def test_profile_edit_misclassified_as_delete_cannot_act(self):
        answer = guide("Quiero cambiar mi foto de perfil",
                       self.prediction("eliminar_cuenta"))
        self.assertEqual(answer["eligible_intent"], "abstenerse")
        self.assertFalse(answer["may_execute_action"])

    def test_non_sensitive_queries_do_not_invent_user_data(self):
        answer = guide("Cuántas Habit Coins tengo",
                       self.prediction("consultar_saldo"))
        self.assertEqual(answer["outcome"], "respond")
        self.assertIsNone(answer["message"])
        self.assertFalse(answer["needs_confirmation"])
        self.assertFalse(answer["may_execute_action"])

    def test_uncertain_intent_asks_for_details(self):
        answer = guide("No quiero ese", self.prediction("abstenerse"))
        self.assertEqual(answer["outcome"], "clarify")
        self.assertIsNone(answer["route_hint"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
