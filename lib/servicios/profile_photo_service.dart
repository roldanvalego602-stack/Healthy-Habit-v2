import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Foto de perfil de usuario. Firestore (users/{uid}.photoUrl) es la
/// fuente de verdad; Firebase Auth se sincroniza como dato secundario.
class ProfilePhotoService {
  ProfilePhotoService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(), databaseId: 'default');

  FirebaseStorage get _storage => FirebaseStorage.instanceFor(
        app: Firebase.app());

  Future<XFile?> pick(ImageSource source) => _picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 88,
        requestFullMetadata: false,
      );

  /// Rechaza imágenes dañadas y genera un JPEG pequeño que se puede subir
  /// mediante putData también desde Flutter web (sin dart:io).
  @visibleForTesting
  static Uint8List prepareJpeg(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > 12 * 1024 * 1024) {
      throw const ProfilePhotoException(
        'Selecciona una imagen de hasta 12 MB.');
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null || decoded.width < 32 || decoded.height < 32) {
      throw const ProfilePhotoException(
        'No se pudo leer la fotografía seleccionada.');
    }
    final oriented = img.bakeOrientation(decoded);
    final target = oriented.width > 1024 || oriented.height > 1024
        ? img.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? 1024 : null,
            height: oriented.height > oriented.width ? 1024 : null,
            interpolation: img.Interpolation.average,
          )
        : oriented;
    return Uint8List.fromList(img.encodeJpg(target, quality: 82));
  }

  /// La foto nunca se vincula a otra cuenta si cambia la sesión durante
  /// la subida. Se usa una ruta distinta para evitar cachés obsoletas.
  /// Quita la fotografía actual; mantiene el resto del perfil sin cambios.
  Future<void> remove() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ProfilePhotoException('Inicia sesión para editar tu foto.');
    }
    final doc = _db.collection('users').doc(user.uid);
    try {
      final current = await doc.get();
      final oldPath = current.data()?['profilePhotoPath']?.toString() ?? '';
      await doc.set({
        'photoUrl': '',
        'profilePhotoPath': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      try {
        await user.updatePhotoURL(null);
      } catch (_) {}
      if (oldPath.startsWith('users/${user.uid}/profile/')) {
        try {
          await _storage.ref().child(oldPath).delete();
        } catch (_) {}
      }
    } on FirebaseException catch (_) {
      throw const ProfilePhotoException(
        'No se pudo quitar la fotografía. Revisa la conexión y permisos.');
    }
  }

  /// Fases independientes para presentar un error útil sin exponer tokens.
  Future<String> upload(XFile selected) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ProfilePhotoException('Inicia sesión para subir una foto.',
          code: 'unauthenticated');
    }

    final bytes = prepareJpeg(await selected.readAsBytes());
    final userRef = _db.collection('users').doc(user.uid);
    var oldPath = '';
    try {
      final previous = await userRef.get();
      oldPath = previous.data()?['profilePhotoPath']?.toString() ?? '';
    } on FirebaseException catch (error) {
      throw explainFirebaseError(error, stage: 'lectura de Firestore');
    }

    final bucket = Firebase.app().options.storageBucket;
    if (bucket == null || bucket.isEmpty) {
      throw const ProfilePhotoException(
        'Firebase no tiene un bucket de Storage configurado. '
        'Actívalo en Firebase Console y actualiza firebase_options.dart.',
        code: 'no-default-bucket',
      );
    }
    final object = _storage.ref().child(
      'users/${user.uid}/profile/avatar_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    try {
      final completed = await object.putData(bytes, SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'private,max-age=3600',
      ));
      if (completed.state != TaskState.success) {
        throw const ProfilePhotoException(
          'La transferencia a Storage no se completó.',
          code: 'upload-incomplete',
        );
      }
    } on FirebaseException catch (error) {
      throw explainFirebaseError(error, stage: 'subida a Storage');
    } catch (_) {
      throw const ProfilePhotoException(
        'No se completó la subida a Storage. Comprueba la conexión.',
        code: 'upload-failed',
      );
    }

    if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
      try { await object.delete(); } catch (_) {}
      throw const ProfilePhotoException(
        'La sesión cambió durante la subida. Vuelve a intentarlo.',
        code: 'session-changed',
      );
    }

    late final String url;
    try {
      url = await object.getDownloadURL();
    } on FirebaseException catch (error) {
      throw explainFirebaseError(error, stage: 'obtención de la URL');
    }
    try {
      await userRef.set({
        'photoUrl': url,
        'profileAvatarStyle': 'foto',
        'profilePhotoPath': object.fullPath,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      try { await object.delete(); } catch (_) {}
      throw explainFirebaseError(error, stage: 'guardado en Firestore');
    }
    // El documento de Firestore es la referencia para toda la app.
    try { await user.updatePhotoURL(url); } catch (_) {}
    if (oldPath.isNotEmpty && oldPath != object.fullPath &&
        oldPath.startsWith('users/${user.uid}/profile/')) {
      try { await _storage.ref().child(oldPath).delete(); } catch (_) {}
    }
    return url;
  }

  @visibleForTesting
  static ProfilePhotoException explainFirebaseError(
    FirebaseException error, {required String stage}) {
    final code = error.code.toLowerCase();
    if (code == 'unauthorized' || code == 'permission-denied') {
      return ProfilePhotoException(
        'Firebase rechazó el permiso en $stage. '
        'Verifica las reglas de acceso y que Storage esté en el '
        'plan Blaze (no Spark). Código: ${error.code}.',
        code: code,
      );
    }
    if (code == 'object-not-found') {
      return ProfilePhotoException(
        'Storage respondió que el objeto no existe durante $stage. '
        'Si sucede al subir una foto nueva, verifica en Firebase Console '
        'que el bucket esté creado y activo y que el proyecto tenga '
        'facturación Blaze; revisa además la ruta y las reglas '
        'users/{uid}/profile/. Bucket configurado: '
        '${Firebase.app().options.storageBucket ?? "sin configurar"}.',
        code: code,
      );
    }
    if (code == 'bucket-not-found' || code == 'invalid-default-bucket' ||
        code == 'no-default-bucket') {
      return ProfilePhotoException(
        'No se encontró el bucket de Firebase Storage. '
        'Comprueba su creación, nombre y plan Blaze en Firebase Console. '
        'Código: ${error.code}.',
        code: code,
      );
    }
    if (code == 'quota-exceeded') {
      return ProfilePhotoException(
        'Se alcanzó el límite de Firebase Storage. '
        'Revisa la cuota y la facturación del proyecto.',
        code: code,
      );
    }
    if (code == 'unauthenticated') {
      return ProfilePhotoException(
        'La sesión de Firebase caducó. Vuelve a iniciar sesión.',
        code: code,
      );
    }
    return ProfilePhotoException(
      'Error en $stage (Firebase: ${error.code}). '
      'Revisa Storage, las reglas y tu conexión.',
      code: code,
    );
  }

}

class ProfilePhotoException implements Exception {
  const ProfilePhotoException(this.message, {this.code = 'unknown'});
  final String message;
  final String code;

  @override
  String toString() => message;
}
