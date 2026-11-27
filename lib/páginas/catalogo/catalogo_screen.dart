import 'package:flutter/material.dart';
import '../../guia/guide_target.dart';
import '../../servicios/healthy_retro_sound_service.dart';
import 'catalogo_media.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/cosmos_theme.dart';
import 'datos/catalogo_datos.dart';
import 'datos/bebidas_catalogo.dart';
import 'catalogo_selector_bienestar.dart';
import 'detalles/catalogo_detalle_screen.dart';
import 'modelos/catalogo_item.dart';
import 'catalogo_explorador.dart';
import 'catalogo_mapas.dart';
import 'catalogo_comparacion.dart';

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
  String? _grupoVisual;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging && mounted) {
        setState(() {
          _filtro = 'Todos';
          _orden = OrdenCatalogo.relevancia;
          _comparar.clear();
          _grupoVisual = null;
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
      case 2:
        return consejosCatalogo;
      default:
        return bebidasCatalogo;
    }
  }

  void _abrirDetalle(CatalogoItem item) {
    HealthyRetroSoundService.play('open');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogoDetalleScreen(item: item),
      ),
    );
  }

  Widget _imagen(CatalogoItem item, double altura) => CatalogoMedia(
        item: item,
        altura: altura,
        usarHero: true,
      );

  Widget _tarjeta(CatalogoItem item) {
    final imagenes = _vista == VistaCatalogo.imagenes;
    final detalles = _vista == VistaCatalogo.detalles;
    final marcado = _comparar.contains(item.id);
    return CosmosCardShell(child: Material(
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
    ));
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
    final elegidos = resultados.where((item) {
      if (_grupoVisual == null) return true;
      if (_tabs.index == 0) {
        return CatalogoExplorador.grupoPlato(item) == _grupoVisual;
      }
      if (_tabs.index == 1) {
        return CatalogoExplorador.zonaEjercicio(item) == _grupoVisual;
      }
      if (_tabs.index == 2) {
        return CatalogoExplorador.grupoExploracion(item) == _grupoVisual;
      }
      return item.detalles['Grupo de bebida'] == _grupoVisual;
    }).toList();

    // El estado inicial y los resultados son pantallas distintas: el
    // encabezado, la descripción y el mapa se funden juntos al seleccionar.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _grupoVisual == null
          ? ListView(
              key: ValueKey('explorar-selector-${_tabs.index}'),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
              children: [
                Text(
                  _tabs.index == 0 ? 'Explora por grupos del plato'
                      : _tabs.index == 1 ? 'Explora por zona de movimiento'
                      : _tabs.index == 2 ? 'Explora por objetivos de bienestar'
                      : 'Explora con la Jarra del Buen Beber',
                  style: TextStyle(color: _oscuro,
                      fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  _tabs.index == 0
                      ? 'Agrupación orientativa. No representa porciones ni una dieta.'
                      : 'Selecciona una opción para conocer sus elementos.',
                  style: TextStyle(color: _gris, fontSize: 12),
                ),
                const SizedBox(height: 14),
                if (_tabs.index == 0)
                  MapaPlatoCatalogo(
                    seleccionado: null,
                    onSeleccionar: (value) =>
                        setState(() => _grupoVisual = value),
                  )
                else if (_tabs.index == 1)
                  MapaMovimientoCatalogo(
                    seleccionado: null,
                    onSeleccionar: (value) =>
                        setState(() => _grupoVisual = value),
                  )
                else if (_tabs.index == 2)
                  SelectorBienestarCatalogo(
                    seleccionado: null,
                    onSeleccionar: (value) =>
                        setState(() => _grupoVisual = value),
                  )
                else
                  JarraBuenBeberCatalogo(
                    seleccionado: null,
                    onSeleccionar: (value) =>
                        setState(() => _grupoVisual = value),
                  ),
              ],
            )
          : ListView(
              key: ValueKey('explorar-resultados-${_tabs.index}-$_grupoVisual'),
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 110),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('explorar-regresar'),
                    onPressed: () => setState(() => _grupoVisual = null),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Volver al selector'),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$_grupoVisual',
                  style: TextStyle(
                    color: _oscuro, fontWeight: FontWeight.w900,
                    fontSize: 20,
                  )),
                const SizedBox(height: 3),
                Text('${elegidos.length} elementos disponibles',
                  style: TextStyle(color: _gris, fontSize: 12)),
                const SizedBox(height: 10),
                if (elegidos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text('No hay elementos en esta selección.',
                      style: TextStyle(color: _gris)),
                  ),
                // Renderizado directo de fichas: sin ExpansionTiles cerrados.
                // El primer elemento aparece inmediatamente al escoger grupo.
                for (final item in elegidos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: HealthyAdaptive.surface,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        key: ValueKey('explorar-item-${item.id}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: HealthyAdaptive.mint,
                          child: Icon(CatalogoMedia.icono(item),
                            color: _verde),
                        ),
                        title: Text(item.titulo, style: const TextStyle(
                          fontWeight: FontWeight.w800)),
                        subtitle: Text(item.descripcion,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _abrirDetalle(item),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _mostrarComparacion(List<CatalogoItem> actuales) {
    final seleccionados = actuales.where(
      (item) => _comparar.contains(item.id),
    ).toList();
    if (seleccionados.length < 2) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => CatalogoComparacion(
        items: seleccionados,
        onAbrir: (item) {
          Navigator.of(sheetContext).pop();
          _abrirDetalle(item);
        },
        onQuitar: (item) {
          Navigator.of(sheetContext).pop();
          if (!mounted) return;
          setState(() => _comparar.remove(item.id));
          if (_comparar.length >= 2) {
            _mostrarComparacion(actuales);
          }
        },
        onLimpiar: () {
          Navigator.of(sheetContext).pop();
          if (mounted) setState(_comparar.clear);
        },
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
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: HealthyAdaptive.mint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.search_off_rounded,
                        color: _verde, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text('No encontramos coincidencias',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _oscuro,
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Prueba otros términos o elimina los filtros activos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _gris)),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _buscador.clear();
                      _filtro = 'Todos';
                      _orden = OrdenCatalogo.relevancia;
                      _grupoVisual = null;
                    }),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Restablecer búsqueda'),
                  ),
                ],
              ),
            ),
          )
        : _vista == VistaCatalogo.explorar
            ? _vistaExplorar(resultados)
            : _vista == VistaCatalogo.imagenes
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width < 390
                          ? 1
                          : MediaQuery.sizeOf(context).width < 720 ? 2 : 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 256,
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
          key: HealthyGuideTargets.catalogTabs,
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: _verde,
          unselectedLabelColor: _gris,
          indicatorColor: _verde,
          tabs: const [
            Tab(text: 'Alimentos'),
            Tab(text: 'Ejercicios'),
            Tab(text: 'Consejos'),
            Tab(text: 'Bebidas'),
          ],
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: TextField(
            key: HealthyGuideTargets.catalogSearch,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Filtrar por etiquetas',
              style: TextStyle(color: _oscuro,
                fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
        KeyedSubtree(
          key: HealthyGuideTargets.catalogFilters,
          child: SizedBox(
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
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 2),
          child: KeyedSubtree(
            key: HealthyGuideTargets.catalogOptions,
            child: Row(children: [
            Expanded(child: Text('${resultados.length} resultados',
                style: TextStyle(color: _gris, fontSize: 12))),
            PopupMenuButton<OrdenCatalogo>(
              tooltip: 'Ordenar resultados (no aplica etiquetas)',
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
              onPressed: (index) => setState(() {
                _vista = VistaCatalogo.values[index];
                _grupoVisual = null;
              }),
              children: const [
                Tooltip(message: 'Lista', child: Icon(Icons.view_list, size: 19)),
                Tooltip(message: 'Imágenes', child: Icon(Icons.grid_view, size: 19)),
                Tooltip(message: 'Detalles', child: Icon(Icons.view_agenda, size: 19)),
                Tooltip(message: 'Explorar grupos', child: Icon(Icons.hub, size: 19)),
              ],
            ),
          ]),
          ),
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
            key: ValueKey('${_tabs.index}-$_vista-$_filtro-$_orden-${_buscador.text}-$_grupoVisual'),
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
}
