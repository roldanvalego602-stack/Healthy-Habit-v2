import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  // Paleta de colores oficial
  static const Color green = Color(0xFF10B981);
  static const Color greenLight = Color(0xFFE6F7F0);
  static const Color navy = Color(0xFF172B36);
  static const Color background = Color(0xFFF8FAF9);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderCard = Color(0xFFE5E7EB);

  void _submit() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu correo electrónico.'),
        ),
      );
      return;
    }

    // Lógica para enviar correo de recuperación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Instrucciones enviadas a $email'),
        backgroundColor: green,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/mascot/healthy.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.eco_rounded, color: green, size: 22),
            ),
            const SizedBox(width: 8),
            const Text(
              'Healthy Habit',
              style: TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido principal
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Círculo verde con icono de llave
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: greenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.key_outlined,
                      color: green,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Título principal
                  const Text(
                    '¿Olvidaste tu contraseña?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtítulo explicativo
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'No pasa nada. Ingresa el correo asociado a tu cuenta y te enviaremos instrucciones para recuperarla.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo de Correo Electrónico
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Correo electrónico',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCard, width: 1),
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: navy, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'nombre@correo.com',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.mail_outline_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Botón de Enviar instrucciones
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Enviar instrucciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Enlace Volver a iniciar sesión
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Volver a iniciar sesión',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Elemento decorativo de hoja verde sutil en la esquina inferior derecha
            Positioned(
              bottom: -20,
              right: -20,
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 180,
                  decoration: BoxDecoration(
                    color: greenLight.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(140),
                      bottomLeft: Radius.circular(40),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}