# Popularidad de hábitos oficiales — contrato de datos

La pantalla de Hábitos lee exclusivamente documentos de la colección
`public_habit_popularity/{habitId}`. No permite escribirlos.

## Esquema esperado

- `activeUsers`: entero positivo, cantidad agregada de usuarios distintos
  que mantienen activo un hábito oficial.
- `verified`: booleano `true`, escrito exclusivamente por el proceso
  de agregación de confianza.
- ID del documento: ID del catálogo oficial (`alim_001`, etc.).

Cuando un documento no existe, no tiene permiso de lectura o su contenido no
cumple este esquema, la aplicación no fabrica números: omite esa entrada.

## Requisitos antes de publicar rankings reales

1. Implementar un proceso **autorizado en el servidor** para contar usuarios
   únicos por `habitId` del catálogo oficial, no intentos ni registros.
2. Considerar solo el estado actualmente activo (`inProgress`); actualizar
   al iniciar, cancelar y completar los intentos. Contar como máximo una
   vez a cada usuario por hábito.
3. Recalcular o reconciliar periódicamente los totales para reparar eventos
   retrasados o duplicados.
4. Restringir las escrituras de `public_habit_popularity` a identidades
   administrativas confiables. Los clientes no deben poder modificar
   `activeUsers` ni `verified`.
5. Permitir lectura de los agregados según las reglas de seguridad de la app,
   sin exponer identificadores de usuarios ni listas individuales de hábitos.
6. Definir política de publicación para conteos pequeños, evitando
   riesgos de privacidad. Documentar cuándo se actualizó el agregado.
7. Desplegar y probar las reglas antes de dar por finalizada la funcionalidad.

No reutilizar el contador de adopciones históricas como `activeUsers`:
el nombre del campo expresa usuarios únicos actualmente activos.

## Implementación incluida en el repositorio

Se añadió la función callable `rebuildPublicHabitPopularity` en
`functions/index.js`, restringida a usuarios con el custom claim
`admin: true`. **No se ha desplegado ni ejecutado**.

- Examina como máximo 10.000 documentos de `collectionGroup('user_habits')`;
  si se excede el límite cancela la publicación para no presentar datos
  parciales. En proyectos grandes deberá sustituirse por paginación.
- Acepta solo las rutas canónicas `users/{uid}/user_habits/{habitId}`
  y los 36 IDs del catálogo oficial (`alim_`, `hidr_`, `ener_`, `bien_`).
- Cuenta usuarios únicos con `latestStatus == 'inProgress'`.
- Publica únicamente valores de cinco o más usuarios distintos.
- Elimina los agregados antiguos cuando dejan de cumplir las condiciones.
- Los archivos `functions/tests/habit_popularity_aggregator.test.js`
  comprueban el conteo, el filtrado y el umbral.

**Precaución operativa:** Este proyecto no contiene un archivo de reglas
Firestore verificable en la rama. Deben existir reglas desplegadas que
impidan las escrituras de clientes y permitan las lecturas de
`public_habit_popularity` conforme al modelo de seguridad de la app.
Las credenciales administrativas de Firebase no se incorporan al cliente.

Verificar también que el despliegue no exponga información sobre usuarios
individuales, que el endpoint solo sea invocado por administradores y que
el coste de lectura de la consulta sea aceptable antes de ejecutarlo.

## Estado

El frontend de lectura y la sección visual están implementados.
**El productor administrativo está implementado, pero todavía no está desplegado ni ejecutado.**
