import 'dart:typed_data';

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
  bool _busy = false;
  bool _ready = false;
  String? _error;
  String? _feedback;
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
      await task();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Firebase: ${e.code}. ${e.message ?? "Sin detalle"}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _execute(() async {
    await widget.auth.signInAnonymously();
    await _service.prepareDemoHabit();
    if (!mounted) return;
    setState(() {
      _ready = true;
      _feedback = 'Sesión de prueba y hábito ficticio preparados.';
    });
  });

  Future<void> _start() => _execute(() async {
    final challenge = await _service.startChallenge(_objectId);
    if (!mounted) return;
    setState(() {
      _challenge = challenge;
      _photo = null;
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
      _feedback = 'Fotografía tomada. Solo se muestra en el dispositivo: '
          'todavía NO se envía ni se verifica.';
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
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy || _ready ? null : _connect,
            icon: const Icon(Icons.link),
            label: Text(_ready ? 'Sesión de prueba preparada' : 'Conectar a Firebase local'),
          ),
          const SizedBox(height: 20),
          const Text('Hábito ficticio: beber agua',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _objectId,
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
            'El reconocimiento de objetos y OCR se incorporarán después. '
            'No se envían fotografías desde esta demo.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
