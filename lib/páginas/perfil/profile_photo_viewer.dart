import 'package:flutter/material.dart';

import '../../tema/healthy_asset_catalog.dart';
import 'profile_avatar.dart';

/// Acciones rápidas para la foto actual, desde Perfil y Editar perfil.
Future<void> showProfilePhotoActions(
  BuildContext context, {
  required String? photoUrl,
  required String preset,
  required VoidCallback onEdit,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Fotografía de perfil')),
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text('Ver en pantalla completa'),
            onTap: () => Navigator.pop(sheetContext, 'view'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar fotografía o avatar'),
            onTap: () => Navigator.pop(sheetContext, 'edit'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (action == 'edit') onEdit();
  if (action == 'view') {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ProfilePhotoFullScreen(
        photoUrl: photoUrl,
        preset: preset,
      ),
    ));
  }
}

/// Visor con zoom para imágenes remotas y avatares locales.
class ProfilePhotoFullScreen extends StatelessWidget {
  const ProfilePhotoFullScreen({
    super.key,
    required this.photoUrl,
    required this.preset,
  });

  final String? photoUrl;
  final String preset;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';
    final asset = HealthyAssetCatalog.avatars[preset];
    final validPhoto = preset == 'foto' && url.startsWith('https://');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Foto de perfil'),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: asset != null
                ? Image.asset(asset, fit: BoxFit.contain)
                : validPhoto
                    ? Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image_outlined,
                                size: 96, color: Colors.white70),
                      )
                    : HealthyProfileAvatar(
                        photoUrl: null,
                        preset: preset,
                        size: 240,
                      ),
          ),
        ),
      ),
    );
  }
}
