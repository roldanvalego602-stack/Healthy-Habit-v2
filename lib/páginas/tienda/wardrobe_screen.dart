import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Armario de Mr. Healthy.
/// Estado local de demostración: conecta monedas/equipo con el modelo global
/// de usuario cuando esa capa exista en el proyecto.
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  static const Color _navy = Color(0xFF193342);
  static const Color _green = Color(0xFF42C99A);
  static const Color _greenDark = Color(0xFF16866B);
  static const Color _mint = Color(0xFFE3F5EC);
  static const Color _background = Color(0xFFF5F8F6);
  static const Color _muted = Color(0xFF82919A);

  int _coins = 240;
  String _filter = 'Todos';

  final Set<String> _owned = {'sunglasses', 'bandana'};
  final Set<String> _equipped = {'sunglasses'};

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedOwned = prefs.getStringList('healthy_habit_wardrobe_owned');
    final savedEquipped = prefs.getStringList('healthy_habit_wardrobe_equipped');
    setState(() {
      _coins = prefs.getInt('healthy_habit_wardrobe_coins') ?? 240;
      if (savedOwned != null) {
        _owned
          ..clear()
          ..addAll(savedOwned);
      }
      if (savedEquipped != null) {
        _equipped
          ..clear()
          ..addAll(savedEquipped);
      }
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('healthy_habit_wardrobe_coins', _coins);
    await prefs.setStringList('healthy_habit_wardrobe_owned', _owned.toList());
    await prefs.setStringList('healthy_habit_wardrobe_equipped', _equipped.toList());
  }

  final List<_WardrobeItem> _catalog = const [
    _WardrobeItem(
      id: 'sunglasses', name: 'Lentes sol', category: 'Accesorios',
      slot: 'ojos', price: 0, emoji: '🕶️', description: 'Un clásico para Mr. Healthy.',
    ),
    _WardrobeItem(
      id: 'bandana', name: 'Bufanda', category: 'Ropa',
      slot: 'cuello', price: 0, emoji: '🧣', description: 'Un toque aventurero.',
    ),
    _WardrobeItem(
      id: 'cap', name: 'Gorra urbana', category: 'Cabeza',
      slot: 'cabeza', price: 100, emoji: '🧢', description: 'Estilo relajado.',
    ),
    _WardrobeItem(
      id: 'crown', name: 'Corona de bronce', category: 'Cabeza',
      slot: 'cabeza', price: 180, emoji: '👑', description: 'Para una racha legendaria.',
    ),
    _WardrobeItem(
      id: 'mint_aura', name: 'Aura menta', category: 'Especiales',
      slot: 'aura', price: 120, emoji: '✨', description: 'Un brillo suave alrededor de la mascota.',
    ),
    _WardrobeItem(
      id: 'cape', name: 'Capa de héroe', category: 'Ropa',
      slot: 'espalda', price: 200, emoji: '🦸', description: 'Listo para completar misiones.',
    ),
    _WardrobeItem(
      id: 'pixel_glasses', name: 'Lentes pixel', category: 'Accesorios',
      slot: 'ojos', price: 80, emoji: '🤓', description: 'Modo gamer activado.',
    ),
    _WardrobeItem(
      id: 'cat_ears', name: 'Orejas felinas', category: 'Cabeza',
      slot: 'cabeza', price: 150, emoji: '🐱', description: 'Una apariencia juguetona.',
    ),
  ];

  List<_WardrobeItem> get _visibleItems {
    if (_filter == 'Todos') return _catalog;
    return _catalog.where((item) => item.category == _filter).toList();
  }

  _WardrobeItem _itemById(String id) => _catalog.firstWhere((item) => item.id == id);

  String? _equippedItemForSlot(String slot) {
    for (final id in _equipped) {
      if (_itemById(id).slot == slot) return id;
    }
    return null;
  }

  String get _lookDescription {
    if (_equipped.isEmpty) return 'Mr. Healthy está listo para personalizarse';
    return _equipped.map((id) => _itemById(id).name).join(' + ');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _resetLook() {
    setState(() => _equipped
      ..clear()
      ..add('sunglasses'));
    unawaited(_saveState());
    _showMessage('Aspecto restablecido. Tus objetos siguen en tu colección.');
  }

  Future<void> _onItemTap(_WardrobeItem item) async {
    if (_owned.contains(item.id)) {
      setState(() {
        if (_equipped.contains(item.id)) {
          _equipped.remove(item.id);
        } else {
          // Solo puede haber un objeto equipado por espacio visual.
          final sameSlot = _equipped.where((id) => _itemById(id).slot == item.slot).toList();
          _equipped.removeAll(sameSlot);
          _equipped.add(item.id);
        }
      });
      unawaited(_saveState());
      return;
    }

    if (_coins < item.price) {
      _showMessage('Te faltan ${item.price - _coins} Habit Coins para comprar ${item.name}.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿Comprar ${item.name}?'),
        content: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Expanded(child: Text('${item.description}\n\nCosto: ${item.price} Habit Coins.')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    if (_coins < item.price) {
      _showMessage('Ya no tienes suficientes Habit Coins.');
      return;
    }

    setState(() {
      _coins -= item.price;
      _owned.add(item.id);
      final sameSlot = _equipped.where((id) => _itemById(id).slot == item.slot).toList();
      _equipped.removeAll(sameSlot);
      _equipped.add(item.id);
    });
    unawaited(_saveState());
    _showMessage('${item.name} comprado y equipado.');
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      _showMessage('Cuando se integre la navegación, aquí volverás a la tienda.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: _navy,
                    tooltip: 'Volver',
                  ),
                  const Expanded(
                    child: Text('Armario', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _navy)),
                  ),
                  _CoinPill(coins: _coins),
                ],
              ),
              const SizedBox(height: 22),
              const Text('Tan único como tú', style: TextStyle(fontSize: 29, height: 1.15, fontWeight: FontWeight.w800, color: _navy)),
              const SizedBox(height: 8),
              const Text('Personaliza a Mr. Healthy.', style: TextStyle(fontSize: 18, color: _muted)),
              const SizedBox(height: 24),
              _buildPreview(),
              const SizedBox(height: 22),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Todos', 'Cabeza', 'Ropa', 'Accesorios', 'Especiales'].map((category) {
                    final selected = _filter == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = category),
                        selectedColor: _green,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected ? _navy : _muted,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide(color: selected ? _green : const Color(0xFFE1E9E5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Text('${_visibleItems.length} objetos · Los que compras se equipan libremente.', style: const TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _visibleItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.76,
                ),
                itemBuilder: (context, index) => _buildItemCard(_visibleItems[index]),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(26)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Consigue más accesorios', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 12),
                    Text('Tienes $_coins Habit Coins. Compra accesorios para darle tu propio estilo a Mr. Healthy.', style: const TextStyle(color: Colors.white70, height: 1.45)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _goBack,
                        icon: const Icon(Icons.storefront_rounded),
                        label: const Text('Volver a la tienda'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: _navy,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final hasAura = _equipped.contains('mint_aura');
    final hasCape = _equipped.contains('cape');
    final headItem = _equippedItemForSlot('cabeza');
    final eyeItem = _equippedItemForSlot('ojos');
    final hasBandana = _equipped.contains('bandana');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE8F7EF), Color(0xFFDDEFE6)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(22)),
                  child: const Text('Cuidado con Mr. Healthy, tiene +999 de Aura', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF26735F), fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
              IconButton(onPressed: _resetLook, icon: const Icon(Icons.refresh_rounded), tooltip: 'Restablecer aspecto', color: _greenDark),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 280,
            width: 280,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (hasAura)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: _green.withOpacity(0.65), blurRadius: 42, spreadRadius: 12)]),
                    ),
                  ),
                if (hasCape)
                  Positioned(
                    top: 145,
                    left: 48,
                    child: Transform.rotate(
                      angle: -0.15,
                      child: Container(width: 184, height: 100, decoration: BoxDecoration(color: const Color(0xFFB94B58), borderRadius: BorderRadius.circular(36))),
                    ),
                  ),
                Image.asset(
                  'assets/mascot/healthy.png',
                  fit: BoxFit.contain,
                  width: 270,
                  height: 270,
                  errorBuilder: (_, __, ___) => const Icon(Icons.sentiment_satisfied_alt_rounded, size: 190, color: _greenDark),
                ),
                if (headItem != null)
                  Positioned(
                    top: 8,
                    child: Text(_itemById(headItem).emoji, style: const TextStyle(fontSize: 48)),
                  ),
                if (eyeItem != null)
                  Positioned(
                    top: 168,
                    child: eyeItem == 'sunglasses' ? const _Sunglasses() : const _PixelGlasses(),
                  ),
                if (hasBandana)
                  Positioned(
                    top: 196,
                    child: Transform.rotate(
                      angle: -0.04,
                      child: Container(
                        width: 100,
                        height: 23,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFF1D7666), borderRadius: BorderRadius.circular(7), border: Border.all(color: Colors.white, width: 1.5)),
                        child: const Text('✦  ✦  ✦', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(_lookDescription, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF397967), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildItemCard(_WardrobeItem item) {
    final owned = _owned.contains(item.id);
    final equipped = _equipped.contains(item.id);
    final canAfford = _coins >= item.price;
    String status;
    if (equipped) {
      status = 'Equipado';
    } else if (owned) {
      status = 'Toca para equipar';
    } else {
      status = '${item.price} H. Coins';
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _onItemTap(item),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: equipped ? _green : const Color(0xFFE2EAE5), width: equipped ? 2.2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: item.category == 'Cabeza'
                        ? const [Color(0xFFFFF3CD), Color(0xFFFFF9E9)]
                        : const [Color(0xFFE5F7EF), Color(0xFFF3FAF6)]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 46))),
                ),
              ),
              const SizedBox(height: 10),
              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navy, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: equipped ? _mint : owned ? const Color(0xFFF1F4F3) : canAfford ? const Color(0xFFFFF4D5) : const Color(0xFFE9ECEF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: equipped ? _greenDark : owned ? _muted : canAfford ? const Color(0xFF9C7620) : _muted, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              Text(equipped ? 'Toca para quitar' : owned ? 'Toca para equipar' : item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11, height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WardrobeItem {
  final String id;
  final String name;
  final String category;
  final String slot;
  final int price;
  final String emoji;
  final String description;

  const _WardrobeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.slot,
    required this.price,
    required this.emoji,
    required this.description,
  });
}

