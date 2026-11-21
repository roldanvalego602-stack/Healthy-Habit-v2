#!/usr/bin/env python3
"""Prueba que la nueva iteración no entrene con la evaluación anterior."""
import json
import unittest
from unittest.mock import patch

import chat_intent_train as old
import chat_intent_v2 as v2


class SecondEvaluationChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fitting, cls.dev, cls.complete, cls.test, cls.labels = v2.prepare()
        cls.old = json.loads(old.CORPUS.read_text(encoding="utf-8"))
        cls.new = json.loads(v2.V2.read_text(encoding="utf-8"))

    def test_held_out_examples_never_enter_training(self):
        heldout = {
            old.normalize(row["text"])
            for row in self.old["samples"] if row["split"] == "test"
        }
        heldout.update(old.normalize(row["text"]) for row in self.test)
        combined = {
            old.normalize(row["text"])
            for row in self.complete
        }
        self.assertTrue(heldout.isdisjoint(combined))
        self.assertEqual(len(self.fitting), 330)
        self.assertEqual(len(self.dev), 45)
        self.assertEqual(len(self.complete), 375)
        self.assertEqual(len(self.test), 60)

    def test_development_is_only_from_new_training(self):
        ids = {row["id"] for row in self.dev}
        source = {
            row["id"] for row in self.new["samples"]
            if row["split"] == "train"
        }
        self.assertTrue(ids.issubset(source))
        self.assertEqual(len(ids), 45)
        self.assertFalse(
            ids.intersection(row["id"] for row in self.fitting)
        )

    def test_rejects_leakage_of_previous_evaluation(self):
        # Copiar un ejemplo v1/test a v2/train invalida la nueva prueba.
        altered = json.loads(json.dumps(self.new))
        first_test = next(
            row for row in self.old["samples"] if row["split"] == "test"
        )
        altered["samples"][0]["text"] = first_test["text"]
        from pathlib import Path
        import tempfile
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "altered.json"
            path.write_text(json.dumps(altered), encoding="utf-8")
            with patch.object(v2, "V2", path):
                with self.assertRaises(ValueError):
                    v2.prepare()

    def test_safety_adapter_only_abstains(self):
        model = old.CentroidClassifier.fit(self.fitting, self.labels)
        batch = [
            {"id": "A", "intent": "ambiguo_necesita_aclaracion",
             "text": "Bórralo"},
            {"id": "B", "intent": "eliminar_cuenta",
             "text": "Quiero eliminar mi cuenta"},
        ]
        raw = old.evaluate(model, batch, self.labels, (0.0, 0.0))
        safe = v2.filtered_evaluate(model, batch, self.labels, (0.0, 0.0))
        self.assertEqual(raw["total"], safe["total"])
        # El cortafuegos no genera etiquetas nuevas (sólo abstenciones).
        predictions = {
            row["id"]: row["predicted"]
            for row in raw["errors"]
        }
        for error in safe["errors"]:
            self.assertIn(error["predicted"], self.labels + ["abstenerse"])

    def test_v2_never_authorizes_production(self):
        source = (v2.ROOT / "tools/chat_intent_v2.py").read_text(
            encoding="utf-8")
        self.assertIn('"production_ready": False', source)
        self.assertNotIn("firebase_admin", source)


if __name__ == "__main__":
    unittest.main(verbosity=2)
