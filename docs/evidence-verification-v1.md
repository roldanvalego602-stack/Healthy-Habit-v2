# Verificación de evidencias — primera fase

**Estado:** módulo experimental en la rama `feature/mr-healthy-foundations`. No conectado todavía a `registrar_habito_screen.dart`, no desplegado, no concede XP.

## Situación auditada

El registro actual añade +15 XP por la presencia de cualquier imagen, sin reconocer su contenido. Se permite tanto cámara como galería. La fotografía se guarda como Base64 en Firestore en `temporary_habit_evidence`; su limpieza se ejecuta oportunistamente cuando la app está abierta, **no garantiza eliminación automática 24 horas después**. El XP se incrementa mediante transacción en el cliente; esto no es una frontera de seguridad contra un usuario que modifique el cliente.

Además, el proyecto contiene cambios locales del desarrollador en `registrar_habito_screen.dart`. No modificar ese archivo sin reconciliar el diff local.

## Propuesta de niveles

- Declarado (10 XP): actividad registrada sin foto.
- Respaldado (15 XP): fotografía adjunta; no anunciarla como verificada.
- Verificado (20 XP): **propuesta pendiente**, únicamente con validación del servidor, desafío vigente, análisis de contenido y reglas de premio atómicas.

No bloquear registros por fallo de cámara, accesibilidad, disponibilidad de objetos, falsos negativos de visión ni falta de conexión. Nunca solicitar rostros, documentos de identidad, ubicación GPS o acceso permanente a cámara.

## Alternativas de objetos

- Cuchara
- Bolígrafo
- Hoja de papel
- Taza
- Servilleta

El usuario podrá elegir entre varias alternativas, pedir otras o registrar sin validación adicional. Se pueden ampliar las alternativas según entorno y tipo de hábito; jamás usar una lista cerrada como condición para registrar una actividad.

## Verificación de actualidad (a implementar)

La presencia de un objeto cotidiano por sí misma **no acredita** la fecha. Se necesita un desafío aleatorio por sesión, emitido en el servidor y con expiración corta, por ejemplo: escribir un código breve sobre una hoja; o combinar dos objetos seleccionados por el usuario. Debe ligarse a `uid + habitId + attemptId`, expirar y usarse una sola vez mediante transacción.

La cámara en sesión y el desafío reducen la reutilización casual, pero no impiden fotos de pantallas, manipulación del dispositivo, deepfakes ni colusión. EXIF o el reloj del cliente no son pruebas de actualidad confiables.

## Clasificación visual (implementado parcialmente)

- `functions/evidence_policy.js`: perfiles de hábitos (hidratación, frutas/verduras, comidas), alternativas y regla conservadora.
- `functions/evidence_vision.js`: adaptador para Google Cloud Vision Label Detection y Object Localization, con cliente inyectable y límite de 250 KB.
- `functions/tests/evidence_policy.test.js`: pruebas unitarias simuladas.
- Resultado `supported` significa **solo coincidencia visual**, jamás verificación temporal ni autorización de recompensa.
- Resultado `review` significa imagen indeterminada o hábito sin cobertura, no acusación de fraude.
- No se analizan calorías, cantidades ingeridas ni datos médicos a partir de la fotografía.

## Instalación futura del proveedor

La integración real requerirá habilitar Cloud Vision API en un proyecto de pruebas con facturación, revisar costes/quotas y ejecutar desde un backend protegido. No llamar al servicio de pago directamente desde Flutter ni incluir secretos en la app.

Desde `functions`:

```bash
npm install @google-cloud/vision
npm test
```

Esto actualizará `functions/package.json` y `functions/package-lock.json`. El adaptador solo carga el SDK cuando recibe una petición real, por lo que las pruebas simuladas pueden ejecutarse antes de instalarlo.

## Bloqueadores antes de habilitar verificación/20 XP

1. Emitir desafíos en el backend, almacenarlos con expiración, `uid`, hábito e intento; impedir replay y concurrencia.
2. Implementar captura y subida privada de imagen, preferiblemente mediante Cloud Storage con reglas de acceso; evitar Base64 en Firestore.
3. Validar formato, tamaño, detección visual, OCR del código opcional y contenido del hábito; calibrar falsos positivos/negativos.
4. Verificar el resultado en el backend y conceder XP mediante una operación única e idempotente del servidor. **Nunca confiar en `verified: true` recibido del cliente**.
5. Planificar borrado real (Cloud Storage lifecycle y/o tarea programada, Firestore TTL como soporte); explicar tiempos reales al usuario.
6. Configurar Firebase App Check, autenticación, límites de invocaciones, presupuesto y seguimiento de uso antes de desplegar.
7. Diseñar apelación/reintento o registro normal cuando Vision no reconozca la imagen.
8. Evaluar como mínimo 30-50 fotos diversas por categoría con consentimiento, distintos teléfonos e iluminación, sin conservar imágenes más tiempo del necesario.

## Pruebas

```bash
cd functions
npm test
```

Estas pruebas **no utilizan imágenes reales ni llaman a Cloud Vision**. El reconocimiento visual real, su precisión y su precio siguen sin verificarse.

Referencias técnicas:
- https://docs.cloud.google.com/vision/docs
- https://docs.cloud.google.com/vision/docs/object-localizer
- https://firebase.google.com/docs/firestore/ttl
- https://firebase.google.com/docs/app-check/cloud-functions
