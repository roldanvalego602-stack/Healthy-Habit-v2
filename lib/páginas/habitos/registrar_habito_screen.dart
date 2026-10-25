import 'package:flutter/material.dart';
import '../../Contenido_del_tema/colores.dart';

class RegistrarHabitoScreen extends StatefulWidget {
  const RegistrarHabitoScreen({super.key});

  @override
  State<RegistrarHabitoScreen> createState() => _RegistrarHabitoScreenState();
}

class _RegistrarHabitoScreenState extends State<RegistrarHabitoScreen> {
  bool _tieneEvidencia = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondoClaro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColores.textoOscuro),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar Hábito',
              style: TextStyle(
                color: AppColores.textoOscuro,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            Text(
              'Añade algo que acompañe tu registro.',
              style: TextStyle(
                color: AppColores.textoGris,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tarjeta del Hábito Actual
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColores.azulAgua,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.water_drop_outlined,
                          color: AppColores.azulTexto,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tomar 6 vasos de agua',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColores.textoOscuro,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Hidratación · Misión diaria',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColores.textoGris,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: 4 / 6,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFEDEFF3),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColores.azulTexto,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '4 / 6 vasos',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColores.azulTexto,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Sección de Fotografía
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Fotografía',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColores.textoOscuro,
                  ),
                ),
                Text(
                  'Opcional',
                  style: TextStyle(fontSize: 13, color: AppColores.textoGris),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColores.verdePrincipal.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColores.verdeMenta,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColores.verdePrincipal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Añadir fotografía',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColores.textoOscuro,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Toma una foto o selecciona una de tu\ndispositivo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColores.textoGris),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              () => setState(() => _tieneEvidencia = true),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text(
                            'Tomar fotografía',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColores.verdePrincipal,
                            backgroundColor: AppColores.verdeMenta,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              () => setState(() => _tieneEvidencia = true),
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text(
                            'Elegir de galería',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColores.textoOscuro,
                            side: const BorderSide(color: AppColores.bordeGris),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Acompaña tu registro, no es obligatorio.',
              style: TextStyle(fontSize: 12, color: AppColores.textoGris),
            ),
            const SizedBox(height: 24),

            // 3. Añadir Nota
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Añadir una nota',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColores.textoOscuro,
                  ),
                ),
                Text(
                  'Opcional',
                  style: TextStyle(fontSize: 13, color: AppColores.textoGris),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej. Terminé mi botella durante el almuerzo.',
                hintStyle: const TextStyle(
                  color: AppColores.textoGris,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColores.bordeGris),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColores.bordeGris),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Desglose de XP
            const Text(
              'Tu registro suma',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColores.textoOscuro,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColores.bordeGris),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Registro normal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.bolt,
                              color: AppColores.textoGris,
                              size: 20,
                            ),
                            Text(
                              '+10 XP',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColores.textoOscuro,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sin fotografía',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColores.textoGris,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColores.verdeMenta,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColores.verdePrincipal.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Con evidencia',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.bolt,
                              color: AppColores.verdePrincipal,
                              size: 20,
                            ),
                            Text(
                              '+15 XP',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColores.verdePrincipal,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Total del registro',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColores.textoGris,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Privacidad y Mr. Healthy
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: AppColores.textoOscuro,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tu privacidad importa',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La evidencia se utiliza únicamente para respaldar este registro y se manejará según tus preferencias de privacidad.',
                    style: TextStyle(fontSize: 12, color: AppColores.textoGris),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ver privacidad de evidencias',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColores.verdePrincipal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/mascot/healthy.png', width: 40, height: 40),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mr. Healthy',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColores.verdePrincipal,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'La evidencia es opcional. Tu progreso sigue contando aunque no adjuntes una foto mientras sigas en esta dificultad. Ten en cuenta que no los Healthy Coins se obtienen al terminar una misión, no al realizar un registro.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColores.textoGris,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Botones Finales
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Lógica para guardar
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text(
                  'Guardar registro',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColores.verdePrincipal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColores.verdePrincipal,
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
