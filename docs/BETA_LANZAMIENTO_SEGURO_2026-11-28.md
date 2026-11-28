# Healthy Habit · Preparación de beta cerrada y sustitución segura de Firebase

**Corte:** 28 de noviembre de 2026 (revisión de código).  
**Rama de trabajo:** `main`; todos los cambios se registran mediante commits en español.  
**Proyecto objetivo:** `cloud-firestore-d8c61`.  
**Base Firestore utilizada por Flutter y Functions:** la base **nombrada** `default`, que NO es la base especial `(default)`.  
**Distribución acordada:** beta Android cerrada para **15–20 participantes mediante APK firmado descargado a través de un código QR**, sin publicar la app en Google Play ni otras tiendas. El QR abre un enlace de descarga; no instala automáticamente ni concede permisos.

**Decisión:** NO ejecutar despliegues a producción hasta completar los pasos de aceptación de este documento. Los archivos preparados **no cambian las reglas activas** de Firebase Console.

## 1. Vulnerabilidad confirmada de las reglas actuales

Las reglas activas que proporcionó el propietario autorizan cualquier lectura y escritura por cualquier usuario con sesión iniciada mediante `match /{document=**}`. En Firebase, las reglas coincidentes se combinan por OR: una regla amplia deja sin efecto la restricción de otra ruta. Bajo esas reglas es posible falsificar XP, monedas, inventarios, registros, desafíos y datos de otras cuentas. Los datos emitidos durante ese período **no se convierten en confiables** por el mero hecho de cerrar las reglas.

**No debe mantenerse ni redeplegarse el permiso universal**. Reemplazarlo solo al final de una revisión sin probar el cliente tampoco es seguro, porque deshabilitaría sus escrituras económicas heredadas.

## 2. Archivos preparados en main

| Archivo | Función |
|---|---|
| `firestore.beta.rules` | Firestore: dueño lee perfil, ajustes validados y chat; el cliente NO escribe XP, monedas, rachas, intentos, inventario, logros, premios o constancias. Privacidad social por UID. |
| `storage.beta.rules` | Foto de perfil JPEG propia; evidencia de hábitos solo mediante Functions y reglas de Storage sin acceso directo. |
| `firebase.beta.emulator.json` | Emulador Auth, Firestore, Functions y Storage en proyecto aislado `demo-healthy-habit`, base nombrada `default`. |
| `firebase.beta.json` | Configuración separada para despliegue futuro **sólo tras autorización** y revisión de base/ambientes. |
| `functions/profile_title_transaction.js` | Títulos equipados por transacción de servidor y constancias oficiales en caso de insignias. |
| `tools/firestore-tests/beta_rules.test.mjs` | Casos negativos de escalación de permisos y casos positivos de perfiles y chats. |
| `.github/workflows/beta_security_emulator.yml` | Gate de emuladores en CI: reglas, cliente real simulado, Storage y catálogo de tienda. |
| `android/app/build.gradle.kts` y `android/key.properties.example` | Firma de release privada y rechazo de builds de distribución firmados con llave debug. |

Los flujos condicionados de beta `activateOfficialHabitBeta`, `cancelOfficialHabitBeta`, `registerOfficialHabitBeta`, `purchaseOfficialShopBeta`, `changeShopAppearanceBeta` y `claimVerifiedChallengeBeta` ya existían en el proyecto; se reutilizan, no se les conceden permisos globales. Se añadió `selectProfileTitleBeta` y la integración de foto de perfil elimina accesorios mediante Functions.

El cliente beta se activa **únicamente** con `--dart-define=HH_BETA_HABITS_CLIENT=true`, que habilita App Check. En release se rechaza el cliente antiguo sin esa bandera. El servidor tiene las comprobaciones independientes `HH_BETA_HABITS_ENABLED=true`, `HH_BETA_RULES_VERIFIED=true`, `HH_BETA_TEST_UIDS`, usuario autenticado y App Check. No declarar esas variables verdaderas hasta comprobar su significado con evidencia real.

### Economía y funcionalidades

