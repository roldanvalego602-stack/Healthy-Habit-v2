#!/usr/bin/env python3
"""Auditoría separada: reconocimiento estadístico y elegibilidad operativa.

No entrena ni recalibra modelos. NO proporciona permisos de escritura.
Este es un diagnóstico retrospectivo sobre V2/test ya observado; sus
resultados no constituyen una nueva evaluación independiente.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from chat_intent_compare import MultinomialNaiveBayes
from chat_intent_train import CentroidClassifier, evaluate, ROOT
from chat_intent_v2 import prepare, choose_bayes_config, choose_centroid_config
from chat_intent_safety import safe_prediction

OUTPUT = ROOT / "outputs/mr_healthy_intent_policy_audit_v2.json"
SENSITIVE = frozenset({"eliminar_cuenta", "eliminar_habito", "agregar_habito"})


def analyze_policy(model, examples, labels, cutoff) -> dict:
    """Puntuación original inalterada y métricas de abstención por separado."""
    recognition = evaluate(model, examples, labels, cutoff)
    rows = []
    for row in examples:
        raw = model.predict(row["text"], *cutoff)
        guarded = safe_prediction(row["text"], raw)
        if guarded["intent"] not in (raw["intent"], "abstenerse"):
            raise AssertionError("El filtro creó una intención nueva")
        if guarded["may_execute_action"] is not False:
            raise AssertionError("La clasificación nunca autoriza una acción")
        rows.append({
            "id": row["id"],
            "expected": row["intent"],
            "predicted": raw["intent"],
            "policy_intent": guarded["intent"],
            "policy_status": guarded["safety_status"],
            "policy_reason": guarded["safety_reason"],
        })
    gated = [row for row in rows if row["policy_intent"] == "abstenerse"
             and row["predicted"] != "abstenerse"]
    unsafe_suggestions = [
        row for row in rows
        if row["predicted"] in SENSITIVE
        and row["predicted"] != row["expected"]
        and row["policy_intent"] != "abstenerse"
    ]
    legit_rejected = [
        row for row in gated
        if row["expected"] == row["predicted"]
    ]
    unsafe_blocked = [
        row for row in gated
        if row["predicted"] in SENSITIVE
        and row["expected"] != row["predicted"]
    ]
    return {
        "recognition": {
            "accuracy": recognition["accuracy"],
            "macro_f1": recognition["macro_f1"],
            "coverage": recognition["coverage"],
            "critical_routing_errors_before_policy":
                len(recognition["critical_routing_errors"]),
        },
        "policy": {
            "blocked_total": len(gated),
            "unsafe_suggestions_blocked": len(unsafe_blocked),
            "legitimate_intents_blocked": len(legit_rejected),
            "incorrect_sensitive_suggestions_not_blocked":
                len(unsafe_suggestions),
            "false_rejections": legit_rejected,
            "unblocked_sensitive_mistakes": unsafe_suggestions,
        },
        "total": len(examples),
        "permission_to_act": False,
        "diagnostic_only": True,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=OUTPUT)
    args = parser.parse_args()
    fitting, dev, training, test, labels = prepare()

    centroid_dev = CentroidClassifier.fit(fitting, labels)
    centroid_params = choose_centroid_config(centroid_dev, dev, labels)
    bayes_params = choose_bayes_config(fitting, dev, labels)
    models = {
        "tfidf_centroid": (
            CentroidClassifier.fit(training, labels),
            centroid_params["cutoff"],
        ),
        "multinomial_naive_bayes": (
            MultinomialNaiveBayes.fit(training, labels, bayes_params["alpha"]),
            bayes_params["cutoff"],
        ),
    }
    result = {
        "schemaVersion": 1,
        "evaluation": "V2/test previously observed; diagnostics only",
        "model_selection_unchanged": True,
        "production_ready": False,
        "models": {
            name: analyze_policy(model, test, labels, cutoff)
            for name, (model, cutoff) in models.items()
        },
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(result, indent=2, ensure_ascii=False)
                           + "\n", encoding="utf-8")
    for name, model in result["models"].items():
        a = model["recognition"]
        p = model["policy"]
        print(
            "{}: reconocimiento macro-F1 {:.3f}; bloqueos={}, "
            "bloqueos legítimos={}, errores sensibles sin bloquear={}".format(
                name, a["macro_f1"], p["blocked_total"],
                p["legitimate_intents_blocked"],
                p["incorrect_sensitive_suggestions_not_blocked"],
            )
        )
    print("Informe de diagnóstico:", args.report)
    print("No son resultados nuevos ni autorización para Flutter.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
