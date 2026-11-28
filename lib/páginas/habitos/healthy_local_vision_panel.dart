import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../servicios/healthy_local_image_recognition.dart';
import '../../servicios/healthy_visual_match.dart';
import '../../tema/healthy_theme.dart';

/// Análisis local y comparación informativa con el hábito elegido.
/// Nunca verifica acciones humanas ni modifica XP, monedas o registros.
class HealthyLocalVisionPanel extends StatefulWidget {
  const HealthyLocalVisionPanel({
    super.key,
    required this.image,
    this.saving = false,
    this.habitTitle = '',
    this.category = '',
    this.initialProfile,
  });

  final Uint8List image;
  final bool saving;
  final String habitTitle;
  final String category;
  final String? initialProfile;

  @override
  State<HealthyLocalVisionPanel> createState() =>
      _HealthyLocalVisionPanelState();
}

class _HealthyLocalVisionPanelState extends State<HealthyLocalVisionPanel> {
  static const _profiles = <String, String>{
    'fruit_vegetable': 'Frutas y verduras',
    'hydration': 'Agua e hidratación',
    'meal': 'Comida',
  };
  int _request = 0;
  bool _busy = false;
  bool _showTechnicalLabels = false;
  String? _error;
  String? _profile;
  List<HealthyDetectedLabel>? _labels;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile ??
        HealthyVisualMatch.suggestedProfile(
          widget.habitTitle, widget.category);
    // El usuario puede ver inmediatamente si la fotografía es compatible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _analyze();
    });
  }

  @override
  void didUpdateWidget(covariant HealthyLocalVisionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.image, widget.image) ||
        oldWidget.habitTitle != widget.habitTitle ||
        oldWidget.category != widget.category) {
      _request++;
      _busy = false;
      _error = null;
      _labels = null;
      _showTechnicalLabels = false;
      _profile = widget.initialProfile ??
          HealthyVisualMatch.suggestedProfile(
              widget.habitTitle, widget.category);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _analyze();
      });
    }
  }

  Future<void> _analyze() async {
    if (_busy || widget.saving || !HealthyLocalImageRecognition.supported) {
      return;
    }
    final current = ++_request;
    setState(() {
      _busy = true;
      _error = null;
      _labels = null;
      _showTechnicalLabels = false;
    });
    try {
      final result = await const HealthyLocalImageRecognition()
          .analyze(widget.image);
      if (!mounted || current != _request) return;
      setState(() => _labels = result);
    } catch (error) {
      if (!mounted || current != _request) return;
      debugPrint('ML Kit image labeling failed: $error');
      setState(() => _error =
          'No fue posible ejecutar el reconocimiento de esta foto. '
          'Comprueba que instalaste la última versión de Healthy Habit '
          'en Android e inténtalo nuevamente. '
          'Detalle técnico: ${error.runtimeType}.');
    } finally {
      if (mounted && current == _request) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _labelBar(HealthyDetectedLabel label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text(
          HealthyVisualMatch.displayName(label.name),
          style: TextStyle(color: HealthyAdaptive.text))),
        Text('${(label.confidence * 100).round()}%',
          style: TextStyle(color: HealthyAdaptive.muted)),
      ]),
      const SizedBox(height: 3),
      LinearProgressIndicator(
        value: label.confidence.clamp(0.0, 1.0),
        minHeight: 4,
      ),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final match = _labels == null
        ? null
        : HealthyVisualMatch.evaluate(labels: _labels!, profile: _profile);
    final relevant = _labels == null
        ? const <HealthyDetectedLabel>[]
        : HealthyVisualMatch.relevantLabels(
            labels: _labels!, profile: _profile);
    final resultColor = match == null
        ? HealthyAdaptive.muted
        : match.isMatch ? HealthyAdaptive.accent
            : Theme.of(context).colorScheme.error;

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
            Icon(Icons.center_focus_strong_outlined,
                color: HealthyAdaptive.accent, size: 21),
            const SizedBox(width: 8),
            Expanded(child: Text('Análisis de evidencia visual',
              style: TextStyle(color: HealthyAdaptive.text,
                  fontWeight: FontWeight.w800))),
            const Text('LOCAL', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text('Google ML Kit identifica elementos de la fotografía. '
              'Comparamos el resultado con el tipo de hábito esperado; '
              'esto no prueba que se haya realizado la actividad.',
            style: TextStyle(color: HealthyAdaptive.muted, fontSize: 12)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey('healthy-local-vision-profile'),
            value: _profile,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: widget.habitTitle.isEmpty
                  ? 'Categoría para comparación exploratoria'
                  : 'Comparación visual del hábito',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final entry in _profiles.entries)
                DropdownMenuItem(
                    value: entry.key, child: Text(entry.value)),
            ],
            onChanged: widget.saving ? null : (value) {
              setState(() => _profile = value);
            },
          ),
          const SizedBox(height: 5),
          Text(widget.habitTitle.isEmpty
              ? 'Cambiar de categoría solo recalcula la comparación; '
                'no identifica automáticamente una actividad.'
              : 'La comparación está asociada al hábito '
                '«${widget.habitTitle}». Seleccionar otra categoría '
                'solo explora etiquetas: no verifica ese hábito.',
              style: TextStyle(color: HealthyAdaptive.muted,
                  fontSize: 11)),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('healthy-local-vision-analyze'),
            onPressed: _busy || widget.saving ||
                !HealthyLocalImageRecognition.supported ? null : _analyze,
            icon: _busy
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.document_scanner_outlined),
            label: Text(_busy ? 'Analizando fotografía…' :
                _labels == null ? 'Analizar fotografía' :
                'Analizar nuevamente'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('Buscando elementos reconocibles en la imagen…',
                textAlign: TextAlign.center),
            ),
          if (!HealthyLocalImageRecognition.supported)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('El motor local requiere un celular Android.'),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SelectableText(_error!, style: TextStyle(
                  color: Theme.of(context).colorScheme.error)),
            ),
          if (match != null) ...[
            const SizedBox(height: 14),
            Container(
              key: const ValueKey('healthy-local-vision-verdict'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.08),
                border: Border.all(color: resultColor.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(match.isMatch ? Icons.check_circle_outline :
                      Icons.help_outline, color: resultColor),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.isMatch
                            ? 'Coincidencia visual encontrada'
                            : 'Coincidencia no confirmada',
                        style: TextStyle(color: resultColor,
                            fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(match.message, style: TextStyle(
                          color: HealthyAdaptive.text, fontSize: 12)),
                      if (match.isMatch) ...[
                        const SizedBox(height: 5),
                        Text('Confianza del modelo: '
                            '${(match.confidence * 100).round()}%',
                          style: TextStyle(color: HealthyAdaptive.text,
                              fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Elementos relacionados con la categoría:',
              key: const ValueKey('healthy-local-vision-result'),
              style: TextStyle(color: HealthyAdaptive.text,
                  fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (relevant.isEmpty)
              Text('No hay etiquetas relevantes para esta categoría. '
                  'Esto no significa que el objeto no esté en la imagen: '
                  'el etiquetador general puede omitirlo.',
                style: TextStyle(color: HealthyAdaptive.muted,
                    fontSize: 12)),
            for (final label in relevant)
              _labelBar(label),
            if (_labels!.length > relevant.length) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const ValueKey('healthy-local-vision-technical-toggle'),
                onPressed: () => setState(
                    () => _showTechnicalLabels = !_showTechnicalLabels),
                icon: Icon(_showTechnicalLabels
                    ? Icons.expand_less : Icons.expand_more),
                label: Text(_showTechnicalLabels
                    ? 'Ocultar etiquetas técnicas'
                    : 'Ver etiquetas técnicas (pueden ser incorrectas)'),
              ),
            ],
            if (_showTechnicalLabels) ...[
              Text('Salida sin filtrar de ML Kit. Estas etiquetas '
                  'son hipótesis del modelo, no hechos confirmados.',
                style: TextStyle(color: HealthyAdaptive.muted,
                    fontSize: 11)),
              for (final label in _labels!)
                _labelBar(label),
            ],
            const SizedBox(height: 9),
            Text('Una coincidencia indica contenido visible compatible, '
                'no consumo ni cumplimiento. No entrega XP adicional.',
              style: TextStyle(color: HealthyAdaptive.muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
