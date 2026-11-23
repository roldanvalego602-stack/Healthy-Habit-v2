import 'package:flutter/material.dart';

import 'shop_service.dart';
import 'shop_item_artwork.dart';

/// Representación compartida de Mr. Healthy: guardarropa y perfiles públicos.
/// No consulta Firestore ni permite comprar/equipar. Dibuja exclusivamente
/// las ranuras cosméticas reconocidas por el catálogo.
class HealthyMascotOutfit extends StatelessWidget {
  const HealthyMascotOutfit({
    super.key,
    required this.equipped,
  });

  final Map<String, String> equipped;

  Widget _accessory(String id, {
    required double left,
    required double top,
    required double size,
  }) {
    final item = shopItemById(id);
    if (item == null) return const SizedBox.shrink();
    return Positioned(
      left: left, top: top, width: size, height: size,
      child: IgnorePointer(child: ShopItemArtwork(item: item, size: size)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget accessory(String id, {
      required double left,
      required double top,
      required double size,
    }) => _accessory(id, left: left, top: top, size: size);

    return SizedBox(
      width: 280,
      height: 275,
      child: Stack(clipBehavior: Clip.none, children: [
                if (equipped['aura'] == 'mint_aura')
                  Positioned(
                    left: 30, top: 17,
                    child: Container(
                      width: 220, height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: const Color(0xFF198568).withValues(alpha: .5),
                          blurRadius: 44, spreadRadius: 8,
                        )],
                      ),
                    ),
                  ),
                // Objetos detrás del cuerpo.
                if (equipped['espalda'] == 'cape')
                  Positioned(
                    left: 47, top: 148,
                    child: Container(
                      width: 185, height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB94B58),
                        borderRadius: BorderRadius.circular(42),
                      ),
                    ),
                  ),
                if (equipped['espalda'] == 'leaf_backpack')
                  accessory('leaf_backpack', left: 165, top: 115, size: 85),
                if (equipped['espalda'] == 'superhero_cape_red')
                  accessory('superhero_cape_red',
                      left: 31, top: 132, size: 218),
                if (equipped['espalda'] == 'star_backpack_blue')
                  accessory('star_backpack_blue',
                      left: 165, top: 115, size: 90),

                Positioned(
                  left: 30, top: 7,
                  width: 220, height: 260,
                  child: Image.asset(
                    'assets/mascot/healthy.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.sentiment_satisfied,
                          size: 170, color: const Color(0xFF198568)),
                  ),
                ),

                // Vestimenta y objetos de frente. Los ojos de la mascota
                // están por encima del centro de la cara (no en la boca).
                if (equipped['torso'] == 'leaf_hoodie')
                  accessory('leaf_hoodie', left: 76, top: 151, size: 128),

                if (equipped['cabeza'] == 'cap')
                  accessory('cap', left: 77, top: 30, size: 125),
                if (equipped['cabeza'] == 'sports_headband')
                  accessory('sports_headband',
                    left: 78, top: 62, size: 122),
                if (equipped['cabeza'] == 'leaf_headphones')
                  accessory('leaf_headphones',
                    left: 61, top: 60, size: 154),
                if (equipped['cabeza'] == 'crown')
                  accessory('crown', left: 94, top: 35, size: 92),
                if (equipped['cabeza'] == 'cat_ears')
                  accessory('cat_ears', left: 85, top: 40, size: 110),
                if (equipped['cabeza'] == 'cat_headphones_pink')
                  accessory('cat_headphones_pink',
                      left: 55, top: 42, size: 174),
                if (equipped['cabeza'] == 'chef_hat_green')
                  accessory('chef_hat_green',
                      left: 73, top: 15, size: 145),
                if (equipped['cabeza'] == 'paper_sailor_hat')
                  accessory('paper_sailor_hat',
                      left: 64, top: 17, size: 160),
                if (equipped['cabeza'] == 'space_helmet')
                  accessory('space_helmet',
                      left: 62, top: 33, size: 159),

                if (equipped['ojos'] == 'sunglasses')
                  accessory('sunglasses', left: 91, top: 107, size: 100),
                if (equipped['ojos'] == 'pixel_glasses')
                  accessory('pixel_glasses',
                    left: 85, top: 107, size: 110),
                if (equipped['ojos'] == 'rock_face_mask')
                  accessory('rock_face_mask',
                      left: 64, top: 110, size: 154),
                if (equipped['ojos'] == 'hero_mask_blue')
                  accessory('hero_mask_blue',
                      left: 79, top: 114, size: 120),
                if (equipped['brazos'] == 'green_gloves')
                  accessory('green_gloves',
                      left: 28, top: 154, size: 225),

                if (equipped['cuello'] == 'wellness_medal')
                  accessory('wellness_medal',
                    left: 111, top: 177, size: 58),
                if (equipped['cuello'] == 'mint_scarf' ||
                    equipped['cuello'] == 'bandana')
                  Positioned(
                    left: 82, top: 192,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 4),
                      decoration: BoxDecoration(
                        color: equipped['cuello'] == 'mint_scarf'
                            ? const Color(0xFF198568) : const Color(0xFF1D7666),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('✦  ✦  ✦',
                        style: TextStyle(color: Colors.white)),
                    ),
                  ),
                if (equipped['mano'] == 'water_bottle')
                  accessory('water_bottle',
                    left: 202, top: 163, size: 61),
              ]),
    );
  }
}
