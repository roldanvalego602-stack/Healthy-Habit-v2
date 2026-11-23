/// Recursos cosméticos nuevos. Los nombres coinciden exactamente con los archivos
/// subidos por el equipo a assets/cosmeticos (Linux distingue mayúsculas).
///
/// Solo se registran archivos presentes en el repositorio.
class HealthyCosmetics {
  HealthyCosmetics._();

  static const Map<String, String> artwork = {
    'cat_headphones_pink': 'assets/cosmeticos/mr_healthy/cabeza/Auriculares Rosas con Orejas de Gato.png',
    'chef_hat_green': 'assets/cosmeticos/mr_healthy/cabeza/Gorro de chef verde con laureles.png',
    'paper_sailor_hat': 'assets/cosmeticos/mr_healthy/cabeza/Sombrero marinero de papel con cinta negra.png',
    'green_gloves': 'assets/cosmeticos/mr_healthy/brazos_manos/Guantes Verdes con Emblemas de Hoja.png',
    'superhero_cape_red': 'assets/cosmeticos/mr_healthy/espalda/Capa roja de superhéroe con medallón dorado.png',
    'star_backpack_blue': 'assets/cosmeticos/mr_healthy/espalda/Mochila azul con estrella amarilla.png',
    'rock_face_mask': 'assets/cosmeticos/mr_healthy/rostro/Máscara de roca con ojos grandes y bandana negra.png',
    'space_helmet': 'assets/cosmeticos/mr_healthy/rostro/casco_espacial_healthy.png',
    'hero_mask_blue': 'assets/cosmeticos/mr_healthy/rostro/mascara_heroe_healthy.png',

    'frame_arcane': 'assets/cosmeticos/perfil/marcos/Marco Mágico de Anillo Violeta.png',
    'frame_emerald': 'assets/cosmeticos/perfil/marcos/Marco circular esmeralda con emblema de hojas.png',
    'frame_cyber': 'assets/cosmeticos/perfil/marcos/Marco de Perfil Cian Futurista.png',
    'frame_nature': 'assets/cosmeticos/perfil/marcos/Marco de perfil verde con gemas doradas.png',

    'banner_space': 'assets/cosmeticos/perfil/banners/Banner espacial.png',
    'banner_sunset': 'assets/cosmeticos/perfil/banners/banner atardecer.png',
    'banner_floral': 'assets/cosmeticos/perfil/banners/banner floral.png',
    'banner_ice': 'assets/cosmeticos/perfil/banners/banner hielo.png',

    'avatar_snowman': 'assets/cosmeticos/perfil/avatares_animados/Muñeco de nieve navideño animado geschniegelt.gif',
    'avatar_christmas': 'assets/cosmeticos/perfil/avatares_animados/avatar navidad.png',
    'avatar_gingerbread': 'assets/cosmeticos/perfil/avatares_animados/galleta.png',
    'avatar_gift': 'assets/cosmeticos/perfil/avatares_animados/regalo.png',

    'reaction_compas': 'assets/cosmeticos/social/reacciones/compas.png',
    'reaction_celebrate': 'assets/cosmeticos/social/reacciones/healthy celebrando.png',
    'reaction_love': 'assets/cosmeticos/social/reacciones/healthy love.png',
    'reaction_goal': 'assets/cosmeticos/social/reacciones/healthy meta.png',
    'reaction_support': 'assets/cosmeticos/social/reacciones/healthy perro.png',
    'reaction_like': 'assets/cosmeticos/social/reacciones/like healthy.png',
    'aviator_goggles_gold': 'assets/cosmeticos/mr_healthy/cabeza/Gafas de aviador de cuero dorado.png',
    'leaf_glow_hat': 'assets/cosmeticos/mr_healthy/cabeza/Hoja verde brillante con destellos amarillos.png',
    'leaf_crown': 'assets/cosmeticos/mr_healthy/cabeza/corona_hojas_healthy.png',
    'skin_christmas_cartoon': 'assets/cosmeticos/mr_healthy/skins/skin cartoon.png',
    'banner_gradient_yellow_pink': 'assets/cosmeticos/perfil/banners/Degradado_Amarillo-Rosa.png',
    'banner_gradient_blue_pink': 'assets/cosmeticos/perfil/banners/Degradado_Azul-Rosa.png',
    'banner_gradient_teal_yellow': 'assets/cosmeticos/perfil/banners/Degradado_Azulverdoso-Amarillo.png',
    'banner_gradient_gold_black': 'assets/cosmeticos/perfil/banners/Degradado_Dorado-Negro.png',
    'banner_gradient_purple_teal': 'assets/cosmeticos/perfil/banners/Degradado_Morad-Azulverdoso.png',
    'banner_gradient_pink_violet': 'assets/cosmeticos/perfil/banners/Degradado_Rosa-Violeta.png',
    'banner_gradient_turquoise_blue': 'assets/cosmeticos/perfil/banners/Degradado_Turqueza-Azul.png',
    'banner_gradient_black_blue': 'assets/cosmeticos/perfil/banners/Degradado_negro-Azul.png',
  };

  static const Map<String, String> reactionEmoji = {
    'reaction_compas': '💪',
    'reaction_celebrate': '🎉',
    'reaction_love': '❤️',
    'reaction_goal': '⭐',
    'reaction_support': '👏',
    'reaction_like': '🔥',
  };

  static String? assetFor(String id) => artwork[id];

  static String? equippedId(Map<String, dynamic> data, String slot,
      {bool publicProfile = false}) {
    final raw = data[publicProfile ? 'healthyEquipped' : 'shopEquipped'];
    if (raw is! Map) return null;
    final id = raw[slot];
    return id is String && artwork.containsKey(id) ? id : null;
  }

  static String? equippedAsset(Map<String, dynamic> data, String slot,
      {bool publicProfile = false}) {
    final id = equippedId(data, slot, publicProfile: publicProfile);
    return id == null ? null : artwork[id];
  }
}
