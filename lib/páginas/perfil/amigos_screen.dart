import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'reaction_picker_dialog.dart'; // Agrega esta línea
import 'amigos_servicio.dart';
import 'buscar_amigos_screen.dart';
import 'perfil_muestra.dart';

class _C {
  static const green = Color(0xFF198568);
  static const mint = Color(0xFF8DE0C0);
  static const navy = Color(0xFF173544);
  static const background = Color(0xFFF4F8F5);
  static const gold = Color(0xFFD5A33E);
  static const grey = Color(0xFF8496A0);
  static const border = Color(0xFFE3ECE7);
  static const mintSoft = Color(0xFFE2F4EB);

  static const avatars = [
    Color(0xFF198568),
    Color(0xFFD5A33E),
    Color(0xFF459FCB),
    Color(0xFF8C72C6),
    Color(0xFFE8736C),
  ];
}

typedef _Perfiles = Map<String, Map<String, dynamic>>;

/// Pantalla de amigos con dos pestañas: Siguiendo y Seguidores.
class AmigosScreen extends StatefulWidget {
  /// 0 = Siguiendo, 1 = Seguidores
  final int initialTab;

  const AmigosScreen({super.key, this.initialTab = 0});

  @override
  State<AmigosScreen> createState() => _AmigosScreenState();
}

class _AmigosScreenState extends State<AmigosScreen> {
  final TextEditingController _search = TextEditingController();
  final Set<String> _ocupados = {};

  late int _tab = widget.initialTab == 1 ? 1 : 0;
  late final String? _uid = AmigosServicio.uidActual;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _siguiendoStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _seguidoresStream;

  String _q = '';
  String _cacheKey = '';
  Future<_Perfiles>? _cacheFuture;

  @override
  void initState() {
    super.initState();

    final uid = _uid;
    if (uid != null) {
      _siguiendoStream = AmigosServicio.siguiendo(uid);
      _seguidoresStream = AmigosServicio.seguidores(uid);
    }

    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _q && mounted) setState(() => _q = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  String _texto(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final t = v.toString().trim();
    return t.isEmpty ? fallback : t;
  }

  int _num(dynamic v, [int fallback = 0]) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  String _username(Map<String, dynamic> d) {
    final u = _texto(d['username']);
    if (u.isEmpty) return '';
    return u.startsWith('@') ? u : '@$u';
  }

  Future<_Perfiles> _perfiles(Set<String> ids) {
    final ordenados = ids.toList()..sort();
    final key = ordenados.join(',');
    if (key != _cacheKey || _cacheFuture == null) {
      _cacheKey = key;
      _cacheFuture = AmigosServicio.perfiles(ordenados);
    }
    return _cacheFuture!;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirmarDejar(String nombre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Dejar de seguir',
              style: TextStyle(color: _C.navy, fontWeight: FontWeight.w900),
            ),
            content: Text(
              '¿Quieres dejar de seguir a $nombre?',
              style: const TextStyle(color: _C.grey, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: _C.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Dejar de seguir',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
    );
    return ok == true;
  }

  Future<void> _toggle(String uid, String nombre, bool siguiendo) async {
    if (_ocupados.contains(uid)) return;

    if (siguiendo) {
      final ok = await _confirmarDejar(nombre);
      if (!ok || !mounted) return;
    }

    setState(() => _ocupados.add(uid));
    try {
      if (siguiendo) {
        await AmigosServicio.dejarDeSeguir(uid);
      } else {
        await AmigosServicio.seguir(uid);
      }
    } catch (e) {
      if (mounted) _snack('No se pudo completar la acción: $e');
    } finally {
      if (mounted) setState(() => _ocupados.remove(uid));
    }
  }

  void _abrirPerfil(String uid, Map<String, dynamic> d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PublicProfileScreen(
              userId: uid,
              name: _texto(d['name'], 'Usuario'),
              username: _username(d).isEmpty ? '@usuario' : _username(d),
              level: _num(d['level'], 1),
              streakDays: _num(d['currentStreak']),
              completedHabits: _num(d['completedHabits']),
            ),
      ),
    );
  }

