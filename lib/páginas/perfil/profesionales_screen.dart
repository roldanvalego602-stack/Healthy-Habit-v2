import 'package:flutter/material.dart';
import '../../Contenido_del_tema/colores.dart';

class ProfesionalesScreen extends StatelessWidget {
  const ProfesionalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondoClaro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColores.textoOscuro),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Orientación profesional',
          style: TextStyle(
            color: AppColores.textoOscuro,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contactos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColores.textoOscuro,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Habla con profesionales de la salud para obtener resultados óptimos y saludables.',
              style: TextStyle(
                fontSize: 13,
                color: AppColores.textoGris,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta 1: Laura Méndez
            _buildProfessionalCard(
              nombre: 'Laura Méndez',
              especialidad: 'Nutrición · consulta externa',
              telefono: '+1111111111',
              horario: 'Lun–vie · 9:00–17:00 (hora local)',
            ),
            const SizedBox(height: 16),

            // Tarjeta 2: Daniel Ríos
            _buildProfessionalCard(
              nombre: 'Daniel Ríos',
              especialidad: 'Nutrición · consulta externa',
              telefono: '+111111111',
              horario: 'Lun–jue · 10:00–18:00 (hora local)',
            ),
            const SizedBox(height: 28),

            // Banner inferior informativo (Mr. Healthy / Disclaimer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBFC), // Tono lila/morado pastel
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¿Necesitas orientación profesional?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColores.textoOscuro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mr. Healthy ofrece información general y no sustituye a un profesional de salud. Estos contactos externos son para orientación individual.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColores.textoGris,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCard({
    required String nombre,
    required String especialidad,
    required String telefono,
    required String horario,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColores.bordeGris, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColores.verdeMenta,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColores.verdeOscuro,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColores.textoOscuro,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      especialidad,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColores.textoGris,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tel. $telefono',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColores.textoOscuro,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            horario,
            style: const TextStyle(fontSize: 12, color: AppColores.textoGris),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: const Text(
                      'Mensaje',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColores.verdeMenta,
                      foregroundColor: AppColores.verdeOscuro,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColores.textoOscuro,
                      side: const BorderSide(color: AppColores.bordeGris),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ver información',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
