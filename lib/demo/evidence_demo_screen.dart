import 'dart:typed_data';
import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../servicios/evidence_demo_service.dart';

/// Solo para `flutter run -t lib/demo/evidence_demo_main.dart`.
/// No forma parte de la navegación de la aplicación normal.
class EvidenceDemoScreen extends StatefulWidget {
  const EvidenceDemoScreen({
    super.key,
    required this.auth,
    required this.functions,
  });

  final FirebaseAuth auth;
  final FirebaseFunctions functions;

  @override
  State<EvidenceDemoScreen> createState() => _EvidenceDemoScreenState();
}

class _EvidenceDemoScreenState extends State<EvidenceDemoScreen> {
  final _picker = ImagePicker();
  String _objectId = 'spoon';
  String _profileId = 'hydration';
  DemoVisualPreview? _visualResult;
  bool _busy = false;
  bool _ready = false;
  String? _error;
  String? _feedback;
  String _step = 'Sin iniciar';
  DemoChallenge? _challenge;
  Uint8List? _photo;

  late final EvidenceDemoService _service =
      EvidenceDemoService.firebase(widget.functions);

  static const _objects = <String, String>{
    'spoon': 'Cuchara',
    'pen': 'Bolígrafo',
    'paper': 'Papel',
    'cup': 'Taza',
    'napkin': 'Servilleta',
  };

