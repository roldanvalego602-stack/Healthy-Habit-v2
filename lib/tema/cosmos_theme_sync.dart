import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'cosmos_theme.dart';
import 'healthy_theme.dart';

/// Sincroniza la autorización del tema con el inventario real de la cuenta.
/// Nunca habilita Cosmos desde preferencias locales ni por un ID comprado
/// de otro usuario. Los cambios en Firestore actualizan la aplicación.
class CosmosThemeSync extends StatefulWidget {
  const CosmosThemeSync({super.key, required this.child});
  final Widget child;
  @override
  State<CosmosThemeSync> createState() => _CosmosThemeSyncState();
}

class _CosmosThemeSyncState extends State<CosmosThemeSync> {
  StreamSubscription<User?>? _auth;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _user;
  String? _listeningUid;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance.authStateChanges().listen(_watchUser);
    _watchUser(FirebaseAuth.instance.currentUser);
  }

  void _watchUser(User? user) {
    if (user?.uid == _listeningUid) return;
    _user?.cancel();
    _user = null;
    _listeningUid = user?.uid;
    HealthyThemeController.instance.syncCosmos(owned: false, equipped: false);
    if (user == null) return;
    final uid = user.uid;
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default');
    _user = db.collection('users').doc(uid).snapshots().listen(
      (doc) {
        if (!mounted || _listeningUid != uid) return;
        final data = doc.data() ?? <String, dynamic>{};
        final items = data['shopInventory'];
        final rawEquipped = data['shopEquipped'];
        final owned = items is List && items.contains(cosmosShopId);
        final equipped = rawEquipped is Map &&
            rawEquipped[cosmosSlot] == cosmosShopId;
        HealthyThemeController.instance.syncCosmos(
          owned: owned, equipped: equipped);
      },
      onError: (Object _) {
        if (_listeningUid == uid) {
          HealthyThemeController.instance.syncCosmos(
            owned: false, equipped: false);
        }
      },
    );
  }

  @override
  void dispose() {
    _auth?.cancel();
    _user?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// La escena vive detrás de todas las rutas de MaterialApp y usa un
/// solo motor de pintura incluso al navegar por pantallas secundarias.
class CosmosAppScene extends StatelessWidget {
  const CosmosAppScene({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (!HealthyAdaptive.isCosmos) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        const IgnorePointer(child: CosmosBackground()),
        child,
      ],
    );
  }
}