class _CoinPill extends StatelessWidget {
  final int coins;
  const _CoinPill({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/monedas/h coin.png', width: 23, height: 23, errorBuilder: (_, __, ___) => const Text('🪙', style: TextStyle(fontSize: 19))),
          const SizedBox(width: 6),
          Text('$coins', style: const TextStyle(color: Color(0xFF16866B), fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}

class _Sunglasses extends StatelessWidget {
  const _Sunglasses();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _lens(),
        Container(width: 9, height: 4, color: const Color(0xFFF4D783)),
        _lens(),
      ],
    );
  }

  Widget _lens() => Container(
    width: 34,
    height: 21,
    decoration: BoxDecoration(color: const Color(0xFF193342), border: Border.all(color: const Color(0xFFF4D783), width: 3), borderRadius: BorderRadius.circular(7)),
  );
}

class _PixelGlasses extends StatelessWidget {
  const _PixelGlasses();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _lens(),
        Container(width: 8, height: 4, color: const Color(0xFF193342)),
        _lens(),
      ],
    );
  }

  Widget _lens() => Container(
    width: 32,
    height: 22,
    decoration: BoxDecoration(color: const Color(0xFF193342), border: Border.all(color: const Color(0xFF42C99A), width: 2), borderRadius: BorderRadius.circular(3)),
  );
}
