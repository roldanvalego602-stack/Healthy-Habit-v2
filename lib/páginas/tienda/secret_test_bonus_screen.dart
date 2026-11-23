import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../servicios/shop_demo_bootstrap.dart';
import '../../tema/healthy_theme.dart';
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

  Future<void> _claim() async {
    if (_loading || !isDemoEnabled) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw StateError('Inicia sesión en el emulador para reclamar.');
      }
      final host = DemoShopPurchaseGateway.emulatorHost;
      ShopDemoBootstrap.validateHost(host);
      if (host != ShopDemoBootstrap.host ||
          DemoShopPurchaseGateway.emulatorPort != 5001) {
        throw StateError('La conexión de prueba no coincide con el emulador.');
      }
      final functions = FirebaseFunctions.instanceFor(
        app: Firebase.app(), region: 'us-central1',
      );
      functions.useFunctionsEmulator(host, 5001);
      final response = await functions
          .httpsCallable('claimSecretTestBonus')
          .call<Map<String, dynamic>>({});
      if (!mounted) return;
      final result = response.data;
      setState(() {
        _message = result['awarded'] == true
            ? '¡Recibiste 1,000 Habit Coins de prueba!'
            : 'Ya reclamaste esta recompensa de prueba.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _message =
          'No se pudo entregar el premio. Comprueba que los emuladores de '
          'Auth, Firestore y Functions estén encendidos.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = isDemoEnabled;
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
              Text(enabled
                  ? 'Recompensa única de 1,000 Habit Coins para pruebas '
                    'en Firebase Emulator.'
                  : 'Esta página es un secreto visual. Para proteger '
                    'las monedas reales, la recompensa solo funciona '
                    'en el proyecto de prueba con Firebase Emulator.',
                textAlign: TextAlign.center,
                style: TextStyle(color: HealthyAdaptive.muted)),
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const Key('secreto-reclamar-monedas'),
                onPressed: enabled && !_loading ? _claim : null,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.toll_rounded),
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
