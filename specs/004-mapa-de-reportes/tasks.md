---
description: "Task list for Mapa de Reportes (004)"
---

# Tasks: Mapa de Reportes

**Input**: Design documents from `/specs/004-mapa-de-reportes/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/map-contract.md](./contracts/map-contract.md)

**Tests**: incluidos. La constitución (Flujo de Desarrollo y Calidad) obliga a tests con
`ProviderContainer` para todo Notifier/AsyncNotifier nuevo y a tests con `mocktail` para todo
Repository; el plan y el quickstart enumeran los archivos de test. Los tests van adyacentes a su
implementación y deben pasar antes de dar la tarea por hecha.

**Organization**: agrupado por User Story (spec.md) para entrega incremental. MVP = User Story 1.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: puede correr en paralelo (archivo distinto, sin dependencias pendientes)
- **[Story]**: US1 / US2 / US3 (solo en fases de User Story)
- Rutas relativas a la raíz del repo (`limpiapp/`)

## Path Conventions

Proyecto Flutter único (mobile-app). Código en `lib/`, tests en `test/`. La feature agrega
`lib/ui/map/{providers,widgets}` y toca 2 archivos compartidos (`lib/domain/models/report.dart`,
`lib/data/model/report_dto.dart`).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: dependencias del mapa y verificación del riesgo de compatibilidad (research.md §1).

- [x] T001 Agregar las 3 dependencias aprobadas (constitución v2.4.0) a `pubspec.yaml` y resolver: `flutter pub add flutter_map latlong2 flutter_map_marker_cluster` seguido de `flutter pub get`.
- [x] T002 Gate de compatibilidad (research.md §1): confirmar que `pub` resolvió `flutter_map_marker_cluster` contra la major instalada de `flutter_map` y que `flutter analyze` compila un import de prueba de `MarkerClusterLayerWidget`. Si NO resuelve, DETENER: ejecutar `/speckit-constitution` para aprobar el plan B (`flutter_map_supercluster`) y actualizar `pubspec.yaml` + [research.md](./research.md) §1 + [plan.md](./plan.md) antes de continuar.

**Checkpoint**: dependencias del mapa instaladas y verificadas.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: exponer las coordenadas que la colección `reports` ya persiste, y el provider de
filtro que `mapMarkersProvider` necesita. Bloquea las 3 User Stories.

**⚠️ CRITICAL**: ninguna User Story puede empezar hasta terminar esta fase.

- [x] T003 Extender el modelo de dominio en `lib/domain/models/report.dart`: agregar `double? latitude`, `double? longitude` y el getter puro `bool get isMappable` (regla exacta en [data-model.md](./data-model.md) §1). Sin imports de Flutter.
- [x] T004 Regenerar código freezed: `dart run build_runner build --delete-conflicting-outputs` (actualiza `lib/domain/models/report.freezed.dart`). Depende de T003.
- [x] T005 Extender `lib/data/model/report_dto.dart`: en `fromFirestore`, leer `latitude`/`longitude` como `(data['x'] as num?)?.toDouble()`. `toFirestoreMap` y `fromSubmission` NO cambian. Depende de T003.
- [x] T006 [P] Ampliar `test/data/repositories/report_list_repository_impl_test.dart`: verificar que `latitude`/`longitude` se mapean desde el registro de Firestore, y que ausentes / `null` / tipo inesperado → `null`. Depende de T005.
- [x] T007 Crear `lib/ui/map/providers/map_report_filter_provider.dart`: `@Riverpod(keepAlive: true)` `Notifier<ReportFilter>` que reutiliza el enum `ReportFilter` de `lib/ui/reports/providers/report_filter.dart`, inicia en `ReportFilter.todos`, método `select(ReportFilter)`. Correr `dart run build_runner build` para el `.g.dart`.
- [x] T008 [P] Crear `test/ui/map/map_report_filter_provider_test.dart` (`ProviderContainer`): valor inicial `todos`, `select()` cambia el estado, y una instancia de `mapReportFilterProvider` es independiente de `reportFilterProvider` (cambiar uno no afecta al otro — FR-015). Depende de T007.

**Checkpoint**: `Report` mapea coordenadas y el filtro del mapa existe — las User Stories pueden empezar.

---

## Phase 3: User Story 1 - Ver mis reportes sobre el mapa (Priority: P1) 🎯 MVP

**Goal**: reemplazar el placeholder del tab "Mapa" por un mapa de Ibagué con los reportes del
dispositivo como marcadores coloreados por estado, con leyenda, agrupación de marcadores próximos,
encuadre automático, y estados de carga / error / vacío.

**Independent Test**: con ≥ 1 reporte con coordenadas enviado desde el dispositivo, abrir el tab
"Mapa" y verificar: mapa OSM con atribución, un marcador por reporte mapeable en su posición,
color por estado (rojo/naranja/verde) + leyenda, encuadre que muestra todos, agrupación cuando
están próximos, y actualización en vivo al cambiar `status` en Firestore. Sin reportes: mapa de
Ibagué + mensaje.

### Implementation for User Story 1

- [x] T009 [P] [US1] Crear `lib/ui/map/widgets/report_marker_style.dart` (helpers no-widget): `Color markerColorFor(ReportStatus)` (pendiente=rojo, enProceso=naranja, solucionado=verde — [research.md](./research.md) §6), `kMarkerLegend`, `kIbagueCenter = LatLng(4.4389, -75.2322)`, `kCityZoom = 12.0`, `kSingleMarkerZoom = 15.0`, `kClusterNeutralColor`.
- [x] T010 [US1] Crear `lib/ui/map/providers/map_markers_provider.dart`: provider derivado que hace `ref.watch(myReportsProvider)` (feature 003, sin cambios) + `ref.watch(mapReportFilterProvider)`, aplica `filter.apply(reports).where((r) => r.isMappable)` y expone `AsyncValue<List<Report>>`. Correr `build_runner`. Depende de T005, T007.
- [x] T011 [P] [US1] Crear `test/ui/map/map_markers_provider_test.dart` (`ProviderContainer`, `myReportsProvider` sobrescrito con streams controlados): caso feliz con mezcla de estados, reporte sin coordenadas excluido, `loading`, `error` propagado como `AsyncError`, filtro aplicado reduce la lista, y una segunda emisión del stream (reporte agregado o `status` cambiado) actualiza la lista derivada sin recrear el provider (FR-021). Depende de T010.
- [x] T012 [US1] Crear `lib/ui/map/widgets/map_view.dart` (`ConsumerStatefulWidget` con `MapController` local — controlador efímero, Excepción Principio III): `FlutterMap` + `TileLayer` OSM (`urlTemplate` `https://tile.openstreetmap.org/{z}/{x}/{y}.png`, `userAgentPackageName: 'com.juanpvivas.limpiapp'`, `errorTileCallback` no-op/log, `evictErrorTileStrategy: EvictErrorTileStrategy.notVisible`) + `RichAttributionWidget` con "OpenStreetMap contributors" (FR-026). Depende de T009.
- [x] T013 [US1] Crear `lib/ui/map/widgets/map_marker_cluster_layer.dart`: capa de `flutter_map_marker_cluster` que construye un `Marker` por `Report` de `mapMarkersProvider` con `Icon(Icons.location_pin, color: markerColorFor(status))` (sin assets — FR-006); burbuja de clúster de color neutro con el conteo; `zoomToBoundsOnClick: true` (FR-010/FR-011). Depende de T010, T012.
- [x] T014 [US1] Encuadre automático en `lib/ui/map/widgets/map_view.dart` vía `ref.listen(mapMarkersProvider, ...)`: ≥ 2 → `mapController.fitCamera(CameraFit.bounds(...))` con padding; == 1 → `move(punto, kSingleMarkerZoom)`; == 0 → `move(kIbagueCenter, kCityZoom)` (FR-008/FR-009). Recalcula al abrir y al cambiar el filtro (FR-016). Depende de T012, T010.
- [x] T015 [P] [US1] Crear `lib/ui/map/widgets/map_legend.dart` (`StatelessWidget`): leyenda color→estado a partir de `kMarkerLegend` (FR-007). Depende de T009.
- [x] T016 [P] [US1] Crear `lib/ui/map/widgets/map_empty_overlay.dart` (`StatelessWidget`): mensaje sobre el mapa con dos variantes — "aún no has enviado reportes" (sin reportes mapeables, FR-023) y "sin reportes en este estado" (por filtro, FR-024) vía un parámetro `filtered`.
- [x] T017 [P] [US1] Crear `lib/ui/map/widgets/map_error_state.dart` (`StatelessWidget`): mensaje + botón "Reintentar" que recibe un `onRetry` (la pantalla lo cablea a `ref.invalidate(myReportsProvider)`) (FR-025).
- [x] T018 [US1] Reemplazar el placeholder `lib/ui/map/widgets/report_map_screen.dart` por la pantalla real (`ConsumerWidget`): `Scaffold` + `AppBar('Mapa de reportes')` + `Stack` con `ref.watch(mapMarkersProvider).when(loading: spinner centrado (FR-022), error: MapErrorState, data: (reports) => MapView + MapMarkerClusterLayer + MapLegend, y MapEmptyOverlay encima si `reports` vacío)`. Depende de T010, T012, T013, T014, T015, T016, T017.
- [x] T019 [US1] Crear `test/ui/map/report_map_screen_test.dart` (`WidgetTester` + `TileProvider` falso 1×1, viewport fijo — [research.md](./research.md) §7): estado de carga (spinner), estado de error (mensaje + "Reintentar"), estado vacío (overlay sobre el mapa), leyenda presente, marcadores renderizados con color por estado, reportes próximos agrupados en clúster con conteo; al emitir el stream un reporte nuevo / con `status` distinto, el marcador aparece / cambia de color sin recargar (FR-021); verificar que ningún archivo de `lib/ui/map/` importa `geolocator`/`permission_handler` y que no hay marcador de ubicación del usuario (FR-027). Depende de T018.

