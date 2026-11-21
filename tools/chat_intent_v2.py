#!/usr/bin/env python3
"""Nueva evaluación V2: v1/train + v2/train; v2/test intacto.

No utiliza v1/test (ya observado) en entrenamiento ni calibración.
Se comparan centroides y Naive Bayes con y sin el filtro de abstención.
El filtro no concede acciones y nunca se integra automáticamente a Flutter.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from chat_intent_train import (
    CORPUS, ROOT, CentroidClassifier, evaluate, normalize, validate,
)
from chat_intent_compare import (
    MultinomialNaiveBayes, choose_bayes_config, choose_centroid_config,
    choose_candidate, score_development,
)
from chat_intent_safety import safe_prediction

V2 = ROOT / "datasets/chat_intents_es_v2_new.json"
OUTPUT = ROOT / "outputs/mr_healthy_intent_v2_report.json"


def v2_rows(path: Path = V2) -> tuple[list[dict], list[str]]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if raw.get("schemaVersion") != 2 or raw.get("language") != "es-MX":
        raise ValueError("Formato V2 incompatible")
    labels = raw.get("labels")
    samples = raw.get("samples")
    if not isinstance(labels, list) or len(labels) != 15:
        raise ValueError("15 intenciones requeridas")
    if not isinstance(samples, list):
        raise ValueError("Sin ejemplos V2")
    ids, messages = set(), set()
    counts = {}
    for row in samples:
        if row["intent"] not in labels or row["split"] not in {"train", "test"}:
            raise ValueError("Intención o split inválido")
        key = normalize(row["text"])
        if len(key) < 3 or key in messages or row["id"] in ids:
            raise ValueError("Texto o ID repetido: " + row["id"])
        messages.add(key)
        ids.add(row["id"])
        counts[row["intent"], row["split"]] = (
            counts.get((row["intent"], row["split"]), 0) + 1
        )
    for label in labels:
        if counts.get((label, "train")) != 10 or counts.get((label, "test")) != 4:
            raise ValueError("Se requieren 10 train y 4 test por clase")
    return samples, labels


def prepare() -> tuple[list[dict], list[dict], list[dict], list[dict], list[str]]:
    old_data = json.loads(CORPUS.read_text(encoding="utf-8"))
    old_rows, old_labels = validate(old_data)
    new_rows, labels = v2_rows()
    if old_labels != labels:
        raise ValueError("Las etiquetas cambiaron entre versiones")
    old_training = [row for row in old_rows if row["split"] == "train"]
    old_evaluation = [row for row in old_rows if row["split"] == "test"]
    new_training = [row for row in new_rows if row["split"] == "train"]
    new_evaluation = [row for row in new_rows if row["split"] == "test"]

    previous_test_text = {normalize(row["text"]) for row in old_evaluation}
    new_text = {normalize(row["text"]) for row in new_rows}
    if previous_test_text & new_text:
        raise ValueError("Fuga de evaluación V1 a corpus V2")
    old_train_text = {normalize(row["text"]) for row in old_training}
    if old_train_text & new_text:
        raise ValueError("Fuga de entrenamiento V1 a corpus V2")

    # Para la iteración V2, solo calibrar con los últimos tres ejemplos
    # de v2/train de cada intención, sin consultar v2/test.
    dev_ids = {
        row["id"]
        for label in labels
        for row in [x for x in new_training if x["intent"] == label][-3:]
    }
    dev = [row for row in new_training if row["id"] in dev_ids]
    fitting = old_training + [
        row for row in new_training if row["id"] not in dev_ids
    ]
    complete_train = old_training + new_training
    if len(fitting) != 330 or len(dev) != 45 or len(complete_train) != 375:
        raise ValueError("Tamaños inesperados del conjunto V2")
    if len(new_evaluation) != 60:
        raise ValueError("Test V2 debe contener 60 ejemplos nuevos")
    return fitting, dev, complete_train, new_evaluation, labels


def filtered_evaluate(model, examples: list[dict], labels: list[str],
                      cutoff: tuple[float, float]) -> dict:
    class SafeAdapter:
        def predict(self, message, min_similarity=0.0, min_margin=0.0):
            original = model.predict(message, min_similarity, min_margin)
            return safe_prediction(message, original)

    return evaluate(SafeAdapter(), examples, labels, cutoff)


def score_safe_dev(model, dev, labels, cutoff) -> dict:
    report = filtered_evaluate(model, dev, labels, cutoff)
    return {
        "macro_f1": report["macro_f1"],
        "accuracy": report["accuracy"],
        "critical_errors": len(report["critical_routing_errors"]),
        "abstentions": report["abstentions"],
    }


def choose_safe_cutoff(model, dev, labels, candidates) -> tuple[tuple, dict]:
    selected = None
    for cutoff in candidates:
        metrics = score_safe_dev(model, dev, labels, cutoff)
        priority = (
            -metrics["critical_errors"], metrics["macro_f1"],
            metrics["accuracy"], -metrics["abstentions"],
            -cutoff[0], -cutoff[1],
        )
        if selected is None or priority > selected[0]:
            selected = (priority, cutoff, metrics)
    assert selected is not None
    return selected[1], selected[2]


def experiment():
    fitting, dev, training, test, labels = prepare()
    c_cal = CentroidClassifier.fit(fitting, labels)
    c_raw = choose_centroid_config(c_cal, dev, labels)
    c_cut = c_raw["cutoff"]

    b_raw = choose_bayes_config(fitting, dev, labels)
    b_cal = MultinomialNaiveBayes.fit(fitting, labels, b_raw["alpha"])
    b_cut = b_raw["cutoff"]

    # La seguridad se calibra exclusivamente con ejemplos de desarrollo.
    centroid_safe_cut, centroid_safe_dev = choose_safe_cutoff(
        c_cal, dev, labels,
        [(s, m) for s in (0.0, 0.06, 0.10, 0.14, 0.18, 0.22, 0.28)
         for m in (0.0, 0.015, 0.03, 0.05, 0.08)],
    )
    bayes_safe_cut, bayes_safe_dev = choose_safe_cutoff(
        b_cal, dev, labels,
        [(s, m) for s in (0.0, 0.25, 0.4, 0.55, 0.7, 0.85)
         for m in (0.0, 0.05, 0.15, 0.3)],
    )

    candidates = {
        "tfidf_raw": (c_raw["dev"], c_cut),
        "tfidf_safety": (centroid_safe_dev, centroid_safe_cut),
        "bayes_raw": (b_raw["dev"], b_cut),
        "bayes_safety": (bayes_safe_dev, bayes_safe_cut),
    }
    # Selección del candidato en development (NUNCA por el test).
    chosen = max(candidates, key=lambda name: (
        -candidates[name][0]["critical_errors"],
        candidates[name][0]["macro_f1"],
        candidates[name][0]["accuracy"],
        -candidates[name][0]["abstentions"],
        name,
    ))

    c_final = CentroidClassifier.fit(training, labels)
    b_final = MultinomialNaiveBayes.fit(training, labels, b_raw["alpha"])
    models = {
        "tfidf_raw": c_final, "tfidf_safety": c_final,
        "bayes_raw": b_final, "bayes_safety": b_final,
    }
    reports = {}
    for name, (dev_metrics, cutoff) in candidates.items():
        model = models[name]
        test_metrics = (
            filtered_evaluate(model, test, labels, cutoff)
            if name.endswith("_safety")
            else evaluate(model, test, labels, cutoff)
        )
        reports[name] = {
            "development": dev_metrics,
            "cutoff": list(cutoff),
            "test": test_metrics,
        }
    winner = reports[chosen]["test"]
    return {
        "schemaVersion": 2,
        "origin": "225 v1/train + 150 novel v2/train; no v1/test",
        "training": 375, "fit": 330, "dev": 45, "new_test": 60,
        "selected_on_development": chosen,
        "models": reports,
        "experimental_acceptance": (
            winner["macro_f1"] >= 0.85 and
            len(winner["critical_routing_errors"]) == 0
        ),
        "production_ready": False,
        "note": "V1 test never used. Safety filter only abstains; no Firebase actions.",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=OUTPUT)
    args = parser.parse_args()
    data = experiment()
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print("V2: 375 entrenamiento, 45 desarrollo internos, 60 test nuevos")
    print("Seleccionado solo en desarrollo:", data["selected_on_development"])
    for name, row in data["models"].items():
        metric = row["test"]
        print("{}: exactitud {:.1%}, macro-F1 {:.3f}, cobertura {:.1%},"
              " críticos {}".format(
                  name, metric["accuracy"], metric["macro_f1"],
                  metric["coverage"], len(metric["critical_routing_errors"])
              ))
    print("Informe:", args.report)
    if not data["experimental_acceptance"]:
        print("NO APROBADO: sin integración a Flutter.", file=sys.stderr)
        return 2
    print("Criterio experimental satisfecho, sin autorización de despliegue.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
