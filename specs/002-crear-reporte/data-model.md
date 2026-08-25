# Phase 1 Data Model: Crear Reporte

## Entidades de dominio (`domain/models/`)

### `Failure` (sealed class, compartida — no exclusiva de esta feature)

Primera vez que el proyecto agrega esta jerarquía (Principio V de la constitución).

| Subtipo | Cuándo se produce |
|---|---|
| `ServerFailure` | Error de Firestore/Storage al crear el documento o subir la foto (`FirebaseException` genérica) |
| `NetworkFailure` | Sin conexión a internet durante el envío (FR-017, SC-004) |
| `PermissionFailure` | El usuario negó el permiso de cámara, galería o ubicación (FR-005, edge case de ubicación) |
| `LocationFailure` | El permiso de ubicación fue concedido pero no se pudo obtener la posición (GPS apagado, timeout, servicio deshabilitado) |

### `WasteCategory` (enum)

Los 5 valores fijos del FR-007, cada uno con su `label` para mostrar en la UI:

| Valor del enum | `label` mostrado |
|---|---|
| `basuraAcumulada` | "Basura acumulada" |
| `escombros` | "Escombros" |
| `mueblesEnseres` | "Muebles/enseres" |
| `residuosVerdes` | "Residuos verdes" |
| `otros` | "Otros" |

### `Photo`

Representa la foto ya procesada (después de compresión), lista para enviarse o para bloquear el envío
si sigue pesando de más.

| Campo | Tipo | Notas |
|---|---|---|
| `bytes` | `Uint8List` | Contenido binario ya comprimido |
| `sizeBytes` | `int` | Tamaño final en bytes, después de la compresión (research.md §7) |

**Regla de negocio derivada** (getter puro, sin I/O): `exceedsMaxSize => sizeBytes > maxPhotoBytes`,
con `maxPhotoBytes = 2 * 1024 * 1024` (2 MB, FR-004/FR-006). Presentation usa este getter para decidir
si muestra el texto rojo y deshabilita "Enviar reporte" — no requiere ninguna llamada adicional.

### `ReportLocation`

Agrega la ubicación automática (si se obtuvo) y/o la dirección manual escrita por el usuario.

| Campo | Tipo | Notas |
|---|---|---|
| `latitude` | `double?` | `null` si la ubicación automática no se obtuvo |
| `longitude` | `double?` | `null` si la ubicación automática no se obtuvo |
| `automaticAddress` | `String?` | Dirección legible (reverse geocoding) o coordenadas crudas como respaldo (research.md §6); `null` si no hay ubicación automática |
| `manualAddress` | `String?` | Texto escrito por el usuario en "Dirección manual"; `null`/vacío si no lo llenó |

