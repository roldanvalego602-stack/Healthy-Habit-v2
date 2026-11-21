#!/usr/bin/env python3
"""Resume los fallos de una evaluación completada. Solo lectura, no entrena.

Admite informes del clasificador inicial y del comparador de dos modelos.
No modifica el dataset ni altera las métricas reservadas.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path

from chat_intent_train import ROOT

DEFAULT_COMPARISON = ROOT / "outputs/mr_healthy_intent_comparison_v1.json"
DEFAULT_BASELINE = ROOT / "outputs/mr_healthy_intent_report_v1.json"
SENSITIVE = {"eliminar_cuenta", "eliminar_habito"}


def load_reports(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    if "models" in data:
        return {name: info["test"] for name, info in data["models"].items()}
    if "evaluation" in data:
        return {data.get("model", "baseline"): data["evaluation"]}
    raise ValueError("Formato de informe desconocido: " + str(path))


def analyze(report: dict) -> dict:
    required = ("errors", "critical_routing_errors", "by_class",
                "accuracy", "macro_f1", "coverage")
    if not all(key in report for key in required):
        raise ValueError("El informe no contiene métricas de evaluación completas")
    errors = report["errors"]
    pairs = Counter((error["expected"], error["predicted"])
                    for error in errors)
    difficult = sorted(
        ((label, metrics["f1"], metrics["recall"],
          metrics["support"]) for label, metrics in report["by_class"].items()),
        key=lambda row: (row[1], row[2], row[0]),
    )
    return {
        "accuracy": report["accuracy"],
        "macro_f1": report["macro_f1"],
        "coverage": report["coverage"],
        "mistakes": len(errors),
        "critical": report["critical_routing_errors"],
        "common_confusions": [
            {"expected": expected, "predicted": predicted, "count": count}
            for (expected, predicted), count in pairs.most_common(10)
        ],
        "weakest_classes": [
            {"intent": label, "f1": f1, "recall": recall, "support": support}
            for label, f1, recall, support in difficult[:6]
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reports", nargs="*", type=Path,
                        default=[DEFAULT_BASELINE, DEFAULT_COMPARISON])
    parser.add_argument("--json", action="store_true",
                        help="Imprimir resumen JSON para procesamiento posterior")
    args = parser.parse_args()
    result = {}
    for path in args.reports:
        for name, metrics in load_reports(path).items():
            result[name] = analyze(metrics)
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 0
    for name, data in result.items():
        print("\n=== {} ===".format(name))
        print("Exactitud: {:.1%}, macro-F1: {:.3f}, cobertura: {:.1%}".format(
            data["accuracy"], data["macro_f1"], data["coverage"]))
        print("Fallos: {}, críticos: {}".format(
            data["mistakes"], len(data["critical"])))
        print("Clases con menor F1:")
        for entry in data["weakest_classes"]:
            print("  {}: F1={:.3f}, recall={:.3f} (n={})".format(
                entry["intent"], entry["f1"], entry["recall"], entry["support"]))
        print("Confusiones frecuentes:")
        for entry in data["common_confusions"]:
            print("  {} → {}: {}".format(
                entry["expected"], entry["predicted"], entry["count"]))
        print("Errores críticos (para revisar, NO usar para reentrenar):")
        for error in data["critical"]:
            print("  {}: '{}' → '{}' (predijo '{}')".format(
                error["id"], error["text"], error["expected"],
                error["predicted"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