**Checkpoint**: MVP funcional — el tab "Mapa" muestra los reportes del dispositivo, se prueba solo.

---

## Phase 4: User Story 2 - Consultar un reporte desde su marcador (Priority: P2)

**Goal**: al tocar un marcador aparece una tarjeta resumen; al tocarla se abre el "Detalle del
reporte" de la feature 003, activando la rama "Inicio".

**Independent Test**: con un marcador visible, tocarlo → tarjeta con miniatura, número, chip de
estado, tipo de residuo, dirección y fecha; tocar otro marcador la reemplaza; tocar fuera / cerrar
la oculta; tocar la tarjeta abre `ReportDetailScreen` y la barra inferior pasa a "Inicio".

### Implementation for User Story 2

- [x] T020 [P] [US2] Crear `lib/ui/core/ui/report_photo_thumbnail.dart` extrayendo el widget privado `_Thumbnail` de `lib/ui/reports/widgets/report_list_item.dart` (miniatura con `Image.network`, placeholders de carga/error). `StatelessWidget`, recibe `url` por constructor.
- [x] T021 [US2] Actualizar `lib/ui/reports/widgets/report_list_item.dart` para usar `ReportPhotoThumbnail` en vez del `_Thumbnail` local (sin cambio visual). Depende de T020.
- [x] T022 [P] [US2] Crear `lib/ui/map/providers/selected_map_report_provider.dart`: `@riverpod` `Notifier<String?>` (el `Report.id` del marcador seleccionado; `null` = sin tarjeta), métodos `select(String)` y `clear()`, auto-dispose. Correr `build_runner`.
- [x] T023 [P] [US2] Crear `test/ui/map/selected_map_report_provider_test.dart` (`ProviderContainer`): inicial `null`, `select(id)` fija el id, `select(otro)` lo reemplaza, `clear()` vuelve a `null` (FR-018). Depende de T022.
- [x] T024 [US2] Crear `lib/ui/map/widgets/report_summary_card.dart` (`StatelessWidget`): recibe `Report` + `onTap` + `onClose`; muestra `ReportPhotoThumbnail`, `report.reportNumber`, `ReportStatusChip(status: report.status)`, `report.category.label`, `report.address` (elipsis), `formatReportDateTime(report.createdAt)` (FR-017). Nota: el chip conserva la paleta de `ReportStatusChip` (ámbar/azul/verde), distinta de la de los marcadores (rojo/naranja/verde) — divergencia deliberada, ver [research.md](./research.md) §6; confirmar en review. Depende de T020.
- [x] T025 [US2] En `lib/ui/map/widgets/map_marker_cluster_layer.dart`: cablear el tap de un marcador individual a `ref.read(selectedMapReportProvider.notifier).select(report.id)`. Depende de T013, T022.
- [x] T026 [US2] En `lib/ui/map/widgets/report_map_screen.dart`: cuando `selectedMapReportProvider != null`, resolver el `Report` por id desde la lista de `mapMarkersProvider` y mostrar `ReportSummaryCard` con `Align(bottomCenter)`; agregar un `GestureDetector` transparente sobre el mapa (solo cuando hay tarjeta) que llama `clear()` (FR-019); `onTap` de la tarjeta → `clear()` + `context.go('$misReportesPath/${report.id}')` ([research.md](./research.md) §5, FR-020). Depende de T018, T022, T024.
- [x] T027 [US2] Ampliar `test/ui/map/report_map_screen_test.dart`: tap en marcador → tarjeta con los campos; tap en otro marcador → reemplaza (una sola tarjeta); tap fuera / botón cerrar → se oculta; tap en la tarjeta → navegación a `/mis-reportes/:id` (verificar con un router espía / `GoRouter` de test). Depende de T026.

