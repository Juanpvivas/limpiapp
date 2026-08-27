# Contrato de datos: extensión de la colección `reports`

Esta feature no crea backend nuevo: extiende el esquema de la colección `reports` ya documentado
en `specs/002-crear-reporte/contracts/firestore-reports-contract.md`, que explícitamente anticipó
esta extensión ("se pueden agregar campos opcionales nuevos... ej. un futuro `status`... sin romper
este contrato"). Este documento reemplaza a aquel como la fuente de verdad vigente del esquema
completo — cualquier feature futura debe leer este archivo, no el de "Crear Reporte".

## Colección `reports` (esquema completo, con los campos nuevos de esta feature)

| Campo | Tipo (Firestore) | Obligatorio | Descripción |
|---|---|---|---|
| `reportNumber` | `string` | Sí | Sin cambios — ver contrato original. |
| `wasteCategory` | `string` | Sí | Sin cambios. |
| `description` | `string` | Sí (puede ser `""`) | Sin cambios. |
| `latitude` / `longitude` | `number` \| `null` | No | Sin cambios. |
| `automaticAddress` / `manualAddress` | `string` \| `null` | No | Sin cambios. |
| `address` | `string` | Sí | Sin cambios. |
| `photoUrl` | `string` | Sí | Sin cambios. |
| `createdAt` | `timestamp` | Sí | Sin cambios. |
| **`status`** | `string` | Sí (**nuevo**) | Uno de `"pendiente"`, `"enProceso"`, `"solucionado"` (nombre del enum `ReportStatus`, no el label en español). Escrito como `"pendiente"` en la misma transacción que crea el documento (`ReportFirestoreService.createReport`, ajustado por esta feature). Ningún flujo de esta feature lo modifica después de creado. |
| **`deviceId`** | `string` | Sí (**nuevo**) | Identificador anónimo generado por `DeviceIdentifierService` (ver research.md §2), escrito al crear el documento. Usado para filtrar "Mis reportes" (`where('deviceId', isEqualTo: ...)`). |
| **`inProgressAt`** | `timestamp` \| `null` | No (**nuevo**) | `null` al crearse. Ninguna pantalla de esta feature lo escribe — queda `null` hasta que un mecanismo futuro (panel administrativo, fuera de alcance) lo actualice directamente en Firestore. |
| **`resolvedAt`** | `timestamp` \| `null` | No (**nuevo**) | Igual que `inProgressAt`, para el estado "solucionado". |

**Invariante nueva**: un documento recién creado siempre tiene `status == "pendiente"`,
`deviceId` no vacío, e `inProgressAt`/`resolvedAt` ambos `null`. La única forma de que
`inProgressAt`/`resolvedAt`/`status` cambien de esos valores iniciales es fuera del alcance de
código de esta feature (no hay ningún método de escritura expuesto para ello).

## Índice de Firestore requerido

Consulta usada por `ReportQueryService.watchReportsByDevice`:

```
collection('reports').where('deviceId', isEqualTo: <id>).orderBy('createdAt', descending: true)
```

Esto es un índice simple (un `where` de igualdad + un `orderBy` sobre un campo distinto) que
Firestore soporta con el índice automático de campo único — **no requiere crear un índice
compuesto manualmente** en la consola, a diferencia de si se filtrara también por `status` en la
misma consulta (research.md §4 — por eso el filtro de estado se resuelve en el cliente).

## Compatibilidad hacia adelante

- Un futuro panel administrativo (fuera de alcance) que escriba `status`/`inProgressAt`/`resolvedAt`
  debe mantenerse dentro de los 3 valores de `ReportStatus` documentados aquí, o coordinar un
  cambio de contrato con esta feature y con "Mis Reportes".
- No se debe renombrar ni eliminar ninguno de los campos listados (ni los originales de "Crear
  Reporte" ni los nuevos) sin actualizar este documento y coordinar con cualquier feature que ya
  dependa de él.
