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

  late final TextEditingController _nombreController;
  late final TextEditingController _usuarioController;
  late final TextEditingController _fraseController;

  bool _cargando = true;
  bool _guardando = false;
  String? _errorCarga;

  User? get _user => FirebaseAuth.instance.currentUser;

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController();
    _usuarioController = TextEditingController();
    _fraseController = TextEditingController();

    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usuarioController.dispose();
    _fraseController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    final user = _user;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _errorCarga = 'No hay una sesión activa. Inicia sesión nuevamente.';
      });
      return;
    }

    try {
      final documento = await _db.collection('users').doc(user.uid).get();

      final data = documento.data() ?? <String, dynamic>{};

      _nombreController.text = _valorTexto(
        data['name'],
        user.displayName ?? '',
      );

      _usuarioController.text = _normalizarUsuario(
        _valorTexto(data['username'], ''),
      );

      _fraseController.text = _valorTexto(
        data['bio'],
        'Pequeños pasos, raíces fuertes.',
      );

      if (!mounted) return;

      setState(() {
        _cargando = false;
        _errorCarga = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _errorCarga = 'No se pudo cargar el perfil. Inténtalo de nuevo.';
      });
    }
  }

  String _valorTexto(dynamic value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  String _normalizarUsuario(String value) {
    return value.trim().replaceFirst(RegExp(r'^@+'), '');
  }

  Future<void> _guardarCambios() async {
    if (_guardando || _cargando) return;

    final user = _user;

    if (user == null) {
      _mostrarMensaje('Tu sesión ha terminado. Inicia sesión nuevamente.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
    });

    final nombre = _nombreController.text.trim();
    final usuario = _normalizarUsuario(_usuarioController.text);
    final bio = _fraseController.text.trim();

    try {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': nombre,
        'username': usuario,
        'bio': bio,
        'email': user.email,
      }, SetOptions(merge: true));

      // Actualiza también el nombre de Firebase Authentication.
      await user.updateDisplayName(nombre);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente.'),
          backgroundColor: AppColores.verdePrincipal,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'No se pudieron guardar los cambios. Verifica tu conexión e inténtalo de nuevo.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
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
          onPressed: _guardando ? null : () => Navigator.pop(context),
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
                            _buildCampoTexto(
                              label: 'Nombre completo',
                              controller: _nombreController,
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Escribe tu nombre.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildCampoTexto(
                              label: 'Nombre de usuario',
                              controller: _usuarioController,
                              icon: Icons.alternate_email,
                              validator: (value) {
                                final usuario = _normalizarUsuario(value ?? '');

                                if (usuario.isEmpty) {
                                  return 'Escribe un nombre de usuario.';
                                }

                                if (!RegExp(
                                  r'^[a-zA-Z0-9._]{3,20}$',
                                ).hasMatch(usuario)) {
                                  return 'Usa entre 3 y 20 caracteres: letras, números, puntos o guiones bajos.';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildCampoTexto(
                              label: 'Frase motivacional / Bio',
                              controller: _fraseController,
                              icon: Icons.edit_note,
                              maxLines: 2,
                              validator: (value) {
                                if ((value ?? '').trim().length > 160) {
                                  return 'La frase no puede superar 160 caracteres.';
                                }
                                return null;
                              },
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

  Widget _buildCampoTexto({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
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
          textCapitalization: TextCapitalization.sentences,
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
