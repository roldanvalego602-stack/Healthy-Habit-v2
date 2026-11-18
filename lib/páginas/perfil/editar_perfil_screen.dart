import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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

  Future<void> _guardarCambios() async {
    if (_guardando || _cargando) return;
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondoClaro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColores.textoOscuro),
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: AppColores.textoOscuro,
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
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColores.verdePrincipal,
                                  width: 3,
                                ),
                                color: Colors.white,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 58,
                                color: AppColores.verdePrincipal,
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
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
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
                            _guardando
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColores.textoOscuro,
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
          style: const TextStyle(fontSize: 14, color: AppColores.textoOscuro),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColores.textoGris, size: 20),
            filled: true,
            fillColor: AppColores.fondoClaro,
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
