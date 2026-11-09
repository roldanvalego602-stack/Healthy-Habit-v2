#!/usr/bin/env python3
"""Ejecutar desde la raíz del proyecto: python3 integrar_configuracion_main.py"""
from pathlib import Path
import re
import shutil

main = Path('lib/main.dart')
if not main.exists():
    raise SystemExit('ERROR: ejecuta el script desde la raíz de tu proyecto Flutter.')
source = main.read_text(encoding='utf-8')
if "import 'servicios/preferencias_app.dart';" not in source:
    source = source.replace(
        "import 'firebase_options.dart';",
        "import 'firebase_options.dart';\nimport 'servicios/preferencias_app.dart';",
        1,
    )

start = source.find('class HabitTrackerApp extends StatelessWidget {')
end = source.find('// ---------- Paleta de Colores ----------', start)
if start < 0 or end < 0:
    raise SystemExit('ERROR: no se encontró HabitTrackerApp o el marcador de paleta; no se modificó nada.')
replacement = """class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PreferenciasApp(
      builder: (context, themeMode, textScale) {
        final light = ThemeData(
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFFF7F9F8),
          useMaterial3: true,
          brightness: Brightness.light,
        );
        final dark = ThemeData(
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFF15242B),
          useMaterial3: true,
          brightness: Brightness.dark,
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Healthy Habit',
          theme: light,
          darkTheme: dark,
          themeMode: themeMode,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}

"""
source = source[:start] + replacement + source[end:]

# El main original declara otra ProfileScreen local que colisiona con la importada.
duplicate = source.find('class ProfileScreen extends StatelessWidget {')
topbar = source.find('// ---------- Top Bar ----------', duplicate)
if duplicate >= 0:
    if topbar < 0:
        raise SystemExit('ERROR: se encontró ProfileScreen duplicada sin marcador Top Bar.')
    source = source[:duplicate] + source[topbar:]

# No sobrescribir si el archivo cambió de estructura inesperadamente.
if source.count('class HabitTrackerApp extends StatelessWidget') != 1:
    raise SystemExit('ERROR: estructura inesperada de HabitTrackerApp.')
if source.count('class ProfileScreen extends StatelessWidget') != 0:
    raise SystemExit('ERROR: todavía existe ProfileScreen local.')

target = Path('lib/servicios/preferencias_app.dart')
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(Path(__file__).parent / 'lib/servicios/preferencias_app.dart', target)
backup = main.with_name('main.dart.bak_antes_configuracion')
if not backup.exists():
    backup.write_text(main.read_text(encoding='utf-8'), encoding='utf-8')
main.write_text(source, encoding='utf-8')
print('Integración aplicada. Respaldo:', backup)
print('Ahora ejecuta: dart format lib/main.dart lib/servicios/preferencias_app.dart')
print('Y después: flutter analyze')