- **Hábitos:** 36 identificadores del catálogo oficial, activación, registro y cancelación por transacciones idempotentes de servidor. En beta no escribir progreso desde Flutter.
- **Tienda:** compra y equipamiento por Functions, y fecha comercial obligatoria para ofertas de beta; nunca se aceptan importes del cliente. Una operación antigua procesada se recupera con el mismo `operationId`.
- **Títulos:** premios por nivel basados en el nivel del servidor. Los títulos especiales requieren constancia independiente de `system/title_attestations`. Sin emisor de constancias, permanecen bloqueados.
- **Desafíos:** se permite la simulación sin cobro, pero el pago verificado NO se habilita sin un emisor fiable de `system/challenge_attestations`. Se prohíbe confiar en documentos históricos con `progressVerified: true`.
- **Racha y recompensas:** la repetición de registros y la manipulación de fechas nunca deben incrementar premios. La reclamación diaria demo no es una función pública de beta.
- **Fotos de evidencia:** cliente desactivado por defecto; su activación exige cuota, consentimiento, Storage privado, `HH_BETA_EVIDENCE_ENABLED=true` y `HH_BETA_EVIDENCE_CLEANUP_ENABLED=true` con purga programada efectivamente comprobada. Una foto compatible no acredita consumo ni XP adicional.
- **Perfil, amigos, ranking, chat:** lectura pública de campos publicados, sin acceso a documentos privados de otros usuarios. La proyección pública de XP, racha, título y cosméticos tiene que corresponder al documento privado; publicar un perfil NO crea progresos oficiales.

## 3. Comprobaciones automáticas reproducibles

Desde un clon actualizado de `main`:

```bash
git fetch origin main
git pull --ff-only origin main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test
npm ci --prefix functions
npm --prefix functions test
npm install --prefix tools/firestore-tests --ignore-scripts
npx --yes firebase-tools@15.34.1 emulators:exec \
  --config firebase.beta.emulator.json \
  --only auth,firestore,functions,storage \
  --project demo-healthy-habit \
  "npm --prefix tools/firestore-tests run test:beta && npm --prefix tools/firestore-tests run test:cliente-integral && npm --prefix tools/firestore-tests run test:evidencias-storage && node --test functions/tests-emulator/shop_catalog.integration.js"
```

**El emulador es obligatorio para estos comandos**: no modificar `GCLOUD_PROJECT` a un proyecto real ni conectar las pruebas a un servicio de producción.

### Criterios negativos obligatorios

Se debe rechazar a cualquier cliente:

1. Lectura/escritura de perfiles privados ajenos, incluso con sesión válida.
2. Alteración de `xp`, `currentXp`, `level`, `habitCoins`, `shopInventory`, `shopEquipped`, racha y conteos de hábitos.
3. Creación/alteración de intentos, registros y logros de otros usuarios o del propio desde un SDK no privilegiado.
4. Fabricación de constancias en `system/**`, premios diarios, `activity_events` o recibos internos.
5. Compras duplicadas, cancelación dos veces, operaciones de UID distinto o descuentos tras vencer fecha.
6. Subida, descarga o eliminación de fotografías de evidencia sin permiso del servidor.

También deben pasar los recorridos positivos reales: registro, compra, equipamiento, favoritos, perfil, amistades, invitaciones, chat, lectura de reportes y fotos de perfil. El estado de CI debe corresponder al **último commit** y a las reglas exactas de despliegue.

### Auditoría histórica de solo lectura

Se incluye `functions/tools/auditar_legado_beta.js`, que cuenta documentos históricos y detecta anomalías sin imprimir UID, nombre ni correo. Necesita credenciales administrativas **solo para leer**; es recomendable ejecutarla con una identidad IAM autorizada únicamente a consultas, tras conocer la fecha UTC exacta del corte de reglas. No conceder permisos de escritura al operador. Revisar el coste de lectura y usar `--limit` de 1 a 1000 para evitar un escaneo accidental.

```bash
# Requiere estar autenticado en GCP con acceso de lectura y haber
# comprobado que las reglas restrictivas están activas en la base default.
cd functions
node tools/auditar_legado_beta.js \
  --project=cloud-firestore-d8c61 --database=default \
  --cutover-utc=YYYY-MM-DDTHH:MM:SSZ \
  --limit=300 --read-only-confirm
```

El valor `YYYY-MM-DDTHH:MM:SSZ` debe sustituirse por la fecha **real y verificada** del despliegue, no una fecha supuesta. Si se llega al límite, el reporte marca `truncated`, por lo que no se debe interpretar como auditoría global. Los perfiles previos y sus recompensas siguen sin certificar aunque no muestren anomalías.

## 4. Pasos manuales bloqueantes antes de publicar

Estos pasos requieren credenciales del propietario y **no se pueden certificar mediante commits GitHub**:

