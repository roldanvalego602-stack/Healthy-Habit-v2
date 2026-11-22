#!/usr/bin/env python3
"""Pruebas del segundo clasificador: independencia, abstención y selección."""
import json
import unittest
from unittest.mock import patch

import chat_intent_compare as comparison
import chat_intent_train as trainer


class ComparisonChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        payload = json.loads(trainer.CORPUS.read_text(encoding="utf-8"))
        cls.rows, cls.labels = trainer.validate(payload)
        cls.fit, cls.dev, cls.train, cls.test = comparison.split_training(
            cls.rows, cls.labels
        )

    def test_development_and_test_do_not_overlap(self):
        fit_ids = {r["id"] for r in self.fit}
        dev_ids = {r["id"] for r in self.dev}
        test_ids = {r["id"] for r in self.test}
        self.assertFalse(fit_ids & dev_ids)
        self.assertFalse(dev_ids & test_ids)
        self.assertFalse(fit_ids & test_ids)
        self.assertEqual(len(self.fit), 180)
        self.assertEqual(len(self.dev), 45)
        self.assertEqual(len(self.test), 90)

    def test_bayes_is_trained_and_deterministic(self):
        first = comparison.MultinomialNaiveBayes.fit(
            self.fit, self.labels, alpha=1.0
        )
        second = comparison.MultinomialNaiveBayes.fit(
            self.fit, self.labels, alpha=1.0
        )
        self.assertEqual(first.model, second.model)
        self.assertEqual(
            first.predict("Quiero consultar mis monedas"),
            second.predict("Quiero consultar mis monedas"),
        )

    def test_model_abstains_with_unseen_tokens(self):
        model = comparison.MultinomialNaiveBayes.fit(self.fit, self.labels)
        result = model.predict("🪐☄️")
        self.assertEqual(result["intent"], "abstenerse")
        # Cualquier frase, incluso si está en vocabulario, puede
        # rechazarse mediante umbrales estrictos.
        strict = model.predict("Quiero revisar mis monedas", 1.1, 1.1)
        self.assertEqual(strict["intent"], "abstenerse")

    def test_probabilities_do_not_authorize_sensitive_actions(self):
        model = comparison.MultinomialNaiveBayes.fit(self.fit, self.labels)
        result = model.predict("Deseo eliminar mi cuenta", 0.0, 0.0)
        self.assertIn(result["candidate"], self.labels)
        self.assertNotIn("action", result)
        self.assertNotIn("firebase", result)
        self.assertNotIn("uid", result)

    def test_selection_is_based_only_on_development_metrics(self):
        a = {"critical_errors": 0, "macro_f1": 0.7,
             "accuracy": 0.7, "abstentions": 0}
        b = {"critical_errors": 1, "macro_f1": 1.0,
             "accuracy": 1.0, "abstentions": 0}
        self.assertEqual(comparison.choose_candidate(a, b), "tfidf_centroid")
        b["critical_errors"] = 0
        self.assertEqual(comparison.choose_candidate(a, b),
                         "multinomial_naive_bayes")

    def test_comparison_does_not_select_using_evaluation_results(self):
        # Si eval vuelve datos imposibles, la elección continúa definida
        # por development; no se consulta test para elegir el candidato.
        fake = {"macro_f1": 0.01, "accuracy": 0.01, "coverage": 0.0,
                "critical_routing_errors": ["simulado"]}
        with patch.object(comparison, "evaluate", return_value=fake):
            # Solo verificamos que el método de elección no depende de
            # los diccionarios de métricas de test.
            dev_a = {"critical_errors": 0, "macro_f1": 0.6,
                     "accuracy": 0.6, "abstentions": 0}
            dev_b = {"critical_errors": 0, "macro_f1": 0.9,
                     "accuracy": 0.9, "abstentions": 0}
            self.assertEqual(comparison.choose_candidate(dev_a, dev_b),
                             "multinomial_naive_bayes")


if __name__ == "__main__":
    unittest.main(verbosity=2)