**Checkpoint**: US1 + US2 funcionan de forma independiente.

---

## Phase 5: User Story 3 - Filtrar el mapa por estado (Priority: P3)

**Goal**: control de filtro (icono embudo) de selección única en la barra superior, independiente
del filtro de "Mis reportes", que se conserva al volver del detalle.

**Independent Test**: con reportes en ≥ 2 estados, abrir el filtro → elegir "Pendiente" → solo
marcadores pendientes y re-encuadre; elegir un estado vacío → aviso "sin reportes en este estado"
con el mapa visible; el filtro de la lista "Mis reportes" no cambió; tras abrir un detalle y
volver al tab "Mapa", el filtro elegido sigue aplicado.

### Implementation for User Story 3

- [x] T028 [P] [US3] Crear `lib/ui/map/widgets/map_filter_control.dart` (`ConsumerWidget`): `IconButton(Icons.filter_list)` que abre una hoja/menú de **selección única** con "Todos" (default), "Pendiente", "En proceso", "Solucionado", cableada a `ref.read(mapReportFilterProvider.notifier).select(...)` (FR-012/FR-013). Muestra la selección actual.
- [x] T029 [US3] Agregar `MapFilterControl` a `AppBar.actions` en `lib/ui/map/widgets/report_map_screen.dart`. Depende de T018, T028.
- [x] T030 [US3] En `lib/ui/map/widgets/report_map_screen.dart`: distinguir vacío-total vs vacío-por-filtro para elegir la variante de `MapEmptyOverlay` (comparar `myReportsProvider` mapeables totales vs lista filtrada de `mapMarkersProvider`) (FR-024). Depende de T016, T018.
- [x] T031 [US3] Ampliar `test/ui/map/report_map_screen_test.dart` (y/o `map_report_filter_provider_test.dart`): cambiar el filtro reduce los marcadores visibles y dispara re-encuadre; filtro sin resultados → mensaje "sin reportes en este estado" con mapa visible; el filtro del mapa no afecta a `reportFilterProvider`; tras `context.go` al detalle y volver, `mapReportFilterProvider` conserva el valor (keepAlive — FR-028). Depende de T029, T030.

