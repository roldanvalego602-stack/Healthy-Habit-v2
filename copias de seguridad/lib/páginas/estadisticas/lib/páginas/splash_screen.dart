import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'inicio.dart';
import 'sesion/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    // Mantiene visible la identidad de la app antes de navegar.
    await Future<void>.delayed(const Duration(milliseconds: 3300));
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;
      } on FirebaseAuthException catch (e) {
        // Sesión revocada, cuenta eliminada o deshabilitada.
        if (e.code == 'user-not-found' ||
            e.code == 'user-disabled' ||
            e.code == 'user-token-expired' ||
            e.code == 'invalid-user-token') {
          await FirebaseAuth.instance.signOut();
          user = null;
        } else {
          // Si no hay conexión, conserva la sesión local existente.
          user = FirebaseAuth.instance.currentUser;
        }
      } catch (_) {
        user = FirebaseAuth.instance.currentUser;
      }
    }
    if (!mounted) return;

    final verified =
        user != null &&
        (user.emailVerified ||
            user.providerData.any((p) => p.providerId == 'google.com'));

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => verified ? const HomeScreen2() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.13, -0.05),
            radius: 1.08,
            colors: [Color(0xFF1D3947), Color(0xFF102633), Color(0xFF071722)],
            stops: [0.0, 0.54, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo/logo.png',
                        width: 152,
                        height: 152,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.eco_rounded,
                              color: Color(0xFFB4ED63),
                              size: 120,
                            ),
                      ),
                      const SizedBox(height: 35),
                      const Text(
                        'Healthy Habit',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Construye hábitos. Desbloquea tu progreso.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFADC0C9),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
