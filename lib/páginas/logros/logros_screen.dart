import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'logros_service.dart';

class LogrosScreen extends StatelessWidget {
  const LogrosScreen({super.key});
  static const _green = Color(0xFF08B889);
  static const _navy = Color(0xFF193344);
  static const _bg = Color(0xFFF5F8F6);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para consultar tus logros.')),
      );
    }
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    final userRef = db.collection('users').doc(user.uid);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Logros y desafíos',
          style: TextStyle(fontWeight: FontWeight.w800, color: _navy),
        ),
        backgroundColor: _bg,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: _green,
              indicatorColor: _green,
              tabs: [Tab(text: 'Logros'), Tab(text: 'Desafíos')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream:
                        userRef
                            .collection('achievements')
                            .doc(LogrosService.primerPasoId)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Center(
                          child: Text('No se pudieron cargar los logros.'),
                        );
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final unlocked = snapshot.data!.exists;
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tu colección',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _navy,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  unlocked
                                      ? '1 de 1 logros desbloqueados'
                                      : '0 de 1 logros desbloqueados',
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: unlocked ? 1 : 0,
                                  color: _green,
                                  minHeight: 7,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color: Colors.white,
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor:
                                        unlocked
                                            ? const Color(0xFFD9F8E9)
                                            : const Color(0xFFE9EEF0),
                                    child: Icon(
                                      unlocked
                                          ? Icons.workspace_premium
                                          : Icons.lock_outline,
                                      size: 30,
                                      color: unlocked ? _green : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Primer paso',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: _navy,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          unlocked
                                              ? '¡Desbloqueado!'
                                              : 'Registra tu primer hábito',
                                          style: TextStyle(
                                            color:
                                                unlocked
                                                    ? _green
                                                    : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          '+25 XP · +10 Habit Coins · Medalla',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Los desafíos se incorporarán más adelante.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
