class CatalogoItem {
  final String id;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String dificultad;
  final String icono;
  final String imagen;
  final List<String> etiquetas;
  final List<String> beneficios;
  final List<String> pasos;
  final List<String> precauciones;
  final List<String> habitosRelacionados;
  final String fuente;
  final String fuenteUrl;
  final Map<String, String> detalles;

  const CatalogoItem({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.dificultad,
    required this.icono,
    required this.imagen,
    required this.etiquetas,
    required this.beneficios,
    required this.pasos,
    required this.precauciones,
    required this.habitosRelacionados,
    required this.fuente,
    required this.fuenteUrl,
    this.detalles = const {},
  });
}
