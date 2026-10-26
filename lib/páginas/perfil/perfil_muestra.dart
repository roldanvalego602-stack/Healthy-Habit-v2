import 'package:flutter/material.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String username;
  final String? bio;
  final String? title;
  final int level;
  final int streakDays;
  final int completedHabits;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.username,
    this.bio = 'Pequeños pasos, raíces fuertes.',
    this.title = 'Cultivador de constancia',
    this.level = 1,
    this.streakDays = 0,
    this.completedHabits = 0,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isFriend = false;
  bool _isLoading = false;

  static const Color green = Color(0xFF198568);
  static const Color mint = Color(0xFF8DE0C0);
  static const Color navy = Color(0xFF173544);
  static const Color background = Color(0xFFF4F8F5);
  static const Color gold = Color(0xFFD5A33E);

  void _toggleFriendship() {
    setState(() => _isLoading = true);

    // Simulación de interacción con Firestore para agregar/eliminar amigo
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isFriend = !_isFriend;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFriend
                  ? '¡Ahora sigues a ${widget.name}!'
                  : 'Has dejado de seguir a ${widget.name}.',
            ),
            backgroundColor: _isFriend ? green : Colors.grey.shade700,
          ),
        );
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
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.username,
          style: const TextStyle(
            color: navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _publicProfileCard(),
              const SizedBox(height: 22),
              _levelCard(),
              const SizedBox(height: 14),
              _statistics(),
              const SizedBox(height: 28),
              _sectionTitle('Logos destacados'),
              const SizedBox(height: 14),
              _achievementsCard(),
              const SizedBox(height: 28),
              _mascotSupportCard(),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta de perfil principal pública
  Widget _publicProfileCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner
          Container(
            height: 130,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF174D4B), Color(0xFF498A75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'PERFIL PÚBLICO',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          // Foto y datos
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: mint, width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFE6F1EC),
                    child: Icon(Icons.person_rounded, size: 50, color: green),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.username,
                  style: const TextStyle(color: Color(0xFF8496A0), fontSize: 13),
                ),
                if (widget.title != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2D2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '✦ ${widget.title}',
                      style: const TextStyle(
                        color: gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                if (widget.bio != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.bio!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8797A0),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                
                // Botón de interacción principal (Agregar / Seguir)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _toggleFriendship,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isFriend
                                  ? Icons.check_circle_rounded
                                  : Icons.person_add_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _isFriend ? 'Amigos' : 'Agregar amigo',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFriend ? navy : green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nivel del usuario buscado
  Widget _levelCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF112F3C), Color(0xFF285566)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: mint, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '${widget.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NIVEL DE HÁBITOS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cultivador Nivel ${widget.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Estadísticas públicas
  Widget _statistics() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.local_fire_department_outlined,
            value: '${widget.streakDays}',
            label: 'Días de racha',
            color: const Color(0xFFFFF0CF),
            iconColor: gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.check_circle_outline_rounded,
            value: '${widget.completedHabits}',
            label: 'Hábitos logrados',
            color: const Color(0xFFE0F3FB),
            iconColor: const Color(0xFF459FCB),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8496A0), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: navy,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  // Muestra del estante de insignias destacadas
  Widget _achievementsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _achievement(
            Icons.water_drop_outlined,
            'Gota constante',
            const Color(0xFF62B7DD),
          ),
          _achievement(
            Icons.local_fire_department_outlined,
            'En llamas',
            gold,
          ),
          _achievement(
            Icons.spa_outlined,
            'Primer brote',
            const Color(0xFF369B7B),
          ),
        ],
      ),
    );
  }

  Widget _achievement(IconData icon, String name, Color color) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            border: Border.all(color: color, width: 1.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: navy,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // Tarjeta de apoyo de Mr. Healthy
  Widget _mascotSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F3E7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: green, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '¡Acompaña a ${widget.name} a mantener sus hábitos saludables!',
              style: const TextStyle(
                color: navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}