**Checkpoint**: las 3 User Stories funcionan de forma independiente.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: cierre, verificación y documentación.

- [x] T032 [P] Actualizar la tabla de features de `README.md`: marcar "Mis Reportes" (003) como implementada/mergeada, "Crear Reporte" como implementada (no "pendiente /speckit-plan"), y agregar la fila de "Mapa de Reportes" (004).
- [x] T033 [P] Verificar que `docs/ARCHITECTURE.md` y `.specify/memory/constitution.md` (v2.4.0) siguen coherentes con lo implementado (el uso de mapa ya se sincronizó); ajustar solo si el código final difiere del contrato.
- [x] T034 Ejecutar `dart format .` y `flutter analyze` — sin errores ni warnings (Flujo de Desarrollo de la constitución).
- [x] T035 Ejecutar `flutter test` — toda la suite en verde (incluye los 4 archivos de test nuevos/ampliados).
- [~] T036 Ejecutar los escenarios 1–4 de [quickstart.md](./quickstart.md) en un dispositivo/emulador real con datos de Firestore (incluye el caso sin conexión: teselas caídas pero marcadores/filtro/tarjeta operativos); medir con cronómetro que el estado inicial aparece < 3 s (SC-004) y que un cambio de `status` en Firestore se refleja < 5 s (SC-006). PARCIAL: smoke test en iOS Simulator OK (build, mapa OSM carga, empty state, leyenda, filtro, atribución, sin excepciones Dart). Falta el QA manual completo con reportes sembrados en varios estados y el caso sin conexión.
- [x] T037 [P] Actualizar la memoria del proyecto: nota de la feature 004 (implementada) y su pointer en `MEMORY.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias. T002 es un gate: si falla, se dispara `/speckit-constitution` antes de seguir.
- **Foundational (Phase 2)**: depende de Setup. BLOQUEA las 3 User Stories.
- **User Stories (Phase 3–5)**: dependen de Foundational.
  - US1 (P1) no depende de US2 ni US3.
  - US2 (P2) y US3 (P3) extienden `report_map_screen.dart` de US1 → en la práctica se hacen después de US1, pero cada una es testeable de forma independiente sobre el MVP.
- **Polish (Phase 6)**: depende de las User Stories que se quieran entregar.

### User Story Dependencies

- **US1**: solo Foundational.
- **US2**: Foundational + la pantalla base de US1 (T018) para colgar la tarjeta y el tap-outside.
- **US3**: Foundational + la pantalla base de US1 (T018) para colgar el control de filtro en el `AppBar`.

### Within Each User Story

- Helpers/providers antes de los widgets que los consumen.
- `map_view.dart` antes de la capa de marcadores/clustering.
- La pantalla integradora (`report_map_screen.dart`) después de sus sub-widgets.
- El test de cada provider/pantalla, adyacente y verde antes de cerrar la tarea.

### Parallel Opportunities

- **Setup**: T001 → T002 (secuencial).
- **Foundational**: T006 ‖ (T003→T004, T003→T005); T007 → T008. T006 ‖ T007.
- **US1**: T009 ‖ T015 ‖ T016 ‖ T017 (archivos distintos). T011 ‖ (tras T010). T012 tras T009; T013 tras T010+T012; T014 tras T012+T010; T018 tras T010,T012–T017.
- **US2**: T020 ‖ T022 (distintos archivos); T023 tras T022; T021 tras T020; T024 tras T020; T025 tras T013+T022; T026 tras T018+T022+T024; T027 tras T026.
- **US3**: T028 ‖ (independiente hasta T029). T029 tras T018+T028; T030 tras T016+T018; T031 tras T029+T030.
- **Polish**: T032 ‖ T033 ‖ T037; T034 → T035 → T036 (secuencial).

---

## Parallel Example: User Story 1

```bash
# Widgets "hoja" de US1 (archivos distintos, sin dependencias entre sí):
Task: "T009 Crear lib/ui/map/widgets/report_marker_style.dart"
Task: "T015 Crear lib/ui/map/widgets/map_legend.dart"          # tras T009
Task: "T016 Crear lib/ui/map/widgets/map_empty_overlay.dart"
Task: "T017 Crear lib/ui/map/widgets/map_error_state.dart"

