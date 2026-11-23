import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/healthy_public_profile_service.dart';

void main() {
  test('public profile does not include credentials or private settings', () {
    final public = HealthyPublicProfileService.project({
      'name': 'Andrea',
      'username': 'andrea',
      'xp': 150,
      'email': 'andrea@example.test',
      'habitCoins': 900,
      'settings': {
        'analizarHistorialIA': true,
        'mostrarRachaAmigos': false,
        'visibilidadLogros': 'Solo yo',
        'permitirRecordatorios': true,
      },
      'currentStreak': 22,
      'streakDays': 22,
      'nextAchievementTitle': 'Logro privado',
      'nextAchievementProgress': 0.9,
      'imageBase64': 'secret',
    });

    expect(public['name'], 'Andrea');
    expect(public['xp'], 150);
    expect(public.containsKey('email'), isFalse);
    expect(public.containsKey('habitCoins'), isFalse);
    expect(public.containsKey('imageBase64'), isFalse);
    expect(public['currentStreak'], 0);
    expect(public['streakDays'], 0);
    expect(public['nextAchievementTitle'], '');
    expect(public['nextAchievementProgress'], 0);
    expect(public['settings'], {
      'mostrarRachaAmigos': false,
      'visibilidadLogros': 'Solo yo',
    });
  });

  test('public profile shares only equipped mascot items', () {
    final profile = HealthyPublicProfileService.project({
      'name': 'Mariana',
      'xp': 42,
      'habitCoins': 700,
      'shopInventory': ['crown', 'banner', 'water_bottle'],
      'shopEquipped': {
        'cabeza': 'crown',
        'mano': 'water_bottle',
        'perfil_banner': 'banner',
        'untrusted_key': 'private',
      },
    });
    expect(profile['healthyEquipped'], {
      'cabeza': 'crown',
      'mano': 'water_bottle',
      'perfil_banner': 'banner',
    });
    expect(profile.containsKey('shopInventory'), isFalse);
    expect(profile.containsKey('shopEquipped'), isFalse);
    expect(profile.containsKey('habitCoins'), isFalse);
  });

  test('profile cosmetics and gloves are publicly projected without wallet', () {
    final result = HealthyPublicProfileService.project({
      'name': 'Eva',
      'shopInventory': ['frame_arcane', 'banner_space', 'avatar_snowman'],
      'habitCoins': 50,
      'shopEquipped': {
        'perfil_marco': 'frame_arcane',
        'perfil_banner': 'banner_space',
        'perfil_avatar': 'avatar_snowman',
        'brazos': 'green_gloves',
        'perfil_password': 'no',
      },
    });
    expect(result['healthyEquipped'], {
      'perfil_marco': 'frame_arcane',
      'perfil_banner': 'banner_space',
      'perfil_avatar': 'avatar_snowman',
      'brazos': 'green_gloves',
    });
    expect(result.containsKey('shopInventory'), isFalse);
    expect(result.containsKey('habitCoins'), isFalse);
  });

  test('a collectible avatar hides the previous public photo URL', () {
    final result = HealthyPublicProfileService.project({
      'name': 'Maya',
      'photoUrl': 'https://example.test/private-old-photo.jpg',
      'profileAvatarStyle': 'foto',
      'shopEquipped': {'perfil_avatar': 'avatar_snowman'},
    });
    expect(result['photoUrl'], isEmpty);
    expect((result['healthyEquipped'] as Map)['perfil_avatar'],
        'avatar_snowman');
  });

  test('la skin se comparte sin revelar inventario o monedas', () {
    final projection = HealthyPublicProfileService.project({
      'name': 'Lia',
      'habitCoins': 400,
      'shopInventory': ['skin_christmas_cartoon'],
      'shopEquipped': {'skin': 'skin_christmas_cartoon'},
    });
    expect((projection['healthyEquipped'] as Map)['skin'],
        'skin_christmas_cartoon');
    expect(projection.containsKey('shopInventory'), isFalse);
    expect(projection.containsKey('habitCoins'), isFalse);
  });

  test('public profile without purchases shows default mascot', () {
    final profile = HealthyPublicProfileService.project({
      'name': 'Alex',
      'xp': 0,
    });
    expect(profile['healthyEquipped'], isEmpty);
  });

  test('public streak is available only when opted in', () {
    final public = HealthyPublicProfileService.project({
      'name': 'Bruno',
      'currentStreak': 12,
      'streakDays': 12,
      'settings': {'mostrarRachaAmigos': true},
    });
    expect(public['currentStreak'], 12);
    expect(public['streakDays'], 12);
  });
}
