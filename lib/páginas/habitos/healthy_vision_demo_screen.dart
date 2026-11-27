import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../tema/healthy_magic_guide.dart';
import 'package:image_picker/image_picker.dart';

import '../../servicios/habit_evidence_image_preparer.dart';
import '../../servicios/healthy_vision_debug_service.dart';
import '../../tema/healthy_theme.dart';
import 'healthy_vision_preview_panel.dart';
import 'healthy_local_vision_panel.dart';

/// Demostración independiente. No abre ni modifica registros de hábitos,
/// balances, XP, imágenes de Storage o documentos de Firestore.
class HealthyVisionDemoScreen extends StatefulWidget {
  const HealthyVisionDemoScreen({super.key});

  @override
  State<HealthyVisionDemoScreen> createState() =>
      _HealthyVisionDemoScreenState();
}

class _HealthyVisionDemoScreenState extends State<HealthyVisionDemoScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _image;
  bool _loading = false;
  String? _error;

  Future<void> _choose(ImageSource source) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (image == null || !mounted) return;
      final raw = await image.readAsBytes();
      // El mismo formato que admite el backend: JPEG, sin metadatos de
      // origen, máximo 250 KB. No envía nada al seleccionar la imagen.
      final prepared = const HabitEvidenceImagePreparer().prepare(raw);
      if (!mounted) return;
      setState(() => _image = prepared.bytes);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
          'No se pudo abrir la imagen. Comprueba los permisos.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const HealthyMagicGuideButton(section: 'imagenes'),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(title: const Text('Reconocimiento de imágenes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.science_outlined, size: 25),
                    SizedBox(width: 9),
                    Expanded(child: Text('LABORATORIO · DEMOSTRACIÓN',
                      style: TextStyle(fontWeight: FontWeight.w900))),
                  ]),
                  const SizedBox(height: 9),
                  const Text('Selecciona una fotografía de comida, frutas, verduras o agua. '
                    'Google ML Kit identificará elementos visibles directamente '
                    'en tu dispositivo Android.'),
                  const SizedBox(height: 8),
                  const Text('No registra un hábito, no acredita consumo '
                    'y no concede XP ni Habit Coins.',
                    style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  if (_image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(_image!,
                        key: const ValueKey('vision-demo-image'),
                        fit: BoxFit.contain, height: 205),
                    ),
                  if (_image != null) ...[
                    const SizedBox(height: 6),
                    Text('Imagen preparada: ${(_image!.lengthInBytes / 1024).toStringAsFixed(0)} KB',
                      style: const TextStyle(fontSize: 11)),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      key: const ValueKey('vision-demo-camera'),
                      onPressed: _loading ? null
                          : () => _choose(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Cámara'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(
                      key: const ValueKey('vision-demo-gallery'),
                      onPressed: _loading ? null
                          : () => _choose(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galería'),
                    )),
                  ]),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator())),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
                    ),
                ],
              ),
            ),
          ),
          if (_image != null)
            HealthyLocalVisionPanel(
              key: ValueKey(_image),
              image: _image!,
              initialProfile: 'fruit_vegetable',
              habitTitle: 'Comer frutas y verduras',
              category: 'Frutas y verduras',
            ),
          if (_image != null && HealthyVisionDebugService.enabled)
            HealthyVisionPreviewPanel(
              // Al sustituir la foto se reconstruye el resultado anterior.
              key: ValueKey(_image),
              image: _image!,
              category: 'Frutas y verduras',
              habitTitle: 'Comer frutas y verduras',
            ),
          const SizedBox(height: 12),
          const Text(
            'El reconocimiento local no envía la fotografía a servidores. '
            'Cloud Vision, si se habilita por separado, puede generar costos.',
            style: TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
