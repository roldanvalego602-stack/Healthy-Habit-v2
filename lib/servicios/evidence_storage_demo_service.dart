import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'shop_demo_bootstrap.dart';
import 'official_habit_emulator_service.dart';

/// Subida privada de evidencias SOLO en el Storage Emulator del proyecto demo.
///
/// No confirma hábitos, no asigna XP ni genera URL pública. La subida todavía
/// no está conectada al formulario de registro: faltan asociación transaccional
/// con el log oficial y limpieza administrativa independiente del cliente.
class EvidenceStorageDemoService {
  const EvidenceStorageDemoService();

  static const maxBytes = 250 * 1024;
  static const _idPattern = r'^[A-Za-z0-9_-]{16,128}$';

  String _uid() {
    ShopDemoBootstrap.validateOfficialHabitsMode();
    ShopDemoBootstrap.validateHost(ShopDemoBootstrap.host);
    if (!ShopDemoBootstrap.officialHabitsEnabled ||
        Firebase.app().options.projectId != ShopDemoBootstrap.demoProjectId) {
      throw StateError('Evidencias disponibles solo en demo-healthy-habit.');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Inicia sesión en Auth Emulator antes de subir.');
    }
    return uid;
  }

  String _contentType(Uint8List bytes) {
    if (bytes.lengthInBytes < 4 || bytes.lengthInBytes > maxBytes) {
      throw ArgumentError('La fotografía debe medir entre 4 B y 250 KB.');
    }
    if (bytes[0] == 0xff && bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.lengthInBytes >= 8 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4e && bytes[3] == 0x47 &&
        bytes[4] == 0x0d && bytes[5] == 0x0a &&
        bytes[6] == 0x1a && bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.lengthInBytes >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    throw ArgumentError('Se admiten exclusivamente imágenes JPEG, PNG o WebP.');
  }

  String _path(String uid, String attemptId, String evidenceId) {
    final rule = RegExp(_idPattern);
    if (!rule.hasMatch(attemptId) || !rule.hasMatch(evidenceId)) {
      throw ArgumentError('Identificadores de evidencia inválidos.');
    }
    return 'habit-evidence/$uid/$attemptId/$evidenceId';
  }

  /// Devuelve una ruta privada, nunca un token ni una URL de descarga.
  /// El servidor administra el borrado; los clientes no eliminan objetos.
  Future<String> upload({
    required String habitId,
    required String attemptId,
    required String evidenceId,
    required Uint8List bytes,
  }) async {
    final uid = _uid();
    final type = _contentType(bytes);
    final path = _path(uid, attemptId, evidenceId);
    // La reserva del servidor no sustituye las reglas de Storage; ambas
    // comprobaciones son necesarias y no conceden recompensas.
    final reservation = await const OfficialHabitEmulatorService()
        .reserveEvidence(
          habitId: habitId,
          attemptId: attemptId,
          operationId: evidenceId,
        );
    if (reservation['storagePath'] != path) {
      throw StateError('La ruta reservada no coincide con el archivo.');
    }
    final expiresAt = DateTime.tryParse(
      reservation['expiresAt']?.toString() ?? '',
    );
    if (expiresAt == null || !expiresAt.isAfter(DateTime.now().toUtc())) {
      throw StateError('La reserva de evidencia ya expiró.');
    }
    if (_uid() != uid) {
      throw StateError('La sesión cambió antes de subir la imagen.');
    }
    final response = await const OfficialHabitEmulatorService()
        .uploadReservedEvidence(
          habitId: habitId,
          attemptId: attemptId,
          operationId: evidenceId,
          bytes: bytes,
          contentType: type,
        );
    if (response['storagePath'] != path) {
      throw StateError('El archivo no coincide con la reserva autorizada.');
    }
    if (_uid() != uid) {
      throw StateError('La sesión cambió durante la subida.');
    }
    return path;
  }

  Future<void> delete({
    required String attemptId,
    required String evidenceId,
  }) async {
    _uid();
    _path(_uid(), attemptId, evidenceId);
    throw UnsupportedError(
      'El borrado del cliente está deshabilitado. '
      'La limpieza de evidencias corresponde al servidor.');
  }
}
