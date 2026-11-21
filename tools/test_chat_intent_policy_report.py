#!/usr/bin/env python3
"""Métricas de intención y de seguridad nunca deben confundirse."""
import unittest

from chat_intent_policy_report import analyze_policy


class StubModel:
    def predict(self, text, *cutoff):
        if text == "cambiar perfil":
            intent = "eliminar_cuenta"  # falso positivo sensible
        elif text == "quiero eliminar mi cuenta":
            intent = "eliminar_cuenta"  # intención correcta
        elif text == "ver saldo":
            intent = "consultar_saldo"
        elif text == "borrar hábito":
            intent = "eliminar_habito"  # intención correcta
        else:
            intent = "abstenerse"
        return {"intent": intent, "candidate": intent, "similarity": 0.9,
                "margin": 0.6}


class ReportChecks(unittest.TestCase):
    def setUp(self):
        self.labels = ["editar_perfil", "eliminar_cuenta",
                       "consultar_saldo", "eliminar_habito"]
        self.examples = [
            {"id": "1", "text": "cambiar perfil",
             "intent": "editar_perfil"},
            {"id": "2", "text": "quiero eliminar mi cuenta",
             "intent": "eliminar_cuenta"},
            {"id": "3", "text": "ver saldo", "intent": "consultar_saldo"},
            {"id": "4", "text": "borrar hábito", "intent": "eliminar_habito"},
        ]

    def test_recognition_remains_wrong_even_when_policy_blocks(self):
        result = analyze_policy(
            StubModel(), self.examples, self.labels, (0.0, 0.0)
        )
        self.assertEqual(result["recognition"]["accuracy"], 0.75)
        self.assertEqual(
            result["policy"]["unsafe_suggestions_blocked"], 1
        )
        self.assertEqual(
            result["policy"]["incorrect_sensitive_suggestions_not_blocked"], 0
        )
        self.assertFalse(result["permission_to_act"])

    def test_rejecting_a_valid_intent_is_reported_separately(self):
        class RejectModel(StubModel):
            def predict(self, text, *cutoff):
                return {"intent": "eliminar_cuenta",
                        "candidate": "eliminar_cuenta",
                        "similarity": 0.9, "margin": 0.7}

        sample = [{
            "id": "ambiguous", "text": "quiero algo",
            "intent": "eliminar_cuenta"
        }]
        result = analyze_policy(RejectModel(), sample, self.labels,
                                (0.0, 0.0))
        self.assertEqual(result["recognition"]["accuracy"], 1.0)
        self.assertEqual(result["policy"]["legitimate_intents_blocked"], 1)
        self.assertFalse(result["permission_to_act"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