- [ ] **Respaldo de datos y permisos:** exportar snapshot y el ruleset ACTIVO de la base nombrada `default`; guardar la versión de Storage; habilitar registros de auditoría. No publicar secretos ni tokens.
- [ ] **Datos históricos no confiables:** no reutilizar saldos, logros, propiedades, progreso, constancias o amistades del período de reglas abiertas. Empezar la beta con **cuentas tester nuevas creadas después del cierre**, o una migración administrativa con procedencia verificable; nunca tratar `shopInventory` o `progressVerified` antiguos como certificados.
- [ ] **Prueba de seguridad en staging real:** probar operaciones de dos UIDs autorizados y un UID no autorizado sobre el mismo esquema y la misma base nombrada; consultar el ruleset ACTIVO tras desplegar.
- [ ] **App Check para APK externo:** registrar paquete y SHA-256 de la clave final de firma; configurar el proveedor Play Integrity para distribución **exclusivamente fuera de Google Play**: `PLAY_RECOGNIZED` **no requerido**, `LICENSED` **no requerido**, nivel mínimo **Device integrity** (`MEETS_DEVICE_INTEGRITY`). Google recomienda explícitamente estos parámetros para APK externos (https://firebase.google.com/docs/app-check/android/play-integrity-provider). Comprobar en teléfonos físicos que la atestación funciona antes de exigir App Check a todos. Registrar la aplicación/activar Play Integrity API si lo exige la configuración de Google Cloud/Play Console, pero **sin publicar** la app en una tienda. No distribuir tokens de depuración.
- [ ] **Firma Android:** crear archivo privado `android/key.properties` desde el ejemplo y una clave propia `.jks`; registrar huella SHA en Firebase. El APK de release **no** usa la firma debug y la compilación falla sin credenciales.
- [ ] **Privacidad y cumplimiento:** comprobar consentimiento, eliminación de fotos, retención, política de datos, tratamiento de cuentas, URLs de fotos de perfil y métricas mínimas de diagnóstico.
- [ ] **Pruebas en Android:** inicio y cierre de sesión, 36 hábitos, registrar/cancelar, rachas, monedas, compras, Armario/UFO, perfiles, búsqueda, invitaciones, desafíos de demostración, chat, redes lentas, reconexión, reintentos y múltiples cuentas. Probar accesibilidad y escala de texto.
- [ ] **Firebase Rules activas:** contrastar en Console (no solo CI) que la base nombrada `default` recibió las reglas restrictivas; comprobar ausencia de cualquier wildcard abierto y que `/system` no es escribible.
- [ ] **Allowlist y activación coordinada:** solo después de verificar todo, configurar las variables backend con UIDs nuevos de tester autorizados. Todas las demás cuentas deben recibir `permission-denied`.
- [ ] **Monitoreo:** errores `permission-denied` de accesos legítimos, fallos de Functions, retención Storage, uso Cloud Vision, presupuesto/coste y respuesta ante incidencias.

### Distribución privada mediante QR (15–20 personas; sin tiendas)

- [ ] Generar un **solo APK release firmado**, nunca un APK debug, con `--dart-define=HH_BETA_HABITS_CLIENT=true`; verificar su paquete y huella SHA-256.
- [ ] Subir el APK a una ubicación **HTTPS** controlada, idealmente con descargas limitadas o accesos gestionados; comprobar que el enlace abre el binario y no una página de autenticación difícil de usar en móviles.
- [ ] Crear un **QR que codifique la URL HTTPS del APK o de una página de instalación**. Un código QR no se crea con la ruta local del archivo; hace falta la URL definitiva. Probar el QR con las cámaras de al menos dos dispositivos.
- [ ] En la página de instalación incluir el nombre Healthy Habit, número de versión, tamaño, huella SHA-256, responsable de la prueba, contacto de soporte e instrucciones para autorizar **solo al navegador** a instalar aplicaciones desconocidas. Recomendar desactivar esa autorización al terminar.
- [ ] Registrar de forma privada los **15–20 UID** del grupo en la lista del servidor `HH_BETA_TEST_UIDS`. No confiar en el QR como contraseña; terceros pueden fotografiarlo, copiarlo o reenviar el enlace. La lista del servidor protege operaciones de beta; **no sustituye revisar lectura y registro de usuarios no autorizados**.
- [ ] Validar con un tester permitido y uno no permitido: descargar, instalar, autenticarse, consultar perfil, registrar hábito, comprar, equipar cosméticos y enviar comentarios. Comprobar expresamente las rutas que quedan públicas a cualquier cuenta autenticada.
- [ ] Conservar siempre la misma **clave de firma y applicationId** en versiones posteriores; incrementar `versionCode` para que Android permita la actualización sin desinstalar. Entregar actualizaciones mediante un QR/enlace nuevo, no mediante APK no firmado.
- [ ] Garantizar que el enlace no sea público en buscadores y que pueda revocarse; eliminar APK antiguos y el acceso de testers cuando finalice la evaluación. Un enlace privado reduce la difusión casual pero no puede impedir completamente que alguien reenvíe el archivo.

**No utilizar Google Play Internal Testing** para este piloto. La documentación de Firebase sobre Play Integrity para **instalaciones exclusivamente externas** indica `PLAY_RECOGNIZED: Not required`, `LICENSED: Not required` y nivel de dispositivo `Device integrity`: https://firebase.google.com/docs/app-check/android/play-integrity-provider. Android permite distribuir APK mediante sitios web y exige consentimiento para instalar desde el navegador: https://developer.android.com/distribute/marketing-tools/alternative-distribution.

## 5. Orden seguro de despliegue (NO EJECUTAR SIN LISTA ANTERIOR)

1. Confirmar CI verde, snapshot de reglas y respaldo de datos. Documentar quién aprueba el cambio.
2. Coordinar una ventana de mantenimiento: las versiones antiguas que escriben XP y monedas desde Flutter **dejarán de funcionar** bajo las reglas nuevas. No dejar versiones antiguas abiertas ni restaurar la regla global insegura para solucionarlo.
3. Desplegar y **verificar** rules de la base nombrada `default` y Storage usando exclusivamente `firebase.beta.json`. Verificar el ruleset remoto con Console o API; una respuesta exitosa del CLI no demuestra por sí sola que se actualizó la base correcta.
4. Desplegar Functions aprobadas con `firebase.json` y comprobar App Check en la región `us-central1`. Mantener las flags de beta apagadas hasta revisar el backend y datos.
5. Habilitar un grupo reducido de UIDs nuevos mediante configuración backend, activar el cliente de beta y comprobar un flujo completo.
6. Monitorizar; ante fallo grave, suspender las funciones de beta y acceso a testers. **No restaurar reglas abiertas** como solución de emergencia.

Para el operador autorizado, **solo después de aprobar todos los puntos**:

```bash
# Ejemplos controlados; revisar destino y Firebase CLI antes de usar.
firebase use cloud-firestore-d8c61
firebase deploy --only firestore:default --config firebase.beta.json --project cloud-firestore-d8c61
firebase deploy --only storage --config firebase.beta.json --project cloud-firestore-d8c61
firebase deploy --only functions --config firebase.json --project cloud-firestore-d8c61
```

**Atención:** la configuración `database: "default"` es un ID de base nombrada. No cambiarlo a `(default)`; el SDK Flutter usa expresamente `databaseId: 'default'`. Verificar en CLI y Console que la implementación incluye realmente esa base; las reglas se despliegan por base de datos. Para Firebase Storage, revisar el bucket objetivo del proyecto. Si el CLI informa reglas sin cambios, confirmar manualmente el ruleset remoto.

Compilación de release, cuando haya firma propia y App Check listo:

```bash
flutter build apk --release --dart-define=HH_BETA_HABITS_CLIENT=true
```

Para probar evidencia real tras certificar purga y consentimiento, añadir `--dart-define=HH_BETA_EVIDENCE_CLIENT=true`. Mantenerla apagada en la primera beta si no se ha cerrado su auditoría. No habilitar el premio Titán secreto hasta finalizar el mismo proceso.

## 6. Límites del estado actual

**El QR todavía no puede emitirse** mientras no exista una URL HTTPS verificada del APK release firmado. **Código preparado no significa beta distribuida.** La consola real y sus reglas siguen sin cambios desde este repositorio, la clave privada de firma no está disponible, App Check exige registro externo y las cuentas históricas pudieron falsificar datos. No activar variables backend ni distribuir APK de producción basándose solo en una ejecución verde del emulador.

Fuentes: documentación oficial de Firebase sobre [reglas de bases nombradas](https://firebase.google.com/docs/firestore/security/rules-structure), [despliegue de reglas](https://firebase.google.com/docs/rules/manage-deploy) y [CLI](https://firebase.google.com/docs/cli).