  void _abrirBuscar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuscarAmigosScreen()),
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 18),
              Expanded(
                child:
                    _uid == null
                        ? const Center(
                          child: Text('Inicia sesión para ver tus amigos.'),
                        )
                        : _contenido(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: IconButton(
            tooltip: 'Volver',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: _C.navy),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Amigos',
            style: TextStyle(
              color: _C.navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: IconButton(
            tooltip: 'Buscar amigos',
            onPressed: _abrirBuscar,
            icon: const Icon(Icons.person_add_alt_1_rounded, color: _C.navy),
          ),
        ),
      ],
    );
  }

  Widget _contenido() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _siguiendoStream,
      builder: (context, snapSiguiendo) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _seguidoresStream,
          builder: (context, snapSeguidores) {
            if (snapSiguiendo.hasError || snapSeguidores.hasError) {
              return _mensaje(
                icono: Icons.cloud_off_outlined,
                titulo: 'No se pudieron cargar tus amigos',
                detalle:
                    'Comprueba tu conexión y que las reglas de Firestore '
                    'permitan leer las colecciones following y followers.',
              );
            }

            if (!snapSiguiendo.hasData || !snapSeguidores.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _C.green),
              );
            }

            final siguiendoIds =
                snapSiguiendo.data!.docs.map((d) => d.id).toList();
            final seguidoresIds =
                snapSeguidores.data!.docs.map((d) => d.id).toList();
            final siguiendoSet = siguiendoIds.toSet();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _segmentos(siguiendoIds.length, seguidoresIds.length),
                const SizedBox(height: 14),
                _buscador(),
                const SizedBox(height: 14),
                Expanded(
                  child: _lista(
                    ids: _tab == 0 ? siguiendoIds : seguidoresIds,
                    siguiendoSet: siguiendoSet,
                    union: {...siguiendoIds, ...seguidoresIds},
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _segmentos(int siguiendo, int seguidores) {
    Widget item(int index, String label, int total) {
      final activo = _tab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: activo ? _C.green : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: activo ? Colors.white : _C.grey,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: activo ? Colors.white24 : _C.mintSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$total',
                    style: TextStyle(
                      color: activo ? Colors.white : _C.green,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(color: _C.navy.withOpacity(0.05), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          item(0, 'Siguiendo', siguiendo),
          item(1, 'Seguidores', seguidores),
        ],
      ),
    );
  }

  Widget _buscador() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: _search,
        decoration: InputDecoration(
          hintText:
              _tab == 0 ? 'Buscar entre quienes sigues...' : 'Buscar seguidor...',
          hintStyle: const TextStyle(color: _C.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _C.grey),
          suffixIcon:
              _q.isEmpty
                  ? null
                  : IconButton(
                    icon: const Icon(Icons.close_rounded, color: _C.grey),
                    onPressed: _search.clear,
                  ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _lista({
    required List<String> ids,
    required Set<String> siguiendoSet,
    required Set<String> union,
  }) {
    if (ids.isEmpty) {
      return _tab == 0
          ? _mensaje(
            icono: Icons.people_outline_rounded,
            titulo: 'Aún no sigues a nadie',
            detalle: 'Busca a tus amigos y sigue su progreso.',
            accion: 'Buscar amigos',
            onAccion: _abrirBuscar,
          )
          : _mensaje(
            icono: Icons.favorite_border_rounded,
            titulo: 'Todavía no tienes seguidores',
            detalle: 'Cuando alguien te siga, aparecerá aquí.',
          );
    }

    return FutureBuilder<_Perfiles>(
      future: _perfiles(union),
      builder: (context, snap) {
        if (snap.hasError) {
          return _mensaje(
            icono: Icons.cloud_off_outlined,
            titulo: 'No se pudieron cargar los perfiles',
            detalle: 'Inténtalo de nuevo en unos segundos.',
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _C.green));
        }

        final perfiles = snap.data!;
        final items =
            ids
                .where(perfiles.containsKey)
                .where((id) {
                  if (_q.isEmpty) return true;
                  final d = perfiles[id]!;
                  final nombre = _texto(d['name']).toLowerCase();
                  final user = _texto(d['username']).toLowerCase();
                  return nombre.contains(_q) || user.contains(_q);
                })
                .toList()
              ..sort(
                (a, b) => _texto(
                  perfiles[a]!['name'],
                ).toLowerCase().compareTo(
                  _texto(perfiles[b]!['name']).toLowerCase(),
                ),
              );

        if (items.isEmpty) {
          return _mensaje(
            icono: Icons.search_off_rounded,
            titulo: 'Sin resultados',
            detalle: 'No encontramos a nadie con ese nombre.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final uid = items[i];
            return _tarjeta(uid, perfiles[uid]!, siguiendoSet.contains(uid));
          },
        );
      },
    );
  }

  Widget _tarjeta(String uid, Map<String, dynamic> d, bool siguiendo) {
    final nombre = _texto(d['name'], 'Usuario');
    final user = _username(d);
    final nivel = _num(d['level'], 1);
    final racha = _num(d['currentStreak']);
    final ocupado = _ocupados.contains(uid);

    final color =
        _C.avatars[uid.codeUnits.fold<int>(0, (a, b) => a + b) %
            _C.avatars.length];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _abrirPerfil(uid, d),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color,
                child: Text(
                  nombre.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _C.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (user.isNotEmpty)
                      Text(
                        user,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _C.grey, fontSize: 12),
                      ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _C.mintSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Nivel $nivel',
                            style: const TextStyle(
                              color: _C.green,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$racha días 🔥',
                          style: const TextStyle(
                            color: _C.navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Botón de reacción (solo si ya sigues a esta persona)
              if (siguiendo && _uid != null)
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(
                      Icons.add_reaction_outlined,
                      color: _C.grey,
                    ),
                    tooltip: 'Enviar reacción',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ReactionPickerDialog(
                          fromUid: _uid!, // Tu ID
                          toUid: uid, // El ID del amigo
                          friendName: nombre,
                        ),
                      );
                    },
                  ),
                ),
              _botonSeguir(uid, nombre, siguiendo, ocupado),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonSeguir(String uid, String nombre, bool siguiendo, bool ocupado) {
    final child =
        ocupado
            ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _C.green,
              ),
            )
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  siguiendo ? Icons.check_rounded : Icons.add_rounded,
                  size: 16,
                  color: siguiendo ? _C.green : _C.navy,
                ),
                const SizedBox(width: 4),
                Text(
                  siguiendo ? 'Siguiendo' : 'Seguir',
                  style: TextStyle(
                    color: siguiendo ? _C.green : _C.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            );

    return GestureDetector(
      onTap: () => _toggle(uid, nombre, siguiendo),
      child: Container(
        height: 36,
        constraints: const BoxConstraints(minWidth: 92),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: siguiendo ? Colors.white : _C.mint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: siguiendo ? _C.green : _C.mint, width: 1.4),
        ),
        child: child,
      ),
    );
  }

  Widget _mensaje({
    required IconData icono,
    required String titulo,
    required String detalle,
    String? accion,
    VoidCallback? onAccion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: _C.mintSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: _C.green, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _C.navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.grey, fontSize: 13, height: 1.4),
            ),
            if (accion != null && onAccion != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: onAccion,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(
                    accion,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.mint,
                    foregroundColor: _C.navy,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}