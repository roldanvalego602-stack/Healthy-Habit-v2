import '../modelos/catalogo_item.dart';

// Contenido inicial de demostración. Los nutrientes son aproximados por 100 g.
// Revisar fuentes y porciones antes de utilizar el catálogo como referencia clínica.
const alimentosCatalogo = <CatalogoItem>[
  CatalogoItem(
    id: 'avena',
    imagen: 'assets/images/catalogo/avena.jpg',
    titulo: 'Avena',
    categoria: 'Alimentos',
    dificultad: 'Fácil de preparar',
    icono: 'grain',
    descripcion:
        'Cereal integral versátil que aporta carbohidratos complejos y fibra.',
    etiquetas: ['Fibra', 'Energía', 'Económico'],
    beneficios: [
      'Aporta fibra soluble, incluida beta-glucano.',
      'Puede contribuir a la saciedad como parte de una alimentación equilibrada.',
    ],
    pasos: [
      'Preparar con agua o leche.',
      'Combinar con fruta natural.',
      'Evitar añadir grandes cantidades de azúcar.',
    ],
    precauciones: [
      'En caso de celiaquía, elegir avena certificada sin gluten y consultar indicaciones médicas.',
    ],
    habitosRelacionados: [
      'Desayunar de forma equilibrada',
      'Consumir alimentos ricos en fibra',
    ],
    fuente: 'USDA FoodData Central',
    fuenteUrl: 'https://fdc.nal.usda.gov/',
    detalles: {
      'Proteína': '≈ 16.9 g',
      'Grasas': '≈ 6.9 g',
      'Carbohidratos': '≈ 66.3 g',
      'Fibra': '≈ 10.6 g',
      'Referencia': '100 g de avena seca',
      'Disponibilidad': 'Habitualmente accesible; depende de la región',
    },
  ),
  CatalogoItem(
    id: 'huevo',
    imagen: 'assets/images/catalogo/huevo.jpg',
    titulo: 'Huevo',
    categoria: 'Alimentos',
    dificultad: 'Preparación sencilla',
    icono: 'egg',
    descripcion:
        'Alimento que aporta proteína de buena calidad, colina y vitamina B12.',
    etiquetas: ['Proteína', 'Vitaminas', 'Versátil'],
    beneficios: [
      'Contribuye al aporte diario de proteína.',
      'Aporta colina, importante para funciones celulares.',
    ],
    pasos: [
      'Consumir bien cocido.',
      'Acompañar con verduras o cereales integrales.',
    ],
    precauciones: [
      'No apto para personas con alergia al huevo.',
      'Evitar preparaciones con huevo crudo por seguridad alimentaria.',
    ],
    habitosRelacionados: [
      'Incluir proteína en las comidas',
      'Preparar desayunos equilibrados',
    ],
    fuente: 'USDA FoodData Central',
    fuenteUrl: 'https://fdc.nal.usda.gov/',
    detalles: {
      'Proteína': '≈ 12.6 g',
      'Grasas': '≈ 9.5 g',
      'Carbohidratos': '≈ 0.7 g',
      'Referencia': '100 g de huevo entero crudo',
      'Disponibilidad': 'Variable según mercado local',
    },
  ),
  CatalogoItem(
    id: 'lentejas',
    imagen: 'assets/images/catalogo/lentejas.jpg',
    titulo: 'Lentejas',
    categoria: 'Alimentos',
    dificultad: 'Económico',
    icono: 'eco',
    descripcion:
        'Legumbre rica en fibra, proteína vegetal y diversos minerales.',
    etiquetas: ['Proteína', 'Fibra', 'Económico'],
    beneficios: [
      'Aportan proteína vegetal.',
      'Su fibra favorece una alimentación variada.',
    ],
    pasos: [
      'Cocer completamente.',
      'Combinar con verduras y alimentos ricos en vitamina C.',
    ],
    precauciones: [
      'Incrementar gradualmente el consumo de legumbres si producen molestias digestivas.',
    ],
    habitosRelacionados: ['Consumir legumbres', 'Aumentar el consumo de fibra'],
    fuente: 'USDA FoodData Central',
    fuenteUrl: 'https://fdc.nal.usda.gov/',
    detalles: {
      'Proteína': '≈ 9.0 g',
      'Grasas': '≈ 0.4 g',
      'Carbohidratos': '≈ 20.1 g',
      'Fibra': '≈ 7.9 g',
      'Referencia': '100 g de lentejas cocidas',
      'Disponibilidad': 'Frecuentemente accesibles, según región',
    },
  ),
];

