import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../servicios/beta_habit_gateway.dart';

/// Diario exclusivo de compras de beta cerrada, independiente del demo.
class BetaShopPurchaseGateway {
  const BetaShopPurchaseGateway();

  static const _prefix = 'hh_beta_shop_pending_v1_';
  static final _inFlight = <String>{};
  static final _itemPattern = RegExp(r'^[a-z][a-z0-9_]{0,127}$');
  static final _idPattern = RegExp(r'^[A-Za-z0-9_-]{16,128}$');

  static String pendingKey(String uid, String itemId) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(uid) ||
        !_itemPattern.hasMatch(itemId)) {
      throw ArgumentError('Identificadores de compra inválidos.');
    }
    return '$_prefix${uid}_$itemId';
  }

  String _uid() {
    if (!BetaHabitGateway.enabled ||
        Firebase.app().options.projectId != BetaHabitGateway.projectId) {
      throw StateError('Las compras de beta no están habilitadas.');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Inicia sesión antes de comprar.');
    }
    return uid;
  }

  static String _newOperationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return 'purchase_$hex';
  }

  static Map<String, String> _decode(
      String raw, String uid, String itemId) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.length != 3 ||
        decoded['uid'] != uid || decoded['itemId'] != itemId ||
        decoded['operationId'] is! String ||
        !_idPattern.hasMatch(decoded['operationId'] as String)) {
      throw StateError('Compra pendiente dañada: no se enviará.');
    }
    return {'itemId': itemId,
      'operationId': decoded['operationId'] as String};
  }

  /// Lista operaciones locales sin contactar al backend ni procesar compras.
  Future<List<String>> listarPendientes() async {
    final uid = _uid();
    final prefs = SharedPreferencesAsync();
    final prefix = '$_prefix${uid}_';
    final keys = await prefs.getKeys();
    final items = <String>[];
    for (final key in keys.where((key) => key.startsWith(prefix))) {
      final raw = await prefs.getString(key);
      if (raw == null) continue;
      final itemId = key.substring(prefix.length);
      try {
        _decode(raw, uid, itemId);
      } catch (_) {
        throw StateError('Hay compras pendientes dañadas; no se reenvían.');
      }
      items.add(itemId);
    }
    if (_uid() != uid) {
      throw StateError('La sesión cambió mientras se consultaban las compras.');
    }
    items.sort();
    return items;
  }

  /// Recuperación explícita: el reintento siempre conserva su operationId.
  Future<Map<String, dynamic>> comprar(String itemId, {
    bool soloRecuperar = false,
  }) async {
    final uid = _uid();
    final key = pendingKey(uid, itemId);
    if (!_inFlight.add(key)) {
      throw StateError('Esta compra ya está en proceso.');
    }
    try {
      final prefs = SharedPreferencesAsync();
      final stored = await prefs.getString(key);
      late final Map<String, String> payload;
      if (stored == null) {
        if (soloRecuperar) {
          throw StateError('La compra pendiente ya no existe.');
        }
        final operationId = _newOperationId();
        payload = {'itemId': itemId, 'operationId': operationId};
        // No enviar si no se pudo guardar el identificador original.
        await prefs.setString(key, jsonEncode({
          'uid': uid, ...payload,
        }));
      } else {
        try {
          payload = _decode(stored, uid, itemId);
        } catch (_) {
          throw StateError('Compra pendiente dañada; no se enviará otra.');
        }
      }
      if (_uid() != uid) {
        throw StateError('La sesión cambió; se conserva la compra pendiente.');
      }
      final response = await FirebaseFunctions.instanceFor(
        app: Firebase.app(), region: 'us-central1',
      ).httpsCallable('purchaseOfficialShopBeta').call<Map<String, dynamic>>(
        payload,
      );
      if (_uid() != uid) {
        throw StateError('La sesión cambió; se conserva la compra pendiente.');
      }
      final data = Map<String, dynamic>.from(response.data);
      if (data['itemId'] != itemId ||
          data['price'] is! int || (data['price'] as int) <= 0 ||
          data['balanceAfter'] is! int ||
          (data['balanceAfter'] as int) < 0) {
        throw StateError('Respuesta de compra inválida; conserva el reintento.');
      }
      await prefs.remove(key);
      return data;
    } finally {
      _inFlight.remove(key);
    }
  }
}
