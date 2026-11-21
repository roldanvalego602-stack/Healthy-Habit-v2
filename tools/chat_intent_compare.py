#!/usr/bin/env python3
"""Compara TF-IDF centroide vs Naive Bayes sin conectar ninguno a Flutter.

Los hiperparámetros y el modelo preferido se seleccionan exclusivamente con
45 frases de desarrollo, tomadas del split train. Las 90 frases de test se
evalúan al final, sin utilizarlas para ajustar el sistema.
"""
from __future__ import annotations

from collections import Counter, defaultdict
import argparse
import json
import math
from pathlib import Path
import sys

from chat_intent_train import (
    CORPUS, ROOT, CentroidClassifier, choose_threshold, evaluate,
    features, validate,
)

OUTPUT = ROOT / "outputs/mr_healthy_intent_comparison_v1.json"


class MultinomialNaiveBayes:
    """Clasificador supervisado con suavizado de Laplace (solo stdlib)."""

    def __init__(self, model: dict):
        self.model = model
        self.labels = sorted(model["labels"])
        self.vocabulary_size = int(model["vocabulary_size"])
        self.counts = model["counts"]
        self.totals = model["totals"]
        self.priors = model["priors"]
        self.alpha = float(model["alpha"])

    @classmethod
    def fit(cls, samples: list[dict], labels: list[str],
            alpha: float = 1.0) -> "MultinomialNaiveBayes":
        if alpha <= 0:
            raise ValueError("Laplace alpha debe ser positivo")
        counts: dict[str, Counter[str]] = {
            label: Counter() for label in labels
        }
        totals = Counter()
        docs = Counter()
        vocabulary: set[str] = set()
        for row in samples:
            label = row["intent"]
            vector = features(row["text"])
            counts[label].update(vector)
            totals[label] += sum(vector.values())
            docs[label] += 1
            vocabulary.update(vector)
        if not vocabulary or any(docs[label] == 0 for label in labels):
            raise ValueError("Faltan características o clases de entrenamiento")
        model = {
            "schemaVersion": 1,
            "algorithm": "multinomial_naive_bayes",
            "alpha": alpha,
            "labels": labels,
            "vocabulary_size": len(vocabulary),
            "counts": {label: dict(sorted(counts[label].items()))
                       for label in labels},
            "totals": dict(totals),
            "priors": {label: docs[label] / len(samples) for label in labels},
        }
        return cls(model)

    def rank(self, message: str) -> list[tuple[str, float]]:
        vector = features(message)
        # No vocabulario compartido => abstenerse mediante puntuación cero.
        known = {feature: value for feature, value in vector.items()
                 if any(feature in self.counts[label] for label in self.labels)}
        if not known:
            return [(label, 0.0) for label in self.labels]
        scores = []
        for label in self.labels:
            label_count = self.counts[label]
            den = self.totals[label] + self.alpha * self.vocabulary_size
            logprob = math.log(self.priors[label])
            for feature, frequency in known.items():
                logprob += frequency * math.log(
                    (label_count.get(feature, 0) + self.alpha) / den
                )
            scores.append((label, logprob))
        peak = max(score for _, score in scores)
        # Reescalar log-verosimilitudes evita overflow en exp().
        exponentials = [(label, math.exp(score - peak))
                        for label, score in scores]
        divisor = sum(value for _, value in exponentials)
        return sorted(
            [(label, value / divisor) for label, value in exponentials],
            key=lambda row: (-row[1], row[0]),
        )

    def predict(self, message: str, min_similarity: float = 0.0,
                min_margin: float = 0.0) -> dict:
        ranked = self.rank(message)
        highest = ranked[0]
        second = ranked[1][1] if len(ranked) > 1 else 0.0
        margin = highest[1] - second
        # Una posterior alta no autoriza acciones: sigue siendo
        # solo un clasificador experimental.
        confidence = highest[1]
        is_unknown = all(value == 0 for _, value in ranked)
        intent = (highest[0] if not is_unknown and
                  confidence >= min_similarity and
                  margin >= min_margin else "abstenerse")
        return {
            "intent": intent,
            "candidate": highest[0],
            "similarity": round(confidence, 4),
            "margin": round(margin, 4),
            "alternatives": [{"intent": label, "similarity": round(score, 4)}
                             for label, score in ranked[:3]],
        }


def split_training(rows: list[dict], labels: list[str]):
    training = [row for row in rows if row["split"] == "train"]
    test = [row for row in rows if row["split"] == "test"]
    by_label = {label: [row for row in training if row["intent"] == label]
                for label in labels}
    development = [row for label in labels for row in by_label[label][-3:]]
    fit = [row for label in labels for row in by_label[label][:-3]]
    return fit, development, training, test