  Future<void> _execute(Future<void> Function() task) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await task().timeout(const Duration(seconds: 25));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Authentication (${e.code}): ${e.message ?? "Sin detalle"}');
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Firebase: ${e.code}. ${e.message ?? "Sin detalle"}';
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _error = 'Tiempo agotado en: $_step. Revisa adb reverse y los emuladores.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error en $_step: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _updateStep(String message) {
    debugPrint('[EvidenceDemo] $message');
    if (mounted) setState(() => _step = message);
  }

  Future<void> _connect() => _execute(() async {
    _updateStep('Autenticando con Firebase local (9099)...');
    final credential = await widget.auth.signInAnonymously()
        .timeout(const Duration(seconds: 12));
    if (credential.user == null) {
      throw StateError('El emulador no devolvió un usuario.');
    }
    _updateStep('Creando hábito ficticio mediante Functions (5001)...');
    await _service.prepareDemoHabit()
        .timeout(const Duration(seconds: 12));
    if (!mounted) return;
    setState(() {
      _ready = true;
      _step = 'Conexión completada';
      _feedback = 'Sesión de prueba y hábito ficticio preparados.';
    });
  });

  Future<void> _start() => _execute(() async {
    final challenge = await _service.startChallenge(_objectId);
    if (!mounted) return;
    setState(() {
      _challenge = challenge;
      _photo = null;
      _visualResult = null;
      _feedback = 'Desafío emitido por Firebase Emulator.';
    });
  });

  Future<void> _takePhoto() => _execute(() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 40,
    );
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photo = bytes;
      _visualResult = null;
      _feedback = 'Fotografía lista. Al pulsar Analizar se enviará '
          'temporalmente a Google Cloud Vision desde el emulador local. '
          'No se guarda en Firestore.';
    });
  });

  Future<void> _analyzePhoto() => _execute(() async {
    final photo = _photo;
    if (photo == null) return;
    _updateStep('Analizando fotografía en el laboratorio...');
    final result = await _service.previewPhoto(photo, _profileId);
    if (!mounted) return;
    setState(() {
      _visualResult = result;
      _feedback = result.message;
      _step = 'Análisis visual completado (sin recompensas)';
    });
  });

  Future<void> _testCodeOnly() => _execute(() async {
    final challenge = _challenge;
    if (challenge == null) return;
    final result = await _service.checkTypedCode(challenge);
    if (!mounted) return;
    setState(() {
      _feedback =
          'Código válido: ${result.codeMatched}. '
          'Imagen verificada: ${result.imageVerified}. '
          'XP entregados: ${result.xpAwarded}. '
          'El desafío ya no se puede reutilizar.';
      _challenge = null;
    });
  });

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mr. Healthy · laboratorio'),
        backgroundColor: const Color(0xFFE7F6ED),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'DEMO AISLADA — solo emuladores locales. '
            'No modifica tu cuenta, progreso, hábitos ni monedas.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text('Estado: $_step', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy || _ready ? null : _connect,
            icon: const Icon(Icons.link),
            label: Text(_ready ? 'Sesión de prueba preparada' : 'Conectar a Firebase local'),
          ),
          const SizedBox(height: 20),
          const Text('Reconocimiento de imágenes (laboratorio)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Requiere Firebase Emulator y Google Cloud Vision '
              'configurado con credenciales de prueba. '
              'La fotografía solo se envía si pulsas Analizar. '
              'No se almacena ni se conceden XP o monedas.'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _profileId,
            decoration: const InputDecoration(
              labelText: 'Categoría visual',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'hydration', child: Text('Hidratación')),
              DropdownMenuItem(value: 'fruit_vegetable',
                  child: Text('Frutas y verduras')),
              DropdownMenuItem(value: 'meal', child: Text('Comida')),
            ],
            onChanged: _busy ? null : (value) {
              if (value != null) {
                setState(() {
                  _profileId = value;
                  _visualResult = null;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: !_ready || _busy ? null : _takePhoto,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Tomar foto para análisis'),
          ),
          if (_photo != null) ...[
            const SizedBox(height: 8),
            Image.memory(_photo!, height: 165, fit: BoxFit.contain),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: !_ready || _busy ? null : _analyzePhoto,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Analizar imagen (sin XP)'),
            ),
          ],
          if (_visualResult != null) ...[
            const SizedBox(height: 10),
            Text(_visualResult!.status == 'visual_match_only'
                ? 'Coincidencia visual orientativa'
                : 'Imagen no concluyente',
              style: const TextStyle(fontWeight: FontWeight.w700)),
            for (final label in _visualResult!.labels)
              Text('${label.name}: ${(label.confidence * 100).toStringAsFixed(0)} %'),
            const Text('Esto NO comprueba que hayas realizado el hábito. '
                'No se modifica tu progreso ni se registra evidencia.'),
          ],
          const SizedBox(height: 20),
          const Text('Hábito ficticio: beber agua',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _objectId,
            decoration: const InputDecoration(
              labelText: 'Objeto accesible para el desafío',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final choice in _objects.entries)
                DropdownMenuItem(value: choice.key, child: Text(choice.value)),
            ],
            onChanged: _busy || challenge != null
                ? null
                : (value) {
                    if (value != null) setState(() => _objectId = value);
                  },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: !_ready || _busy || challenge != null ? null : _start,
            icon: const Icon(Icons.security),
            label: const Text('Solicitar desafío'),
          ),
          if (challenge != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text('Código temporal (5 minutos)'),
                    SelectableText(
                      challenge.code,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                      ),
                    ),
                    Text('Objeto: ${_objects[challenge.objectId] ?? challenge.objectId}'),
                    Text('Caduca: ${challenge.expiresAt.toLocal()}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Escribe el código en una hoja y colócalo con el objeto '
                      'junto a un vaso de agua. Por ahora, la cámara solo '
                      'permite revisar la composición.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Tomar fotografía de prueba'),
                    ),
                    if (_photo != null) ...[
                      const SizedBox(height: 12),
                      Image.memory(_photo!, height: 220, fit: BoxFit.contain),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _busy ? null : _testCodeOnly,
                      child: const Text('Probar consumo del código (sin analizar foto)'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_busy) const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
          if (_feedback != null) Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(_feedback!, style: const TextStyle(color: Color(0xFF176545))),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aviso: una foto tomada no equivale a un hábito verificado. '
            'La clasificación visual es orientativa y no verifica hábitos. '
            'Solo se envía la foto cuando se solicita expresamente '
            'el análisis desde el laboratorio.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
