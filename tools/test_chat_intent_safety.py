#!/usr/bin/env python3
"""Pruebas del filtro auxiliar sin modificar los modelos ni sus umbrales."""
import unittest
from chat_intent_safety import safe_prediction


class SafetyGateChecks(unittest.TestCase):
    @staticmethod
    def prediction(intent):
        return {"intent": intent, "candidate": intent,
                "similarity": 0.99, "margin": 0.98}

    def test_ambiguous_delete_must_abstain(self):
        for text in ["Bórralo", "No quiero ese", "Hazlo ya",
                     "Deseo quitarlo", "Elimínalo por favor"]:
            with self.subTest(text=text):
                result = safe_prediction(text, self.prediction("eliminar_cuenta"))
                self.assertEqual(result["intent"], "abstenerse")
                self.assertFalse(result["may_execute_action"])

    def test_profile_edit_cannot_become_account_deletion(self):
        for text in ["Quiero cambiar mi imagen de perfil",
                     "Necesito editar mi cuenta",
                     "Voy a actualizar mi avatar"]:
            with self.subTest(text=text):
                result = safe_prediction(text, self.prediction("eliminar_cuenta"))
                self.assertEqual(result["intent"], "abstenerse")

    def test_outside_topic_cannot_delete_habit(self):
        result = safe_prediction(
            "Necesito ayuda para calcular algo de álgebra",
            self.prediction("eliminar_habito"),
        )
        self.assertEqual(result["intent"], "abstenerse")

    def test_explicit_account_deletion_is_still_only_a_suggestion(self):
        result = safe_prediction(
            "Quiero eliminar mi cuenta", self.prediction("eliminar_cuenta"))
        self.assertEqual(result["intent"], "eliminar_cuenta")
        self.assertFalse(result["may_execute_action"])

    def test_habit_deletion_does_not_grant_account_deletion(self):
        result = safe_prediction(
            "Deseo borrar el hábito de caminar",
            self.prediction("eliminar_cuenta"))
        self.assertEqual(result["intent"], "abstenerse")

    def test_conflicting_targets_abstain(self):
        result = safe_prediction(
            "Quiero borrar mi cuenta y mis hábitos",
            self.prediction("eliminar_habito"))
        self.assertEqual(result["intent"], "abstenerse")

    def test_add_habit_requires_explicit_action_and_object(self):
        for message in ["¿Qué hábitos existen?", "Agrega eso"]:
            self.assertEqual(
                safe_prediction(message, self.prediction("agregar_habito"))["intent"],
                "abstenerse")
        self.assertEqual(
            safe_prediction("Quiero agregar un hábito",
                            self.prediction("agregar_habito"))["intent"],
            "agregar_habito")

    def test_never_upgrades_a_rejected_prediction(self):
        result = safe_prediction("Quiero borrar mi cuenta",
                                 self.prediction("abstenerse"))
        self.assertEqual(result["intent"], "abstenerse")
        self.assertFalse(result["may_execute_action"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
