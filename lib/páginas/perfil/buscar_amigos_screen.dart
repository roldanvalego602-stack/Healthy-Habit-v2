import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:healthy_habit/p%C3%A1ginas/perfil/perfil_muestra.dart';

import '../../Contenido_del_tema/colores.dart';
import '../../Contenido_del_tema/chip_recompensa.dart';

class BuscarAmigosScreen extends StatefulWidget {
  const BuscarAmigosScreen({super.key});

  @override
  State<BuscarAmigosScreen> createState() => _BuscarAmigosScreenState();
}

class _BuscarAmigosScreenState extends State<BuscarAmigosScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _terminoBusqueda = '';

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _terminoBusqueda = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _texto(dynamic valor, [String predeterminado = '']) {
    if (valor == null) return predeterminado;

    final texto = valor.toString().trim();
    return texto.isEmpty ? predeterminado : texto;
  }

  int _numero(dynamic valor, [int predeterminado = 0]) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();

    return int.tryParse(valor?.toString() ?? '') ?? predeterminado;
  }

  String _username(Map<String, dynamic> datos) {
    final username = _texto(datos['username'], 'usuario');
    return username.startsWith('@') ? username : '@$username';
  }

  bool _coincide(Map<String, dynamic> datos) {
    if (_terminoBusqueda.isEmpty) return true;

    final nombre = _texto(datos['name']).toLowerCase();
    final username = _texto(datos['username']).toLowerCase();
    final usernameConArroba = '@$username';

    return nombre.contains(_terminoBusqueda) ||
        username.contains(_terminoBusqueda) ||
        usernameConArroba.contains(_terminoBusqueda);
  }

  void _abrirPerfil(Map<String, dynamic> datos, String uid) {
    final nombre = _texto(datos['name'], 'Usuario');
    final username = _username(datos);
    final nivel = _numero(datos['level'], 1);
    final racha = _numero(datos['currentStreak'], 0);

    // El perfil público existente recibe completedHabits.
    // Este campo se usa si existe en el documento de Firestore.
    final habitosCompletados = _numero(datos['completedHabits'], 0);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PublicProfileScreen(
              userId: uid,
              name: nombre,
              username: username,
              level: nivel,
              streakDays: racha,
              completedHabits: habitosCompletados,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActual = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColores.fondoClaro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColores.textoOscuro),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buscar Amigos',
          style: TextStyle(
            color: AppColores.textoOscuro,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por usuario o nombre...',
                  hintStyle: TextStyle(
                    color: AppColores.textoGris,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: AppColores.textoGris),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sugerencias de la comunidad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColores.textoOscuro,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child:
                  usuarioActual == null
                      ? const Center(
                        child: Text('Inicia sesión para buscar amigos.'),
                      )
                      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _db.collection('users').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text(
                                'No se pudieron cargar los usuarios. '
                                'Verifica las reglas de Firestore.',
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColores.verdePrincipal,
                              ),
                            );
                          }

                          final documentos = snapshot.data?.docs ?? [];

                          final usuarios =
                              documentos.where((documento) {
                                if (documento.id == usuarioActual.uid) {
                                  return false;
                                }

                                return _coincide(documento.data());
                              }).toList();

                          if (usuarios.isEmpty) {
                            return Center(
                              child: Text(
                                _terminoBusqueda.isEmpty
                                    ? 'Todavía no hay otros usuarios registrados.'
                                    : 'No se encontraron usuarios.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColores.textoGris,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: usuarios.length,
                            separatorBuilder:
                                (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final documento = usuarios[index];
                              final datos = documento.data();
                              final uid = documento.id;

                              final nombre = _texto(datos['name'], 'Usuario');
                              final username = _username(datos);
                              final nivel = _numero(datos['level'], 1);
                              final racha = _numero(datos['currentStreak'], 0);

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColores.bordeGris,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColores.verdeMenta,
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: AppColores.verdeOscuro,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nombre,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: AppColores.textoOscuro,
                                            ),
                                          ),
                                          Text(
                                            username,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColores.textoGris,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              ChipRecompensa(
                                                texto: 'Nivel $nivel',
                                                colorFondo:
                                                    AppColores.verdeMenta,
                                                colorTexto:
                                                    AppColores.verdeOscuro,
                                              ),
                                              Text(
                                                '$racha días 🔥',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Ver perfil',
                                      onPressed: () => _abrirPerfil(datos, uid),
                                      icon: const Icon(
                                        Icons.person_add_alt_1_rounded,
                                        color: AppColores.verdePrincipal,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
