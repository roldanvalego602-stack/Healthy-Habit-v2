import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'healthy_mascot_outfit.dart';
import 'healthy_mascot_idle.dart';
import 'shop_item_artwork.dart';
import 'shop_service.dart';

/// Mascota coherente en chat y perfil, con la vestimenta EQUIPADA por usuario.
/// Los ajustes finos del armario se leen de la misma clave local existente;
/// no modifica inventario, compras ni recompensas.
class HealthyMascotLive extends StatelessWidget {
  const HealthyMascotLive({super.key, this.size = 100});
  final double size;

  Future<Map<String, dynamic>> _readLayouts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    try {
      final raw = await SharedPreferencesAsync()
          .getString('hh_wardrobe_layout_v1_$uid');
      if (raw == null) return {};
      final value = jsonDecode(raw);
      return value is Map
          ? value.map((key, v) => MapEntry(key.toString(), v))
          : {};
    } catch (_) {
      return {};
    }
  }

  Widget _buildOutfit(ShopState? state, Map<String, dynamic> layouts) {
    final equipped = state?.equipped ?? const <String, String>{};
    final custom = <String, Map<String, double>>{};
    for (final id in equipped.values) {
      final raw = layouts[id];
      if (raw is! Map ||
          raw['x'] is! num || raw['y'] is! num ||
          raw['size'] is! num) {
        continue;
      }
      final x = (raw['x'] as num).toDouble();
      final y = (raw['y'] as num).toDouble();
      final scale = (raw['size'] as num).toDouble();
      final rotation = raw['rotation'] is num
          ? (raw['rotation'] as num).toDouble() : 0.0;
      if (![x, y, scale, rotation].every((v) => v.isFinite) ||
          x < 0 || y < 0 || x > 270 || y > 265 ||
          scale < 30 || scale > 250 ||
          rotation < -180 || rotation > 180) {
        continue;
      }
      custom[id] = {
        'x': x, 'y': y, 'size': scale, 'rotation': rotation,
      };
    }
    final defaultOutfit = {
      ...equipped,
      for (final entry in equipped.entries)
        if (custom.containsKey(entry.value) &&
            entry.key != 'skin' && entry.key != 'aura')
          entry.key: '',
    };
    return SizedBox(
      width: 280, height: 275,
      child: Stack(clipBehavior: Clip.none, children: [
        HealthyMascotOutfit(equipped: defaultOutfit),
        for (final entry in equipped.entries)
          if (custom.containsKey(entry.value) &&
              entry.key != 'skin' && entry.key != 'aura' &&
              shopItemById(entry.value) != null)
            Positioned(
              left: custom[entry.value]!['x']!,
              top: custom[entry.value]!['y']!,
              width: custom[entry.value]!['size']!,
              height: custom[entry.value]!['size']!,
              child: Transform.rotate(
                angle: custom[entry.value]!['rotation']! *
                    3.141592653589793 / 180,
                child: ShopItemArtwork(
                  item: shopItemById(entry.value)!,
                  size: custom[entry.value]!['size']!,
                ),
              ),
            ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty ||
        FirebaseAuth.instance.currentUser == null) {
      return Image.asset('assets/mascot/healthy.png',
        width: size, height: size, fit: BoxFit.contain);
    }
    return SizedBox(
    width: size,
    height: size,
    child: FittedBox(
      fit: BoxFit.contain,
      child: HealthyMascotIdle(
        child: StreamBuilder<ShopState>(
          stream: ShopService.instance.watch(),
        builder: (context, snapshot) =>
            FutureBuilder<Map<String, dynamic>>(
          future: _readLayouts(),
          builder: (context, preferences) =>
              _buildOutfit(snapshot.data, preferences.data ?? {}),
        ),
        ),
      ),
    ),
  );
  }
}
