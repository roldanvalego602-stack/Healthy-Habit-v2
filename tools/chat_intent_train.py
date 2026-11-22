#!/usr/bin/env python3
"""Entrenar/evaluar un clasificador local de intenciones para Mr. Healthy.

Solo biblioteca estándar: no ejecuta Flutter, no consulta servicios externos,
no toca Firebase y NO instala un modelo en la aplicación.

Uso:
  python3 tools/chat_intent_train.py
  python3 tools/chat_intent_train.py --predict "Cuántas monedas me quedan"
  python3 tools/chat_intent_train.py --model outputs/mr_healthy_intent_model_v1.json
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import json
import math
from pathlib import Path
import re
import sys
import unicodedata

ROOT = Path(__file__).resolve().parents[1]
CORPUS = ROOT / "datasets/chat_intents_es_v1.json"
DEFAULT_MODEL = ROOT / "outputs/mr_healthy_intent_model_v1.json"
DEFAULT_REPORT = ROOT / "outputs/mr_healthy_intent_report_v1.json"
SENSITIVE_LABELS = {"eliminar_cuenta", "eliminar_habito", "consultar_saldo"}
SCHEMA_VERSION = 1


def normalize(text: str) -> str:
    text = unicodedata.normalize("NFKD", text.casefold())
    text = "".join(c for c in text if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9]+", " ", text)).strip()


def features(text: str) -> Counter[str]:
    clean = normalize(text)
    words = clean.split()
    result: Counter[str] = Counter()
    for w in words:
        result["w:" + w] += 2
    for a, b in zip(words, words[1:]):
        result["b:" + a + "_" + b] += 2
    for word in words:
        padded = "^" + word + "$"
        for n in (3, 4, 5):
            for i in range(max(0, len(padded) - n + 1)):
                result["c:" + padded[i:i + n]] += 1
    return result


def validate(data: dict) -> tuple[list[dict], list[str]]:
    if data.get("schemaVersion") != SCHEMA_VERSION:
        raise ValueError("Versión de dataset no soportada")
    if data.get("language") != "es-MX":
        raise ValueError("Idioma del dataset incorrecto")
    labels = data.get("labels")
    samples = data.get("samples")
    if not isinstance(labels, list) or len(labels) != len(set(labels)):
        raise ValueError("Etiquetas inválidas o repetidas")
    if not isinstance(samples, list) or not samples:
        raise ValueError("Sin ejemplos")
    ids: set[str] = set()
    texts: set[str] = set()
    counts: Counter[tuple[str, str]] = Counter()
    for item in samples:
        if not isinstance(item, dict):
            raise ValueError("Ejemplo inválido")
        if item.get("split") not in ("train", "test"):
            raise ValueError("Split train/test requerido")
        if item.get("intent") not in labels:
            raise ValueError("Intención fuera de catálogo")
        value = item.get("text")
        if not isinstance(value, str) or len(normalize(value)) < 3:
            raise ValueError("Texto de intención vacío")
        if not isinstance(item.get("id"), str) or item["id"] in ids:
            raise ValueError("IDs repetidos o no válidos")
        text_key = normalize(value)
        if text_key in texts:
            raise ValueError("Fuga entre corpus o ejemplo duplicado: " + value)
        ids.add(item["id"])
        texts.add(text_key)
        counts[item["intent"], item["split"]] += 1
    for label in labels:
        if counts[label, "train"] < 8 or counts[label, "test"] < 3:
            raise ValueError("Datos insuficientes para " + label)
    return samples, labels


class CentroidClassifier:
    """Modelo entrenable de recuperación TF-IDF multiclase, no un LLM."""

    def __init__(self, model: dict):
        self.model = model
        self.idf = model["idf"]
        self.centroids = model["centroids"]
        self.labels = sorted(self.centroids)

    @staticmethod
    def vector(counts: Counter[str], idf: dict[str, float]) -> dict[str, float]:
        vec = {key: (1 + math.log(freq)) * idf[key]
               for key, freq in counts.items() if key in idf}
        norm = math.sqrt(sum(v * v for v in vec.values()))
        return {key: val / norm for key, val in vec.items()} if norm else {}

    @classmethod
    def fit(cls, examples: list[dict], labels: list[str]) -> "CentroidClassifier":
        document_counts: Counter[str] = Counter()
        tokenized: list[Counter[str]] = []
        for row in examples:
            row_features = features(row["text"])
            tokenized.append(row_features)
            document_counts.update(row_features.keys())
        n_docs = len(examples)
        idf = {feature: round(math.log((1 + n_docs) / (1 + freq)) + 1, 7)
               for feature, freq in sorted(document_counts.items())}
        accumulated: dict[str, dict[str, float]] = {
            label: defaultdict(float) for label in labels
        }
        totals: Counter[str] = Counter()
        for row, tokens in zip(examples, tokenized):
            totals[row["intent"]] += 1
            for key, value in cls.vector(tokens, idf).items():
                accumulated[row["intent"]][key] += value
        centers = {}
        for label in labels:
            if totals[label] == 0:
                raise ValueError("Clase ausente en entrenamiento: " + label)
            center = accumulated[label]
            length = math.sqrt(sum(v * v for v in center.values()))
            centers[label] = {
                key: round(value / length, 8)
                for key, value in sorted(center.items())
                if value and length
            }
        return cls({"schemaVersion": 1, "algorithm": "tfidf_centroid",
                    "idf": idf, "centroids": centers})

    def rank(self, message: str) -> list[tuple[str, float]]:
        query = self.vector(features(message), self.idf)
        results = [
            (label, sum(v * center.get(key, 0) for key, v in query.items()))
            for label, center in self.centroids.items()
        ]
        return sorted(results, key=lambda r: (-r[1], r[0]))

    def predict(self, message: str, min_similarity: float = 0.0,
                min_margin: float = 0.0) -> dict:
        ranked = self.rank(message)
        top = ranked[0]
        runner_up = ranked[1][1] if len(ranked) > 1 else 0.0
        margin = max(0.0, top[1] - runner_up)
        label = top[0] if top[1] >= min_similarity and margin >= min_margin             else "abstenerse"
        return {"intent": label, "candidate": top[0],
                "similarity": round(top[1], 4),
                "margin": round(margin, 4),
                "alternatives": [{"intent": k, "similarity": round(v, 4)}
                                 for k, v in ranked[:3]]}


def choose_threshold(model: CentroidClassifier, dev: list[dict]) -> tuple[float, float]:
    # SOLO el subconjunto dev del split train se utiliza para seleccionar
    # umbrales; el split test no influye en entrenamiento ni calibración.
    candidates = [(s, m) for s in (0.0, 0.06, 0.10, 0.14, 0.18, 0.22)
                  for m in (0.0, 0.015, 0.03, 0.05)]
    best = None
    for similarity, margin in candidates:
        predictions = [model.predict(row["text"], similarity, margin)
                       for row in dev]
        correct = sum(p["intent"] == row["intent"] for p, row in zip(predictions, dev))
        abstained = sum(p["intent"] == "abstenerse" for p in predictions)
        dangerous = sum(
            row["intent"] == "eliminar_cuenta" and p["intent"] == "eliminar_habito"
            for p, row in zip(predictions, dev)
        )
        metric = (correct - 0.15 * abstained - 4 * dangerous) / max(1, len(dev))
        candidate = (metric, -abstained, -similarity, -margin, similarity, margin)
        if best is None or candidate > best:
            best = candidate
    assert best is not None
    return best[-2], best[-1]


def evaluate(model: CentroidClassifier, samples: list[dict],
             labels: list[str], threshold: tuple[float, float]) -> dict:
    results = [(row, model.predict(row["text"], *threshold)) for row in samples]
    confusion = {label: {p: 0 for p in labels + ["abstenerse"]}
                 for label in labels}
    for row, prediction in results:
        confusion[row["intent"]][prediction["intent"]] += 1
    correct = sum(row["intent"] == pred["intent"] for row, pred in results)
    abstentions = sum(pred["intent"] == "abstenerse" for _, pred in results)
    by_class = {}
    for label in labels:
        tp = confusion[label][label]
        support = sum(confusion[label].values())
        fp = sum(confusion[other][label] for other in labels if other != label)
        precision = tp / (tp + fp) if tp + fp else 0.0
        recall = tp / support if support else 0.0
        f1 = 2 * precision * recall / (precision + recall)             if precision + recall else 0.0
        by_class[label] = {"support": support, "precision": round(precision, 4),
                           "recall": round(recall, 4), "f1": round(f1, 4)}
    mistakes = [
        {"id": row["id"], "expected": row["intent"],
         "predicted": pred["intent"], "text": row["text"],
         "similarity": pred["similarity"]}
        for row, pred in results if pred["intent"] != row["intent"]
    ]
    dangerous = [
        item for item in mistakes
        if (
            item["expected"] == "eliminar_cuenta" and
            item["predicted"] == "eliminar_habito"
        ) or (
            item["expected"] in {"ambiguo_necesita_aclaracion",
                                "fuera_de_alcance"} and
            item["predicted"] in {"eliminar_cuenta", "eliminar_habito"}
        ) or (
            item["expected"] == "editar_perfil" and
            item["predicted"] == "eliminar_cuenta"
        )
    ]
    return {"total": len(samples), "correct": correct,
            "accuracy": round(correct / len(samples), 4),
            "coverage": round(1 - abstentions / len(samples), 4),
            "abstentions": abstentions,
            "macro_f1": round(sum(p["f1"] for p in by_class.values()) /
                              len(by_class), 4),
            "critical_account_to_habit_errors": [
                e for e in dangerous
                if e["expected"] == "eliminar_cuenta" and
                e["predicted"] == "eliminar_habito"
            ],
            "critical_routing_errors": dangerous,
            "by_class": by_class, "confusion": confusion, "errors": mistakes}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", type=Path, default=CORPUS)
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--predict", help="Clasifica una frase con el modelo guardado")
    args = parser.parse_args()

    if args.predict is not None:
        trained = json.loads(args.model.read_text(encoding="utf-8"))
        classifier = CentroidClassifier(trained)
        cutoff = (trained["min_similarity"], trained["min_margin"])
        print(json.dumps(classifier.predict(args.predict, *cutoff),
                         ensure_ascii=False, indent=2))
        return 0

    data = json.loads(args.data.read_text(encoding="utf-8"))
    samples, labels = validate(data)
    training = [row for row in samples if row["split"] == "train"]
    evaluation = [row for row in samples if row["split"] == "test"]
    per_label: dict[str, list[dict]] = {
        label: [row for row in training if row["intent"] == label]
        for label in labels
    }
    # Dev queda excluido del ajuste y se usa únicamente para umbrales.
    dev = [row for label in labels for row in per_label[label][-3:]]
    fit_rows = [row for label in labels for row in per_label[label][:-3]]
    calibration = CentroidClassifier.fit(fit_rows, labels)
    thresholds = choose_threshold(calibration, dev)
    # Ajuste final exclusivamente con training; test sigue intacto.
    trained = CentroidClassifier.fit(training, labels)
    trained.model["min_similarity"] = thresholds[0]
    trained.model["min_margin"] = thresholds[1]
    trained.model["labels"] = labels
    trained.model["training_count"] = len(training)
    trained.model["critical_policy"] = (
        "ADVISORY_ONLY; authorization and confirmation remain in existing "
        "deterministic Flutter code")
    result = evaluate(trained, evaluation, labels, thresholds)
    report = {
        "schemaVersion": SCHEMA_VERSION,
        "training_examples": len(training),
        "development_examples": len(dev),
        "evaluation_examples": len(evaluation),
        "model": "tfidf_centroid",
        "thresholds_selected_on_train_dev": {
            "min_similarity": thresholds[0],
            "min_margin": thresholds[1],
        },
        "evaluation": result,
        "status": "experimental_not_connected_to_flutter",
    }
    args.model.parent.mkdir(parents=True, exist_ok=True)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.model.write_text(json.dumps(trained.model, ensure_ascii=False,
                                    sort_keys=True, separators=(",", ":")),
                          encoding="utf-8")
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2),
                           encoding="utf-8")
    print("Entrenamiento: {0} | desarrollo: {1} | test: {2}".format(
        len(training), len(dev), len(evaluation)))
    print("Exactitud test: {accuracy:.1%} | macro-F1: {macro_f1:.3f} | "
          "cobertura: {coverage:.1%} | abstenciones: {abstentions}".format(**result))
    print("Errores críticos de enrutamiento: {}".format(
        len(result["critical_routing_errors"])))
    print("Modelo:", args.model)
    print("Informe:", args.report)
    # Falta de calidad NO elimina el reporte: el equipo puede analizar errores.
    # Código 2 indica que no debe proponerse integración como decisor único.
    if result["critical_routing_errors"] or result["macro_f1"] < 0.85:
        print("REVISAR: métricas insuficientes para integración.", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
