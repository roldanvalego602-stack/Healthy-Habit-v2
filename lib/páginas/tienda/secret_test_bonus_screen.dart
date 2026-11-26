import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../servicios/shop_demo_bootstrap.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_coin.dart';
import 'shop_purchase_gateway.dart';

/// Página oculta de pruebas: las monedas son reales SOLO en la base
/// de datos del emulador demo. Nunca escribe el saldo desde Flutter.
class SecretTestBonusScreen extends StatefulWidget {
  const SecretTestBonusScreen({super.key});

  @override
  State<SecretTestBonusScreen> createState() => _SecretTestBonusScreenState();
}

class _SecretTestBonusScreenState extends State<SecretTestBonusScreen> {
  bool _loading = false;
  String? _message;

  static bool get isDemoEnabled =>
      kDebugMode &&
      Firebase.app().options.projectId == DemoShopPurchaseGateway.demoProjectId &&
      DemoShopPurchaseGateway.requested &&
      ShopDemoBootstrap.enabled;

  // La ruta normal no concede monedas desde Flutter: utiliza el callable
  // administrativo ya existente, que comprueba el claim admin en servidor.
  // Disponible solo en compilaciones de depuración.
  static bool get isAdminTestEnabled =>
      kDebugMode && !ShopDemoBootstrap.enabled;

  Future<void> _claim() async {
    if (_loading || (!isDemoEnabled && !isAdminTestEnabled)) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Inicia sesión para reclamar.');
      }
      final functions = FirebaseFunctions.instanceFor(
        app: Firebase.app(), region: 'us-central1',
      );
      if (isDemoEnabled) {
        final host = DemoShopPurchaseGateway.emulatorHost;
        ShopDemoBootstrap.validateHost(host);
        if (host != ShopDemoBootstrap.host ||
            DemoShopPurchaseGateway.emulatorPort != 5001) {
          throw StateError('La conexión de prueba no coincide con el emulador.');
        }
        functions.useFunctionsEmulator(host, 5001);
        final response = await functions
            .httpsCallable('claimSecretTestBonus')
            .call<Map<String, dynamic>>({});
        if (!mounted) return;
        setState(() {
          _message = response.data['awarded'] == true
              ? '¡Recibiste 1,000 Habit Coins de prueba!'
              : 'Ya reclamaste esta recompensa de prueba.';
        });
      } else {
        // El ID es estable por cuenta: aunque el usuario toque otra vez,
        // el servidor procesa este regalo como máximo una vez.
        final operationId = 'test_bonus_1000_v1_${user.uid}';
        final response = await functions
            .httpsCallable('adjustHabitCoins')
            .call<Map<String, dynamic>>({
          'userId': user.uid,
          'operation': 'grant',
          'amount': 1000,
          'reason': 'Bonificación única de pruebas de la tienda Healthy Habit',
          'operationId': operationId,
        });
        if (!mounted) return;
        setState(() {
          _message = response.data['success'] == true
              ? response.data['alreadyProcessed'] == true
                  ? 'Ya reclamaste esta recompensa de prueba.'
                  : '¡Recibiste 1,000 Habit Coins de prueba!'
              : 'El servidor no confirmó la recompensa.';
        });
      }
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.code == 'permission-denied'
            ? 'Tu cuenta necesita permisos de administrador para recibir '
                'monedas reales de prueba.'
            : 'No se pudo entregar la recompensa: ${error.message ?? error.code}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _message =
          'No se pudo entregar la recompensa. Comprueba la sesión '
          'y la disponibilidad de Cloud Functions.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = isDemoEnabled || isAdminTestEnabled;
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(title: const Text('Sala secreta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 78,
                color: HealthyAdaptive.accent),
              const SizedBox(height: 18),
              Text('¡Encontraste el secreto!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                  color: HealthyAdaptive.text)),
              const SizedBox(height: 12),
              Text(isDemoEnabled
                  ? 'Recompensa única de 1,000 Habit Coins para pruebas '
                    'en Firebase Emulator.'
                  : isAdminTestEnabled
                      ? 'Obtén 1,000 Habit Coins para probar la tienda. '
                        'Esta operación requiere una cuenta autorizada '
                        'como administradora y solo se ejecuta una vez.'
                      : 'Recompensa de desarrollo desactivada '
                        'en esta compilación.',
                textAlign: TextAlign.center,
                style: TextStyle(color: HealthyAdaptive.muted)),
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const Key('secreto-reclamar-monedas'),
                onPressed: enabled && !_loading ? _claim : null,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const HealthyCoinIcon(size: 20),
                label: const Text('Reclamar 1,000 monedas'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 15),
                Text(_message!, textAlign: TextAlign.center,
                  style: TextStyle(color: HealthyAdaptive.accent,
                    fontWeight: FontWeight.w800)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
