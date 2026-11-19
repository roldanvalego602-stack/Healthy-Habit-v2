import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../tema/healthy_theme.dart';
import 'datos/catalogo_datos.dart';
import 'detalles/catalogo_detalle_screen.dart';
import 'modelos/catalogo_item.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen>
    with SingleTickerProviderStateMixin {
  Color get _verde => HealthyAdaptive.accent;
  Color get _oscuro => HealthyAdaptive.text;
  Color get _fondo => HealthyAdaptive.background;
  Color get _gris => HealthyAdaptive.muted;
  late final TabController _tabs;
  final _buscador = TextEditingController();
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging && mounted) {
        setState(() {
          _filtro = 'Todos';
          _buscador.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _buscador.dispose();
    super.dispose();
  }

  List<CatalogoItem> get _actuales {
    switch (_tabs.index) {
      case 0:
        return alimentosCatalogo;
      case 1:
        return ejerciciosCatalogo;
      default:
        return consejosCatalogo;
    }
  }

  IconData _icono(String nombre) {
    switch (nombre) {
      case 'grain':
        return Icons.grain;
      case 'egg':
        return Icons.egg_outlined;
      case 'eco':
        return Icons.eco_outlined;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'bedtime':
        return Icons.bedtime_outlined;
      case 'health_and_safety':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.self_improvement;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtros = <String>[
      'Todos',
      ..._actuales.expand((e) => e.etiquetas).toSet(),
    ];
    final consulta = _buscador.text.toLowerCase().trim();
    final resultados =
        _actuales.where((e) {
          final coincideFiltro =
              _filtro == 'Todos' || e.etiquetas.contains(_filtro);
          final texto =
              '${e.titulo} ${e.descripcion} ${e.etiquetas.join(' ')} ${e.beneficios.join(' ')}'
                  .toLowerCase();
          return coincideFiltro && texto.contains(consulta);
        }).toList();

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _fondo,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Catálogo',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: _oscuro,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.menu_book_outlined, color: _verde),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: _verde,
          unselectedLabelColor: _gris,
          indicatorColor: _verde,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Alimentos'),
            Tab(text: 'Ejercicios'),
            Tab(text: 'Consejos'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: TextField(
              controller: _buscador,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText:
                    'Buscar en ${['alimentos', 'ejercicios', 'consejos'][_tabs.index]}...',
                prefixIcon: Icon(Icons.search, color: _gris),
                suffixIcon:
                    _buscador.text.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_buscador.clear),
                        ),
                filled: true,
                fillColor: HealthyAdaptive.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 43,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: filtros.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = filtros[i];
                final activo = f == _filtro;
                return ChoiceChip(
                  label: Text(f),
                  selected: activo,
                  onSelected: (_) => setState(() => _filtro = f),
                  selectedColor: HealthyAdaptive.mint,
                  backgroundColor: HealthyAdaptive.surface,
                  labelStyle: TextStyle(
                    color: activo ? _verde : _oscuro,
                    fontWeight: activo ? FontWeight.w800 : FontWeight.w500,
                  ),
                  side: BorderSide.none,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                resultados.isEmpty
                    ? Center(
                      child: Text(
                        'No se encontraron resultados.',
                        style: TextStyle(color: _gris),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemCount: resultados.length,
                      itemBuilder: (context, i) {
                        final item = resultados[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: HealthyAdaptive.surface,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap:
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              CatalogoDetalleScreen(item: item),
                                    ),
                                  ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    child: item.imagen.endsWith('.svg')
                                        ? SvgPicture.asset(
                                            item.imagen,
                                            semanticsLabel: 'Ilustración de ${item.titulo}',
                                            height: 138,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _imagenAlternativa(item, 138),
                                          )
                                        : Image.asset(
                                            item.imagen,
                                            semanticLabel: 'Fotografía de ${item.titulo}',
                                            height: 138,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            filterQuality: FilterQuality.medium,
                                            errorBuilder: (_, __, ___) =>
                                                _imagenAlternativa(item, 138),
                                          ),
                                  ),
                                  Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: HealthyAdaptive.mint,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        _icono(item.icono),
                                        color: _verde,
                                        size: 29,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.titulo,
                                            style: TextStyle(
                                              color: _oscuro,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            item.descripcion,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: _gris,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.etiquetas.take(2).join(' · '),
                                            style: TextStyle(
                                              color: _verde,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: _gris,
                                    ),
                                  ],
                                ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
  Widget _imagenAlternativa(CatalogoItem item, double altura) => SizedBox(
    height: altura,
    width: double.infinity,
    child: ColoredBox(
      color: HealthyAdaptive.mint,
      child: Icon(_icono(item.icono), size: 48, color: _verde),
    ),
  );

}
