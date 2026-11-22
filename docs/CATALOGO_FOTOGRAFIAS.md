# Fotografías proporcionadas para el Catálogo

## Contenido

El paquete `healthy_habit_catalogo_fotos.zip` contiene nueve fotografías enviadas por el equipo y optimizadas para la aplicación. Debe extraerse **desde la raíz del proyecto Flutter**; los nueve recursos quedarán en `assets/images/catalogo/`.

| Elemento del catálogo | Archivo |
| --- | --- |
| Avena | avena.jpg |
| Huevo | huevo.jpg |
| Lentejas | lentejas.jpg |
| Sentadillas | sentadillas.jpg |
| Plancha abdominal | plancha.jpg |
| Caminar en casa | caminar.jpg |
| Dormir mejor | dormir_mejor.jpg |
| Prevenir caídas | prevenir_caidas.jpg |
| Hacer pausas activas | pausas_activas.jpg |

## Instalación local

```bash
# Ejecutar en la raíz de Healthy-Habit:
unzip -o /ruta/al/archivo/healthy_habit_catalogo_fotos.zip
flutter pub get
flutter test test/catalogo_fotos_test.dart
flutter run

# Incorporar los JPG al repositorio:
git add assets/images/catalogo/*.jpg
git commit -m "assets: fotografías para las nueve fichas del catálogo"
git push origin feature/mr-healthy-foundations
```

Los cambios de código (`catalogo_datos.dart`, `catalogo_screen.dart` y `catalogo_detalle_screen.dart`) ya están guardados en la rama. **Los JPG no pueden adjuntarse por la conexión actual a GitHub:** deben subirse mediante el procedimiento anterior. Hasta instalarlos, el catálogo muestra los iconos de respaldo en lugar de las fotos.

Se mantiene la compatibilidad con los SVG originales; ni las estadísticas nutricionales ni los datos educativos de las fichas se han modificado. El archivo `pubspec.yaml` ya incluye la carpeta `assets/images/catalogo/`.

Nota de presentación: la foto suministrada para «Caminar en casa» representa una caminata al aire libre. Se conservó la correspondencia de archivos solicitada, pero conviene reemplazarla en el futuro si se busca consistencia exacta entre imagen y actividad.