def score_development(model, development: list[dict], labels: list[str],
                      cutoff: tuple[float, float]) -> dict:
    result = evaluate(model, development, labels, cutoff)
    return {
        "macro_f1": result["macro_f1"],
        "accuracy": result["accuracy"],
        "critical_errors": len(result["critical_routing_errors"]),
        "abstentions": result["abstentions"],
    }


def choose_bayes_config(fit_rows: list[dict], development: list[dict],
                        labels: list[str]):
    selected = None
    for alpha in (0.1, 0.5, 1.0, 2.0):
        model = MultinomialNaiveBayes.fit(fit_rows, labels, alpha)
        for minimum in (0.0, 0.25, 0.40, 0.55, 0.70, 0.85):
            for margin in (0.0, 0.05, 0.15, 0.30):
                metrics = score_development(
                    model, development, labels, (minimum, margin)
                )
                # Seguridad por encima del porcentaje de aciertos.
                priority = (
                    -metrics["critical_errors"],
                    metrics["macro_f1"],
                    metrics["accuracy"],
                    -metrics["abstentions"],
                    -alpha,
                    -minimum,
                    -margin,
                )
                if selected is None or priority > selected["priority"]:
                    selected = {
                        "priority": priority,
                        "alpha": alpha,
                        "cutoff": (minimum, margin),
                        "dev": metrics,
                    }
    assert selected is not None
    return selected


def choose_candidate(centroid_dev: dict, bayes_dev: dict) -> str:
    # La selección NO puede consultar los resultados test.
    left = (-centroid_dev["critical_errors"], centroid_dev["macro_f1"],
            centroid_dev["accuracy"], -centroid_dev["abstentions"])
    right = (-bayes_dev["critical_errors"], bayes_dev["macro_f1"],
             bayes_dev["accuracy"], -bayes_dev["abstentions"])
    return "multinomial_naive_bayes" if right > left else "tfidf_centroid"


def compare(data_path: Path = CORPUS) -> dict:
    corpus = json.loads(data_path.read_text(encoding="utf-8"))
    rows, labels = validate(corpus)
    fit, development, training, test = split_training(rows, labels)

    centroid_calibration = CentroidClassifier.fit(fit, labels)
    centroid_cutoff = choose_threshold(centroid_calibration, development)
    centroid_dev = score_development(
        centroid_calibration, development, labels, centroid_cutoff
    )

    best_nb = choose_bayes_config(fit, development, labels)
    nb_dev = best_nb["dev"]
    selected = choose_candidate(centroid_dev, nb_dev)

    # Entrenar ambos modelos finales únicamente con el split train.
    centroid = CentroidClassifier.fit(training, labels)
    bayes = MultinomialNaiveBayes.fit(training, labels, best_nb["alpha"])

    centroid_test = evaluate(centroid, test, labels, centroid_cutoff)
    bayes_test = evaluate(bayes, test, labels, best_nb["cutoff"])
    reports = {
        "tfidf_centroid": {
            "development": centroid_dev,
            "cutoff": list(centroid_cutoff),
            "test": centroid_test,
        },
        "multinomial_naive_bayes": {
            "development": nb_dev,
            "alpha": best_nb["alpha"],
            "cutoff": list(best_nb["cutoff"]),
            "test": bayes_test,
        },
    }
    winner = reports[selected]["test"]
    safe_enough = (
        winner["macro_f1"] >= 0.85 and
        not winner["critical_routing_errors"]
    )
    return {
        "schemaVersion": 1,
        "training_examples": len(training),
        "development_examples": len(development),
        "test_examples": len(test),
        "selection_basis": "TRAIN_DEV_ONLY",
        "selected_on_development": selected,
        "models": reports,
        "experimental_acceptance": safe_enough,
        "production_ready": False,
        "note": "La selección del candidato no usa test. Ningún modelo"
                " se integra en Flutter ni autoriza acciones.",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", type=Path, default=CORPUS)
    parser.add_argument("--report", type=Path, default=OUTPUT)
    args = parser.parse_args()
    result = compare(args.data)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print("Comparación experimental: centroide TF-IDF vs Naive Bayes")
    print("Seleccionado en desarrollo:", result["selected_on_development"])
    for name, item in result["models"].items():
        report = item["test"]
        print(
            "{}: exactitud {:.1%}, macro-F1 {:.3f}, cobertura {:.1%},"
            " errores críticos {}".format(
                name, report["accuracy"], report["macro_f1"],
                report["coverage"], len(report["critical_routing_errors"])
            )
        )
    print("Informe:", args.report)
    if not result["experimental_acceptance"]:
        print("NO APROBADO: mantener clasificador fuera de Flutter.",
              file=sys.stderr)
        return 2
    print("Aprobación experimental: requiere revisión antes de integración.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
