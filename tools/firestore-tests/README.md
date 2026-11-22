# Pruebas de seguridad Firestore (entorno local)

**No desplegar reglas.** Esta suite usa `@firebase/rules-unit-testing`
con el archivo que ya carga `firebase.emulator.json`:
`firestore.candidate.rules`.

Desde la raíz del proyecto, con los emuladores encendidos:

```bash
npm install --prefix tools/firestore-tests
node --test tools/firestore-tests/rules.test.mjs
```

Las primeras siete pruebas identificaron dos fallos reales en la candidata:
la creación unilateral de amistades estaba permitida y las invitaciones
a hábitos en pareja estaban bloqueadas. El archivo
`firestore.candidate.rules` **ya contiene correcciones propuestas**:
amistades creadas de manera recíproca y atómica con una solicitud previa,
invitaciones accesibles por participantes, reacciones restringidas a
amigos y soporte de `permitirReacciones` en el perfil público.

Las pruebas actuales incluyen casos adversariales y operaciones
recíprocas. No se han ejecutado en el ordenador del usuario después
de estos cambios. Los siguientes resultados pueden mostrar nuevas
incompatibilidades; deben resolverse dentro del emulador antes de
considerar un despliegue.

**Interpretación:** el texto de un test fallido debe guiar las
correcciones; no se recomienda cambiar las reglas productivas
directamente para lograr que los tests queden verdes.

El identificador utilizado es `demo-healthy-habit`, con servicios en
`127.0.0.1:8080` y `127.0.0.1:9099`. Los datos se eliminan entre casos
mediante el SDK de pruebas: el proyecto de producción no participa.

Algunos tests preparan documentos iniciales con reglas deshabilitadas,
solamente dentro del emulador; esto **no es equivalente** a una operación
que un usuario real pueda realizar en producción.

La configuración del CLI utiliza Node.js 24 y se ha fijado la versión
6.0.0 del paquete de pruebas. Los errores de reglas no se deben
confundir con errores de instalación de dependencias.
