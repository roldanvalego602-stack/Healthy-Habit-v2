#!/usr/bin/env python3
"""Pruebas locales de integridad, entrenamiento y aislamiento del dataset."""
import json
from pathlib import Path
import tempfile
import unittest

import chat_intent_train as trainer


class DatasetChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.payload = json.loads(trainer.CORPUS.read_text(encoding="utf-8"))
        cls.rows, cls.labels = trainer.validate(cls.payload)

    def test_train_and_test_are_separate(self):
        training = {trainer.normalize(r["text"]) for r in self.rows
                    if r["split"] == "train"}
        evaluation = {trainer.normalize(r["text"]) for r in self.rows
                      if r["split"] == "test"}
        self.assertFalse(training.intersection(evaluation))
        self.assertEqual(len(self.labels), 15)
        self.assertEqual(len(training), 225)
        self.assertEqual(len(evaluation), 90)

    def test_missing_label_or_duplicate_text_is_rejected(self):
        clone = json.loads(json.dumps(self.payload))
        clone["samples"][0]["intent"] = "intencion_inventada"
        with self.assertRaises(ValueError):
            trainer.validate(clone)
        clone = json.loads(json.dumps(self.payload))
        clone["samples"][0]["text"] = clone["samples"][-1]["text"]
        with self.assertRaises(ValueError):
            trainer.validate(clone)

    def test_training_is_deterministic(self):
        examples = [r for r in self.rows if r["split"] == "train"]
        first = trainer.CentroidClassifier.fit(examples, self.labels)
        second = trainer.CentroidClassifier.fit(examples, self.labels)
        self.assertEqual(first.model, second.model)
        self.assertEqual(first.predict("Dime mis monedas"),
                         second.predict("Dime mis monedas"))

    def test_model_abstains_on_unknown_input_with_strict_threshold(self):
        examples = [r for r in self.rows if r["split"] == "train"]
        classifier = trainer.CentroidClassifier.fit(examples, self.labels)
        prediction = classifier.predict("Saturno y telescopios", 1.1, 1.0)
        self.assertEqual(prediction["intent"], "abstenerse")

    def test_model_is_fitted_only_on_training_samples(self):
        training = [r for r in self.rows if r["split"] == "train"]
        classifier = trainer.CentroidClassifier.fit(training, self.labels)
        self.assertEqual(classifier.model["algorithm"], "tfidf_centroid")
        self.assertEqual(set(classifier.labels), set(self.labels))
        report = trainer.evaluate(classifier,
            [r for r in self.rows if r["split"] == "test"],
            self.labels, (0.0, 0.0))
        self.assertEqual(report["total"], 90)
        self.assertIn("macro_f1", report)
        self.assertIn("critical_account_to_habit_errors", report)

    def test_dialogue_set_has_stable_intents_without_private_data(self):
        scenarios = json.loads(
            (trainer.ROOT / "datasets/chat_dialogues_es_v1.json")
            .read_text(encoding="utf-8"))["scenarios"]
        self.assertGreaterEqual(len(scenarios), 20)
        for scenario in scenarios:
            for turn in scenario["turns"]:
                self.assertIn(turn["expectedIntent"], self.labels)
                self.assertEqual(turn["role"], "user")

    def test_no_dependency_on_flutter_or_firebase(self):
        text = (trainer.ROOT / "tools/chat_intent_train.py").read_text(
            encoding="utf-8")
        self.assertNotIn("firebase_admin", text)
        self.assertNotIn("from tensorflow", text)
        self.assertNotIn("import sklearn", text)


if __name__ == "__main__":
    unittest.main(verbosity=2)
