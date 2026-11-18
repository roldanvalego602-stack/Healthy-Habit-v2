# Tema claro y oscuro — fase 1 (17 nov 2026)

## Alcance implementado
- Controlador global de apariencia con tres modos: Claro, Oscuro y Sistema.
- Guardado local persistente mediante shared_preferences (clave healthy_habit_theme_v1); **no requiere conexión ni sesión Firebase**.
- Configuración existente > Experiencia visual > Tema aplica la selección al instante y realiza un respaldo best-effort de la preferencia en Firestore, sin impedir cambios offline.
- MaterialApp aplica theme, darkTheme y themeMode globalmente.
- Logros, vitrina de rarezas y Configuración incorporan colores adaptados.
- La preferencia inicialmente no configurada conserva el aspecto claro para evitar una migración inesperada.

## Importante
Varios módulos tienen colores fijos definidos por pantalla. Por tanto, **activar MaterialApp.darkTheme NO convierte automáticamente todos esos widgets a oscuro**. La infraestructura global funciona, pero queda pendiente la migración visual completa de Inicio, Hábitos, Tienda, Desafíos, Perfil y pantallas secundarias. No presentar la fase 1 como soporte oscuro completo.

El guardado local define el aspecto del dispositivo actual. La copia en Firestore no sincroniza automáticamente la elección con otros dispositivos: se necesitaría un protocolo explícito de sincronización y resolución de conflictos para ello.

## Pruebas a ejecutar en Linux Mint
Desde la raíz del repo:

```bash
git fetch origin feature/mr-healthy-foundations
git merge --ff-only FETCH_HEAD
flutter pub get
flutter test test/healthy_theme_test.dart
flutter test test/logros_theme_test.dart
flutter test test/logros_responsive_test.dart
flutter run
```

Si existe trabajo local sin confirmar en cualquiera de los archivos modificados, primero comparar diferencias o hacer respaldo de esos archivos específicos; no descartar ni resetear.

En Android: Perfil > Configuración > Experiencia visual > Tema > Claro/Oscuro/Sistema; visitar Logros y su vitrina; cambiar tema, navegar y reiniciar la aplicación; revisar textos, fondos, estados y orientación. No se ha ejecutado Flutter ni se ha verificado Android físico desde GitHub.

## Siguiente fase
Migrar los demás módulos usando Theme.of(context).colorScheme y un conjunto común de tokens; no introducir cambio por colorFilter ni invertir colores de imágenes/insignias.