**Reglas de negocio derivadas** (getters puros):
- `hasAutomaticLocation => automaticAddress != null`
- `hasManualAddress => manualAddress != null && manualAddress!.trim().isNotEmpty`
- `hasAnyLocation => hasAutomaticLocation || hasManualAddress` — implementa la regla FR-014 ("al
  menos una de las dos") y es la fuente de verdad que usa el botón "Enviar reporte" (FR-015) y el
  campo de dirección manual para saber si es obligatorio (FR-013).

### `NewReportDraft`

Agregado inmutable con todo lo capturado en el formulario, pasado a `ReportRepository.submitReport`.
No se persiste en ningún lado hasta que el envío es exitoso (Assumption del spec: sin guardado de
borrador).

| Campo | Tipo | Notas |
|---|---|---|
| `photo` | `Photo` | Ya validada como `!exceedsMaxSize` antes de construir el draft (Presentation no arma el draft si la foto es inválida) |
| `category` | `WasteCategory` | Obligatorio (FR-008) |
| `description` | `String` | Puede ser cadena vacía (FR-009, opcional) |
| `location` | `ReportLocation` | Debe cumplir `hasAnyLocation == true` antes de construir el draft |

### `Report`

Lo que retorna un envío exitoso; consumido por la pantalla "Confirmación".

| Campo | Tipo | Notas |
|---|---|---|
| `reportNumber` | `String` | Formato completo `#IL-{año}-{consecutivo}` (research.md §2), ya listo para mostrar (FR-020) |
| `category` | `WasteCategory` | Copiado del draft |
| `description` | `String` | Copiado del draft |
| `address` | `String` | Dirección final mostrable — `manualAddress` si existe, si no `automaticAddress` (ver Reglas de mapeo abajo) |
| `photoUrl` | `String` | URL de descarga de Firebase Storage de la foto ya subida |
| `createdAt` | `DateTime` | Timestamp de creación (usado también como parte del cálculo del año del contador) |

**Regla de mapeo `NewReportDraft.location` → `Report.address`**: si `manualAddress` tiene contenido,
se usa como la dirección final (el usuario la escribió o la usó para completar/corregir la
automática); si no, se usa `automaticAddress`. Esto no es una decisión de UI sino del Repository, ya
que es lo que se persiste como el campo `address` del documento de Firestore (ver
`contracts/firestore-reports-contract.md`).

## Interfaces de Repository (`domain/repositories/`)

```dart
abstract class ReportRepository {
  Future<Either<Failure, Report>> submitReport(NewReportDraft draft);
}

abstract class PhotoRepository {
  Future<Either<Failure, Photo>> pickFromCamera();
  Future<Either<Failure, Photo>> pickFromGallery();
}

abstract class LocationRepository {
  Future<Either<Failure, ReportLocation>> getCurrentLocation();
}
```

- `PhotoRepository`: un `Left` solo ocurre por permiso denegado o error del picker/compresor
  (`PermissionFailure`/`ServerFailure`) — una foto que sigue pesando >2 MB tras comprimirse **no** es
  un `Left`, es un `Right(Photo)` con `exceedsMaxSize == true` (research.md §7).
- `LocationRepository`: un `Left` (`PermissionFailure`/`LocationFailure`) es la señal de "ubicación
  automática no disponible" que activa FR-013 (dirección manual obligatoria) en Presentation.

## Concepto de UI (no es un domain model)

`NewReportState` (freezed, en `ui/reports/providers/new_report_state.dart`) agrega, además de los
campos que vienen de Domain, banderas puramente de presentación: `isLoadingLocation`, `isSubmitting`,
`submitError` (mensaje de FR-017), y `showPermissionDeniedAlert` (dispara la alerta de FR-005 una sola
vez). No vive en `domain/` porque no representa una entidad de negocio persistida, es estado efímero
de la pantalla — mismo criterio que `AppTab` en la feature de navegación.

## Validaciones y transiciones de estado

- **Habilitación de "Enviar reporte" (FR-015)**: `canSubmit = photo != null && !photo.exceedsMaxSize
  && category != null && location.hasAnyLocation`. Es una función pura de `NewReportState`, sin I/O.
- **Obligatoriedad de "Dirección manual" (FR-012/FR-013)**: `location.hasAutomaticLocation` decide si
  el campo se muestra como opcional u obligatorio; la validación de envío en sí depende de
  `location.hasAnyLocation`, no de cuál de los dos campos está lleno.
- **Transición de envío (FR-016/FR-017/FR-018)**: `idle → submitting → (success → navega a
  Confirmación) | (failure → vuelve a idle con submitError seteado, datos del formulario intactos)`.
  No existe un estado intermedio persistido: si el envío falla, `NewReportDraft` nunca se guarda en
  ningún lado, solo permanece en el `state` en memoria del Notifier (por eso los datos "ya
  ingresados" sobreviven un fallo, FR-017/SC-004).
- **Alcance de "Confirmación" (FR-025)**: la pantalla de confirmación requiere un `Report` recibido
  como `extra` de navegación (`context.push(path, extra: report)`); si se accede a la ruta sin ese
  `extra` (navegación directa/deep link), redirige a Inicio en vez de mostrar una confirmación vacía.
