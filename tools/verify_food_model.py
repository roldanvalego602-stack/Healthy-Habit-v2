#!/usr/bin/env python3
"""Smoke test externo del modelo ONNX; no se usa en Android en ejecución."""
import hashlib
import json
import pathlib
import tempfile
import urllib.request

import numpy as np
import onnxruntime as ort

VERSION = "46cc9c69263010519dc471c6f5c74cfd301f25f9"
BASE = f"https://huggingface.co/bcbertenex/sekokuva-mobile-423k/resolve/{VERSION}/"
DATA_HASH = "61c5f90b82503fb1e36f9ffac8a102a2c15856b228ee4dde21654c95c8807fe8"
FILES = {
    "onnx/sekokuva_mobile_classifier.onnx": 200_000,
    "onnx/sekokuva_mobile_classifier.onnx.data": 2_000_000,
    "class_names.json": 5_000,
}


def download(relative, target, maximum):
    req = urllib.request.Request(
        BASE + relative,
        headers={"User-Agent": "HealthyHabit-Model-Verification/1"},
    )
    with urllib.request.urlopen(req, timeout=50) as response, target.open("wb") as out:
        content = response.read(maximum + 1)
        if len(content) > maximum:
            raise AssertionError(f"Demasiados bytes: {relative}")
        out.write(content)
    assert target.stat().st_size > 0, relative


def names_from_json(source):
    raw = json.loads(source.read_text(encoding="utf8"))
    if isinstance(raw, list):
        return raw
    if isinstance(raw, dict):
        if all(str(k).isdigit() for k in raw):
            return [raw[str(i)] for i in range(len(raw))]
        return [k for k, _ in sorted(raw.items(), key=lambda pair: pair[1])]
    raise AssertionError("Formato de categorías inesperado")


with tempfile.TemporaryDirectory(prefix="healthy-food-onnx-") as folder:
    root = pathlib.Path(folder)
    (root / "onnx").mkdir()
    for relative, maximum in FILES.items():
        download(relative, root / relative, maximum)
    payload = root / "onnx" / "sekokuva_mobile_classifier.onnx.data"
    assert hashlib.sha256(payload.read_bytes()).hexdigest() == DATA_HASH, "SHA256 inválido"
    names = names_from_json(root / "class_names.json")
    assert len(names) == 65, f"Esperadas 65 clases, recibidas {len(names)}"
    assert "watermelon" in names and "carrot" in names and "apple_fruit" in names
    model_path = root / "onnx" / "sekokuva_mobile_classifier.onnx"
    session = ort.InferenceSession(str(model_path), providers=["CPUExecutionProvider"])
    inputs = session.get_inputs()
    assert len(inputs) == 1, "El puente Android admite una entrada"
    sample = np.zeros((1, 3, 224, 224), dtype=np.float32)
    response = session.run(None, {inputs[0].name: sample})
    assert len(response) >= 1
    prediction = np.asarray(response[0]).reshape(-1)
    assert prediction.shape == (65,), f"Salida incompatible: {prediction.shape}"
    assert np.isfinite(prediction).all(), "Logits inválidos"
    print("Modelo ONNX verificado: SHA256, 65 clases, input NCHW y salida finita")
