# Pruebas de seguridad Firestore (entorno local)

**No desplegar reglas.** Esta suite usa `@firebase/rules-unit-testing`
con el archivo que ya carga `firebase.emulator.json`:
`firestore.candidate.rules`.

Desde la raíz del proyecto, con los emuladores encendidos:

```bash
npm install --prefix tools/firestore-tests
node --test tools/firestore-tests/rules.test.mjs
```

Las pruebas **no están diseñadas para aprobar todas todavía**.
Los casos de denegación y permiso señalan diferencias entre la política
actual y los nuevos requisitos sociales. En particular:

- La candidata existente permite escribir directamente en
  `users/{uid}/friends/{friendId}` si el usuario es propietario.
  Esto representa un agujero de autorización: se podría crear
  unilateralmente una amistad sin solicitud.
- El candidato anterior no declara
  `shared_habit_invites/{inviteId}`, por lo que las invitaciones
  reales a hábitos en pareja serán denegadas.
- La política de reacciones existente **no exige una amistad**;
  una prueba positiva entre amigos no demuestra que la validación
  negativa esté implementada.

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
