import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../servicios/healthy_local_image_recognition.dart';
import '../../tema/healthy_theme.dart';

/// Resultado informativo de ML Kit; no comprueba la ejecución de un hábito.
class HealthyLocalVisionPanel extends StatefulWidget {
  const HealthyLocalVisionPanel({
    super.key,
    required this.image,
    this.saving = false,
  });

  final Uint8List image;
  final bool saving;

  @override
  State<HealthyLocalVisionPanel> createState() => _HealthyLocalVisionPanelState();
}

class _HealthyLocalVisionPanelState extends State<HealthyLocalVisionPanel> {
  int _request = 0;
  bool _busy = false;
  String? _error;
  List<HealthyDetectedLabel>? _labels;

  @override
  void didUpdateWidget(covariant HealthyLocalVisionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.image, widget.image)) {
      _request++;
      _busy = false;
      _error = null;
      _labels = null;
    }
  }

  Future<void> _analyze() async {
    if (_busy || widget.saving) return;
    final current = ++_request;
    setState(() {
      _busy = true;
      _error = null;
      _labels = null;
    });
    try {
      final result = await const HealthyLocalImageRecognition()
          .analyze(widget.image);
      if (!mounted || current != _request) return;
      setState(() => _labels = result);
    } catch (error) {
      if (!mounted || current != _request) return;
      setState(() => _error =
          'No se pudo reconocer la foto en este dispositivo. '
          'Revisa que ML Kit esté instalado y vuelve a intentarlo.');
      debugPrint('ML Kit image labeling error: ${error.runtimeType}');
    } finally {
      if (mounted && current == _request) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('healthy-local-vision-panel'),
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HealthyAdaptive.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome_rounded,
                color: HealthyAdaptive.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Reconocimiento de imagen',
              style: TextStyle(color: HealthyAdaptive.text,
                  fontWeight: FontWeight.w800),
            )),
            const Text('EN EL CELULAR',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Detecta elementos visibles con Google ML Kit. La foto se '
            'analiza en este Android sin enviarla a Cloud Vision. '
            'El resultado es orientativo y no concede recompensas.',
            style: TextStyle(color: HealthyAdaptive.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('healthy-local-vision-analyze'),
            onPressed: _busy || widget.saving ||
                    !HealthyLocalImageRecognition.supported ? null : _analyze,
            icon: _busy
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.document_scanner_outlined),
            label: Text(_busy ? 'Reconociendo…' : 'Reconocer fotografía'),
          ),
          if (!HealthyLocalImageRecognition.supported)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Esta función requiere un dispositivo Android.'),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: TextStyle(
                  color: Theme.of(context).colorScheme.error)),
            ),
          if (_labels != null) ...[
            const SizedBox(height: 12),
            Text(_labels!.isEmpty
                ? 'No se identificaron elementos con suficiente confianza.'
                : 'Elementos identificados:',
              key: const ValueKey('healthy-local-vision-result'),
              style: TextStyle(color: HealthyAdaptive.text,
                  fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final label in _labels!) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text(label.name,
                    style: TextStyle(color: HealthyAdaptive.text))),
                  Text('${(label.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: HealthyAdaptive.muted)),
                ]),
              ),
              LinearProgressIndicator(
                value: label.confidence.clamp(0.0, 1.0),
                minHeight: 4,
              ),
            ],
            const SizedBox(height: 8),
            Text('Es una detección visual, no una verificación del hábito.',
                style: TextStyle(color: HealthyAdaptive.muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