const ejerciciosCatalogo = <CatalogoItem>[
  CatalogoItem(
    id: 'sentadillas',
    imagen: 'assets/images/catalogo/sentadillas.jpg',
    titulo: 'Sentadillas',
    categoria: 'Ejercicios',
    dificultad: 'Principiante',
    icono: 'fitness_center',
    descripcion:
        'Movimiento de fuerza para piernas y glúteos que puede practicarse en casa.',
    etiquetas: ['Fuerza', 'Sin equipo', 'Piernas'],
    beneficios: [
      'Trabaja los músculos de las piernas y glúteos.',
      'Puede contribuir a mejorar la fuerza funcional.',
    ],
    pasos: [
      'Coloca los pies a una distancia cómoda.',
      'Flexiona caderas y rodillas con control.',
      'Regresa a la posición inicial sin movimientos bruscos.',
      'Empieza con pocas repeticiones y adapta el rango de movimiento.',
    ],
    precauciones: [
      'Detente ante dolor.',
      'Usa una silla estable como referencia si necesitas apoyo.',
    ],
    habitosRelacionados: ['Realizar actividad física', 'Fortalecer piernas'],
    fuente: 'CDC - Physical Activity',
    fuenteUrl: 'https://www.cdc.gov/physical-activity/',
    detalles: {
      'Equipo': 'Ninguno',
      'Grupo muscular': 'Piernas y glúteos',
      'Impacto': 'Bajo',
    },
  ),
  CatalogoItem(
    id: 'plancha',
    imagen: 'assets/images/catalogo/plancha.jpg',
    titulo: 'Plancha abdominal',
    categoria: 'Ejercicios',
    dificultad: 'Adaptable',
    icono: 'accessibility_new',
    descripcion: 'Ejercicio de estabilidad para la zona media del cuerpo.',
    etiquetas: ['Fuerza', 'Sin equipo', 'Zona media'],
    beneficios: ['Trabaja la estabilidad del tronco.'],
    pasos: [
      'Apoya antebrazos y rodillas o puntas de los pies.',
      'Mantén el cuerpo alineado y respira normalmente.',
      'Sostén solo el tiempo que permita una técnica cómoda.',
    ],
    precauciones: [
      'Evita contener la respiración.',
      'Suspende ante dolor de espalda o articulaciones.',
    ],
    habitosRelacionados: [
      'Fortalecer la zona media',
      'Realizar actividad física',
    ],
    fuente: 'CDC - Physical Activity',
    fuenteUrl: 'https://www.cdc.gov/physical-activity/',
    detalles: {
      'Equipo': 'Colchoneta opcional',
      'Grupo muscular': 'Zona media',
      'Impacto': 'Bajo',
    },
  ),
  CatalogoItem(
    id: 'caminar',
    imagen: 'assets/images/catalogo/caminar.jpg',
    titulo: 'Caminar en casa',
    categoria: 'Ejercicios',
    dificultad: 'Principiante',
    icono: 'directions_walk',
    descripcion: 'Actividad aeróbica ligera adaptable al espacio disponible.',
    etiquetas: ['Cardio', 'Sin equipo', 'Bajo impacto'],
    beneficios: [
      'Ayuda a reducir el tiempo sedentario.',
      'Contribuye al movimiento diario.',
    ],
    pasos: [
      'Despeja una zona segura.',
      'Camina a ritmo cómodo.',
      'Aumenta el tiempo gradualmente según tu tolerancia.',
    ],
    precauciones: [
      'Evita superficies resbaladizas y obstáculos.',
      'Consulta a un profesional si tienes limitaciones importantes de movilidad.',
    ],
    habitosRelacionados: ['Caminar diariamente', 'Reducir el sedentarismo'],
    fuente: 'OMS - Actividad física',
    fuenteUrl:
        'https://www.who.int/news-room/fact-sheets/detail/physical-activity',
    detalles: {
      'Equipo': 'Calzado cómodo',
      'Grupo muscular': 'Cuerpo completo',
      'Impacto': 'Bajo',
    },
  ),
];

