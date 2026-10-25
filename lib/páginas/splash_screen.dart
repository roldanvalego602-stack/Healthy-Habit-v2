import 'package:flutter/material.dart';
import '/páginas/sesion/login_screen.dart'; // Ajusta esta ruta a tu pantalla principal o de login

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

    // Inicia la animación milisegundos después de renderizar la pantalla
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _opacidad = 1.0;
          _escala = 1.0;
        });
      }
    });

    // Navega a la siguiente pantalla después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    const LoginScreen(), // Cambia a tu vista inicial
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
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
            colors: [
              Color(0xFF121B2B), // Azul noche oscuro arriba
              Color(0xFF0A0F1A), // Azul casi negro abajo
            ],
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 1200),
            opacity: _opacidad,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 1200),
              scale: _escala,
              curve: Curves.easeOutBack, // Efecto de rebote sutil
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8), // Gris azulado claro
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
