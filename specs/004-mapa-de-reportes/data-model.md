# Data Model: Mapa de Reportes

Esta feature **no** introduce entidades de dominio nuevas ni cambia el esquema de Firestore. Solo
extiende una entidad compartida existente para exponer datos que ya se persisten, y define unos
pocos tipos de **Presentation** (concepto de UI, no de dominio).

## 1. Entidad de dominio modificada: `Report`

`lib/domain/models/report.dart` — se agregan 2 campos y 1 getter puro. El resto de la entidad
(feature 002/003) no cambia.

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `latitude` | `double?` | No (**nuevo**) | Latitud del punto reportado. `null` si el reporte no tiene ubicación automática registrada. Ya persistido por "Crear Reporte" (`reports.latitude`, `number \| null`). |
| `longitude` | `double?` | No (**nuevo**) | Longitud del punto reportado. Mismo origen que `latitude`. |

**Getter nuevo** (lógica pura, sin dependencias):

```text
bool get isMappable =>
    latitude != null && longitude != null &&
    latitude!.abs() <= 90 && longitude!.abs() <= 180 &&
    !(latitude == 0 && longitude == 0);
```

- `isMappable == false` → el reporte **no** genera marcador (FR-004), no cuenta para el encuadre
  (FR-008) ni para decidir el estado vacío (FR-023).
- `(0, 0)` se trata como "sin ubicación" (centinela): un reporte de Ibagué está en ~`(4.44,
  -75.23)`, nunca en `(0, 0)`.

**Regeneración**: `report.freezed.dart` se regenera con `dart run build_runner build
--delete-conflicting-outputs`.

**Reglas de validación**: ninguna nueva en escritura (esta feature no escribe reportes). En
lectura, `ReportDto.fromFirestore` tolera `latitude`/`longitude` ausentes, `null` o de tipo
inesperado → los deja en `null` (mismo criterio defensivo que el resto de `fromFirestore`).

**Transiciones de estado**: sin cambios. `status`/`inProgressAt`/`resolvedAt` siguen siendo de
solo lectura para todo el código de la app (contrato de la 003).

## 2. Mapeo DTO modificado: `ReportDto.fromFirestore`

`lib/data/model/report_dto.dart` — única modificación:

```text
latitude:  (data['latitude']  as num?)?.toDouble(),
longitude: (data['longitude'] as num?)?.toDouble(),
```

`toFirestoreMap` y `fromSubmission` **no cambian** (ya manejan coordenadas / no las necesitan).

## 3. Tipos de Presentation (UI, no dominio)

Viven en `lib/ui/map/`. No son entidades de dominio (mismo criterio que `AppTab` y `ReportFilter`).

### 3.1 `ReportFilter` (reutilizado de la 003, sin cambios)

`lib/ui/reports/providers/report_filter.dart` — enum `todos / pendientes / enProceso /
solucionados`, cada valor con `label` y `status: ReportStatus?`, y `List<Report> apply(List<Report>)`
(filtro puro en memoria). El mapa **reutiliza el enum**; el estado seleccionado es una instancia
propia (ver 3.2).

### 3.2 Estado del filtro del mapa — `mapReportFilterProvider`

| Aspecto | Valor |
|---|---|
| Tipo | `@Riverpod(keepAlive: true)` `Notifier<ReportFilter>` |
| Valor inicial | `ReportFilter.todos` (FR-013) |
| Mutación | `select(ReportFilter filter)` |
| Independencia | Instancia separada de `reportFilterProvider` (FR-015): cambiar uno no afecta al otro |
| Ciclo de vida | `keepAlive` → sobrevive al cambio de tab y al ida-y-vuelta al detalle (FR-028) |

### 3.3 Marcadores visibles — `mapMarkersProvider`

| Aspecto | Valor |
|---|---|
| Tipo | Provider derivado → `AsyncValue<List<Report>>` |
| Fuente | `ref.watch(myReportsProvider)` (feature 003, sin cambios) |
| Transformación | `filter.apply(reports).where((r) => r.isMappable).toList()` |
| Estados | `loading` (primer emisión), `error` (propaga el `AsyncError` de `myReportsProvider`), `data` (lista, posiblemente vacía) |

Distinción de "vacío" para la UI (FR-023 vs FR-024):
- `myReports` trae 0 reportes mapeables en total → estado vacío general ("aún no has enviado
  reportes").
- `myReports` trae reportes pero el filtro activo deja 0 → aviso "sin reportes en este estado",
  mapa visible.

### 3.4 Reporte seleccionado (tarjeta) — `selectedMapReportProvider`

| Aspecto | Valor |
|---|---|
| Tipo | `@riverpod` `Notifier<String?>` (el `Report.id` del marcador tocado; `null` = sin tarjeta) |
| Mutaciones | `select(String reportId)`, `clear()` |
| Ciclo de vida | auto-dispose (la selección no persiste al salir del mapa) |
| Invariante | como máximo un id a la vez → una sola tarjeta (FR-018) |

### 3.5 Estilo de marcador — `report_marker_style.dart` (helpers, no widget)

| Símbolo | Tipo | Descripción |
|---|---|---|
| `markerColorFor(ReportStatus)` | `Color` | `pendiente → rojo`, `enProceso → naranja`, `solucionado → verde` (FR-005, mock). **Distinto** de `ReportStatusChip` (research.md §6). |
| `kMarkerLegend` | `List<(Color, String)>` | Entradas de la leyenda color→estado (FR-007). |
| `kIbagueCenter` | `LatLng` | `LatLng(4.4389, -75.2322)` — centro por defecto (FR-023). |
| `kCityZoom` / `kSingleMarkerZoom` | `double` | `12.0` / `15.0` (FR-009/FR-023). |
| `kClusterNeutralColor` | `Color` | Gris oscuro del tema para la burbuja de clúster (research.md §10). |

## 4. Relaciones y flujo

```text
myReportsProvider (003)            mapReportFilterProvider (nuevo, keepAlive)
   AsyncValue<List<Report>>              ReportFilter
            \                               /
             \                             /
              v                           v
        mapMarkersProvider (nuevo)  ──►  AsyncValue<List<Report>>  (filtrados + isMappable)
                    |
        ┌───────────┼─────────────────────────────┐
        v           v                             v
   MapView      MapLegend                 (cálculo de encuadre:
 (marcadores/                              fitCamera / move sobre
  clustering)                              el MapController local)

  tap marcador ──► selectedMapReportProvider.select(id)
                        |
                        v
                 ReportSummaryCard (Report tomado de mapMarkersProvider por id)
                        |
        tap tarjeta ──► clear() + context.go('/mis-reportes/<id>')  ──► ReportDetailScreen (003)
```

## 5. Sin cambios de esquema ni de índices

- Colección `reports`: sin campos nuevos. `latitude`/`longitude` ya están en el contrato vigente
  (`specs/003-mis-reportes/contracts/reports-schema.md`).
- Consulta: se reutiliza `ReportQueryService.watchReportsByDevice` (igualdad por `deviceId` +
  `orderBy createdAt desc`) — índice de campo único, **sin índice compuesto nuevo**.
- Storage / reglas: sin cambios.
