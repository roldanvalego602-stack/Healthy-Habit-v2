import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../servicios/healthy_feedback_service.dart';
import '../../tema/healthy_coin.dart';
import '../../tema/healthy_cosmetics.dart';
import '../../tema/healthy_theme.dart';
import '../perfil/profile_avatar.dart';
import '../perfil/profile_banner.dart';
import 'healthy_mascot_outfit.dart';
import 'healthy_mascot_idle.dart';
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

const profileWardrobeSlots = <WardrobeSlot>[
  WardrobeSlot('perfil_avatar', 'Avatar', Icons.account_circle_rounded),
  WardrobeSlot('perfil_marco', 'Marco', Icons.crop_square_rounded),
  WardrobeSlot('perfil_banner', 'Banner', Icons.panorama_rounded),
  WardrobeSlot('perfil_expositor', 'Expositor', Icons.workspace_premium_rounded),
];

/// Selecciona exclusivamente artículos equipables de la ranura elegida.
/// Las reacciones consumibles y extras sin ranura permanecen en la tienda.
List<ShopItem> wardrobeItemsForSlot(String slot) =>
    shopCatalog.where((item) => item.slot == slot &&
        (isShopItemVisible(item.id))).toList(growable: false);

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  bool _profileMode = false;
  String _slot = 'cabeza';
  String? _busy;

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
    if (_profileMode == profile) return;
    setState(() {
      _profileMode = profile;
      _slot = profile ? 'perfil_avatar' : 'cabeza';
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
    final slots = _profileMode ? profileWardrobeSlots : mascotWardrobeSlots;
    return Scaffold(
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
                        child: _profileMode
                            ? _profileStage(state)
                            : _mascotStage(state),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _sectionTitle(slots),
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
        ]),
      ),
    );
  }

  Widget _modeButton(bool profile, IconData icon, String label) {
    final active = _profileMode == profile;
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
          child: IconButton(
            tooltip: 'Restablecer accesorios y skin',
            onPressed: state == null || _busy != null ? null : _reset,
            icon: Icon(Icons.restart_alt_rounded, color: _ink),
          ),
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
                child: HealthyMascotOutfit(
                  equipped: state?.equipped ?? const <String, String>{},
                ),
              ),
            ),
          ),
        ),
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
              child: Container(
                width: avatarSize + 9,
                height: avatarSize + 9,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HealthyAdaptive.surface,
                ),
                child: Stack(fit: StackFit.expand, children: [
                  HealthyProfileAvatar(
                    photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
                    preset: avatar,
                    size: avatarSize,
                  ),
                  if (frame != null)
                    IgnorePointer(
                      child: Image.asset(frame, fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink()),
                    ),
                ]),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _sectionTitle(List<WardrobeSlot> slots) {
    final label = slots.firstWhere((s) => s.id == _slot).label;
    final count = wardrobeItemsForSlot(_slot).length;
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
    final items = wardrobeItemsForSlot(_slot);
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
