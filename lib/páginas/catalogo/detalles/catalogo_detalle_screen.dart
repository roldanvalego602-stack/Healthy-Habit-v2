import 'package:flutter/material.dart';
import '../catalogo_media.dart';
import '../../../tema/healthy_theme.dart';
import '../modelos/catalogo_item.dart';
import '../catalogo_explorador.dart';
import '../datos/catalogo_datos.dart';
import 'catalogo_detalle_interactivo.dart';

class CatalogoDetalleScreen extends StatelessWidget {
  final CatalogoItem item;
  const CatalogoDetalleScreen({super.key, required this.item});

  Color get _verde => HealthyAdaptive.accent;
  Color get _oscuro => HealthyAdaptive.text;
  Color get _fondo => HealthyAdaptive.background;
  Color get _gris => HealthyAdaptive.muted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _fondo,
        foregroundColor: _oscuro,
        elevation: 0,
        title: Text(
          item.categoria,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CatalogoMedia(
            item: item,
            altura: 190,
            radio: 24,
            usarHero: true,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: HealthyAdaptive.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: HealthyAdaptive.mint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(CatalogoMedia.icono(item),
                      size: 36, color: _verde),
                ),
                const SizedBox(height: 16),
                Text(
                  item.titulo,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _oscuro,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.descripcion,
                  style: TextStyle(
                    fontSize: 15,
                    color: _gris,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(item.dificultad),
                    ...item.etiquetas.map(_chip),
                  ],
                ),
              ],
            ),
          ),
          if (item.categoria == 'Alimentos') ...[
            const SizedBox(height: 18),
            _seccion('Información nutricional',
                ResumenNutricionalCatalogo(item: item)),
          ],
          if (item.detalles.isNotEmpty) ...[
            const SizedBox(height: 18),
            _seccion(
              'Datos importantes',
              Column(
                children:
                    item.detalles.entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: TextStyle(color: _gris),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _oscuro,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _seccion(
            'Beneficios',
            _lista(item.beneficios, Icons.check_circle_outline),
          ),
          const SizedBox(height: 18),
          _seccion(
            item.categoria == 'Ejercicios'
                ? 'Cómo realizarlo'
                : item.categoria == 'Alimentos'
                ? 'Sugerencias de consumo'
                : 'Acciones recomendadas',
            item.categoria == 'Ejercicios'
                ? GuiaPasosCatalogo(item: item)
                : _lista(item.pasos, Icons.arrow_forward_ios, numerada: true),
          ),
          const SizedBox(height: 18),
          _seccion(
            'Precauciones',
            _lista(item.precauciones, Icons.info_outline),
          ),
          const SizedBox(height: 18),
          _seccion(
            'Hábitos relacionados',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...item.habitosRelacionados.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(Icons.link, color: _verde, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            h,
                            style: TextStyle(color: _oscuro),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'Vinculación informativa. No activa hábitos ni concede XP.',
                  style: TextStyle(color: _gris, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_relacionados.isNotEmpty) ...[
            const SizedBox(height: 18),
            _seccion(
              'También puede interesarte',
              Column(children: [
                for (final relacionado in _relacionados)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: HealthyAdaptive.mint,
                      child: Icon(CatalogoMedia.icono(relacionado),
                          color: _verde),
                    ),
                    title: Text(relacionado.titulo),
                    subtitle: Text(relacionado.categoria),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CatalogoDetalleScreen(
                            item: relacionado),
                      ),
                    ),
                  ),
              ]),
            ),
          ],
          const SizedBox(height: 18),
          _seccion(
            'Fuente de referencia',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fuente,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _oscuro,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  item.fuenteUrl,
                  style: TextStyle(color: _verde, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  'Contenido educativo general; no sustituye asesoramiento médico o nutricional individualizado.',
                  style: TextStyle(color: _gris, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  List<CatalogoItem> get _relacionados {
    final todos = <CatalogoItem>[
      ...alimentosCatalogo, ...ejerciciosCatalogo, ...consejosCatalogo,
    ];
    final claves = item.etiquetas
        .map(CatalogoExplorador.normalizar).toSet();
    final resultados = todos.where((otro) =>
        otro.id != item.id && otro.categoria == item.categoria).toList();
    resultados.sort((a, b) {
      int puntos(CatalogoItem value) => value.etiquetas
          .map(CatalogoExplorador.normalizar)
          .where(claves.contains).length;
      final diferencia = puntos(b).compareTo(puntos(a));
      return diferencia == 0
          ? a.titulo.compareTo(b.titulo) : diferencia;
    });
    return resultados.take(3).toList();
  }

  Widget _chip(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: HealthyAdaptive.mint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      s,
      style: TextStyle(
        color: _verde,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );

  Widget _seccion(String titulo, Widget contenido) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: HealthyAdaptive.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _oscuro,
          ),
        ),
        const SizedBox(height: 14),
        contenido,
      ],
    ),
  );

  Widget _lista(List<String> textos, IconData icono, {bool numerada = false}) =>
      Column(
        children:
            textos
                .asMap()
                .entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        numerada
                            ? CircleAvatar(
                              radius: 12,
                              backgroundColor: HealthyAdaptive.mint,
                              child: Text(
                                '${e.key + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _verde,
                                ),
                              ),
                            )
                            : Icon(icono, size: 19, color: _verde),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: _oscuro,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      );
}
