# Phase 1 Data Model: Mis Reportes

## Entidades de dominio (`domain/models/`)

### `ReportStatus` (enum, nuevo)

Los 3 estados posibles de un reporte, cada uno con su `label` para mostrar en la UI (mismo patrón
que `WasteCategory`):

| Valor del enum | `label` mostrado | Color de etiqueta sugerido |
|---|---|---|
| `pendiente` | "Pendiente" | Naranja/ámbar |
| `enProceso` | "En proceso" | Azul |
| `solucionado` | "Solucionado" | Verde |

### `Report` (extendido — mismo archivo `report.dart` de "Crear Reporte")

Se agregan 5 campos a la entidad ya existente (`reportNumber`, `category`, `description`,
`address`, `photoUrl`, `createdAt` se mantienen igual):

| Campo nuevo | Tipo | Requerido en el factory | Notas |
|---|---|---|---|
| `id` | `String` | Sí | ID del documento de Firestore (antes no se exponía; "Crear Reporte" no lo necesitaba porque solo mostraba `reportNumber`). Necesario para la ruta `/mis-reportes/:reportId` y para `watchReportById`. |
| `status` | `ReportStatus` | Sí | Valor inicial `pendiente` al crearse (FR del spec de "Crear Reporte" se amplía con este default). |
| `deviceId` | `String` | Sí | Identificador anónimo del dispositivo que envió el reporte (FR-003). |
| `inProgressAt` | `DateTime?` | No (default `null`) | `null` hasta que el reporte pase a "en proceso" (FR-014). Ninguna pantalla de esta feature lo escribe — se lee tal como esté en Firestore. |
| `resolvedAt` | `DateTime?` | No (default `null`) | `null` hasta que el reporte pase a "solucionado" (FR-014). Idem: solo lectura. |

**Regla de negocio derivada** (getter puro en `Report`, sin I/O): la línea de tiempo del detalle
(FR-012 a FR-014) se construye directamente de estos 3 campos —
`createdAt` (paso "Reporte recibido", siempre con fecha), `inProgressAt` (paso "En proceso"),
`resolvedAt` (paso "Solucionado") — sin necesitar un campo adicional de "pasos".

### `Failure` (sealed class, extendida — mismo archivo `failure.dart` de "Crear Reporte")

Se agrega un subtipo nuevo, ya anticipado como ejemplo en el Principio V de la constitución:

| Subtipo | Cuándo se produce |
|---|---|
| `CacheFailure` | Falla al leer o escribir el identificador de dispositivo en `shared_preferences` (caso raro: almacenamiento local no disponible). |

## Interfaces de Repository (`domain/repositories/`)

```dart
abstract class ReportListRepository {
  /// Todos los reportes del dispositivo (`deviceId`), ordenados por
  /// `createdAt` descendente. El filtro por pestaña (FR-005) se aplica en
  /// Presentation sobre esta misma lista (research.md §4), no aquí.
  Stream<Either<Failure, List<Report>>> watchReports(String deviceId);

  /// Un reporte específico por su `id` de documento, para "Detalle del
  /// reporte". `Right(null)` si el documento no existe (ej. borrado o ID
  /// inválido) — no es un `Failure`, es un dato válido de "no encontrado".
  Stream<Either<Failure, Report?>> watchReportById(String reportId);
}

abstract class DeviceIdentifierRepository {
  /// Genera el identificador la primera vez y lo reutiliza después
  /// (persistido localmente). Nunca requiere red ni Firebase.
  Future<Either<Failure, String>> getDeviceId();
}
```

- `ReportListRepository`: un `Left` solo ocurre por un error real de lectura de Firestore (ej. sin
  conexión, permisos denegados) — nunca por "no hay reportes" (eso es `Right([])`) ni por "el
  reporte no existe" (eso es `Right(null)` en `watchReportById`).
- `DeviceIdentifierRepository`: separada de `ReportRepository`/`ReportListRepository` porque no
  depende de Firebase — es persistencia puramente local, reutilizable por cualquier feature futura
  que necesite el mismo identificador (research.md §2).

## Ajuste a `ReportRepository` (interfaz sin cambios, implementación sí)

`ReportRepository.submitReport` (interfaz de "Crear Reporte") no cambia de firma. Su
implementación (`ReportRepositoryImpl`) sí cambia: resuelve `DeviceIdentifierRepository.getDeviceId()`
antes de construir el mapa a persistir, y `ReportDto.toFirestoreMap` ahora incluye
`status: 'pendiente'` y `deviceId`. Ver `contracts/reports-schema.md`.

## Concepto de UI (no son domain models)

- **`ReportFilter`** (`ui/reports/providers/report_filter.dart`): enum de UI con 4 valores
  (`todos`, `pendientes`, `enProceso`, `solucionados`) — no vive en `domain/` porque es un detalle
  de la pestaña seleccionada, no una entidad de negocio (mismo criterio que `AppTab` en la feature
  de navegación). El filtro `todos` no corresponde a ningún `ReportStatus` (es "sin filtro"), por
  eso es un tipo separado en vez de reutilizar `ReportStatus?`.

## Validaciones y transiciones de estado

- **Filtro de la lista (FR-005/FR-006)**: `visibleReports = filter == ReportFilter.todos ? all : all.where((r) => r.status == filter.toReportStatus).toList()`. Función pura sobre la lista ya recibida del stream, sin I/O.
- **Estado vacío (FR-009)**: se distingue "sin reportes en absoluto" (mensaje general) de "sin
  reportes en esta pestaña" (mensaje específico del filtro) según si `all.isEmpty` vs.
  `visibleReports.isEmpty && all.isNotEmpty`.
- **Línea de tiempo del detalle (FR-012 a FR-014)**: cada paso es "cumplido" si su campo de fecha
  correspondiente (`createdAt`/`inProgressAt`/`resolvedAt`) no es `null`; el texto mostrado es esa
  fecha formateada, o `"Pendiente"` si es `null`.
- **Alcance de "solo lectura" (FR-015)**: ningún widget de esta feature llama a ningún método de
  escritura sobre `status`/`inProgressAt`/`resolvedAt` — `ReportListRepository` no expone ningún
  método de escritura en absoluto (solo los 2 `Stream` de lectura), lo que hace la restricción
  verificable a nivel de interfaz, no solo de convención.
