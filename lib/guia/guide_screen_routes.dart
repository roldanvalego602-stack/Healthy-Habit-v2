import 'package:flutter/material.dart';
import 'guide_step.dart';
import 'guide_target.dart';

/// Recorridos editoriales sobre controles reales, sin acciones automáticas.
/// Las capturas son opcionales y solo se habilitan para contenido no sensible.
class HealthyGuideScreenRoutes {
  const HealthyGuideScreenRoutes._();

  static const supported = <String>{'inicio', 'tienda', 'catalogo', 'perfil'};

  static List<HealthySpotlightStep> forSection(String section) {
    switch (section) {
      case 'inicio':
        return [
          HealthySpotlightStep(
            title: 'Tu punto de partida',
            description: 'En esta cabecera encuentras el acceso a tu '
                'perfil y tus avisos. El recorrido es informativo y no '
                'realiza cambios en tu cuenta.',
            icon: Icons.home_rounded,
            targetKey: HealthyGuideTargets.homeHeader,
          ),
          HealthySpotlightStep(
            title: 'Nivel y experiencia',
            description: 'Esta tarjeta presenta tu nivel y tu avance '
                'de experiencia. Puedes ver sus indicadores de cerca; '
                'la ampliación es solo una imagen.',
            icon: Icons.insights_rounded,
            targetKey: HealthyGuideTargets.homeLevel,
            extract: true,
          ),
          HealthySpotlightStep(
            title: 'Tus Habit Coins',
            description: 'Aquí consultas tu saldo virtual. '
                'Al tocarlo fuera de la guía puedes ir a Tienda; '
                'las monedas no equivalen a dinero real.',
            icon: Icons.toll_rounded,
            targetKey: HealthyGuideTargets.homeCoins,
          ),
          HealthySpotlightStep(
            title: 'Muévete por Healthy Habit',
            description: 'La barra inferior permite abrir Hábitos, '
                'Tienda, Catálogo o Perfil. Este botón de ayuda cambia '
                'su recorrido según la sección.',
            icon: Icons.touch_app_rounded,
            targetKey: HealthyGuideTargets.mainNavigation,
          ),
        ];
      case 'tienda':
        return [
          HealthySpotlightStep(
            title: 'Saldo y tienda',
            description: 'El encabezado muestra tu saldo de Habit Coins. '
                'Son recompensas virtuales y no dinero real.',
            icon: Icons.toll_rounded,
            targetKey: HealthyGuideTargets.shopHeader,
          ),
          HealthySpotlightStep(
            title: 'Filtra los artículos',
            description: 'Selecciona una categoría para explorar '
                'recompensas disponibles. Esta ampliación es solo '
                'informativa; no cambia tus filtros.',
            icon: Icons.category_outlined,
            targetKey: HealthyGuideTargets.shopCategories,
            extract: true,
          ),
          HealthySpotlightStep(
            title: 'Recompensas disponibles',
            description: 'Aquí aparece el catálogo de recompensas. '
                'Antes de confirmar una compra, revisa el costo, '
                'si tienes monedas suficientes y si ya posees el artículo.',
            icon: Icons.storefront_outlined,
            targetKey: HealthyGuideTargets.shopRewards,
          ),
          HealthySpotlightStep(
            title: 'Personaliza en Armario',
            description: 'Este botón abre el Armario, donde puedes '
                'equipar cosméticos y personalizar tu presentación. '
                'La guía no equipa ni compra ningún artículo.',
            icon: Icons.checkroom_outlined,
            targetKey: HealthyGuideTargets.shopWardrobe,
          ),
        ];
      case 'catalogo':
        return [
          HealthySpotlightStep(
            title: 'Secciones del catálogo',
            description: 'Cambia entre Alimentos, Ejercicios, Consejos '
                'y Bebidas usando estas pestañas.',
            icon: Icons.menu_book_rounded,
            targetKey: HealthyGuideTargets.catalogTabs,
          ),
          HealthySpotlightStep(
            title: 'Busca información',
            description: 'Escribe el nombre de un alimento o ejercicio, '
                'un beneficio o un objetivo para buscar en las fichas.',
            icon: Icons.search_rounded,
            targetKey: HealthyGuideTargets.catalogSearch,
          ),
          HealthySpotlightStep(
            title: 'Filtra por etiquetas',
            description: 'Estos filtros ayudan a reducir resultados '
                'según las etiquetas disponibles. Puedes cambiar '
                'los filtros una vez que cierres la guía.',
            icon: Icons.filter_alt_outlined,
            targetKey: HealthyGuideTargets.catalogFilters,
          ),
          HealthySpotlightStep(
            title: 'Orden y presentación',
            description: 'Aquí puedes ordenar los resultados y elegir '
                'una vista de lista, imágenes, detalles o grupos. '
                'Para comparar fichas compatibles, selecciónalas '
                'desde sus tarjetas.',
            icon: Icons.tune_rounded,
            targetKey: HealthyGuideTargets.catalogOptions,
          ),
        ];
      case 'perfil':
        return [
          HealthySpotlightStep(
            title: 'Tu identidad en Healthy Habit',
            description: 'Revisa tu presentación y los datos visibles '
                'de tu perfil. La guía no captura ni amplía '
                'información personal.',
            icon: Icons.person_outline_rounded,
            targetKey: HealthyGuideTargets.profileIdentity,
          ),
          HealthySpotlightStep(
            title: 'Accesos de perfil',
            description: 'En la cabecera puedes encontrar los controles '
                'de navegación y las acciones disponibles para tu perfil.',
            icon: Icons.edit_outlined,
            targetKey: HealthyGuideTargets.profileHeader,
          ),
          HealthySpotlightStep(
            title: 'Amigos y comunidad',
            description: 'Consulta amistades y accesos a las funciones '
                'sociales. Enviar solicitudes requiere una acción '
                'explícita fuera del recorrido.',
            icon: Icons.people_outline_rounded,
            targetKey: HealthyGuideTargets.profileFriends,
          ),
          HealthySpotlightStep(
            title: 'Configuración',
            description: 'Aquí encuentras los ajustes de la aplicación. '
                'La guía no modifica preferencias ni tu sesión.',
            icon: Icons.settings_outlined,
            targetKey: HealthyGuideTargets.profileSettings,
          ),
        ];
      default:
        return const <HealthySpotlightStep>[];
    }
  }
}
