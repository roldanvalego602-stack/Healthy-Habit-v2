#!/usr/bin/env python3
"""Pruebas de la auditoría sin reutilizar los ejemplos test para ajuste."""
import json
from pathlib import Path
import tempfile
import unittest

import chat_intent_audit as audit


class AuditChecks(unittest.TestCase):
    def test_read_only_audit_comparison(self):
        item = {
            "accuracy": 0.5, "macro_f1": 0.45, "coverage": 0.9,
            "errors": [
                {"id": "I1", "text": "borra mi cuenta",
                 "expected": "eliminar_cuenta",
                 "predicted": "eliminar_habito"}
            ],
            "critical_routing_errors": [
                {"id": "I1", "text": "borra mi cuenta",
                 "expected": "eliminar_cuenta",
                 "predicted": "eliminar_habito"}
            ],
            "by_class": {
                "eliminar_cuenta": {
                    "f1": 0.0, "recall": 0.0, "support": 1
                },
                "eliminar_habito": {
                    "f1": 0.5, "recall": 0.5, "support": 1
                }
            },
        }
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "comparison.json"
            path.write_text(
                json.dumps({"models": {
                    "tfidf_centroid": {"test": item},
                    "multinomial_naive_bayes": {"test": item},
                }}), encoding="utf-8"
            )
            result = audit.load_reports(path)
            self.assertEqual(len(result), 2)
            diagnosis = audit.analyze(result["tfidf_centroid"])
            self.assertEqual(diagnosis["mistakes"], 1)
            self.assertEqual(len(diagnosis["critical"]), 1)
            self.assertEqual(diagnosis["weakest_classes"][0]["intent"],
                             "eliminar_cuenta")
            self.assertEqual(diagnosis["common_confusions"][0]["count"], 1)

    def test_audit_rejects_incomplete_report(self):
        with self.assertRaises(ValueError):
            audit.analyze({"accuracy": 1.0})


if __name__ == "__main__":
    unittest.main(verbosity=2)
