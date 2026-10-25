import 'package:flutter/material.dart';
import '../../Contenido_del_tema/colores.dart';
import '../../Contenido_del_tema/chip_recompensa.dart';

class BuscarAmigosScreen extends StatefulWidget {
  const BuscarAmigosScreen({super.key});

  @override
  State<BuscarAmigosScreen> createState() => _BuscarAmigosScreenState();
}

class _BuscarAmigosScreenState extends State<BuscarAmigosScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Lista simulada de usuarios para la comunidad de Healthy Habit
  final List<Map<String, dynamic>> _usuarios = [
    {
      'nombre': 'Steven Morones',
      'usuario': '@steven.dev',
      'nivel': 'Nivel 8',
      'racha': '15 días 🔥',
      'agregado': false,
      'avatar': 'https://i.pravatar.cc/150?img=60',
    },
    {
      'nombre': 'Carlos Cisneros',
      'usuario': '@carlos.test',
      'nivel': 'Nivel 5',
      'racha': '9 días 🔥',
      'agregado': true,
      'avatar': 'https://i.pravatar.cc/150?img=33',
    },
    {
      'nombre': 'Cristian Gámez',
      'usuario': '@cristian.doc',
      'nivel': 'Nivel 7',
      'racha': '12 días 🔥',
      'agregado': false,
      'avatar': 'https://i.pravatar.cc/150?img=11',
    },
    {
      'nombre': 'Diego Rojas',
      'usuario': '@diego.rojas',
      'nivel': 'Nivel 6',
      'racha': '10 días 🔥',
      'agregado': false,
      'avatar': 'https://i.pravatar.cc/150?img=68',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondoClaro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColores.textoOscuro),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buscar Amigos',
          style: TextStyle(
            color: AppColores.textoOscuro,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de Búsqueda
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por usuario o nombre...',
                  hintStyle: const TextStyle(
                    color: AppColores.textoGris,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColores.textoGris,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Sugerencias de la comunidad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColores.textoOscuro,
              ),
            ),
            const SizedBox(height: 14),

            // Lista de usuarios encontrados
            Expanded(
              child: ListView.separated(
                itemCount: _usuarios.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = _usuarios[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColores.bordeGris, width: 1),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(user['avatar']),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['nombre'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColores.textoOscuro,
                                ),
                              ),
                              Text(
                                user['usuario'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColores.textoGris,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  ChipRecompensa(
                                    texto: user['nivel'],
                                    colorFondo: AppColores.verdeMenta,
                                    colorTexto: AppColores.verdeOscuro,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    user['racha'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              user['agregado'] = !user['agregado'];
                            });
                          },
                          // Reemplaza las líneas 186-190 por esto:
                          icon: Icon(
                            user['agregado']
                                ? Icons
                                    .check_circle_rounded // Icono corregido
                                : Icons.person_add_alt_1_rounded,
                            color:
                                user['agregado']
                                    ? AppColores.verdePrincipal
                                    : AppColores.textoGris,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
