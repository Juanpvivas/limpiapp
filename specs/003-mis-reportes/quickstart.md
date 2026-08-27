# Quickstart: Validar Mis Reportes

Guía para verificar manualmente, de punta a punta, que las 3 User Stories del
[spec.md](./spec.md) funcionan antes de dar la feature por completa.

## Prerrequisitos

- Flutter SDK `^3.13.1` instalado, dependencias instaladas (`flutter pub get`), incluyendo
  `shared_preferences` (nueva de esta feature).
- Proyecto de Firebase ya configurado y con Firestore habilitado (ya lo estaba desde "Crear
  Reporte").
- Al menos un reporte ya enviado desde el dispositivo de prueba (usar el flujo de "Crear Reporte"
  si hace falta); idealmente varios, para poder probar los filtros y estados.
- **Cambiar el estado de un reporte para las pruebas de línea de tiempo**: como no existe ningún
  panel administrativo (fuera de alcance), edita manualmente los campos `status`/`inProgressAt`/
  `resolvedAt` de un documento directamente desde la consola de Firebase (Firestore Database →
  `reports` → el documento) para simular "en proceso" y "solucionado".

## Levantar la app

```bash
cd limpiapp
flutter pub get
flutter run
```

## Escenarios a validar

### 1. Ver la lista de mis reportes (US1, P1)

1. Desde la pantalla de inicio, toca **"Mis reportes"**.
2. Verifica que aparecen todos los reportes enviados desde este dispositivo, cada uno con
   miniatura, etiqueta de estado, número, dirección y fecha/hora — el más reciente primero.
3. Envía un reporte nuevo (flujo de "Crear Reporte") y confirma que, al volver a "Mis reportes",
   aparece arriba de todo con estado "Pendiente".
4. Con un dispositivo/emulador distinto (o borrando los datos de la app para generar un
   identificador nuevo), confirma que **no** ves los reportes del primer dispositivo.
5. Toca cualquier reporte de la lista y confirma que navega a "Detalle del reporte" de ese mismo
   reporte.

**Resultado esperado**: FR-001 a FR-004, FR-007, FR-008, FR-010.

### 2. Filtrar por estado (US2, P2)

1. En la consola de Firebase, deja al menos un reporte en cada estado (`pendiente`, `enProceso`,
   `solucionado`) para este dispositivo.
2. En la app, confirma que "Todos" está seleccionada por defecto y muestra los 3.
3. Toca "Pendientes" y confirma que solo se ven los reportes en ese estado.
4. Repite con "En proceso" y "Solucionados".
5. Toca una pestaña sin ningún reporte en ese estado y confirma el estado vacío específico (sin
   mezclar reportes de otros estados).

**Resultado esperado**: FR-005, FR-006, FR-009.

### 3. Ver el detalle y la línea de tiempo de seguimiento (US3, P3)

1. Abre el detalle de un reporte "Pendiente": confirma que la línea de tiempo muestra fecha solo
   en "Reporte recibido", y "Pendiente" en "En proceso" y "Solucionado".
2. Cambia ese mismo documento a `enProceso` con un `inProgressAt` en la consola de Firebase, sin
   cerrar la app — confirma que la pantalla de detalle ya abierta se actualiza sola (sin recargar)
   mostrando la nueva etiqueta de estado y la fecha en el paso "En proceso".
3. Cambia el documento a `solucionado` con `resolvedAt`, y confirma que el detalle vuelve a
   actualizarse solo, con los 3 pasos mostrando fecha.
4. Revisa toda la pantalla de detalle y confirma que no hay ningún botón, menú ni control para
   cambiar el estado manualmente.

**Resultado esperado**: FR-011 a FR-016.

## Casos límite a probar

- **Dispositivo sin ningún reporte enviado**: "Mis reportes" muestra el estado vacío general (no
  el de una pestaña) la primera vez que se abre (FR-009).
- **Reporte sin descripción**: el detalle no genera error, simplemente omite o deja vacía esa
  sección (Edge case de spec.md).
- **Sin conexión**: abrir "Mis reportes"/el detalle sin internet debe mostrar un error manejado
  (no un crash) — la lista puede quedar vacía o mostrar un mensaje de error de conexión.
- **Cambios en tiempo real en la lista**: con "Mis reportes" abierto, cambia el estado de un
  reporte desde la consola de Firebase y confirma que la etiqueta de color en la lista se
  actualiza sin recargar la pantalla.

## Siguiente paso

Con estos escenarios validados manualmente, corre `/speckit-tasks` para desglosar esta feature en
tareas de implementación, y luego `/speckit-implement` para construirla.
