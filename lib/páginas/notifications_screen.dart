import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String description;
  String timeText;
  final String actionText;
  final IconData? iconData;
  final String? assetPath;
  final Color iconBgColor;
  final Color iconColor;
  bool isUnread;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timeText,
    required this.actionText,
    this.iconData,
    this.assetPath,
    required this.iconBgColor,
    required this.iconColor,
    this.isUnread = true,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Paleta de colores oficial
  static const Color green = Color(0xFF198568);
  static const Color navy = Color(0xFF172B36);
  static const Color background = Color(0xFFF7F9F8);
  static const Color textMuted = Color(0xFF7A869A);
  static const Color borderCard = Color(0xFFE5EEE9);

  // Lista de notificaciones mapeada a la imagen
  final List<NotificationItem> todayNotifications = [
    NotificationItem(
      id: '1',
      title: 'Tu misión te espera',
      description: 'Un pequeño paso para hoy: dedica un momento a tu rutina.',
      timeText: 'Hace 5 min · Sin leer',
      actionText: 'Ver misión',
      iconData: Icons.outlined_flag_rounded,
      iconBgColor: const Color(0xFFE2F7ED),
      iconColor: green,
      isUnread: true,
    ),
    NotificationItem(
      id: '2',
      title: 'Tu racha necesita un paso',
      description:
          'Aún puedes registrar un hábito hoy. Si no llegas, mañana es otra oportunidad.',
      timeText: 'Hace 20 min · Sin leer',
      actionText: 'Ver mis hábitos',
      iconData: Icons.local_fire_department_outlined,
      iconBgColor: const Color(0xFFFDF0ED),
      iconColor: const Color(0xFFE56A54),
      isUnread: true,
    ),
    NotificationItem(
      id: '3',
      title: '¡Gota constante es tuya!',
      description:
          '7 días de hidratación. Tu nueva insignia ya está en la colección.',
      timeText: 'Hace 1 h · Sin leer',
      actionText: 'Ver logro',
      iconData: Icons.verified_outlined,
      iconBgColor: const Color(0xFFE2F3FB),
      iconColor: const Color(0xFF459FCB),
      isUnread: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Una recompensa para ti',
      description: 'Recibiste +30 Habit Coins por tu logro Gota constante.',
      timeText: 'Hace 1 h · Sin leer',
      actionText: 'Ver recompensa',
      assetPath: 'assets/monedas/h coin.png',
      iconBgColor: const Color(0xFFFFF3D7),
      iconColor: const Color(0xFFD5A33E),
      isUnread: true,
    ),
  ];

  final List<NotificationItem> thisWeekNotifications = [
    NotificationItem(
      id: '5',
      title: 'Sofía te propone un desafío',
      description: '7 días, pequeños pasos. Tú eliges si te unes.',
      timeText: 'Ayer · 18:30 · Leído',
      actionText: 'Ver invitación',
      iconData: Icons.sports_kabaddi_outlined,
      iconBgColor: const Color(0xFFF0E8FA),
      iconColor: const Color(0xFF8C72C6),
      isUnread: false,
    ),
    NotificationItem(
      id: '6',
      title: 'Ana quiere ser tu amiga',
      description: 'Ana Torres · Nivel 12 · Nuevos comienzos',
      timeText: 'Ayer · 12:10 · Leído',
      actionText: 'Ver solicitud',
      iconData: Icons.person_add_outlined,
      iconBgColor: const Color(0xFFE2F7ED),
      iconColor: green,
      isUnread: false,
    ),
  ];

  final List<NotificationItem> previousNotifications = [
    NotificationItem(
      id: '7',
      title: 'Un nuevo look disponible',
      description: 'Desbloqueaste el Pañuelo de emo. Pruébalo con Mr. Healthy.',
      timeText: '16 oct · 10:15 · Leído',
      actionText: 'Abrir armario',
      iconData: Icons.checkroom_outlined,
      iconBgColor: const Color(0xFFFFF5DC),
      iconColor: const Color(0xFFD5A33E),
      isUnread: false,
    ),
  ];

  int get totalUnread {
    return todayNotifications.where((n) => n.isUnread).length +
        thisWeekNotifications.where((n) => n.isUnread).length +
        previousNotifications.where((n) => n.isUnread).length;
  }

  void markAllAsRead() {
    setState(() {
      for (var item in todayNotifications) {
        item.isUnread = false;
        item.timeText = item.timeText.replaceAll('Sin leer', 'Leído');
      }
      for (var item in thisWeekNotifications) {
        item.isUnread = false;
        item.timeText = item.timeText.replaceAll('Sin leer', 'Leído');
      }
      for (var item in previousNotifications) {
        item.isUnread = false;
        item.timeText = item.timeText.replaceAll('Sin leer', 'Leído');
      }
    });
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
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: navy,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subheader de contador y 'Marcar como leído'
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: navy,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$totalUnread sin leer',
                        style: const TextStyle(
                          color: navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: totalUnread > 0 ? markAllAsRead : null,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Marcar como leído',
                      style: TextStyle(
                        color: totalUnread > 0 ? green : textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Seccion: Hoy
              if (todayNotifications.isNotEmpty) ...[
                _buildSectionHeader('Hoy'),
                const SizedBox(height: 12),
                ...todayNotifications.map(
                  (item) => _buildNotificationCard(item),
                ),
                const SizedBox(height: 16),
              ],

              // Seccion: Esta semana
              if (thisWeekNotifications.isNotEmpty) ...[
                _buildSectionHeader('Esta semana'),
                const SizedBox(height: 12),
                ...thisWeekNotifications.map(
                  (item) => _buildNotificationCard(item),
                ),
                const SizedBox(height: 16),
              ],

              // Seccion: Anteriores
              if (previousNotifications.isNotEmpty) ...[
                _buildSectionHeader('Anteriores'),
                const SizedBox(height: 12),
                ...previousNotifications.map(
                  (item) => _buildNotificationCard(item),
                ),
                const SizedBox(height: 24),
              ],

              // Pie de página descriptivo
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Estás al día con tus pequeños grandes pasos.',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: navy,
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderCard, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono / Imagen miniatura de la notificación
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child:
                      item.assetPath != null
                          ? Image.asset(
                            item.assetPath!,
                            width: 22,
                            height: 22,
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.eco_rounded,
                                  color: item.iconColor,
                                  size: 22,
                                ),
                          )
                          : Icon(
                            item.iconData,
                            color: item.iconColor,
                            size: 22,
                          ),
                ),
              ),
              const SizedBox(width: 12),

              // Contenido principal (Título + Descripción)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: navy,
                            ),
                          ),
                        ),
                        if (item.isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: textMuted,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tiempo transcurrido
          Text(
            item.timeText,
            style: const TextStyle(
              fontSize: 11,
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Acciones de pie de tarjeta
          InkWell(
            onTap: () {
              setState(() {
                item.isUnread = false;
                item.timeText = item.timeText.replaceAll('Sin leer', 'Leído');
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.actionText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: green,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.north_east_rounded, size: 15, color: green),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
