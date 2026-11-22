# Foto de perfil — Healthy Habit

## Implementación

La pantalla `EditarPerfilScreen` ahora permite pulsar el avatar y escoger
**Galería** o **Cámara**. Las imágenes se leen desde `image_picker`, se
convierten a JPEG, se reducen a un máximo de 1024 px por lado y se suben
mediante `FirebaseStorage.putData` a:

```
users/{uid}/profile/avatar_{timestamp}.jpg
```

Al completar la subida se actualiza, sin borrar otros datos del usuario:

```
Firestore: users/{uid} -> photoUrl, profilePhotoPath, updatedAt
Firebase Auth: currentUser.photoURL (sincronización secundaria)
```

Los avatares se actualizan en Perfil, Editar perfil, Perfil público,
Buscar amigos, listas de Amigos y feed social. El inicio de la app ya
consultaba `photoUrl` en Firestore.

El botón **Quitar foto** solicita confirmación, deja `photoUrl` vacío y
elimina el objeto anterior cuando pertenece al usuario autenticado.
La subida de una fotografía nueva también intenta limpiar la anterior.
El nombre, biografía y usuario se guardan por separado con **Guardar cambios**.

## Diagnóstico de la subida

En la versión actual, la aplicación distingue el paso que falla:
lectura de Firestore, subida a Storage, obtención de URL o guardado en
Firestore. El SnackBar muestra un código de Firebase cuando existe.

**Desde febrero de 2026, Firebase Cloud Storage exige que el proyecto esté
en el plan Blaze.** En Spark, los buckets no son accesibles mediante la
API y pueden producir errores HTTP 402 o 403 aunque las reglas estén bien.
Referencia oficial:
https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024

Antes de editar reglas o pagar, comprobar en Firebase Console:
1. Proyecto `cloud-firestore-d8c61` → **Configuración → Uso y facturación**.
2. **Storage → Archivos**: confirmar que existe y es accesible el bucket
   `cloud-firestore-d8c61.firebasestorage.app`.
3. **Storage → Reglas**: permitir `create` JPEG dentro de
   `users/{uid}/profile/` solo para el mismo usuario autenticado.
4. Reintentar una subida en Android y anotar el **código concreto**.
   No cambiar de plan sin revisar antes los costes y límites de facturación.

## Requisito operativo: Firebase Storage

**El repositorio actualmente no define un bloque `storage` en
`firebase.json` ni contiene reglas Storage versionadas**. Puede haber
reglas ya desplegadas en Firebase Console. Antes de publicar las nuevas,
revisar y conservar las reglas de otros archivos, como evidencias temporales.
No sobrescribir reglas de producción sin revisarlas.

Incorporar este bloque de regla a las reglas Storage existentes (dentro de
`service firebase.storage { match /b/{bucket}/o { ... } }`):

```text
match /users/{userId}/profile/{fileName} {
  allow read: if request.auth != null;
  allow create: if request.auth != null
    && request.auth.uid == userId
    && fileName.matches('avatar_[0-9]+\\.jpg')
    && request.resource.size < 4 * 1024 * 1024
    && request.resource.contentType == 'image/jpeg';
  allow delete: if request.auth != null
    && request.auth.uid == userId;
  allow update: if false;
}
```

La URL de descarga de Firebase Storage funciona como un enlace con token;
los perfiles se consideran públicos para usuarios que disponen del enlace.
Si se necesita privacidad estricta, usar un sistema de descarga autenticado
en lugar de URLs con token.

Los permisos de Firestore existentes también deben permitir que cada usuario
actualice **su propio documento** `users/{uid}`, y que se puedan leer
`photoUrl` en los perfiles públicos según las políticas de la aplicación.
No permitir que un cliente edite documentos de otros usuarios.

## Validación local

```bash
git fetch origin feature/mr-healthy-foundations
git merge --ff-only FETCH_HEAD
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/profile_photo_service_test.dart
flutter run
```

Pruebas manuales:

1. Entrar a Perfil; tocar el avatar y elegir una fotografía de galería.
2. Verificar que cambia en Editar perfil y, al volver, en Perfil e Inicio.
3. Comprobar `users/{uid}.photoUrl` y el objeto subido en Firebase Storage.
4. Abrir el perfil desde otra cuenta; verificar que se muestra la misma foto.
5. Sustituirla y luego quitarla; verificar que vuelve el avatar genérico.
6. Intentar cargar una imagen no válida o denegar permisos de cámara:
   la interfaz debe mostrar un error sin alterar los otros campos.
7. Verificar que el usuario no puede escribir en
   `users/{otroUid}/profile/` desde una sesión ajena.

Si Storage devuelve `unauthorized`, revisar el bucket, las reglas y el
estado de facturación habilitado para Storage en Firebase Console.
El código no puede publicar ni habilitar reglas de Firebase por sí solo.

## Límite de verificación

Los cambios están guardados en GitHub, pero no se ejecutaron pruebas Flutter
o subidas reales contra Firebase desde el entorno de edición.
