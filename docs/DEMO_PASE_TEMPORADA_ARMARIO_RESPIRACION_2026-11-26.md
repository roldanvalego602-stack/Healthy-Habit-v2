# Healthy Habit — cambios visuales para la demostración (26 nov 2026)

**Rama:** `main`. **Estado:** implementación en código; falta revisión en Android real.  
**Decisión vigente:** beta y reglas restrictivas de producción pausadas; no desplegar.

## 1. Monetización simulada

Nueva pantalla `lib/páginas/tienda/season_pass_preview_screen.dart`, abierta
desde la portada de `StoreScreen`. Presenta «Temporada 01: Cultiva tu
leyenda», cinco niveles ilustrativos, carriles gratuito/premium y productos
cosméticos exclusivos propuestos (aura, sombrero, banner, marco y skin).

El pase se muestra con **precio ficticio 99 MXN**, y las ofertas simuladas
de Habit Coins son **100 / 19 MXN**, **550 / 79 MXN** y **1200 / 149 MXN**.
Esos números son **propuestas para una demostración**; no son precios
publicados ni compromisos comerciales.

**No hay** proveedor de pagos, compras in-app, registro de propiedad,
desbloqueo, otorgamiento de artículos, nivel de temporada ni créditos.
Todos los botones de producto solo muestran la explicación de simulación:
**sin cargo ni cambios de saldo**. No dar a entender que ya se puede pagar.
Para implementarlo de verdad se necesitarán verificación server-side
de comprobantes de tiendas, antifraude, política de reembolso, moneda real,
permisos y catálogo de recompensas separado de los artículos existentes.

## 2. Respiración guiada

`lib/páginas/habitos/habit_interaction_card.dart` corregido: el contador
usa `Stopwatch` para contar tiempo transcurrido y actualiza al padre.
Cuando el padre devuelve ese mismo valor mediante `initialValue`,
`didUpdateWidget` **ya no reinicia** el cronómetro. La recuperación de
un valor realmente externo sigue disponible; deben comprobarse iniciar,
pausar, reanudar, completar, salir/regresar y navegación por pasos.

## 3. Armario y personalización

`wardrobe_screen.dart`: nuevo deslizador de giro de **-180° a +180°**,
además de arrastrar y cambiar escala. El valor se conserva en JSON local
`hh_wardrobe_layout_v1_{uid}` junto con posición y tamaño.
**Esta transformación personalizada no se sincroniza entre dispositivos**:
solo el objeto equipado se almacena en el perfil Firestore.

Las pantallas principales de perfil dejaron de mostrar el selector
duplicado de banner, marco, estante y título. Todas estas tareas se
gestionan desde el Armario; allí se agregó la ranura «Título» con las
opciones de texto preexistentes. No se han creado títulos de pago.

`HealthyMascotLive` representa la vestimenta realmente equipada y
aplica los ajustes locales: chat, perfil, navegación principal, inicio,
registro de hábito y celebración de logros. Usa la animación suave
`HealthyMascotIdle` y no se conecta a Firestore si no hay sesión.
El avatar del chatbot aparece observando el borrador y mientras el
asistente prepara una respuesta. Verificar escalas y recortes en Android.

## 4. Estante / expositor de logros

`healthy_achievement_display.dart` crea un estante ilustrado con panel,
peana y tres medallas. `ShopItemArtwork` lo usa en la ficha del artículo
`achievement_display`; el perfil lo muestra cuando ese artículo está
equipado. Se alimenta del número existente de logros, sin otorgar
premios ni modificar el catálogo económico.

## 5. Pruebas pendientes en el dispositivo

Desde la raíz del repositorio:

```bash
git fetch origin main
git merge --ff-only origin/main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test
node --test tools/tests/demo_monetization_wardrobe_breathing.test.mjs
flutter run
```

Checklist manual:
1. Tienda → Pase de temporada: cambiar entre pistas, abrir tarjetas,
   tocar precios y **confirmar que el saldo no cambió**.
2. Hábitos → Respiración: medir 15 segundos sin reinicio;
   pausar, reanudar, verificar 4+2+6 segundos.
3. Armario → equipar prenda, mover, agrandar, girar 90°, salir y reabrir.
4. Abrir chat, perfil, inicio, registro y logro: la misma prenda debe
   visualizarse, incluyendo su transformación personalizada cuando sea
   aplicable.
5. Perfil → «Personalización» abre exclusivamente Armario; el título
   debe guardarse sin requerir moneda.
6. Comprar/exhibir `achievement_display` con una cuenta de laboratorio
   autorizada; confirmar dibujo, sin inventar medallas.
7. Teléfono pequeño, teclado abierto, modo oscuro y modo Lite.

**La CI de Flutter es el filtro de sintaxis, no una prueba del resultado
visual en Android.** No activar `HH_BETA_HABITS_CLIENT` ni modificar
las reglas de producción por estos cambios.

## 6. Pendientes posteriores

- Sincronización remota de rotaciones entre dispositivos.
- Progreso auténtico de temporada y reglas de premios premium.
- Integración de compras reales en un proceso separado y autorizado.
- Refinar sprites faciales de Mr. Healthy (parpadeo/mirada animada).
- Probar el diálogo de pase y los sonidos retro en un Android físico.

## 7. Ajustes posteriores: entrada numérica, colección de títulos y pausas del chat

En `wardrobe_screen.dart` se conservan los deslizadores pero ahora hay
botones para escribir **tamaño exacto en px (30–250)** y **ángulo exacto
en grados (−180 a +180)**. Se validan límites y números no finitos y se
guardan mediante el mismo formato de ajustes locales existente.

Los títulos se gestionan en el Armario, con tarjetas de colección,
candados, requisitos y selección. Catálogo:
- «Semilla saludable»: inicial.
- «Cultivador de constancia»: nivel 3.
- «Explorador del bienestar»: nivel 5.
- «Leyenda saludable»: nivel 10.
- «Primer paso cumplido»: insignia oficial `primera_meta`.
- «Guardián de la constancia»: insignia oficial `racha_7`.
- «Espíritu del festival»: insignia `festival_participant_2026`.
- «Campeón de temporada»: insignia `season_champion_01`.

Las insignias de festivales y temporadas todavía NO se emiten; sus
títulos permanecerán bloqueados. El cliente comprueba el nivel y, cuando
se pueda leer, la noticia oficial de desbloqueo. El perfil escucha
`profileTitle` y muestra la elección autorizada, o un título inicial
de respaldo. Esto ofrece bloqueo **en la interfaz**, no antifraude
definitivo: las reglas del servidor deberán impedir escrituras falsas
antes de la beta pública; el perfil normal todavía mantiene rutas de
escritura heredadas.

Mr. Healthy muestra el indicador animado de «está escribiendo» y su
mascota equipada durante la espera. Para respuestas locales rápidas,
el mínimo aumenta según el tamaño del texto a **1.1–2.4 segundos**;
si el cálculo genuino ya tardó más, no se añade espera artificial.
El retardo no cambia contenido ni consulta a un modelo remoto.

Pruebas incluidas: `test/perfil/profile_titles_test.dart`.
Verificar en Android que los campos numéricos se abren sin desbordamiento
al aparecer el teclado; desbloquear nivel 3 y elegir título, observarlo
en Perfil; comprobar que festivales permanezcan bloqueados y que el
chat muestre los puntos animados mientras responde.
