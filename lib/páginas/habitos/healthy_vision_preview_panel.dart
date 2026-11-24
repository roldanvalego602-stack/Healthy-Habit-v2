import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../servicios/evidence_demo_service.dart';
import '../../servicios/healthy_vision_debug_service.dart';
import '../../tema/healthy_theme.dart';

/// El panel solo aparece en debug + HH_VISION_DEBUG=true.
/// No comparte credenciales, documentos ni transacciones con la cuenta real.
class HealthyVisionPreviewPanel extends StatefulWidget {
  const HealthyVisionPreviewPanel({
    super.key,
    required this.image,
    required this.category,
    this.saving = false,
  });

  final Uint8List image;
  final String category;
  final bool saving;

  @override
  State<HealthyVisionPreviewPanel> createState() =>
      _HealthyVisionPreviewPanelState();
}

class _HealthyVisionPreviewPanelState extends State<HealthyVisionPreviewPanel> {
  bool _busy = false;
  String _profile = 'hydration';
  String? _error;
  DemoVisualPreview? _preview;
  int _revision = 0;

  static String suggestedProfile(String category) {
    final c = category.toLowerCase();
    if (c.contains('hidrat') || c.contains('agua')) return 'hydration';
    if (c.contains('fruta') || c.contains('verdura')) return 'fruit_vegetable';
    return 'meal';
  }

  @override
  void initState() {
    super.initState();
    _profile = suggestedProfile(widget.category);
  }

  @override
  void didUpdateWidget(covariant HealthyVisionPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.image, widget.image) ||
        oldWidget.category != widget.category) {
      _revision++;
      _preview = null;
      _error = null;
      _busy = false;
      _profile = suggestedProfile(widget.category);
    }
  }

  Future<void> _analyze() async {
    if (_busy || widget.saving || !HealthyVisionDebugService.enabled) return;
    final request = ++_revision;
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    try {
      final result = await HealthyVisionDebugService
          .analyze(widget.image, _profile)
          .timeout(const Duration(seconds: 35));
      if (!mounted || _revision != request) return;
      setState(() => _preview = result);
    } on TimeoutException {
      if (!mounted || _revision != request) return;
      setState(() => _error =
          HealthyVisionDebugService.useLiveBackend
              ? 'Tiempo agotado al conectar con Cloud Functions.'
              : 'Tiempo agotado. Comprueba adb reverse y Firebase Emulator.');
    } on FirebaseFunctionsException catch (error) {
      if (!mounted || _revision != request) return;
      setState(() => _error =
          'No se pudo analizar (${error.code}). '
          HealthyVisionDebugService.useLiveBackend
              ? 'Verifica el despliegue y los permisos del piloto.'
              : 'Comprueba que Vision esté habilitado en el emulador.');
    } catch (_) {
      if (!mounted || _revision != request) return;
      setState(() => _error =
          'El laboratorio no está disponible. '
          'Puedes registrar tu hábito normalmente.');
    } finally {
      if (mounted && _revision == request) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!HealthyVisionDebugService.enabled) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('healthy-vision-debug-panel'),
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HealthyAdaptive.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Análisis visual · laboratorio',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: HealthyAdaptive.text,
                    )),
              ),
              const Text('DEBUG', style: TextStyle(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            HealthyVisionDebugService.useLiveBackend
                ? 'Prueba controlada en Cloud Functions reales. Al pulsar Analizar '
                  'se enviará esta imagen a Google Cloud Vision, con posibles '
                  'cargos. El análisis no otorga XP ni monedas y no guarda la foto.'
                : 'Opcional. Al pulsar Analizar, esta fotografía se envía '
                  'a Google Cloud Vision a través de Firebase Emulator. '
                  'Puede generar cargos de API. No se guarda como resultado '
                  'ni modifica XP, monedas o registros.',
            style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _profile,
            decoration: const InputDecoration(
              labelText: 'Qué tipo de imagen analizar',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'hydration', child: Text('Hidratación')),
              DropdownMenuItem(
                value: 'fruit_vegetable', child: Text('Frutas y verduras')),
              DropdownMenuItem(value: 'meal', child: Text('Comida')),
            ],
            onChanged: _busy || widget.saving ? null : (value) {
              if (value != null) setState(() {
                _revision++;
                _profile = value;
                _preview = null;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('healthy-vision-analyze'),
            onPressed: _busy || widget.saving ? null : _analyze,
            icon: _busy
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.document_scanner_outlined),
            label: Text(_busy ? 'Analizando…' : 'Analizar con IA (sin XP)'),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 10),
            Text(_preview!.status == 'visual_match_only'
                ? 'Contenido compatible detectado'
                : 'Resultado no concluyente',
              style: TextStyle(
                color: HealthyAdaptive.text, fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final label in _preview!.labels)
              Text('${label.name}: ${(label.confidence * 100).toStringAsFixed(0)} %',
                style: TextStyle(fontSize: 12, color: HealthyAdaptive.text)),
            const SizedBox(height: 4),
            Text('La imagen no prueba que realizaste el hábito.',
              style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: scheme.error, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
