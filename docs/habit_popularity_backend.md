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

## Pendiente en el servidor antes de mostrar rankings reales

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

## Estado

El frontend de lectura y la sección visual están implementados.
**El productor de estadísticas todavía no está desplegado**.