# Provider + su test:
Task: "T010 Crear lib/ui/map/providers/map_markers_provider.dart"
Task: "T011 Crear test/ui/map/map_markers_provider_test.dart"   # tras T010
```

---

## Implementation Strategy

### MVP First (solo User Story 1)

1. Phase 1: Setup (incluye el gate de compatibilidad T002).
2. Phase 2: Foundational (coordenadas en `Report` + provider de filtro).
3. Phase 3: User Story 1.
4. **PARAR y VALIDAR**: probar el tab "Mapa" con el Independent Test de US1 y el escenario 1 del quickstart.
5. Entregar/demo (MVP).

### Incremental Delivery

1. Setup + Foundational → base lista.
2. US1 → mapa con marcadores, leyenda, clustering, estados → demo (MVP).
3. US2 → tarjeta resumen + navegación al detalle → demo.
4. US3 → filtro por estado → demo.
5. Polish → README/memoria, `analyze`/`test`/quickstart completos.

---

## Notes

- `[P]` = archivos distintos, sin dependencias pendientes.
- La feature es casi toda Presentation: **no** hay tareas de Repository/Service/índices/reglas nuevas — se reutiliza `myReportsProvider` (003).
- Riesgo activo: T002. Si `flutter_map_marker_cluster` no es compatible, el plan B (`flutter_map_supercluster`) exige `/speckit-constitution` antes de T009+.
- `routes.dart`, `service_locator.dart` y `main.dart` NO se tocan.
- Correr `dart run build_runner build --delete-conflicting-outputs` tras T003 y tras cada provider nuevo con `@riverpod` (T007, T010, T022).
- Commit tras cada tarea o grupo lógico; `dart format .` + `flutter analyze` antes de cada commit.
