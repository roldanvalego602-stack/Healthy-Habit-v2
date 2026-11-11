import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  static const Color green = Color(0xFF10B981);
  static const Color greenLight = Color(0xFFE6F7F0);
  static const Color navy = Color(0xFF172B36);
  static const Color background = Color(0xFFF8FAF9);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderCard = Color(0xFFE5E7EB);

  bool _enviando = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _mostrarMensaje('Ingresa un correo electrónico válido.');
      return;
    }

    setState(() => _enviando = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      _mostrarMensaje(
        'Si existe una cuenta asociada, recibirás instrucciones para restablecer la contraseña.',
        color: green,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String mensaje;
      switch (e.code) {
        case 'invalid-email':
          mensaje = 'El formato del correo electrónico no es válido.';
          break;
        case 'too-many-requests':
          mensaje =
              'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
          break;
        case 'network-request-failed':
          mensaje =
              'No hay conexión. Comprueba tu internet e inténtalo de nuevo.';
          break;
        default:
          mensaje = 'No se pudo procesar la solicitud. Inténtalo de nuevo.';
      }

      _mostrarMensaje(mensaje);
    } catch (_) {
      if (mounted) {
        _mostrarMensaje('Ocurrió un error. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: color ?? navy),
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
              errorBuilder:
                  (context, error, stackTrace) =>
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
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
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
                      autofillHints: const [AutofillHints.email],
                      enabled: !_enviando,
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
                      onSubmitted: (_) => _enviando ? null : _submit(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        disabledBackgroundColor: green.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          _enviando
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
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
            Positioned(
              bottom: -20,
              right: -20,
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 180,
                  decoration: BoxDecoration(
                    color: greenLight.withValues(alpha: 0.5),
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
