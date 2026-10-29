import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../Contenido_del_tema/colores.dart';

class RegistrarHabitoScreen extends StatefulWidget {
  final String? habitId;
  final String? habitTitle;
  final String? category;
  final int? currentProgress;
  final int? goal;

  const RegistrarHabitoScreen({
    super.key,
    this.habitId,
    this.habitTitle,
    this.category,
    this.currentProgress,
    this.goal,
  });

  @override
  State<RegistrarHabitoScreen> createState() => _RegistrarHabitoScreenState();
}

class _RegistrarHabitoScreenState extends State<RegistrarHabitoScreen> {
  late final FirebaseFirestore _db;

  final TextEditingController _notaController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _imagenSeleccionada;
  Uint8List? _bytesImagen;

  bool _guardando = false;
  bool _cargando = true;
  bool _subiendoImagen = false;

  String? _error;
  String? _documentId;

  String _nombreHabito = 'Tomar 6 vasos de agua';
  String _categoria = 'Hidratación';
  int _progreso = 0;
  int _meta = 6;

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> get _habitos {
    return _userDoc.collection('user_habits');
  }

  bool get _tieneEvidencia => _imagenSeleccionada != null;

  int get _xpPorRegistro => _tieneEvidencia ? 15 : 10;

  @override
  void initState() {
    super.initState();

    _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );

    _nombreHabito = widget.habitTitle ?? _nombreHabito;
    _categoria = widget.category ?? _categoria;
    _progreso = widget.currentProgress ?? 0;
    _meta = widget.goal ?? 6;

