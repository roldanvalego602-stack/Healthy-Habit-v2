import 'healthy_cosmetics.dart';

/// Resuelve la identidad visual de un perfil sin consultar datos privados.
///
/// Los perfiles públicos usan healthyEquipped; la cuenta propia usa
/// shopEquipped. Solo se aceptan artículos catalogados para perfil_avatar.
class HealthyProfilePresentation {
  HealthyProfilePresentation._();

  static String avatarPreset(Map<String, dynamic> data,
      {bool publicProfile = false}) {
    final equipped = data[publicProfile ? 'healthyEquipped' : 'shopEquipped'];
    if (equipped is Map) {
      final id = equipped['perfil_avatar'];
      if (id is String && _allowedAvatar(id)) return id;
    }
    final preset = data['profileAvatarStyle'];
    if (preset is String && const {
      'foto', 'naturaleza', 'agua', 'energia',
    }.contains(preset)) {
      return preset;
    }
    return 'foto';
  }

  static bool _allowedAvatar(String id) =>
      const {
        'avatar_snowman',
        'avatar_christmas',
        'avatar_gingerbread',
        'avatar_gift',
      }.contains(id) && HealthyCosmetics.assetFor(id) != null;

  static String? photoUrl(Map<String, dynamic> data,
      {bool publicProfile = false}) {
    if (avatarPreset(data, publicProfile: publicProfile) != 'foto') {
      return null;
    }
    final url = data['photoUrl'];
    return url is String && (url.startsWith('https://') ||
        url.startsWith('http://')) ? url : null;
  }

  static String? frameAsset(Map<String, dynamic> data,
      {bool publicProfile = false}) {
    final equipped = data[publicProfile ? 'healthyEquipped' : 'shopEquipped'];
    if (equipped is! Map) return null;
    final id = equipped['perfil_marco'];
    return id is String && id.startsWith('frame_')
        ? HealthyCosmetics.assetFor(id) : null;
  }
}
