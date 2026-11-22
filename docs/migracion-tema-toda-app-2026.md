# Migración visual claro/oscuro — inspección de integración

Fecha de corte: 17 noviembre 2026. Rama: `feature/mr-healthy-foundations`.

## Implementado en GitHub (no validado aún en el móvil)
- `lib/tema/healthy_theme.dart`: selector persistente (Claro, Oscuro, Sistema) y tokens `HealthyAdaptive` para fondos, superficies, texto, bordes, acentos y tarjetas suaves.
- Entradas: `lib/main.dart` y `lib/páginas/inicio.dart`.
- Pestañas: Inicio, Hábitos, Tienda, Catálogo y Perfil.
- Secciones: Desafíos, Logros, Configuración, Armario, Estadísticas, Mr. Healthy (chat), Notificaciones, Ranking, Camino de niveles, Detalle del catálogo, Celebración de logros.
- Social y perfil: Amigos, Feed de amigos, perfil público, búsqueda de amigos, edición de perfil, directorio de profesionales.
- Acceso: Login, Registro de cuenta y recuperación de contraseña.
- Componentes reutilizables: `TarjetaContenedor` y `HabitInteractionCard`.

Las pantallas principales conservan sus colores de gamificación y sus datos, navegación, métodos de Firestore y operaciones económicas; los cambios son de presentación, no de negocio.

## Limitaciones importantes
1. **`lib/páginas/habitos/registrar_habito_screen.dart`** se dejó intacto porque el desarrollador tiene cambios locales sin fusionar en ese archivo. Sus componentes compartidos ya se adaptan, pero la pantalla completa requiere una conciliación posterior.
2. Existen pantallas secundarias y widgets con colores aún literales en el proyecto, incluidas algunas superficies ilustrativas de nivel, premios y detalles. La migración global es amplia, **no garantiza cobertura visual del 100%** sin una inspección en dispositivo.
3. Splash usa deliberadamente la identidad gráfica original y no alterna fondos.
4. La preferencia del dispositivo es local y funciona offline; la copia opcional a Firestore no sincroniza automáticamente la elección entre dispositivos.
5. Ningún test de Flutter ni prueba visual Android ha sido ejecutado por el asistente. Los commits de GitHub no equivalen a compilación verificada.

## Pruebas solicitadas
Desde el raíz del proyecto:

```bash
git status -sb
git fetch origin feature/mr-healthy-foundations
git merge --ff-only FETCH_HEAD
flutter pub get
flutter analyze --no-fatal-infos
flutter test test/healthy_theme_test.dart test/healthy_adaptive_components_test.dart test/logros_theme_test.dart test/logros_responsive_test.dart
flutter run
```

Si Git informa un conflicto, **no** usar `reset --hard`, `clean -fd` ni sobrescribir archivos locales. Primero respaldar **solo** los archivos afectados y consultar sus diferencias. No ejecutar todas las pruebas si el merge no se completó.

## Recorrido en el celular
1. Configuración > Experiencia visual > Tema > Claro; recorrer Inicio, Hábitos, Tienda, Catálogo y Perfil.
2. Cambiar a Oscuro. Repetir, comprobando contraste, menús, categorías, cuadros de diálogo, botones y ausencia de overflow.
3. Abrir Logros, cinco rarezas y las animaciones; después Desafíos.
4. Abrir Registro de hábito (pantalla excepcional), Armario, Estadísticas, Ranking y niveles.
5. Abrir Mr. Healthy, Notificaciones, Amigos, perfil público y búsqueda; revisar entrada y teclado.
6. Abrir acceso / registro / recuperar contraseña, sin crear cuentas de prueba ni cambiar credenciales si no se necesita.
7. Cambiar a Sistema y verificar respuesta al modo del teléfono.
8. Cerrar y volver a abrir. Verificar persistencia local.
9. Revisar también letra grande y ancho de 320–360 dp para detectar recortes.

Criterio de fase: pruebas Flutter sin errores **y** recorrido visual en Android. Corregir cada pantalla que conserve fondos claros con textos claros o a la inversa. No dar por finalizada una excepción por el mero hecho de adoptar `HealthyAdaptive`.
