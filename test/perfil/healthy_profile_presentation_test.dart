import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/healthy_profile_presentation.dart';
import 'package:healthy_habit/páginas/perfil/profile_avatar.dart';

void main() {
  test('Inicio utiliza el avatar comprado en lugar de la foto antigua', () {
    final account = <String, dynamic>{
      'photoUrl': 'https://example.com/old.jpg',
      'profileAvatarStyle': 'foto',
      'shopEquipped': {'perfil_avatar': 'avatar_snowman'},
    };
    expect(HealthyProfilePresentation.avatarPreset(account), 'avatar_snowman');
    expect(HealthyProfilePresentation.photoUrl(account), isNull);
  });

  test('Ranking usa el avatar del perfil publicado', () {
    final profile = <String, dynamic>{
      'photoUrl': '',
      'profileAvatarStyle': 'foto',
      'healthyEquipped': {'perfil_avatar': 'avatar_snowman'},
    };
    expect(HealthyProfilePresentation.avatarPreset(
      profile, publicProfile: true), 'avatar_snowman');
    expect(HealthyProfilePresentation.photoUrl(
      profile, publicProfile: true), isNull);
  });

  test('avatar no reconocido no puede suplantar otros recursos', () {
    final data = <String, dynamic>{
      'profileAvatarStyle': 'naturaleza',
      'healthyEquipped': {'perfil_avatar': 'banner_space'},
    };
    expect(HealthyProfilePresentation.avatarPreset(
      data, publicProfile: true), 'naturaleza');
  });

  testWidgets('el avatar animado usa el recurso GIF existente', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HealthyProfileAvatar(
        photoUrl: null, preset: 'avatar_snowman', size: 44)),
    ));
    final widget = tester.widget<Image>(find.byType(Image));
    expect((widget.image as AssetImage).assetName,
      'assets/cosmeticos/perfil/avatares_animados/'
      'Muñeco de nieve navideño animado geschniegelt.gif');
  });
}
