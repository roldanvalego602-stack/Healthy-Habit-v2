import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../servicios/evidence_demo_service.dart';
import '../../servicios/healthy_vision_debug_service.dart';
import '../../servicios/habit_vision_profile.dart';
import '../../tema/healthy_theme.dart';

/// El panel solo aparece en debug + HH_VISION_DEBUG=true.
/// No comparte credenciales, documentos ni transacciones con la cuenta real.
class HealthyVisionPreviewPanel extends StatefulWidget {
  const HealthyVisionPreviewPanel({
    super.key,
    required this.image,
    required this.category,
    required this.habitTitle,
    this.saving = false,
  });

  final Uint8List image;
  final String category;
  final String habitTitle;
  final bool saving;

  @override
  State<HealthyVisionPreviewPanel> createState() =>
      _HealthyVisionPreviewPanelState();
}

class _HealthyVisionPreviewPanelState extends State<HealthyVisionPreviewPanel> {
  bool _busy = false;
  String? _profile;
  bool _manualSelection = false;
  String? _error;
  DemoVisualPreview? _preview;
  int _revision = 0;

  static const _labelSpanish = <String, String>{
    'text': 'Texto', 'font': 'Tipografía', 'screenshot': 'Captura de pantalla',
    'number': 'Número', 'electronic device': 'Dispositivo electrónico',
    'technology': 'Tecnología', 'display device': 'Pantalla',
    'software': 'Software', 'multimedia': 'Multimedia', 'symbol': 'Símbolo',
    'food': 'Alimento', 'ingredient': 'Ingrediente',
    'staple food': 'Alimento básico', 'cereal': 'Cereal',
    'breakfast cereal': 'Cereal de desayuno', 'meal': 'Comida',
    'breakfast': 'Desayuno', 'lunch': 'Almuerzo', 'dinner': 'Cena',
    'fruit': 'Fruta', 'vegetable': 'Verdura', 'apple': 'Manzana',
    'banana': 'Plátano', 'orange': 'Naranja', 'carrot': 'Zanahoria',
    'salad': 'Ensalada', 'rice': 'Arroz', 'bread': 'Pan',
    'water': 'Agua', 'drinking water': 'Agua potable',
    'bottled water': 'Agua embotellada', 'water bottle': 'Botella de agua',
    'glass': 'Vaso', 'bottle': 'Botella', 'beverage': 'Bebida',
    'drink': 'Bebida', 'sandwich': 'Sándwich', 'soup': 'Sopa',
    'pasta': 'Pasta', 'tomato': 'Tomate',
  };

  static String _displayLabel(String value) =>
      _labelSpanish[value.trim().toLowerCase()] ?? value;


  @override
  void initState() {
    super.initState();
    _profile = HabitVisionProfile.suggest(
      title: widget.habitTitle, category: widget.category,
    );
  }

  @override
  void didUpdateWidget(covariant HealthyVisionPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.image, widget.image) ||
        oldWidget.category != widget.category ||
        oldWidget.habitTitle != widget.habitTitle) {
      _revision++;
      _preview = null;
      _error = null;
      _busy = false;
      _manualSelection = false;
      _profile = HabitVisionProfile.suggest(
        title: widget.habitTitle, category: widget.category,
      );
    }
  }

  Future<void> _analyze() async {
    if (_busy || widget.saving || !HealthyVisionDebugService.enabled ||
        _profile == null) return;
    final request = ++_revision;
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    try {
      final result = await HealthyVisionDebugService
          .analyze(widget.image, _profile!)
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
          'No se pudo analizar (${error.code}). ' +
          (HealthyVisionDebugService.useLiveBackend
              ? 'Verifica el despliegue y los permisos del piloto.'
              : 'Comprueba que Vision esté habilitado en el emulador.'));
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
          Text(
            'Hábito actual: ${widget.habitTitle}',
            style: TextStyle(
              color: HealthyAdaptive.text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _manualSelection
                ? 'Perfil elegido manualmente para esta prueba.'
                : _profile == null
                    ? 'Este hábito no tiene un perfil visual automático. '
                      'El análisis está desactivado hasta elegir uno compatible.'
                    : 'Perfil sugerido automáticamente: '
                      '${HabitVisionProfile.label(_profile)}.',
            style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _profile,
            decoration: const InputDecoration(
              labelText: 'Perfil visual (opcional)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            hint: const Text('Selecciona perfil de prueba'),
            items: const [
              DropdownMenuItem(value: 'hydration', child: Text('Hidratación')),
              DropdownMenuItem(
                value: 'fruit_vegetable', child: Text('Frutas y verduras')),
              DropdownMenuItem(value: 'meal', child: Text('Comida')),
            ],
            onChanged: _busy || widget.saving ? null : (value) {
              if (value != null) setState(() {
                _revision++;
                _manualSelection = true;
                _profile = value;
                _preview = null;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('healthy-vision-analyze'),
            onPressed: _busy || widget.saving || _profile == null ? null : _analyze,
            icon: _busy
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.document_scanner_outlined),
            label: Text(_busy ? 'Analizando…' : 'Analizar con IA (sin XP)'),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _preview!.status == 'visual_match_only'
                      ? Icons.info_outline_rounded
                      : Icons.help_outline_rounded,
                  color: HealthyAdaptive.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _preview!.status == 'visual_match_only'
                        ? 'Elementos relacionados detectados'
                        : 'Sin coincidencia clara',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: HealthyAdaptive.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _preview!.message,
              style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted),
            ),
            if (_preview!.labels.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Principales elementos detectados',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: HealthyAdaptive.text,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              for (final label in _preview!.labels.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _displayLabel(label.name),
                          style: TextStyle(
                            color: HealthyAdaptive.text,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(label.confidence * 100).toStringAsFixed(0)} %',
                        style: TextStyle(
                          color: HealthyAdaptive.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                'Estos porcentajes reflejan la confianza de detección, '
                'no la probabilidad de que hayas cumplido el hábito.',
                style: TextStyle(
                  fontSize: 11,
                  color: HealthyAdaptive.muted,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Sin verificación de hábitos ni XP adicional.',
              style: TextStyle(fontSize: 11, color: HealthyAdaptive.muted),
            ),
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
