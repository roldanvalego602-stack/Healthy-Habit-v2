import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../tema/healthy_theme.dart';
import 'datos/catalogo_datos.dart';
import 'detalles/catalogo_detalle_screen.dart';
import 'modelos/catalogo_item.dart';
import 'catalogo_explorador.dart';

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
  VistaCatalogo _vista = VistaCatalogo.lista;
  OrdenCatalogo _orden = OrdenCatalogo.relevancia;
  final Set<String> _comparar = <String>{};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging && mounted) {
        setState(() {
          _filtro = 'Todos';
          _orden = OrdenCatalogo.relevancia;
          _comparar.clear();
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


  void _abrirDetalle(CatalogoItem item) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CatalogoDetalleScreen(item: item),
        ),
      );

  Widget _imagen(CatalogoItem item, double altura) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: item.imagen.endsWith('.svg')
            ? SvgPicture.asset(
                item.imagen,
                height: altura,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticsLabel: 'Ilustración de ${item.titulo}',
                errorBuilder: (_, __, ___) => _imagenAlternativa(item, altura),
              )
            : Image.asset(
                item.imagen,
                height: altura,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: 'Imagen de ${item.titulo}',
                errorBuilder: (_, __, ___) => _imagenAlternativa(item, altura),
              ),
      );

  Widget _tarjeta(CatalogoItem item) {
    final imagenes = _vista == VistaCatalogo.imagenes;
    final detalles = _vista == VistaCatalogo.detalles;
    final marcado = _comparar.contains(item.id);
    return Material(
      color: HealthyAdaptive.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _abrirDetalle(item),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: imagenes
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _imagen(item, 108),
                    const SizedBox(height: 10),
                    Text(item.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w800,
                            color: _oscuro)),
                    Text(item.etiquetas.take(2).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _verde, fontSize: 11)),
                    _botonComparar(item, marcado),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      SizedBox(width: 88, child: _imagen(item, 88)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.titulo,
                              style: TextStyle(color: _oscuro,
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(item.descripcion, maxLines: detalles ? 4 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _gris, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(item.etiquetas.take(3).join(' · '),
                              style: TextStyle(color: _verde, fontSize: 11)),
                        ],
                      )),
                      Icon(Icons.chevron_right_rounded, color: _gris),
                    ]),
                    if (detalles && item.detalles.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      for (final entry in item.detalles.entries.take(4))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(children: [
                            Expanded(child: Text(entry.key,
                                style: TextStyle(color: _gris, fontSize: 12))),
                            Flexible(child: Text(entry.value,
                                textAlign: TextAlign.right,
                                style: TextStyle(color: _oscuro,
                                    fontSize: 12, fontWeight: FontWeight.w700))),
                          ]),
                        ),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: _botonComparar(item, marcado),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _botonComparar(CatalogoItem item, bool marcado) => TextButton.icon(
    onPressed: () {
      setState(() {
        if (marcado) {
          _comparar.remove(item.id);
        } else if (_comparar.length < 3) {
          _comparar.add(item.id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Puedes comparar hasta tres elementos.'),
          ));
        }
      });
    },
    icon: Icon(marcado ? Icons.check_circle_rounded
        : Icons.add_circle_outline, size: 17),
    label: Text(marcado ? 'Seleccionado' : 'Comparar',
        style: const TextStyle(fontSize: 12)),
  );

  Widget _vistaExplorar(List<CatalogoItem> resultados) {
    final grupos = <String, List<CatalogoItem>>{};
    for (final item in resultados) {
      grupos.putIfAbsent(CatalogoExplorador.grupoExploracion(item), () => [])
          .add(item);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
      children: [
        Text(_tabs.index == 0 ? 'Explora por grupos del plato'
            : _tabs.index == 1 ? 'Explora por zona de movimiento'
            : 'Explora por objetivos de bienestar',
            style: TextStyle(color: _oscuro,
                fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 6),
        Text(_tabs.index == 0
            ? 'Agrupación orientativa. No representa porciones ni una dieta.'
            : 'Elige un objetivo para conocer sus elementos.',
            style: TextStyle(color: _gris, fontSize: 12)),
        const SizedBox(height: 14),
        for (final group in grupos.entries) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: HealthyAdaptive.surface,
                borderRadius: BorderRadius.circular(22)),
            child: ExpansionTile(
              initiallyExpanded: grupos.length == 1,
              leading: CircleAvatar(
                backgroundColor: HealthyAdaptive.mint,
                child: Icon(_tabs.index == 0 ? Icons.pie_chart_outline
                    : _tabs.index == 1 ? Icons.accessibility_new
                    : Icons.spa_outlined, color: _verde)),
              title: Text(group.key, style: const TextStyle(
                  fontWeight: FontWeight.w800)),
              subtitle: Text('${group.value.length} elementos'),
              children: [
                for (final item in group.value)
                  ListTile(
                    title: Text(item.titulo),
                    subtitle: Text(item.etiquetas.take(2).join(' · ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrirDetalle(item),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _mostrarComparacion(List<CatalogoItem> actuales) {
    final seleccionados = actuales.where(
        (item) => _comparar.contains(item.id)).toList();
    if (seleccionados.length < 2) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Comparar elementos',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 14),
              for (final item in seleccionados)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.titulo, style: const TextStyle(
                          fontWeight: FontWeight.w800)),
                      Text(item.descripcion,
                          style: const TextStyle(fontSize: 12)),
                      for (final metric in <String>[
                        'Proteína', 'Grasas', 'Carbohidratos', 'Fibra',
                        'Grupo muscular', 'Impacto',
                      ])
                        if (item.detalles.containsKey(metric))
                          Text('$metric: ${item.detalles[metric]}',
                              style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              const Text('Comparación informativa: las referencias nutricionales pueden diferir entre crudo y cocido.',
                  style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actuales = _actuales;
    final filtros = CatalogoExplorador.filtros(actuales);
    final resultados = CatalogoExplorador.filtrar(
      items: actuales,
      consulta: _buscador.text,
      etiqueta: _filtro,
      orden: _tabs.index == 0 ? _orden :
          (_orden == OrdenCatalogo.nombre
              ? OrdenCatalogo.nombre : OrdenCatalogo.relevancia),
    );
    final lista = resultados.isEmpty
        ? Center(child: Text('Sin coincidencias. Prueba otra búsqueda o filtro.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _gris)))
        : _vista == VistaCatalogo.explorar
            ? _vistaExplorar(resultados)
            : _vista == VistaCatalogo.imagenes
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 252,
                    ),
                    itemCount: resultados.length,
                    itemBuilder: (_, i) => _tarjeta(resultados[i]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                    itemCount: resultados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _tarjeta(resultados[i]),
                  );
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _fondo,
        automaticallyImplyLeading: false,
        title: Text('Explorar catálogo',
            style: TextStyle(fontWeight: FontWeight.w900, color: _oscuro)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _verde,
          unselectedLabelColor: _gris,
          indicatorColor: _verde,
          tabs: const [
            Tab(text: 'Alimentos'),
            Tab(text: 'Ejercicios'),
            Tab(text: 'Consejos'),
          ],
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: TextField(
            controller: _buscador,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Busca por nombre, beneficio u objetivo',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _buscador.text.isEmpty ? null : IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Borrar búsqueda',
                onPressed: () => setState(_buscador.clear),
              ),
              filled: true,
              fillColor: HealthyAdaptive.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none),
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
            itemBuilder: (_, index) => ChoiceChip(
              label: Text(filtros[index]),
              selected: _filtro == filtros[index],
              onSelected: (_) => setState(() => _filtro = filtros[index]),
              selectedColor: HealthyAdaptive.mint,
              backgroundColor: HealthyAdaptive.surface,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 2),
          child: Row(children: [
            Expanded(child: Text('${resultados.length} resultados',
                style: TextStyle(color: _gris, fontSize: 12))),
            PopupMenuButton<OrdenCatalogo>(
              tooltip: 'Ordenar por prioridad',
              icon: Icon(Icons.sort_rounded, color: _verde),
              onSelected: (value) => setState(() => _orden = value),
              itemBuilder: (_) => [
                const PopupMenuItem(value: OrdenCatalogo.relevancia,
                    child: Text('Orden original')),
                const PopupMenuItem(value: OrdenCatalogo.nombre,
                    child: Text('Nombre A–Z')),
                if (_tabs.index == 0) ...[
                  const PopupMenuItem(value: OrdenCatalogo.proteina,
                      child: Text('Mayor proteína')),
                  const PopupMenuItem(value: OrdenCatalogo.grasas,
                      child: Text('Mayor cantidad de grasas')),
                  const PopupMenuItem(value: OrdenCatalogo.carbohidratos,
                      child: Text('Más carbohidratos')),
                  const PopupMenuItem(value: OrdenCatalogo.fibra,
                      child: Text('Más fibra')),
                ],
              ],
            ),
            const SizedBox(width: 4),
            ToggleButtons(
              constraints: const BoxConstraints(minWidth: 39, minHeight: 38),
              borderRadius: BorderRadius.circular(12),
              isSelected: [for (final value in VistaCatalogo.values)
                value == _vista],
              onPressed: (index) => setState(
                  () => _vista = VistaCatalogo.values[index]),
              children: const [
                Tooltip(message: 'Lista', child: Icon(Icons.view_list, size: 19)),
                Tooltip(message: 'Imágenes', child: Icon(Icons.grid_view, size: 19)),
                Tooltip(message: 'Detalles', child: Icon(Icons.view_agenda, size: 19)),
                Tooltip(message: 'Explorar grupos', child: Icon(Icons.hub, size: 19)),
              ],
            ),
          ]),
        ),
        if (_tabs.index == 0 &&
            CatalogoExplorador.campoOrden(_orden) != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
            child: Text(
              'Valores aproximados por 100 g según la referencia de cada '
              'ficha. Algunos alimentos se comparan crudos y otros cocidos.',
              style: TextStyle(color: _gris, fontSize: 11),
            ),
          ),
        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: KeyedSubtree(
            key: ValueKey('${_tabs.index}-$_vista-$_filtro-$_orden-${_buscador.text}'),
            child: lista,
          ),
        )),
      ]),
      floatingActionButton: _comparar.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarComparacion(actuales),
              icon: const Icon(Icons.compare_arrows),
              label: Text('Comparar (${_comparar.length})'),
            )
          : null,
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
