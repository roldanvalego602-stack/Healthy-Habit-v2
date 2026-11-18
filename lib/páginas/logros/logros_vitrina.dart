import 'package:flutter/material.dart';
import 'logro_insignia.dart';
import 'logros_service.dart';

/// Galería visual de las cinco jerarquías, sin tocar datos del usuario.
/// Las insignias se muestran como desbloqueadas solo para enseñar sus efectos.
class VitrinaRarezas extends StatelessWidget {
  const VitrinaRarezas({super.key});

  static const icons = <IconData>[
    Icons.water_drop_rounded,
    Icons.directions_run_rounded,
    Icons.favorite_rounded,
    Icons.local_fire_department_rounded,
    Icons.emoji_events_rounded,
  ];
  static const descriptions = <String>[
    'Un emblema limpio con marco metálico sencillo.',
    'Refuerzos laterales y un destello de cristal azul.',
    'Corona de hojas, gema central y brillo pulsante.',
    'Órbita, cristales flotantes y energía violeta.',
    'Alas doradas, corona, partículas y aura giratoria.',
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mainText = dark ? Colors.white : const Color(0xFF183341);
    final secondaryText = dark ? const Color(0xFFAFBBC4) : const Color(0xFF50636C);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: ListView(
          key: const Key('vitrina-rarezas'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            Row(
              children: [
                Expanded(child: Text(
                  'JERARQUÍA DE INSIGNIAS',
                  style: TextStyle(color: mainText, fontSize: 15,
                    letterSpacing: 1.1, fontWeight: FontWeight.bold),
                )),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar',
                  icon: Icon(Icons.close_rounded, color: mainText),
                ),
              ],
            ),
            Text('Vista previa de los efectos. No desbloquea logros ni da recompensas.',
              style: TextStyle(color: secondaryText, fontSize: 12)),
            const SizedBox(height: 14),
            for (var i = 0; i < RarezaLogro.values.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1B2935) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorRareza(RarezaLogro.values[i]).withOpacity(0.65),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      LogroInsignia(
                        key: ValueKey('preview-${RarezaLogro.values[i].name}'),
                        rareza: RarezaLogro.values[i],
                        icono: icons[i],
                        desbloqueado: true,
                        size: 88,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(RarezaLogro.values[i].etiqueta,
                              style: TextStyle(
                                color: colorRareza(RarezaLogro.values[i]),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              )),
                            const SizedBox(height: 6),
                            Text(descriptions[i],
                              softWrap: true,
                              style: TextStyle(
                                color: mainText,
                                height: 1.35, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
