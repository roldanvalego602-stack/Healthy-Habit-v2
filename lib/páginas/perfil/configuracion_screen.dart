import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Paleta de colores oficial
  static const Color green = Color(0xFF198568);
  static const Color navy = Color(0xFF172B36);
  static const Color background = Color(0xFFF7F9F8);
  static const Color textMuted = Color(0xFF7A869A);
  static const Color borderCard = Color(0xFFE5EEE9);

  // Estados de los interruptores (Switches)
  bool analizarHistorialIA = true;
  bool sonidosApp = true;
  bool vibracionHaptica = true;
  bool animacionesDivertidas = true;
  bool mostrarRachaAmigos = true;
  bool permitirReacciones = true;
  bool permitirRecordatorios = true;
  bool recordatorioHabito = true;
  bool recordatorioRacha = true;
  bool recordatorioDesafios = false;
  bool descansoSemanal = true;
  bool mostrarXp = true;
  bool mostrarPuntos = true;
  bool mostrarNivelPerfil = true;
  bool mostrarRachasDiarias = true;
  bool efectosRecompensa = true;
  bool modoDiscreto = false;

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración',
              style: TextStyle(
                color: navy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Personaliza tu experiencia',
              style: TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CUENTA
              _buildSectionHeader(Icons.person_outline_rounded, 'CUENTA'),
              _buildCardContainer([
                _buildActionRow('Editar perfil', onTap: () {}),
                _buildDivider(),
                _buildActionRow(
                  'Cambiar correo electrónico',
                  value: 'diego@hermosa.com',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionRow('Cambiar contraseña', onTap: () {}),
                _buildDivider(),
                _buildActionRow(
                  'Foto o avatar',
                  value: 'Personalizado',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionRow(
                  'Nombre de usuario',
                  value: '@diego',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 24),

              // 2. PREFERENCIAS DE HÁBITOS
              _buildSectionHeader(
                Icons.tune_rounded,
                'PREFERENCIAS DE HÁBITOS',
              ),
              _buildCardContainer([
                _buildActionRow(
                  'Objetivo principal',
                  value: '6 vasos de agua',
                  onTap: () {},
                ),
                _buildDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Categorías de interés',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip(
                            'Alimentación',
                            const Color(0xFFFDE8E3),
                            const Color(0xFFE56A54),
                          ),
                          _buildChip(
                            'Hidratación',
                            const Color(0xFFE2F3FB),
                            const Color(0xFF459FCB),
                          ),
                          _buildChip(
                            'Fitness',
                            const Color(0xFFFFF3D7),
                            const Color(0xFFD5A33E),
                          ),
                          _buildChip(
                            'Bienestar',
                            const Color(0xFFF0E8FA),
                            const Color(0xFF8C72C6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildDivider(),
                _buildActionRow(
                  'Nivel de dificultad',
                  value: 'Moderado',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionRow(
                  'Frecuencia de hábitos',
                  value: 'Diaria',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionRow(
                  'Máximo de hábitos activos',
                  value: '5 activos',
                  onTap: () {},
                ),
                _buildDivider(),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Recalcular mis recomendaciones',
                      style: TextStyle(
                        color: green,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // 3. ASISTENTE IA
              _buildSectionHeader(Icons.auto_awesome_outlined, 'ASISTENTE IA'),
              _buildCardContainer([
                _buildSwitchRow(
                  'Analizar historial de hábitos',
                  subtitle:
                      'Permite sugerencias personalizadas sobre tu rutina.',
                  value: analizarHistorialIA,
                  onChanged: (val) => setState(() => analizarHistorialIA = val),
                ),
              ]),
              const SizedBox(height: 24),

              // 4. PRIVACIDAD Y DATOS
              _buildSectionHeader(Icons.shield_outlined, 'PRIVACIDAD Y DATOS'),
              _buildCardContainer([
                _buildActionRow('Ver política de privacidad', onTap: () {}),
                _buildDivider(),
                _buildActionRow(
                  'Tendencias guardadas',
                  value: '12 fotos',
                  onTap: () {},
                ),
                _buildDivider(),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Eliminar mi cuenta definitivamente',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // 5. EXPERIENCIA VISUAL
              _buildSectionHeader(
                Icons.visibility_outlined,
                'EXPERIENCIA VISUAL',
              ),
              _buildCardContainer([
                _buildActionRow(
                  'Tema',
                  value: 'Sistema (Automático)',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Sonidos de la app',
                  value: sonidosApp,
                  onChanged: (val) => setState(() => sonidosApp = val),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Vibración (Háptica)',
                  value: vibracionHaptica,
                  onChanged: (val) => setState(() => vibracionHaptica = val),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Animaciones divertidas',
                  value: animacionesDivertidas,
                  onChanged:
                      (val) => setState(() => animacionesDivertidas = val),
                ),
                _buildDivider(),
                _buildActionRow(
                  'Tamaño de texto',
                  value: 'Normal',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionRow('Idioma', value: 'Español (ES)', onTap: () {}),
              ]),
              const SizedBox(height: 24),

              // 6. CONFIGURACIÓN SOCIAL
              _buildSectionHeader(
                Icons.people_outline_rounded,
                'CONFIGURACIÓN SOCIAL',
              ),
              _buildCardContainer([
                _buildActionRow(
                  'Quién puede ver mis logros',
                  value: 'Solo amigos',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionRow(
                  'Quién puede enviarme desafíos',
                  value: 'Todos',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Mostrar racha a mis amigos',
                  value: mostrarRachaAmigos,
                  onChanged: (val) => setState(() => mostrarRachaAmigos = val),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Permitir reacciones',
                  value: permitirReacciones,
                  onChanged: (val) => setState(() => permitirReacciones = val),
                ),
                _buildDivider(),
                _buildActionRow(
                  'Bloquear o administrar usuarios',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 24),

              // 7. RECORDATORIOS
              _buildSectionHeader(
                Icons.notifications_none_rounded,
                'RECORDATORIOS',
              ),
              _buildCardContainer([
                _buildSwitchRow(
                  'Permitir recordatorios',
                  subtitle:
                      'Activa las alertas y notificaciones que la app te notifica.',
                  value: permitirRecordatorios,
                  onChanged:
                      (val) => setState(() => permitirRecordatorios = val),
                ),
                _buildDivider(),
                _buildActionRow(
                  'Horario preferido',
                  value: 'Mañana (09:00)',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Recordatorios por hábito',
                  subtitle: 'Alerta individualizada por cada objetivo activo.',
                  value: recordatorioHabito,
                  onChanged: (val) => setState(() => recordatorioHabito = val),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Recordatorio de racha',
                  subtitle: 'Aviso antes de que concluya tu día sin registrar.',
                  value: recordatorioRacha,
                  onChanged: (val) => setState(() => recordatorioRacha = val),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Recordatorio de desafíos',
                  subtitle: 'Avisos sobre nuevos eventos y retos.',
                  value: recordatorioDesafios,
                  onChanged:
                      (val) => setState(() => recordatorioDesafios = val),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Descanso semanal',
                  subtitle: 'Un respiro todos los domingos con tu avance.',
                  value: descansoSemanal,
                  onChanged: (val) => setState(() => descansoSemanal = val),
                ),
              ]),
              const SizedBox(height: 24),

              // 8. GAMIFICACIÓN
              _buildSectionHeader(Icons.emoji_events_outlined, 'GAMIFICACIÓN'),
              _buildCardContainer([
                _buildSwitchRow(
                  'Mostrar XP lograda',
                  value: mostrarXp,
                  onChanged: (val) => setState(() => mostrarXp = val),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Mostrar puntos acumulados',
                  value: mostrarPuntos,
                  onChanged: (val) => setState(() => mostrarPuntos = val),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Mostrar nivel en perfil',
                  value: mostrarNivelPerfil,
                  onChanged: (val) => setState(() => mostrarNivelPerfil = val),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Mostrar rachas diarias',
                  value: mostrarRachasDiarias,
                  onChanged:
                      (val) => setState(() => mostrarRachasDiarias = val),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Efectos visuales de recompensa',
                  value: efectosRecompensa,
                  onChanged: (val) => setState(() => efectosRecompensa = val),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  'Modo discreto',
                  subtitle:
                      'Reduce el modo visual y efectos de recompensas en pantalla y para no interrumpir tus tareas.',
                  value: modoDiscreto,
                  onChanged: (val) => setState(() => modoDiscreto = val),
                ),
              ]),
              const SizedBox(height: 24),

              // 9. INFORMACIÓN Y SOPORTE
              _buildSectionHeader(
                Icons.info_outline_rounded,
                'INFORMACIÓN Y SOPORTE',
              ),
              _buildCardContainer([
                _buildActionRow('Acerca de Healthy Habit', onTap: () {}),
                _buildDivider(),
                _buildActionRow('Términos de uso', onTap: () {}),
                _buildDivider(),
                _buildActionRow('Aviso de privacidad', onTap: () {}),
                _buildDivider(),
                _buildActionRow('Versión de la aplicación', value: '1.0.0'),
                _buildDivider(),
                _buildActionRow('Ayuda y soporte técnico', onTap: () {}),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Componente de Encabezado de Sección
  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: green),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: green,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta contenedora blanca redondeada
  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderCard, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Fila para opciones interactivas simples o con valor desplegable
  Widget _buildActionRow(String title, {String? value, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: navy,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: textMuted,
              ),
          ],
        ),
      ),
    );
  }

  // Fila para opciones con interruptores (Switch)
  Widget _buildSwitchRow(
    String title, {
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: green,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFDCDFE3),
          ),
        ],
      ),
    );
  }

  // Separador fino entre filas
  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF2F5F3));
  }

  // Chip para categorías de hábitos
  Widget _buildChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}
