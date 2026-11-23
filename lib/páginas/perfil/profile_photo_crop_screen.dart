import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../servicios/profile_photo_service.dart';
import 'profile_photo_crop_geometry.dart';

/// Recorte cuadrado con vista circular, sin plugins nativos adicionales.
/// El JPEG resultante es el recorte real que se almacena en Firebase.
class ProfilePhotoCropScreen extends StatefulWidget {
  const ProfilePhotoCropScreen({super.key, required this.original});
  final XFile original;

  @override
  State<ProfilePhotoCropScreen> createState() => _ProfilePhotoCropScreenState();
}

class _ProfilePhotoCropScreenState extends State<ProfilePhotoCropScreen> {
  Uint8List? _bytes;
  img.Image? _image;
  String? _error;
  double _zoom = 1;
  double _gestureStartZoom = 1;
  Offset _offset = Offset.zero;
  bool _saving = false;
  double _viewport = 300;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final normalized = ProfilePhotoService.prepareJpeg(
        await widget.original.readAsBytes(),
      );
      final image = img.decodeImage(normalized);
      if (image == null) throw const FormatException('Imagen inválida');
      if (!mounted) return;
      setState(() {
        _bytes = normalized;
        _image = image;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo abrir la imagen seleccionada.');
      }
    }
  }

  Size _baseSize(img.Image image) =>
      ProfilePhotoCropGeometry.baseSize(
        imageWidth: image.width,
        imageHeight: image.height,
        viewport: _viewport,
      );

  Offset _clampedOffset(Offset proposed, double zoom, img.Image image) =>
      ProfilePhotoCropGeometry.clampOffset(
        offset: proposed,
        base: _baseSize(image),
        zoom: zoom,
        viewport: _viewport,
      );

  void _reset() {
    setState(() {
      _zoom = 1;
      _offset = Offset.zero;
    });
  }

  Future<void> _save() async {
    if (_saving || _image == null) return;
    setState(() => _saving = true);
    try {
      final image = _image!;
      final rect = ProfilePhotoCropGeometry.sourceRect(
        imageWidth: image.width,
        imageHeight: image.height,
        viewport: _viewport,
        zoom: _zoom,
        offset: _offset,
      );
      final cropped = img.copyCrop(
        image, x: rect.left.toInt(), y: rect.top.toInt(),
        width: rect.width.toInt(), height: rect.height.toInt(),
      );
      final sized = img.copyResize(cropped, width: 768, height: 768);
      final result = Uint8List.fromList(img.encodeJpg(sized, quality: 85));
      if (!mounted) return;
      Navigator.pop(
        context,
        XFile.fromData(
          result,
          mimeType: 'image/jpeg',
          name: 'avatar_ajustado.jpg',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo recortar la fotografía.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final bytes = _bytes;
    final dimension = math.max(100.0, math.min(
      MediaQuery.sizeOf(context).width - 40, 340.0,
    ));
    if (_viewport != dimension) {
      _viewport = dimension;
      if (image != null) _offset = _clampedOffset(_offset, _zoom, image);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustar fotografía')),
      body: SafeArea(
        child: image == null || bytes == null
            ? Center(child: _error == null
                ? const CircularProgressIndicator()
                : Text(_error!))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Mueve la imagen con un dedo y pellizca para acercar.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onScaleStart: (_) {
                          _gestureStartZoom = _zoom;
                        },
                        onScaleUpdate: (details) {
                          setState(() {
                            _zoom = (_gestureStartZoom * details.scale)
                                .clamp(1.0, 4.0);
                            _offset = _clampedOffset(
                              _offset + details.focalPointDelta,
                              _zoom, image,
                            );
                          });
                          _gestureStartOffset = _offset;
                        },
                        child: ClipOval(
                          child: SizedBox.square(
                            dimension: dimension,
                            child: ColoredBox(
                              color: Colors.black,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  Transform.translate(
                                    offset: _offset,
                                    child: Transform.scale(
                                      scale: _zoom,
                                      child: SizedBox(
                                        width: _baseSize(image).width,
                                        height: _baseSize(image).height,
                                        child: Image.memory(
                                          bytes,
                                          fit: BoxFit.fill,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Así se verá en tu perfil',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.remove_circle_outline),
                        Expanded(
                          child: Slider(
                            value: _zoom,
                            min: 1,
                            max: 4,
                            label: '${_zoom.toStringAsFixed(1)}x',
                            onChanged: (value) => setState(() {
                              _zoom = value;
                              _offset = _clampedOffset(_offset, value, image);
                            }),
                          ),
                        ),
                        const Icon(Icons.add_circle_outline),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Restablecer encuadre'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(_saving
                            ? 'Preparando fotografía…'
                            : 'Usar esta fotografía'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
