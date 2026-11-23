import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../servicios/profile_photo_service.dart';
import 'profile_avatar.dart';
import 'profile_photo_crop_screen.dart';
import 'profile_photo_viewer.dart';
import '../../tema/healthy_theme.dart';

import '../../Contenido_del_tema/colores.dart';
import '../../Contenido_del_tema/boton_principal.dart';
import '../../Contenido_del_tema/tarjeta_contenedor.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _fraseController = TextEditingController();
  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoFoto = false;
  String? _errorFoto;
  String? _photoUrl;
  String _avatarStyle = 'foto';
  final ProfilePhotoService _photoService = ProfilePhotoService();
  String? _errorCarga;
  int _cargaActual = 0;

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _cargaActual++;
    _nombreController.dispose();
    _usuarioController.dispose();
    _fraseController.dispose();
    super.dispose();
  }

  String _texto(dynamic value, String fallback) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;

  String _usuario(String value) =>
      value.trim().replaceFirst(RegExp(r'^@+'), '');

  Future<void> _cargarPerfil() async {
    final carga = ++_cargaActual;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted || carga != _cargaActual) return;
      setState(() {
        _cargando = false;
        _errorCarga = 'No hay una sesión activa.';
      });
      return;
    }
    try {
      final snapshot = await _db.collection('users').doc(user.uid).get();
      // IMPORTANTE: comprobar mounted ANTES de escribir en controladores.
      if (!mounted || carga != _cargaActual) return;
      final data = snapshot.data() ?? <String, dynamic>{};
      _nombreController.text = _texto(data['name'], user.displayName ?? '');
      _usuarioController.text = _usuario(_texto(data['username'], ''));
      _fraseController.text = _texto(
        data['bio'],
        'Pequeños pasos, raíces fuertes.',
      );
      _photoUrl = data.containsKey('photoUrl')
          ? data['photoUrl']?.toString() ?? ''
          : user.photoURL ?? '';
      _avatarStyle = _texto(data['profileAvatarStyle'], 'foto');
      setState(() {
        _cargando = false;
        _errorCarga = null;
      });
    } catch (_) {
      if (!mounted || carga != _cargaActual) return;
      setState(() {
        _cargando = false;
        _errorCarga = 'No se pudo cargar el perfil. Inténtalo de nuevo.';
      });
    }
  }

  Future<void> _elegirFoto() async {
    if (_subiendoFoto || _guardando || _cargando) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: HealthyAdaptive.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galería'),
                onTap: () =>
                    Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar una foto'),
                onTap: () =>
                    Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _errorFoto = null);
    try {
      final selected = await _photoService.pick(source);
      if (selected == null || !mounted) return;
      final cropped = await Navigator.of(context).push<XFile>(
        MaterialPageRoute<XFile>(
          builder: (_) => ProfilePhotoCropScreen(original: selected),
        ),
      );
      if (cropped == null || !mounted) return;
      setState(() => _subiendoFoto = true);
      final url = await _photoService.upload(cropped);
      if (!mounted) return;
      setState(() { _photoUrl = url; _avatarStyle = 'foto'; _errorFoto = null; });
      _mensaje('Foto de perfil actualizada.');
    } on ProfilePhotoException catch (error) {
      if (mounted) setState(() => _errorFoto = error.message);
      // El mensaje queda visible junto a la foto; evitar duplicarlo
      // en un SnackBar que ocupe media pantalla en Android.
    } on PlatformException catch (error) {
      if (mounted) setState(() => _errorFoto = 'Permiso de cámara o galería: ${error.code}. Revisa ajustes de Android.');
      _mensaje('No se pudo acceder a cámara o galería '
          '(código: ${error.code}). Revisa los permisos del dispositivo.');
    } catch (error) {
      if (mounted) setState(() => _errorFoto = 'Falló el procesamiento o la subida (${error.runtimeType}). Revisa Firebase Storage.');
      _mensaje('No fue posible procesar la foto. Revisa que sea una '
          'imagen válida y comprueba tu conexión.');
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _elegirAvatar() async {
    if (_subiendoFoto || _guardando || _cargando) return;
    const styles = <String, String>{
      'foto': 'Mi fotografía',
      'naturaleza': 'Naturaleza',
      'agua': 'Hidratación',
      'energia': 'Energía',
    };
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: HealthyAdaptive.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Elige tu avatar',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Puedes volver a tu foto o elegir una imagen gratuita.',
                  style: Theme.of(sheetContext).textTheme.bodySmall),
              const SizedBox(height: 18),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.12,
                children: [
                  for (final entry in styles.entries)
                    InkWell(
                      key: ValueKey('avatar-choice-${entry.key}'),
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(sheetContext, entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _avatarStyle == entry.key
                                ? HealthyAdaptive.accent
                                : HealthyAdaptive.border,
                            width: _avatarStyle == entry.key ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HealthyProfileAvatar(
                              photoUrl: entry.key == 'foto' ? _photoUrl : null,
                              preset: entry.key,
                              size: 72,
                            ),
                            const SizedBox(height: 6),
                            Text(entry.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, 'upload'),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Subir otra fotografía'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == 'upload') {
      if (mounted) await _elegirFoto();
      return;
    }
    if (selected == 'foto' && (_photoUrl ?? '').trim().isEmpty) {
      if (mounted) await _elegirFoto();
      return;
    }
    if (selected == null || !mounted || selected == _avatarStyle) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _mensaje('Inicia sesión nuevamente para editar tu avatar.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await _db.collection('users').doc(user.uid).set({
        'profileAvatarStyle': selected,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _avatarStyle = selected);
      _mensaje('Avatar actualizado.');
    } catch (_) {
      _mensaje('No se pudo cambiar el avatar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _quitarFoto() async {
    if (_subiendoFoto || _guardando || _cargando) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Quitar foto de perfil?'),
        content: const Text(
          'Volverá a mostrarse el avatar predeterminado. '
          'Tu nombre y los demás datos no cambiarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Quitar foto'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => _subiendoFoto = true);
    try {
      await _photoService.remove();
      if (!mounted) return;
      setState(() => _photoUrl = '');
      _mensaje('La foto se quitó de tu perfil.');
    } on ProfilePhotoException catch (error) {
      _mensaje(error.message);
    } catch (_) {
      _mensaje('No se pudo quitar la foto. Revisa la conexión.');
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _guardarCambios() async {
    if (_guardando || _cargando || _subiendoFoto) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _mensaje('Tu sesión ha terminado. Inicia sesión nuevamente.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final nombre = _nombreController.text.trim();
    final usuario = _usuario(_usuarioController.text);
    final bio = _fraseController.text.trim();
    setState(() => _guardando = true);
    var firestoreGuardado = false;
    try {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': nombre,
        'username': usuario,
        'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      firestoreGuardado = true;
      try {
        await user.updateDisplayName(nombre);
      } catch (_) {
        // Los datos de perfil ya se guardaron en Firestore.
        // No indicar que toda la operación falló por este paso secundario.
      }
      if (!mounted) return;
      // Mensaje en la pantalla anterior: no depende del contexto que se elimina.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente.'),
          backgroundColor: AppColores.verdePrincipal,
        ),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      _mensaje(
        firestoreGuardado
            ? 'Los datos se guardaron, pero no se pudo sincronizar la cuenta.'
            : 'No se pudieron guardar los cambios. Revisa tu conexión.',
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mensaje(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 7),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: HealthyAdaptive.text),
          onPressed: _guardando || _subiendoFoto ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Editar Perfil',
          style: TextStyle(
            color: HealthyAdaptive.text,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body:
          _cargando
              ? const Center(
                child: CircularProgressIndicator(
                  color: AppColores.verdePrincipal,
                ),
              )
              : _errorCarga != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColores.verdePrincipal,
                      ),
                      const SizedBox(height: 12),
                      Text(_errorCarga!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _cargando = true;
                            _errorCarga = null;
                          });
                          _cargarPerfil();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
              : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              button: true,
                              label: 'Opciones de foto de perfil',
                              child: InkWell(
                                key: const Key('edit-profile-photo'),
                                onTap: _subiendoFoto || _guardando
                                    ? null
                                    : () => showProfilePhotoActions(
                                        context,
                                        photoUrl: _photoUrl,
                                        preset: _avatarStyle,
                                        onEdit: _elegirFoto,
                                      ),
                                customBorder: const CircleBorder(),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 104,
                                      height: 104,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColores.verdePrincipal,
                                          width: 3,
                                        ),
                                      ),
                                      child: HealthyProfileAvatar(
                                        photoUrl: _photoUrl,
                                        preset: _avatarStyle,
                                        size: 96,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: AppColores.verdePrincipal,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 19,
                                        ),
                                      ),
                                    ),
                                    if (_subiendoFoto)
                                      const Positioned.fill(
                                        child: ColoredBox(
                                          color: Color(0x77000000),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _subiendoFoto
                                  ? 'Subiendo fotografía…'
                                  : 'Toca tu imagen para verla o editarla',
                              style: TextStyle(
                                fontSize: 12,
                                color: HealthyAdaptive.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((_photoUrl ?? '').isNotEmpty) ...[
                              const SizedBox(height: 3),
                              TextButton.icon(
                                onPressed: _subiendoFoto ? null : _quitarFoto,
                                icon: const Icon(Icons.delete_outline_rounded,
                                  size: 17),
                                label: const Text('Quitar foto'),
                              ),
                            ],
                            OutlinedButton.icon(
                              onPressed: _guardando || _subiendoFoto ? null : _elegirAvatar,
                              icon: const Icon(Icons.face_retouching_natural_rounded),
                              label: const Text('Elegir avatar'),
                            ),
                            const SizedBox(height: 6),
                            if (_errorFoto != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                key: const ValueKey('profile-photo-error'),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_errorFoto!,
                                    style: const TextStyle(
                                      color: Colors.red, fontSize: 12))),
                                ]),
                              ),
                            ],
                            Text(
                              'La fotografía se guarda al subirla.',
                              style: TextStyle(
                                fontSize: 11,
                                color: HealthyAdaptive.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TarjetaContenedor(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _campo(
                              'Nombre completo',
                              _nombreController,
                              Icons.person_outline,
                              (v) =>
                                  (v ?? '').trim().isEmpty
                                      ? 'Escribe tu nombre.'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            _campo(
                              'Nombre de usuario',
                              _usuarioController,
                              Icons.alternate_email,
                              (v) {
                                final value = _usuario(v ?? '');
                                if (value.isEmpty) return 'Escribe un usuario.';
                                if (!RegExp(
                                  r'^[a-zA-Z0-9._]{3,20}$',
                                ).hasMatch(value)) {
                                  return 'Usa de 3 a 20 caracteres: letras, números, . o _.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _campo(
                              'Frase motivacional / Bio',
                              _fraseController,
                              Icons.edit_note,
                              (v) =>
                                  (v ?? '').trim().length > 160
                                      ? 'Máximo 160 caracteres.'
                                      : null,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child:
                            _guardando || _subiendoFoto
                                ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      color: AppColores.verdePrincipal,
                                    ),
                                  ),
                                )
                                : BotonPrincipal(
                                  texto: 'Guardar cambios',
                                  onPressed: _guardarCambios,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController controller,
    IconData icon,
    String? Function(String?) validator, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: HealthyAdaptive.text,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLines > 1 ? 160 : null,
          validator: validator,
          textCapitalization:
              maxLines > 1 || label == 'Nombre completo'
                  ? TextCapitalization.sentences
                  : TextCapitalization.none,
          autocorrect: label != 'Nombre de usuario',
          style: TextStyle(fontSize: 14, color: HealthyAdaptive.text),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: HealthyAdaptive.muted, size: 20),
            filled: true,
            fillColor: HealthyAdaptive.background,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