const consejosCatalogo = <CatalogoItem>[
  CatalogoItem(
    id: 'dormir_mejor',
    imagen: 'assets/images/catalogo/dormir_mejor.jpg',
    titulo: 'Dormir mejor',
    categoria: 'Consejos',
    dificultad: 'Práctica diaria',
    icono: 'bedtime',
    descripcion:
        'Recomendaciones para favorecer un descanso suficiente y regular.',
    etiquetas: ['Sueño', 'Descanso', 'Bienestar'],
    beneficios: [
      'Favorece la atención y la memoria.',
      'Apoya la recuperación física.',
      'Contribuye al bienestar emocional.',
    ],
    pasos: [
      'Mantén horarios similares para dormir y despertar.',
      'Procura un dormitorio oscuro, tranquilo y cómodo.',
      'Reduce la cafeína varias horas antes de acostarte.',
      'Establece una rutina relajante antes de dormir.',
      'Busca luz natural y movimiento durante el día.',
      'Si las siestas dificultan tu sueño nocturno, hazlas breves y temprano.',
    ],
    precauciones: [
      'La mayoría de los adultos necesita aproximadamente 7–9 horas de sueño; las necesidades varían con la edad.',
      'Consulta a un profesional si el insomnio persiste, hay somnolencia excesiva o se observan pausas respiratorias al dormir.',
    ],
    habitosRelacionados: [
      'Mantener horarios de sueño',
      'Crear una rutina nocturna',
    ],
    fuente: 'CDC - Sleep',
    fuenteUrl: 'https://www.cdc.gov/sleep/',
    detalles: {
      'Frecuencia': 'Diaria',
      'Lugar': 'En casa',
      'Costo': 'Generalmente sin costo',
    },
  ),
  CatalogoItem(
    id: 'prevenir_caidas',
    imagen: 'assets/images/catalogo/prevenir_caidas.jpg',
    titulo: 'Prevenir caídas',
    categoria: 'Consejos',
    dificultad: 'Práctica diaria',
    icono: 'health_and_safety',
    descripcion: 'Acciones para reducir riesgos de caídas y lesiones en casa.',
    etiquetas: ['Prevención', 'Seguridad', 'Movilidad'],
    beneficios: [
      'Ayuda a reducir situaciones de riesgo.',
      'Favorece entornos domésticos más seguros.',
    ],
    pasos: [
      'Mantén pasillos despejados y bien iluminados.',
      'Retira o fija alfombras sueltas.',
      'Utiliza calzado adecuado.',
      'Incluye actividad física de fuerza y equilibrio adaptada a tu capacidad.',
    ],
    precauciones: [
      'Si has sufrido caídas, mareos o problemas de equilibrio, solicita valoración profesional.',
      'No todas las fracturas pueden prevenirse con estas medidas.',
    ],
    habitosRelacionados: [
      'Realizar actividad física',
      'Mantener el hogar seguro',
    ],
    fuente: 'CDC - Older Adult Fall Prevention',
    fuenteUrl: 'https://www.cdc.gov/falls/',
    detalles: {
      'Frecuencia': 'Revisión periódica',
      'Lugar': 'Hogar',
      'Costo': 'Variable',
    },
  ),
  CatalogoItem(
    id: 'pausas_activas',
    imagen: 'assets/images/catalogo/pausas_activas.jpg',
    titulo: 'Hacer pausas activas',
    categoria: 'Consejos',
    dificultad: 'Fácil',
    icono: 'self_improvement',
    descripcion:
        'Interrumpe periodos prolongados sentado con movimientos breves.',
    etiquetas: ['Movimiento', 'Postura', 'Bienestar'],
    beneficios: [
      'Reduce periodos prolongados de inactividad.',
      'Permite cambiar de postura durante el día.',
    ],
    pasos: [
      'Levántate periódicamente si puedes hacerlo con seguridad.',
      'Camina unos minutos o realiza movimientos suaves.',
      'Adapta la frecuencia a tus actividades y necesidades.',
    ],
    precauciones: ['Evita movimientos que provoquen dolor o mareo.'],
    habitosRelacionados: ['Moverse durante el día', 'Reducir el sedentarismo'],
    fuente: 'OMS - Actividad física',
    fuenteUrl:
        'https://www.who.int/news-room/fact-sheets/detail/physical-activity',
    detalles: {
      'Frecuencia': 'A lo largo del día',
      'Lugar': 'Casa o trabajo',
      'Costo': 'Sin costo',
    },
  ),
];
