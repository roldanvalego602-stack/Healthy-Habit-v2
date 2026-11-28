import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../servicios/beta_habit_gateway.dart';
import 'package:flutter/material.dart';
import '../../tema/healthy_magic_guide.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../servicios/healthy_feedback_service.dart';
import '../../tema/healthy_coin.dart';
import '../../tema/healthy_cosmetics.dart';
import '../../tema/healthy_theme.dart';
import '../perfil/healthy_framed_avatar.dart';
import '../perfil/profile_banner.dart';
import '../perfil/profile_titles.dart';
import 'healthy_mascot_outfit.dart';
import 'healthy_mascot_idle.dart';
import '../../guia/healthy_ufo_visual.dart';
import 'healthy_ufo_skin_art.dart';
import 'shop_item_artwork.dart';
import 'shop_service.dart';

/// Una ranura equivale a una sola pieza equipable en Firestore.
/// La categoría comercial no determina dónde se coloca un objeto.
class WardrobeSlot {
  const WardrobeSlot(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

const mascotWardrobeSlots = <WardrobeSlot>[
  WardrobeSlot('cabeza', 'Cabeza', Icons.face_retouching_natural_rounded),
  WardrobeSlot('ojos', 'Rostro', Icons.visibility_rounded),
  WardrobeSlot('cuello', 'Cuello', Icons.dry_cleaning_rounded),
  WardrobeSlot('torso', 'Torso', Icons.checkroom_rounded),
  WardrobeSlot('brazos', 'Brazos', Icons.back_hand_rounded),
  WardrobeSlot('mano', 'Manos', Icons.pan_tool_alt_rounded),
  WardrobeSlot('pies', 'Pies', Icons.ice_skating_rounded),
  WardrobeSlot('espalda', 'Espalda', Icons.backpack_rounded),
  WardrobeSlot('skin', 'Skins', Icons.palette_rounded),
  WardrobeSlot('aura', 'Aura', Icons.auto_awesome_rounded),
];

const ufoWardrobeSlots = <WardrobeSlot>[
  WardrobeSlot('ufo_skin', 'Aspectos OVNI', Icons.rocket_launch_rounded),
];

const profileWardrobeSlots = <WardrobeSlot>[
  WardrobeSlot('perfil_avatar', 'Avatar', Icons.account_circle_rounded),
  WardrobeSlot('perfil_marco', 'Marco', Icons.crop_square_rounded),
  WardrobeSlot('perfil_banner', 'Banner', Icons.panorama_rounded),
  WardrobeSlot('perfil_expositor', 'Expositor', Icons.workspace_premium_rounded),
  WardrobeSlot('perfil_titulo', 'Título', Icons.badge_rounded),
];

/// Selecciona exclusivamente artículos equipables de la ranura elegida.
/// Las reacciones consumibles y extras sin ranura permanecen en la tienda.
List<ShopItem> wardrobeItemsForSlot(String slot, {ShopState? state}) =>
    shopCatalog.where((item) => item.slot == slot &&
        (isShopItemVisible(item.id) || item.id == 'skin_titan_secret' ||
          (state?.owned.contains(item.id) ?? false)))
        .toList(growable: false);

/// Coordenadas del accesorio dentro del lienzo de 280×275 de Mr. Healthy.
/// Solo representa el diseño visual; no altera compras o propiedad.
class _AccessoryLayout {
  const _AccessoryLayout(this.x, this.y, this.size, [this.rotation = 0]);
  final double x, y, size, rotation;
  Map<String, double> toJson() => {
    'x': x, 'y': y, 'size': size, 'rotation': rotation,
  };

  factory _AccessoryLayout.fromJson(Object? raw) {
    if (raw is! Map || raw['x'] is! num ||
        raw['y'] is! num || raw['size'] is! num) {
      throw const FormatException('Coordenadas inválidas');
    }
    final x = (raw['x'] as num).toDouble();
    final y = (raw['y'] as num).toDouble();
    final size = (raw['size'] as num).toDouble();
    final angle = raw['rotation'] is num
        ? (raw['rotation'] as num).toDouble() : 0.0;
    if (!x.isFinite || !y.isFinite || !size.isFinite ||
        !angle.isFinite || angle < -180 || angle > 180 ||
        x < 0 || x > 270 || y < 0 || y > 265 ||
        size < 30 || size > 250) {
      throw const FormatException('Accesorio fuera del escenario');
    }
    return _AccessoryLayout(x, y, size, angle);
  }
}

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key, this.initialSlot = 'cabeza'});

  /// Permite abrir directamente una colección, por ejemplo Skins.
  final String initialSlot;

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  bool _profileMode = false;
  bool _ufoMode = false;
  String _slot = 'cabeza';
  String? _busy;
  bool _layoutEditor = false;
  final Map<String, _AccessoryLayout> _layouts = {};
  static const _layoutPrefix = 'hh_wardrobe_layout_v1_';

  @override
  void initState() {
    super.initState();
    if (mascotWardrobeSlots.any((slot) => slot.id == widget.initialSlot)) {
      _slot = widget.initialSlot;
    }
    _loadLayouts();
  }

  Future<void> _loadLayouts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final raw = await SharedPreferencesAsync().getString('$_layoutPrefix$uid');
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final loaded = <String, _AccessoryLayout>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String || shopItemById(entry.key) == null) continue;
        try {
          loaded[entry.key as String] = _AccessoryLayout.fromJson(entry.value);
        } catch (_) {
          // No usar posiciones que estén fuera del escenario.
        }
      }
      if (mounted && FirebaseAuth.instance.currentUser?.uid == uid) {
        setState(() { _layouts..clear()..addAll(loaded); });
      }
    } catch (_) {
      // Se restaura la disposición estándar sin alterar el inventario.
    }
  }

  Future<void> _saveLayouts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await SharedPreferencesAsync().setString('$_layoutPrefix$uid',
        jsonEncode(_layouts.map((id, placement) =>
          MapEntry(id, placement.toJson()))));
    } catch (_) {
      _message('No se pudieron guardar los ajustes del armario.');
    }
  }

  static _AccessoryLayout _defaultLayout(String slot) {
    return switch (slot) {
      'cabeza' => const _AccessoryLayout(75, 25, 130),
      'ojos' => const _AccessoryLayout(88, 106, 110),
      'cuello' => const _AccessoryLayout(88, 181, 95),
      'torso' => const _AccessoryLayout(74, 144, 130),
      'brazos' => const _AccessoryLayout(25, 151, 225),
      'mano' => const _AccessoryLayout(200, 157, 65),
      'espalda' => const _AccessoryLayout(41, 127, 190),
      'pies' => const _AccessoryLayout(74, 221, 132),
      _ => const _AccessoryLayout(75, 25, 120),
    };
  }

  bool get _editableSlot => !_profileMode && !_ufoMode &&
      _slot != 'skin' && _slot != 'aura';

  void _updateLayout(ShopItem item, _AccessoryLayout layout) {
    final size = layout.size.clamp(30.0, 250.0);
    setState(() {
      _layouts[item.id] = _AccessoryLayout(
        layout.x.clamp(0.0, 280.0 - size),
        layout.y.clamp(0.0, 275.0 - size),
        size, layout.rotation.clamp(-180.0, 180.0),
      );
    });
  }

  Color get _ink => HealthyAdaptive.text;
  Color get _accent => HealthyAdaptive.accent;
  Color get _muted => HealthyAdaptive.muted;

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectMode(bool profile) {
    if (_profileMode == profile && !_ufoMode) return;
    setState(() {
      _profileMode = profile;
      _ufoMode = false;
      _slot = profile ? 'perfil_avatar' : 'cabeza';
      _layoutEditor = false;
    });
  }

  void _selectUfoMode() {
    if (_ufoMode) return;
    setState(() {
      _profileMode = false;
      _ufoMode = true;
      _slot = 'ufo_skin';
      _layoutEditor = false;
    });
  }

  Future<void> _equip(ShopItem item, ShopState state) async {
    if (_busy != null) return;
    if (!state.owns(item.id)) {
      _message('Objeto bloqueado. Consíguelo primero en la tienda.');
      return;
    }
    final removing = state.equipped[item.slot] == item.id;
    setState(() => _busy = item.id);
    try {
      await ShopService.instance.equip(item, remove: removing);
      await HealthyFeedbackService.onEquip();
      _message(removing ? 'Objeto retirado.' : 'Objeto equipado.');
    } catch (error) {
      _message(error is ShopException
          ? error.message
          : 'No se pudo guardar el cambio. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _changeProfileTitle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default');
    try {
      final profile = await db.collection('users').doc(uid).get();
      final level = (profile.data()?['level'] as num?)?.toInt() ?? 1;
      final selected = profile.data()?['profileTitle']?.toString();
      // Las distinciones de festivales requieren certificados oficiales.
      // No permitir títulos de temporada basándose en entradas libres.
      final verifiedBadges = <String>{};
      try {
        final official = await db.collection('public_profiles').doc(uid)
          .collection('activity_events')
          .where('kind', isEqualTo: 'achievement_unlocked')
          .limit(100).get();
        for (final doc in official.docs) {
          final badge = doc.data()['achievementId'];
          if (badge is String) verifiedBadges.add(badge);
        }
      } catch (_) {
        // Sin permiso o sin eventos: títulos de eventos bloqueados.
      }
      if (!mounted) return;
      final choice = await showModalBottomSheet<HealthyProfileTitle>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .72,
          child: Column(children: [
            const ListTile(
              title: Text('Colección de títulos',
                style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('Desbloquea títulos con niveles, logros '
                'y eventos oficiales. Los bloqueados no se pueden usar.'),
            ),
            Expanded(child: ListView.builder(
              itemCount: HealthyProfileTitles.catalog.length,
              itemBuilder: (context, index) {
                final title = HealthyProfileTitles.catalog[index];
                final unlocked = title.available(level, verifiedBadges);
                final active = selected == title.name;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                  child: ListTile(
                    key: ValueKey('profile-title-${title.id}'),
                    leading: CircleAvatar(
                      child: Icon(title.icon)),
                    title: Text(title.name,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(unlocked
                        ? title.description
                        : 'Bloqueado · ${title.description}'),
                    trailing: active && unlocked
                        ? const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF198568))
                        : Icon(unlocked
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.lock_outline_rounded),
                    enabled: unlocked,
                    onTap: unlocked
                        ? () => Navigator.pop(sheetContext, title) : null,
                  ),
                );
              },
            )),
          ]),
        )),
      );
      if (choice == null || !mounted) return;
      // Releer el nivel justo antes de guardar evita desbloqueos por
      // un panel desactualizado; el servidor debe imponer esta regla
      // cuando se publique la beta comercial.
      final latest = await db.collection('users').doc(uid).get();
      final latestLevel =
          (latest.data()?['level'] as num?)?.toInt() ?? 1;
      if (!choice.available(latestLevel, verifiedBadges)) {
        _message('El título todavía no está desbloqueado.');
        return;
      }
      if (BetaHabitGateway.enabled) {
        await FirebaseFunctions.instanceFor(
          app: Firebase.app(), region: 'us-central1',
        ).httpsCallable('selectProfileTitleBeta').call({'titleId': choice.id});
        if (FirebaseAuth.instance.currentUser?.uid != uid) {
          throw StateError('La sesión cambió durante el equipamiento.');
        }
      } else {
        await db.collection('users').doc(uid).update({
          'profileTitle': choice.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      _message('Título equipado: ${choice.name}.');
    } catch (_) {
      _message('No se pudo consultar o guardar tu título.');
    }
  }

  Future<void> _reset() async {
    if (_busy != null) return;
    setState(() => _busy = 'reset');
    try {
      await ShopService.instance.resetLook();
      _message('Mr. Healthy volvió a su aspecto original.');
    } catch (_) {
      _message('No se pudo restablecer el aspecto.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = _ufoMode ? ufoWardrobeSlots :
        (_profileMode ? profileWardrobeSlots : mascotWardrobeSlots);
    return Scaffold(
      floatingActionButton: const HealthyMagicGuideButton(section: 'armario'),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      backgroundColor: HealthyAdaptive.background,
      body: SafeArea(
        child: StreamBuilder<ShopState>(
          stream: ShopService.instance.watch(),
          builder: (context, snapshot) {
            final state = snapshot.data;
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(state),
                  const SizedBox(height: 8),
                  _modeSelector(),
                  const SizedBox(height: 10),
                  // El escenario NO está dentro de ningún ScrollView.
                  // La cuadrícula inferior se desplaza de forma independiente.
                  Expanded(
                    flex: 11,
                    child: Container(
                      key: const Key('armario-escenario-fijo'),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: HealthyAdaptive.isDark
                              ? const [Color(0xFF21443F), Color(0xFF152B32)]
                              : const [Color(0xFFE6F6ED), Color(0xFFD2EBE2)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _ufoMode
                            ? _ufoStage(state)
                            : _profileMode
                                ? _profileStage(state)
                                : _mascotStage(state),
                      ),
                    ),
                  ),
                  if (_layoutEditor && _editableSlot && state != null &&
                      state.equipped[_slot] != null) ...[
                    const SizedBox(height: 6),
                    _layoutControls(state.equipped[_slot]!),
                  ],
                  const SizedBox(height: 10),
                  _sectionTitle(slots, state),
                  const SizedBox(height: 7),
                  _slotBar(slots),
                  const SizedBox(height: 9),
                  if (snapshot.hasError)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('No fue posible cargar el inventario.',
                        style: TextStyle(color: Colors.red)),
                    ),
                  // Altura siempre acotada. La lista nunca empuja al escenario.
                  Expanded(
                    flex: 9,
                    child: Container(
                      key: const Key('armario-inventario-scroll'),
                      decoration: BoxDecoration(
                        color: HealthyAdaptive.surface,
                        border: Border.all(color: HealthyAdaptive.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: state == null
                          ? Center(child: snapshot.hasError
                              ? const Icon(Icons.cloud_off_rounded)
                              : const CircularProgressIndicator())
                          : _itemGrid(state),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _footer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(ShopState? state) => Row(
    children: [
      IconButton(
        tooltip: 'Volver',
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      Expanded(
        child: Text('Armario', style: TextStyle(
          color: _ink, fontWeight: FontWeight.w900, fontSize: 23)),
      ),
      const HealthyCoinIcon(size: 23),
      const SizedBox(width: 5),
      Text(state == null ? '...' : '${state.coins}', style: TextStyle(
        color: _ink, fontWeight: FontWeight.w800, fontSize: 16)),
    ],
  );

  Widget _modeSelector() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
        key: const Key('armario-selector-modo'),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: HealthyAdaptive.surface,
          border: Border.all(color: HealthyAdaptive.border),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _modeButton(false, Icons.emoji_emotions_rounded, 'Mr. Healthy'),
          _modeButton(true, Icons.account_circle_rounded, 'Perfil'),
          _ufoModeButton(),
        ]),
        ),
      ),
    );
  }

  Widget _modeButton(bool profile, IconData icon, String label) {
    final active = _profileMode == profile && !_ufoMode;
    return InkWell(
      key: ValueKey(profile ? 'armario-modo-perfil' : 'armario-modo-mascota'),
      borderRadius: BorderRadius.circular(40),
      onTap: () => _selectMode(profile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _accent : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 17,
            color: active ? Colors.white : _muted),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            color: active ? Colors.white : _ink,
            fontWeight: FontWeight.w800, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _ufoModeButton() => InkWell(
    key: const ValueKey('armario-modo-ufo'),
    borderRadius: BorderRadius.circular(40),
    onTap: _selectUfoMode,
    child: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero : const Duration(milliseconds: 190),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: _ufoMode ? _accent : Colors.transparent,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.rocket_launch_rounded, size: 17,
          color: _ufoMode ? Colors.white : _muted),
        const SizedBox(width: 5),
        Text('OVNI', style: TextStyle(
          color: _ufoMode ? Colors.white : _ink,
          fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    ),
  );

  Widget _mascotStage(ShopState? state) {
    return Stack(
      key: const ValueKey('escenario-mascota'),
      children: [
        Positioned(
          top: 13, left: 16,
          child: Text('MR. HEALTHY', style: TextStyle(
            color: _ink, fontSize: 11, fontWeight: FontWeight.w900,
            letterSpacing: 1.5)),
        ),
        Positioned(
          top: 2, right: 7,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (_editableSlot && state?.equipped[_slot] != null)
              IconButton(
                key: const ValueKey('wardrobe-edit-layout'),
                tooltip: _layoutEditor ? 'Terminar de ajustar' : 'Mover, escalar y girar accesorio',
                onPressed: () => setState(() =>
                  _layoutEditor = !_layoutEditor),
                icon: Icon(_layoutEditor ? Icons.check_circle_rounded :
                  Icons.open_with_rounded, color: _ink),
              ),
            IconButton(
              tooltip: 'Restablecer accesorios y skin',
              onPressed: state == null || _busy != null ? null : _reset,
              icon: Icon(Icons.restart_alt_rounded, color: _ink),
            ),
          ]),
        ),
        Align(
          alignment: const Alignment(0, .94),
          child: Container(
            width: 172, height: 17,
            decoration: BoxDecoration(
              color: const Color(0xFF18493A).withValues(alpha: .22),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(color: const Color(0xFF18493A)
                    .withValues(alpha: .15), blurRadius: 16,
                  spreadRadius: 9),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              // El balanceo incluye todas las capas para que ningún
              // accesorio se separe de Mr. Healthy al respirar.
              child: HealthyMascotIdle(
                child: SizedBox(width: 280, height: 275,
                  child: Stack(clipBehavior: Clip.none, children: [
                    HealthyMascotOutfit(
                      equipped: {
                        ...?state?.equipped,
                        for (final entry in (state?.equipped ??
                            const <String, String>{}).entries)
                          if (_layouts.containsKey(entry.value) ||
                              (_layoutEditor && entry.key == _slot &&
                               _editableSlot))
                            entry.key: '',
                      },
                    ),
                    for (final entry in (state?.equipped ??
                        const <String, String>{}).entries)
                      if (shopItemById(entry.value) != null &&
                          (_layouts.containsKey(entry.value) ||
                           (_layoutEditor && entry.key == _slot &&
                            _editableSlot)) &&
                          entry.key != 'aura' && entry.key != 'skin')
                        _positionedAccessory(entry.key, entry.value),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _positionedAccessory(String slot, String itemId) {
    final item = shopItemById(itemId);
    if (item == null) return const SizedBox.shrink();
    final placement = _layouts[itemId] ?? _defaultLayout(slot);
    final editable = _layoutEditor && slot == _slot;
    return Positioned(
      left: placement.x, top: placement.y,
      width: placement.size, height: placement.size,
      child: GestureDetector(
        key: ValueKey('wardrobe-movable-$itemId'),
        behavior: HitTestBehavior.opaque,
        onPanUpdate: editable ? (details) =>
            _updateLayout(item, _AccessoryLayout(
              placement.x + details.delta.dx,
              placement.y + details.delta.dy,
              placement.size, placement.rotation,
            )) : null,
        onPanEnd: editable ? (_) => _saveLayouts() : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: editable ? Border.all(
              color: HealthyAdaptive.accent, width: 2) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Transform.rotate(
            angle: placement.rotation * 3.141592653589793 / 180,
            child: ShopItemArtwork(item: item, size: placement.size),
          ),
        ),
      ),
    );
  }

  Future<void> _enterAccessoryNumber(String itemId, {required bool rotation}) async {
    final item = shopItemById(itemId);
    if (item == null || item.slot == null) return;
    final layout = _layouts[itemId] ?? _defaultLayout(item.slot!);
    final current = rotation ? layout.rotation : layout.size;

    // El diálogo administra solo una cadena. No crear ni desechar un
    // TextEditingController mientras Flutter sigue desmontando la ruta.
    // Eso puede disparar '_dependents.isEmpty' al cerrar el teclado.
    var draft = current.round().toString();
    String? error;

    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void apply() {
            final parsed = double.tryParse(draft.trim());
            final min = rotation ? -180.0 : 30.0;
            final max = rotation ? 180.0 : 250.0;
            if (parsed == null || !parsed.isFinite ||
                parsed < min || parsed > max) {
              setDialogState(() => error = 'Valor fuera de rango');
              return;
            }
            // Un número negativo, como -5°, es un valor válido.
            FocusScope.of(dialogContext).unfocus();
            Navigator.of(dialogContext).pop(parsed);
          }

          return AlertDialog(
            title: Text(rotation ? 'Giro del accesorio' : 'Tamaño del accesorio'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(rotation
                  ? 'Escribe un ángulo entre -180° y 180°.'
                  : 'Escribe un tamaño entre 30 y 250.'),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey(rotation
                    ? 'wardrobe-rotation-number' : 'wardrobe-size-number'),
                initialValue: draft,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(
                  signed: rotation, decimal: false),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixText: rotation ? '°' : 'px',
                  errorText: error,
                ),
                onChanged: (text) {
                  draft = text;
                  if (error != null) {
                    setDialogState(() => error = null);
                  }
                },
                onFieldSubmitted: (_) => apply(),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: apply,
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted || value == null) return;
    final latest = _layouts[itemId] ?? _defaultLayout(item.slot!);
    _updateLayout(item, _AccessoryLayout(
      latest.x, latest.y,
      rotation ? latest.size : value,
      rotation ? value : latest.rotation,
    ));
    await _saveLayouts();
  }

  Widget _layoutControls(String itemId) {
    final item = shopItemById(itemId);
    if (item?.slot == null) return const SizedBox.shrink();
    final current = _layouts[itemId] ?? _defaultLayout(item!.slot!);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        const Icon(Icons.open_with_rounded, size: 17),
        const SizedBox(width: 5),
        const Expanded(flex: 2, child: Text('Arrastra para mover',
          style: TextStyle(fontSize: 11))),
        const Icon(Icons.zoom_out_rounded, size: 17),
        Expanded(flex: 3, child: Slider(
          key: const ValueKey('wardrobe-accessory-scale'),
          value: current.size.clamp(30.0, 250.0),
          min: 30, max: 250,
          onChanged: (size) => _updateLayout(item!, _AccessoryLayout(
            current.x, current.y, size, current.rotation)),
          onChangeEnd: (_) => _saveLayouts(),
        )),
        IconButton(
          key: const ValueKey('wardrobe-edit-size-number'),
          tooltip: 'Escribir tamaño exacto',
          onPressed: () => _enterAccessoryNumber(itemId, rotation: false),
          icon: const Icon(Icons.edit_note_rounded, size: 21),
        ),
      ]),
      Row(children: [
        const Icon(Icons.rotate_right_rounded, size: 19),
        const SizedBox(width: 5),
        const Text('Girar', style: TextStyle(fontSize: 11)),
        Expanded(child: Slider(
          key: const ValueKey('wardrobe-accessory-rotation'),
          value: current.rotation.clamp(-180.0, 180.0),
          min: -180, max: 180, divisions: 72,
          label: '${current.rotation.round()}°',
          onChanged: (angle) => _updateLayout(item!, _AccessoryLayout(
            current.x, current.y, current.size, angle)),
          onChangeEnd: (_) => _saveLayouts(),
        )),
        Text('${current.rotation.round()}°',
          style: const TextStyle(fontSize: 11)),
        IconButton(
          key: const ValueKey('wardrobe-edit-rotation-number'),
          tooltip: 'Escribir grados exactos',
          onPressed: () => _enterAccessoryNumber(itemId, rotation: true),
          icon: const Icon(Icons.edit_note_rounded, size: 21),
        ),
        IconButton(
          tooltip: 'Restablecer giro',
          onPressed: () {
            _updateLayout(item!, _AccessoryLayout(
              current.x, current.y, current.size, 0));
            _saveLayouts();
          },
          icon: const Icon(Icons.restart_alt_rounded, size: 19),
        ),
      ]),
    ]);
  }

  Widget _ufoStage(ShopState? state) {
    final equipped = state?.equipped['ufo_skin'];
    final valid = equipped != null &&
        HealthyUfoSkinArt.ids.contains(equipped) && state!.owns(equipped);
    return Column(
      key: const ValueKey('escenario-ufo'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('TU OVNI', style: TextStyle(color: _ink,
          fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 5),
        Flexible(child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero : const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          child: valid
              ? HealthyUfoSkinArt(key: ValueKey(equipped),
                  id: equipped, size: 175)
              : Image.asset(HealthyUfoVisual.asset,
                  key: const ValueKey('ovnipredeterminado'),
                  width: 175, height: 175, fit: BoxFit.contain),
        )),
        const SizedBox(height: 6),
        Text(valid ? 'Aspecto equipado' : 'Aspecto original',
          style: TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 5),
        Text('Se muestra también durante el tutorial.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 10)),
      ],
    );
  }

  Widget _profileStage(ShopState? state) {
    final equipped = state?.equipped ?? const <String, String>{};
    final banner = equipped['perfil_banner'] ?? 'Amanecer';
    final avatar = equipped['perfil_avatar'] ?? 'foto';
    final frame = HealthyCosmetics.assetFor(equipped['perfil_marco'] ?? '');
    final hasExhibitor = equipped['perfil_expositor'] == 'achievement_display';
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final avatarSize = (constraints.maxHeight * .32).clamp(48.0, 86.0);
      return Stack(
        key: const ValueKey('escenario-perfil'),
        children: [
          Positioned(
            top: 12, left: 14,
            child: Text('VISTA PREVIA DEL PERFIL',
              style: TextStyle(color: _ink, fontSize: 10,
                letterSpacing: 1, fontWeight: FontWeight.w900)),
          ),
          Positioned(
            top: 34, left: 12, right: 12,
            child: SizedBox(
              width: width - 24,
              child: ProfileBanner(
                bannerStyle: banner,
                label: 'MI PERFIL',
                fallbackColors: const [
                  Color(0xFF174D4B), Color(0xFF498A75)],
              ),
            ),
          ),
          if (hasExhibitor)
            Positioned(
              left: 12, bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: HealthyAdaptive.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD5A33E)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.workspace_premium_rounded,
                    size: 15, color: Color(0xFFD5A33E)),
                  SizedBox(width: 4),
                  Text('Expositor', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          Positioned(
            bottom: 9,
            left: 0, right: 0,
            child: Center(
              child: HealthyFramedAvatar(
                size: avatarSize,
                photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
                preset: avatar,
                frameAsset: frame,
                backgroundColor: HealthyAdaptive.surface,
                borderColor: HealthyAdaptive.accent,
                frameOverflow: 9,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _sectionTitle(List<WardrobeSlot> slots, ShopState? state) {
    final label = slots.firstWhere((s) => s.id == _slot).label;
    final count = wardrobeItemsForSlot(_slot, state: state).length;
    return Row(children: [
      Expanded(
        child: Text('Personalizar · $label', style: TextStyle(
          color: _ink, fontSize: 15, fontWeight: FontWeight.w900)),
      ),
      Text('$count objetos', style: TextStyle(
        color: _muted, fontSize: 12)),
    ]);
  }

  Widget _slotBar(List<WardrobeSlot> slots) {
    return SizedBox(
      height: 65,
      child: ListView.separated(
        key: const Key('armario-ranuras'),
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, index) {
          final slot = slots[index];
          final selected = slot.id == _slot;
          return InkWell(
            key: ValueKey('armario-ranura-${slot.id}'),
            borderRadius: BorderRadius.circular(15),
            onTap: () => setState(() => _slot = slot.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 74,
              decoration: BoxDecoration(
                color: selected ? _accent : HealthyAdaptive.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: selected
                    ? _accent : HealthyAdaptive.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(slot.icon, size: 24, color:
                      selected ? Colors.white : _ink),
                  const SizedBox(height: 4),
                  Text(slot.label, style: TextStyle(
                    color: selected ? Colors.white : _muted,
                    fontWeight: FontWeight.w700, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _itemGrid(ShopState state) {
    if (_slot == 'perfil_titulo') {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.badge_outlined, size: 42),
          const SizedBox(height: 10),
          const Text('Colecciona títulos por nivel, logros y festivales.',
            textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('wardrobe-profile-title'),
            onPressed: _changeProfileTitle,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Ver colección de títulos'),
          ),
        ]),
      ));
    }
    final items = wardrobeItemsForSlot(_slot, state: state);
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inventory_2_outlined, size: 31, color: _muted),
            const SizedBox(height: 7),
            Text('Todavía no hay objetos para esta ranura.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12)),
          ]),
        ),
      );
    }
    return GridView.builder(
      key: ValueKey('armario-objetos-$_slot'),
      padding: const EdgeInsets.all(9),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: .78,
      ),
      itemBuilder: (_, index) => _itemTile(items[index], state),
    );
  }

  Widget _itemTile(ShopItem item, ShopState state) {
    final owned = state.owns(item.id);
    final equipped = state.equipped[item.slot] == item.id;
    return Material(
      key: ValueKey('armario-objeto-${item.id}'),
      color: HealthyAdaptive.surfaceAlt,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: _busy == null ? () => _equip(item, state) : null,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: equipped ? _accent : HealthyAdaptive.border,
              width: equipped ? 2 : 1),
          ),
          child: Column(children: [
            Expanded(
              child: Stack(alignment: Alignment.center, children: [
                Opacity(
                  opacity: owned ? 1 : .32,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: ShopItemArtwork(item: item, size: 76),
                  ),
                ),
                if (!owned)
                  Container(
                    key: ValueKey('armario-candado-${item.id}'),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: HealthyAdaptive.surface.withValues(alpha: .94),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_rounded,
                      size: 21, color: _ink),
                  ),
                if (equipped)
                  Positioned(
                    top: 1, right: 1,
                    child: Icon(Icons.check_circle_rounded,
                      size: 19, color: _accent),
                  ),
              ]),
            ),
            const SizedBox(height: 4),
            Text(item.name,
              maxLines: 2, textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _ink,
                fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(height: 3),
            Text(_busy == item.id
                    ? 'Guardando...'
                    : !owned
                        ? 'Bloqueado'
                        : equipped
                            ? 'Equipado'
                            : 'Equipar',
              maxLines: 1,
              style: TextStyle(color: equipped ? _accent : _muted,
                fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  Widget _footer() => SizedBox(
    height: 36,
    child: TextButton.icon(
      onPressed: () => Navigator.maybePop(context),
      icon: const Icon(Icons.storefront_rounded, size: 18),
      label: const Text('Volver a la tienda'),
    ),
  );
}