    _cargarHabito();
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  int _leerEntero(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> _cargarHabito() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'Inicia sesión para registrar un hábito.';
        });
      }
      return;
    }

    try {
      DocumentSnapshot<Map<String, dynamic>>? snapshot;

      if (widget.habitId != null && widget.habitId!.isNotEmpty) {
        snapshot = await _habitos.doc(widget.habitId).get();
      } else {
        final resultados = await _habitos.get();

        for (final doc in resultados.docs) {
          final data = doc.data();
          final nombre =
              (data['title'] ?? data['name'] ?? data['nombre'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();

          if (nombre == _nombreHabito.trim().toLowerCase()) {
            snapshot = doc;
            break;
          }
        }
      }

      if (snapshot != null && snapshot.exists) {
        final data = snapshot.data()!;

        _documentId = snapshot.id;
        _nombreHabito =
            (data['title'] ?? data['name'] ?? data['nombre'] ?? _nombreHabito)
                .toString();

        _categoria =
            (data['category'] ?? data['categoria'] ?? _categoria).toString();

        _progreso = _leerEntero(
          data['progress'] ?? data['currentProgress'],
          _progreso,
        );

        _meta = _leerEntero(
          data['goal'] ?? data['target'] ?? data['meta'],
          _meta,
        );

        if (_meta < 1) _meta = 1;
      } else if (widget.habitId != null && widget.habitId!.isNotEmpty) {
        throw Exception('No se encontró el hábito seleccionado.');
      }

      if (mounted) {
        setState(() {
          _cargando = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'No se pudo cargar el hábito: $e';
        });
      }
    }
  }

  Future<DocumentReference<Map<String, dynamic>>>
  _obtenerReferenciaHabito() async {
    if (_documentId != null) {
      return _habitos.doc(_documentId);
    }

    final nuevoDoc = _habitos.doc();

    await nuevoDoc.set({
      'title': _nombreHabito,
      'name': _nombreHabito,
      'category': _categoria,
      'progress': _progreso,
      'goal': _meta,
      'xp': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _documentId = nuevoDoc.id;
    return nuevoDoc;
  }

  Future<void> _seleccionarImagen(ImageSource origen) async {
    if (_guardando || _cargando) return;

    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: origen,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (!mounted || imagen == null) return;

      final bytes = await imagen.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imagenSeleccionada = imagen;
        _bytesImagen = bytes;
        _error = null;
      });
    } catch (e) {
      _mostrarMensaje(
        'No se pudo seleccionar la imagen. '
        'Comprueba los permisos o la compatibilidad del dispositivo.',
      );
    }
  }

  void _quitarImagen() {
    if (_guardando) return;

    setState(() {
      _imagenSeleccionada = null;
      _bytesImagen = null;
    });
  }

  String _extensionImagen(String nombre) {
    final partes = nombre.toLowerCase().split('.');
    if (partes.length < 2) return 'jpg';

    final extension = partes.last;

    const permitidas = ['jpg', 'jpeg', 'png', 'webp'];
    return permitidas.contains(extension) ? extension : 'jpg';
  }

  String _tipoContenido(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<String?> _subirImagen({
    required String uid,
    required String registroId,
    required String habitId,
  }) async {
    final imagen = _imagenSeleccionada;
    final bytes = _bytesImagen;

    if (imagen == null || bytes == null) return null;

    if (mounted) {
      setState(() => _subiendoImagen = true);
    }

    final extension = _extensionImagen(imagen.name);

    final referencia = FirebaseStorage.instance.ref().child(
      'users/$uid/habit_evidence/$registroId.$extension',
    );

    try {
      final metadata = SettableMetadata(
        contentType: _tipoContenido(extension),
        customMetadata: {
          'userId': uid,
          'habitId': habitId,
          'recordId': registroId,
        },
      );

      await referencia.putData(bytes, metadata);
      return await referencia.getDownloadURL();
    } finally {
      if (mounted) {
        setState(() => _subiendoImagen = false);
      }
    }
  }

  Future<void> _guardarRegistro() async {
    if (_guardando || _cargando) return;

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      _mostrarMensaje('Debes iniciar sesión para guardar el registro.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    Reference? referenciaImagenSubida;

    try {
      final habitoRef = await _obtenerReferenciaHabito();
      final usuarioRef = _userDoc;
      final registroRef = habitoRef.collection('logs').doc();

      final nota = _notaController.text.trim();
      final uid = usuario.uid;

      String? imagenUrl;

      if (_imagenSeleccionada != null) {
        final extension = _extensionImagen(_imagenSeleccionada!.name);

        referenciaImagenSubida = FirebaseStorage.instance.ref().child(
          'users/$uid/habit_evidence/'
          '${registroRef.id}.$extension',
        );

        imagenUrl = await _subirImagen(
          uid: uid,
          registroId: registroRef.id,
          habitId: habitoRef.id,
        );
      }

      // Los XP adicionales se otorgan solo si la imagen se subió.
      final tieneEvidenciaReal = imagenUrl != null;
      final xpGanado = tieneEvidenciaReal ? 15 : 10;

      await _db.runTransaction((transaction) async {
        final habitoSnapshot = await transaction.get(habitoRef);
        final usuarioSnapshot = await transaction.get(usuarioRef);

        final datosHabito = habitoSnapshot.data() ?? <String, dynamic>{};
        final datosUsuario = usuarioSnapshot.data() ?? <String, dynamic>{};

        final progresoActual = _leerEntero(
          datosHabito['progress'] ?? datosHabito['currentProgress'],
          _progreso,
        );

        final metaActual = _leerEntero(
          datosHabito['goal'] ?? datosHabito['target'] ?? datosHabito['meta'],
          _meta,
        );

        final metaSegura = metaActual < 1 ? 1 : metaActual;
        final xpActual = _leerEntero(datosUsuario['xp'], 0);
        final xpHabito = _leerEntero(datosHabito['xp'], 0);

        final nuevoProgreso = (progresoActual + 1).clamp(0, metaSegura);

        transaction.set(habitoRef, {
          'title': datosHabito['title'] ?? _nombreHabito,
          'name': datosHabito['name'] ?? _nombreHabito,
          'category': datosHabito['category'] ?? _categoria,
          'progress': nuevoProgreso,
          'goal': metaSegura,
          'xp': xpHabito + xpGanado,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.set(usuarioRef, {
          'xp': xpActual + xpGanado,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.set(registroRef, {
          'habitId': habitoRef.id,
          'habitTitle': _nombreHabito,
          'category': _categoria,
          'note': nota,
          'hasEvidence': tieneEvidenciaReal,
          'imageUrl': imagenUrl,
          'xpEarned': xpGanado,
          'progressAfter': nuevoProgreso,
          'goal': metaSegura,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': uid,
        });
      });

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      // Si la imagen se subió pero el registro falló, intenta
      // eliminar el archivo para no dejar evidencia huérfana.
      if (referenciaImagenSubida != null) {
        try {
          await referenciaImagenSubida!.delete();
        } catch (_) {
          // No reemplazar el error original si falla la limpieza.
        }
      }

      if (mounted) {
        setState(() {
          _error =
              'No se pudo guardar el registro. Verifica tu conexión, '
              'Firebase Storage y las reglas de seguridad.';
        });
        _mostrarMensaje('Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        backgroundColor: AppColores.fondoClaro,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColores.textoOscuro),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColores.fondoClaro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColores.textoOscuro),
          onPressed: _guardando ? null : () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar Hábito',
              style: TextStyle(
                color: AppColores.textoOscuro,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            Text(
              'Añade algo que acompañe tu registro.',
              style: TextStyle(
                color: AppColores.textoGris,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTarjetaHabito(),
            const SizedBox(height: 24),
            _buildTituloSeccion('Fotografía', 'Opcional'),
            const SizedBox(height: 12),
            _buildFotografia(),
            const SizedBox(height: 8),
            const Text(
              'Puedes adjuntar una fotografía como evidencia '
              'de tu hábito. Es opcional.',
              style: TextStyle(fontSize: 12, color: AppColores.textoGris),
            ),
            const SizedBox(height: 24),
            _buildTituloSeccion('Añadir una nota', 'Opcional'),
            const SizedBox(height: 12),
            TextField(
              controller: _notaController,
              enabled: !_guardando,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej. Terminé mi botella durante el almuerzo.',
                hintStyle: const TextStyle(
                  color: AppColores.textoGris,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColores.bordeGris),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColores.bordeGris),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tu registro suma',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColores.textoOscuro,
              ),
            ),
            const SizedBox(height: 12),
            _buildTarjetasXP(),
            const SizedBox(height: 24),
            _buildPrivacidad(),
            const SizedBox(height: 16),
            _buildMrHealthy(),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardarRegistro,
                icon:
                    _guardando
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  _guardando
                      ? (_subiendoImagen
                          ? 'Subiendo imagen...'
                          : 'Guardando...')
                      : 'Guardar registro',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColores.verdePrincipal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColores.verdePrincipal
                      .withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: _guardando ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColores.verdePrincipal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaHabito() {
    final progresoVisual =
        _meta > 0 ? (_progreso / _meta).clamp(0.0, 1.0).toDouble() : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColores.azulAgua,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _nombreHabito.toLowerCase().contains('agua')
                      ? Icons.water_drop_outlined
                      : Icons.check_circle_outline,
                  color: AppColores.azulTexto,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nombreHabito,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColores.textoOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_categoria · Misión diaria',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColores.textoGris,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progresoVisual,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEDEFF3),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColores.azulTexto,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$_progreso / $_meta',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColores.azulTexto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Al guardar, el progreso avanzará una unidad.',
              style: TextStyle(fontSize: 12, color: AppColores.textoGris),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTituloSeccion(String titulo, String subtitulo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColores.textoOscuro,
          ),
        ),
        Text(
          subtitulo,
          style: const TextStyle(fontSize: 13, color: AppColores.textoGris),
        ),
      ],
    );
  }

  Widget _buildFotografia() {
    final tieneImagen = _bytesImagen != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColores.verdePrincipal.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          if (tieneImagen) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _bytesImagen!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColores.verdePrincipal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Imagen seleccionada',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColores.textoOscuro,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _guardando ? null : _quitarImagen,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Quitar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColores.verdeMenta,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColores.verdePrincipal,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Añadir fotografía',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColores.textoOscuro,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Adjunta una imagen para respaldar tu registro.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColores.textoGris),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _guardando
                          ? null
                          : () => _seleccionarImagen(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text(
                    'Tomar fotografía',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColores.verdePrincipal,
                    backgroundColor: AppColores.verdeMenta,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _guardando
                          ? null
                          : () => _seleccionarImagen(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text(
                    'Elegir de galería',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColores.textoOscuro,
                    side: const BorderSide(color: AppColores.bordeGris),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Registrar con evidencia',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              tieneImagen
                  ? 'La imagen se subirá al guardar el registro.'
                  : 'Selecciona una imagen para activar la evidencia.',
              style: const TextStyle(fontSize: 11),
            ),
            value: tieneImagen,
            activeColor: AppColores.verdePrincipal,
            onChanged:
                _guardando
                    ? null
                    : (value) {
                      if (!value) {
                        _quitarImagen();
                      } else {
                        _seleccionarImagen(ImageSource.gallery);
                      }
                    },
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetasXP() {
    return Row(
      children: [
        Expanded(
          child: _tarjetaXP(
            titulo: 'Registro normal',
            xp: '+10 XP',
            descripcion: 'Sin evidencia',
            color: Colors.white,
            colorTexto: AppColores.textoOscuro,
            borde: AppColores.bordeGris,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _tarjetaXP(
            titulo: 'Con evidencia',
            xp: '+15 XP',
            descripcion: 'Total del registro',
            color: AppColores.verdeMenta,
            colorTexto: AppColores.verdePrincipal,
            borde: AppColores.verdePrincipal.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaXP({
    required String titulo,
    required String xp,
    required String descripcion,
    required Color color,
    required Color colorTexto,
    required Color borde,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.bolt, color: colorTexto, size: 20),
              Flexible(
                child: Text(
                  xp,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colorTexto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: const TextStyle(fontSize: 11, color: AppColores.textoGris),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacidad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: AppColores.textoOscuro),
              SizedBox(width: 8),
              Text(
                'Tu privacidad importa',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'La evidencia se utiliza para respaldar este registro y '
            'se manejará según tus preferencias de privacidad.',
            style: TextStyle(fontSize: 12, color: AppColores.textoGris),
          ),
        ],
      ),
    );
  }

  Widget _buildMrHealthy() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/mascot/healthy.png',
          width: 40,
          height: 40,
          errorBuilder:
              (context, error, stackTrace) => const Icon(Icons.eco, size: 40),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mr. Healthy',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColores.verdePrincipal,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'La evidencia es opcional. Obtienes XP al registrar '
                'tu hábito; los Healthy Coins se obtienen al completar '
                'una misión, no por cada registro.',
                style: TextStyle(fontSize: 12, color: AppColores.textoGris),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
