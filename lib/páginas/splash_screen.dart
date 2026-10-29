import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthy_habit/p%C3%A1ginas/inicio.dart';

import '/páginas/sesion/login_screen.dart';
import '/main.dart' show HomeScreen2;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacidad = 0.0;
  double _escala = 0.8;

  @override
  void initState() {
    super.initState();

    _iniciarSplash();
  }

  Future<void> _iniciarSplash() async {
    // Iniciar la animación del logo.
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _opacidad = 1.0;
      _escala = 1.0;
    });

    // Mantener visible el splash durante tres segundos.
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Consultar si Firebase conserva una sesión activa.
    final User? usuario = FirebaseAuth.instance.currentUser;

    final Widget siguientePantalla =
        usuario != null ? const HomeScreen2() : const LoginScreen();

    if (!mounted) return;

    // Reemplazar el splash para evitar regresar a él con Atrás.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) {
          return siguientePantalla;
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121B2B), Color(0xFF0A0F1A)],
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 1200),
            opacity: _opacidad,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 1200),
              scale: _escala,
              curve: Curves.easeOutBack,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo/logo.png', width: 140, height: 140),
                  const SizedBox(height: 32),
                  const Text(
                    'Healthy Habit',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Construye hábitos. Desbloquea tu progreso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
