import 'package:flutter/material.dart';

/// Contenido informativo editable del proyecto. No sustituye documentos legales.
class InformacionAppScreen extends StatelessWidget {
  final String tipo;
  const InformacionAppScreen({super.key, required this.tipo});

  static const _navy = Color(0xFF172B36);
  static const _green = Color(0xFF198568);

  @override
  Widget build(BuildContext context) {
    final contenido = _contenido(tipo);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: Text(contenido.$1),
        backgroundColor: const Color(0xFFF7F9F8),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Image.asset(
            'assets/logo/logo.png',
            width: 76,
            height: 76,
            alignment: Alignment.centerLeft,
            errorBuilder:
                (_, __, ___) =>
                    const Icon(Icons.eco_rounded, color: _green, size: 55),
          ),
          const SizedBox(height: 18),
          Text(
            contenido.$1,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _navy,
            ),
          ),
          const SizedBox(height: 16),
          ...contenido.$2.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                p,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: _navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, List<String>) _contenido(String tipo) {
    switch (tipo) {
      case 'acerca':
        return (
          'Acerca de Healthy Habit',
          [
            'Healthy Habit es una aplicación de seguimiento de hábitos saludables. Su objetivo es ayudarte a crear rutinas mediante metas, registros de progreso y motivación cotidiana.',
            'Puedes explorar hábitos de Alimentación, Hidratación, Energía y Bienestar; registrar avances, acumular experiencia (XP), obtener Habit Coins y consultar tus logros.',
            'La aplicación también incluye funciones sociales y herramientas de acompañamiento. Los contenidos de bienestar son informativos y no sustituyen la atención de profesionales de la salud.',
          ],
        );
      case 'terminos':
        return (
          'Términos de uso',
          [
            'Documento informativo provisional del proyecto Healthy Habit. Antes de publicar la aplicación, el equipo responsable debe aprobar y publicar términos legales completos.',
            'Utiliza la aplicación de forma respetuosa. No compartas contenido que vulnere derechos de terceros ni intentes acceder a cuentas ajenas.',
            'Los puntos, niveles, logros y Habit Coins son elementos de gamificación de la aplicación; no representan dinero ni tienen valor monetario garantizado.',
            'Healthy Habit no presta diagnóstico, tratamiento ni asesoría médica personalizada. Ante una situación de salud, consulta a un profesional.',
            'El equipo debe definir formalmente condiciones de acceso, limitaciones, moderación, contacto, jurisdicción y fecha de entrada en vigor antes de su distribución pública.',
          ],
        );
      case 'privacidad':
        return (
          'Privacidad y tratamiento de datos',
          [
            'Documento explicativo provisional. No constituye una política de privacidad legal aprobada. Debe revisarse antes de publicar Healthy Habit.',
            'La aplicación utiliza Firebase Authentication para la cuenta y Cloud Firestore para información del perfil, hábitos, intentos, registros, preferencias y funciones sociales.',
            'Cuando adjuntas una fotografía a un registro, el código actual puede guardar evidencia temporal asociada a tu cuenta. La limpieza de evidencias vencidas se ejecuta desde la aplicación; esto no garantiza eliminación automática exacta al cumplirse 24 horas.',
            'Puedes revisar tus preferencias y solicitar la eliminación de tu cuenta. La eliminación integral de todos los datos requiere verificar las colecciones y servicios asociados, además de cumplir las obligaciones legales aplicables.',
            'Antes del lanzamiento, el equipo debe documentar responsables, finalidades, bases legales, plazos de conservación, proveedores, derechos de las personas y un canal de contacto verificable.',
          ],
        );
      case 'ayuda':
        return (
          'Ayuda y soporte',
          [
            'Para registrar un hábito: abre Hábitos, selecciona un intento activo y pulsa Registrar. Puedes añadir una nota y una fotografía opcional.',
            'Los registros normales suman 10 XP; con evidencia fotográfica suman 15 XP. El progreso de cada intento se guarda en Firestore.',
            'Si tus cambios no aparecen, verifica la conexión, cierra y vuelve a abrir la pantalla, y confirma que hayas iniciado sesión con la cuenta correcta.',
            'Si no puedes iniciar sesión, utiliza las opciones de recuperación de Firebase Authentication disponibles en tu pantalla de acceso.',
            'Canal de soporte: pendiente de definir por el equipo de Healthy Habit. No se incluye una dirección de correo inventada.',
          ],
        );
      default:
        return ('Healthy Habit', ['Información no disponible.']);
    }
  }
}
