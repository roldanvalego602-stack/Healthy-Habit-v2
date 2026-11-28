import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/healthy_public_profile_service.dart';

void main() {
  group('Proyección segura de perfil público', () {
    test('utiliza el título personalizado y datos públicos permitidos', () {
      final result = HealthyPublicProfileService.project({
        'name': 'Ana',
        'username': 'ana',
        'title': 'Título antiguo',
        'profileTitle': 'Explorador del bienestar',
        'bio': 'Me gusta cuidar mi salud.',
        'level': 3,
        'xp': 250,
        'currentStreak': 4,
        'settings': {'mostrarRachaAmigos': true, 'visibilidadLogros': 'Todos'},
      });
      expect(result['title'], 'Explorador del bienestar');
      expect(result['name'], 'Ana');
      expect(result['level'], 3);
      expect(result['currentStreak'], 4);
      expect(result['settings']['visibilidadLogros'], 'Todos');
    });

    test('oculta la racha cuando el usuario desactiva compartirla', () {
      final result = HealthyPublicProfileService.project({
        'currentStreak': 17,
        'streakDays': 17,
        'settings': {'mostrarRachaAmigos': false},
      });
      expect(result['currentStreak'], 0);
      expect(result['streakDays'], 0);
      expect(result['settings']['mostrarRachaAmigos'], false);
    });

    test('nunca copia correo, monedas, inventario ni preferencias privadas', () {
      final result = HealthyPublicProfileService.project({
        'name': 'Ana',
        'email': 'privado@example.test',
        'habitCoins': 999,
        'shopInventory': ['crown'],
        'claimedLevelRewards': [2, 3],
        'profilePhotoPath': 'users/ana/profile/private.jpg',
        'settings': {
          'visibilidadLogros': 'Solo yo',
          'analizarHistorialIA': true,
          'modoDiscreto': true,
        },
      });
      for (final key in [
        'email', 'habitCoins', 'shopInventory',
        'claimedLevelRewards', 'profilePhotoPath',
      ]) {
        expect(result.containsKey(key), false, reason: key);
      }
      expect(result['settings']['visibilidadLogros'], 'Solo yo');
      expect(result['settings'].containsKey('analizarHistorialIA'), false);
      expect(result['settings'].containsKey('modoDiscreto'), false);
    });

    test('solo publica identificadores de avatar predeterminado permitidos', () {
      final valid = HealthyPublicProfileService.project({
        'profileAvatarStyle': 'naturaleza',
        'photoUrl': 'https://example.test/foto-anterior.jpg',
      });
      expect(valid['profileAvatarStyle'], 'naturaleza');
      expect(valid['photoUrl'], isEmpty);
      final invalid = HealthyPublicProfileService.project({
        'profileAvatarStyle': 'archivo://privado',
      });
      expect(invalid['profileAvatarStyle'], 'foto');
    });

    test('el nuevo usuario empieza como Semilla saludable', () {
      final result = HealthyPublicProfileService.project({
        'level': 1, 'xp': 0,
      });
      expect(result['title'], 'Semilla saludable');
    });

    test('mantiene compatibilidad con títulos guardados anteriormente', () {
      final result = HealthyPublicProfileService.project({
        'title': 'Cultivador de constancia',
      });
      expect(result['title'], 'Cultivador de constancia');
    });
  });
}
