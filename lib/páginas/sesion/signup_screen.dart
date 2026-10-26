import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:healthy_habit/páginas/inicio.dart';
import 'package:healthy_habit/servicios/autenticacion_servicio.dart';
import 'login_screen.dart'; // Importa para reutilizar AppColors y componentes

class AppColors {
  static const primaryGreen = Color(0xFF00C88C);
  static const darkGreenCard = Color(0xFF143834);
  static const textDark = Color(0xFF0E1A30);
  static const textGrey = Color(0xFF7A869A);
  static const yellowCard = Color(0xFFFDE89D);
  static const blueWaterCard = Color(0xFFE8F6FC);
  static const purpleCard = Color(0xFFF0EBFC);
  static const mintCard = Color(0xFFE2F7ED);
  static const green = Color(0xFF00C88C);
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Controladores para capturar los campos de registro
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Método para manejar el registro de usuario
  void _handleSignup() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        username: username.startsWith('@') ? username : '@$username',
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen2()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrarse: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Logo
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Crea tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Empieza a construir tus hábitos hoy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.textGrey),
              ),
              const SizedBox(height: 28),

              const FieldLabel('Nombre completo'),
              const SizedBox(height: 8),
              AuthTextField(
                hint: 'Tu nombre',
                icon: Icons.person_outline_rounded,
                controller: _nameController,
              ),
              const SizedBox(height: 16),

              const FieldLabel('Nombre de usuario'),
              const SizedBox(height: 8),

              AuthTextField(
                hint: 'usuario_hot_69_sixseven_Girls',
                icon: Icons.alternate_email_rounded,
                controller: _usernameController,
              ),
              const SizedBox(height: 16),

              const FieldLabel('Correo electrónico'),
              const SizedBox(height: 8),
              AuthTextField(
                hint: 'ejemplo@correo.com',
                icon: Icons.mail_outline_rounded,
                controller: _emailController,
              ),
              const SizedBox(height: 16),

              const FieldLabel('Contraseña'),
              const SizedBox(height: 8),
              AuthTextField(
                hint: 'Crea una contraseña segura',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                controller: _passwordController,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textGrey,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : const Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Color.fromARGB(255, 225, 145, 59),
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'o',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Color.fromARGB(255, 225, 145, 59),
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color.fromARGB(255, 225, 145, 59),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      GoogleG(),
                      SizedBox(width: 10),
                      Text(
                        'Registrarse con Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                    children: [
                      const TextSpan(text: '¿Ya tienes una cuenta? '),
                      TextSpan(
                        text: 'Iniciar sesión',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 5, 80, 58),
                          fontWeight: FontWeight.w800,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).pop();
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
