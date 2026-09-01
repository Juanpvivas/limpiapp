# Implementation Plan: Mapa de Reportes

**Branch**: `004-mapa-de-reportes` | **Date**: 2026-08-31 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-mapa-de-reportes/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Reemplazar el placeholder del tab "Mapa" por un mapa interactivo de Ibagué que muestra **solo los
reportes del propio dispositivo** como marcadores coloreados por estado (rojo/naranja/verde), con
leyenda, agrupación de marcadores próximos, filtro por estado (selección única, independiente del
de "Mis reportes"), y una tarjeta resumen al tocar un marcador que abre el "Detalle del reporte" ya
existente.

Enfoque técnico: **cero backend nuevo y cero capa Data nueva**. El origen de datos es el provider
`myReportsProvider` de la feature 003 tal cual (ya resuelve `deviceId` + stream en tiempo real +
`AsyncValue`). El único cambio de Data/Domain es exponer en la lectura las coordenadas que la
colección `reports` **ya persiste** pero que `Report`/`ReportDto.fromFirestore` hoy no leen de
vuelta (`latitude`/`longitude`). Todo lo demás es capa Presentation nueva en `lib/ui/map/`:
3 providers de Riverpod (filtro del mapa `keepAlive`, marcadores derivados, reporte seleccionado) y
un árbol de widgets sobre `flutter_map` + `flutter_map_marker_cluster` (aprobados en la
constitución v2.4.0). La navegación al detalle usa `context.go('/mis-reportes/:reportId')`
(declarativa) para cruzar de la rama "Mapa" a la ruta anidada bajo la rama "Inicio", evitando el
`goBranch` manual que causó el bug de la feature 001.

## Technical Context

**Language/Version**: Dart, Flutter SDK `^3.13.1` (ya fijado en `pubspec.yaml`).

**Primary Dependencies**:
- `flutter_map` + `latlong2` — **nuevos**, aprobados en la constitución v2.4.0. Mapa base sobre
  teselas de OpenStreetMap, sin API key ni facturación. Atribución OSM visible obligatoria
  (FR-026).
- `flutter_map_marker_cluster` — **nuevo**, aprobado en v2.4.0. Agrupación de marcadores próximos
  con conteo (FR-010/FR-011). Ver research.md §1 para el riesgo de compatibilidad de versiones y su
  plan B.
- `flutter_riverpod` + `riverpod_annotation` — 3 providers nuevos de Presentation, ninguno toca
  Data directamente.
- `cloud_firestore` — ya en uso; esta feature **no** agrega consultas ni índices (reutiliza
  `ReportQueryService.watchReportsByDevice` de la 003). Solo se lee `latitude`/`longitude` de los
  documentos que ya se traen.
- `freezed` + `build_runner` (dev) — regeneración de `Report` al agregar `latitude`/`longitude`.
- `go_router` — ya en uso; **sin rutas nuevas** (la ruta `/mis-reportes/:reportId` ya existe desde
  la 003). Solo se usa `context.go(...)` desde el mapa.
- `mocktail` (dev) — solo si se agrega un test unitario de `ReportDto.fromFirestore` para las
  coordenadas; la lógica de marcadores/filtro se testea con `ProviderContainer`.

Ningún paquete fuera de la lista aprobada por la constitución (Principio I, v2.4.0).

**Storage**: Firestore, colección `reports` — **sin cambios de esquema**. `latitude`/`longitude`
ya están documentados como `number | null` en
`specs/003-mis-reportes/contracts/reports-schema.md` (heredados de "Crear Reporte"); esta feature
solo empieza a leerlos. Ningún índice compuesto nuevo.

**Testing**: `ProviderContainer` para los 3 providers nuevos (con `myReportsProvider` sobrescrito
por streams controlados); `WidgetTester` para la pantalla del mapa (carga / error+reintento /
vacío sobre el mapa / leyenda / tap en marcador → tarjeta → navegación / una tarjeta a la vez);
extensión de `report_list_repository_impl_test.dart` para verificar el mapeo de coordenadas. Los
tests de widget usan un `TileProvider` falso para no pegarle a la red (research.md §7).

**Target Platform**: Android + iOS (ya en uso). Sin permisos nuevos (FR-027 — no se usa
`geolocator`/`permission_handler`).

**Project Type**: mobile-app — proyecto Flutter único. Agrega la carpeta feature-first
`lib/ui/map/{providers,widgets}` (hoy solo tiene el placeholder `widgets/report_map_screen.dart`);
extiende `domain/`/`data/` con cambios mínimos en 2 archivos compartidos.

**Performance Goals**: el mapa muestra su estado inicial (marcadores o estado vacío) en menos de
3 s tras abrir el tab, en red normal (SC-004); un cambio de estado de un reporte se refleja en el
color del marcador en menos de 5 s sin recargar (SC-006). Volumen objetivo: decenas de reportes
por dispositivo, no miles (Assumption de spec.md).

**Constraints**:
- Los fallos de teselas de `flutter_map` (sin conexión, proveedor caído) **no** se envuelven en
  `Failure` — se degradan en Presentación (constitución v2.4.0, Principio V). El mapa queda sin
  mosaicos pero con marcadores y controles operativos.
- El filtro del mapa es **independiente** del de "Mis reportes" (FR-015) → provider propio, no se
  reutiliza `reportFilterProvider`.
- El filtro se conserva al volver del detalle (FR-028) → provider `keepAlive` + la rama "Mapa"
  permanece montada en el `IndexedStack` del shell.
- No hay un "tab Mis reportes": `/mis-reportes/:reportId` está anidada bajo la rama **Inicio**
  (routes.dart, feature 001). Navegar allí desde el mapa cambia la rama activa a Inicio
  (research.md §5).

**Scale/Scope**: 1 pantalla (reemplaza `report_map_screen.dart`), ~8 sub-widgets nuevos + 1 helper
no-widget, 3 providers nuevos, 2 archivos compartidos modificados (`report.dart`,
`report_dto.dart`), 1 refactor menor (extraer la miniatura de foto de `report_list_item.dart` para
reusarla en la tarjeta), 3 dependencias nuevas ya aprobadas. Sin cambios en `routes.dart`,
`service_locator.dart` ni `main.dart`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Aplica a esta feature | Estado |
|---|---|---|
| I. Stack Tecnológico Oficial | Usa exclusivamente paquetes aprobados. `flutter_map`, `latlong2` y `flutter_map_marker_cluster` fueron agregados a la lista en la enmienda **v2.4.0** justamente para esta feature. El resto (`flutter_riverpod`, `cloud_firestore`, `go_router`, `freezed`, `mocktail`) ya estaba en uso. **Riesgo** (research.md §1): si al instalar, `flutter_map_marker_cluster` no es compatible con la major de `flutter_map` disponible, el plan B es `flutter_map_supercluster`, que **requeriría otra enmienda** a la constitución antes de implementar — no es una violación del plan actual, es un follow-up condicional. | ✅ PASS (con riesgo registrado) |
| II. Clean Architecture en Capas | Domain: `report.dart` gana 2 campos (`latitude`/`longitude`) + un getter `isMappable` — misma clase compartida que ya extendió la 003. Data: `report_dto.dart` lee esos 2 campos en `fromFirestore` (los documentos ya los traen). **No** se crean interfaces, Repositories ni Services nuevos: se reutiliza `ReportListRepository`/`myReportsProvider` de la 003. Presentation nueva (`lib/ui/map/`) depende solo de `myReportsProvider` (Stream ya expuesto) y del enum de dominio `ReportStatus`; nunca importa `lib/data/`. | ✅ PASS |
| III. Convenciones de Código y Estilo Dart | `ReportMapScreen` es un `ConsumerWidget` (solo lee providers vía `ref.watch`). El `MapController` local (controlador efímero, Excepción del Principio III) vive en `map_view.dart`, que por eso es `ConsumerStatefulWidget` (research.md §8, tasks T012). Los sub-widgets que solo reciben datos por constructor (`MapLegend`, `ReportSummaryCard`, `ReportPhotoThumbnail`) son `StatelessWidget`. `snake_case.dart`, `PascalCase`, `const` obligatorio. | ✅ PASS |
| IV. Restricciones Estrictas | Sin `setState` para estado de negocio (filtro/selección/markers viven en providers de Riverpod; el `MapController` es estado local efímero permitido). Ningún archivo de `lib/ui/map/` importa `lib/data/`. La pantalla se divide en ~8 sub-widgets para respetar el límite de 200 líneas por archivo de UI. `context.mounted` se verifica tras cualquier `await` en callbacks. | ✅ PASS |
| V. Inyección de Dependencias y Manejo de Errores | No se registra nada nuevo en `service_locator.dart` (se reutilizan `ReportListRepository` y `DeviceIdentifierRepository` ya registrados). Los errores de datos llegan como `AsyncError` vía `myReportsProvider` (que ya traduce `Left(Failure)` → `ReportsFailureException`), la pantalla los muestra con reintento (FR-025). Los errores de renderizado de teselas de `flutter_map` **no** se mapean a `Failure`: se manejan con `errorTileCallback`/`evictErrorTileStrategy` degradando la vista, exactamente como aclara el Principio V en v2.4.0. | ✅ PASS |

No hay violaciones que requieran entrada en Complexity Tracking. El único riesgo abierto
(compatibilidad `flutter_map` ↔ plugin de clustering) se resuelve en research.md §1 con un plan B
explícito.

## Project Structure

### Documentation (this feature)

```text
specs/004-mapa-de-reportes/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output — contrato de lectura + contrato de UI del mapa
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
# Mobile-app — proyecto Flutter único, layout layer-first ya fijado en docs/ARCHITECTURE.md.
# Esta feature agrega lib/ui/map/ y toca 2 archivos compartidos + 1 refactor menor.

limpiapp/
├── pubspec.yaml                                       # MODIFICADO — +flutter_map, +latlong2,
│                                                       #   +flutter_map_marker_cluster
├── lib/
│   ├── config/
│   │   ├── routes.dart                                # SIN CAMBIOS — la ruta /mis-reportes/:reportId
│   │   │                                               #   ya existe; el mapa navega con context.go()
│   │   └── service_locator.dart                       # SIN CAMBIOS — reutiliza Repositories de la 003
│   ├── domain/models/
│   │   ├── report.dart                                # MODIFICADO — +latitude, +longitude, +isMappable
│   │   └── report.freezed.dart                        # REGENERADO (build_runner)
│   ├── data/model/
│   │   └── report_dto.dart                            # MODIFICADO — fromFirestore lee latitude/longitude
│   └── ui/
│       ├── core/ui/
│       │   └── report_photo_thumbnail.dart            # NUEVO — miniatura de foto extraída de
│       │                                               #   report_list_item.dart, reusable
│       ├── reports/widgets/
│       │   └── report_list_item.dart                  # MODIFICADO — usa ReportPhotoThumbnail
│       └── map/
│           ├── providers/
│           │   ├── map_report_filter_provider.dart    # NUEVO — @Riverpod(keepAlive:true) Notifier<ReportFilter>
│           │   ├── map_markers_provider.dart          # NUEVO — derivado: AsyncValue<List<Report>> mapeables+filtrados
│           │   └── selected_map_report_provider.dart  # NUEVO — Notifier<String?> (reportId de la tarjeta)
│           └── widgets/
│               ├── report_map_screen.dart             # REEMPLAZA el placeholder (FR-001..FR-028)
│               ├── map_view.dart                      # NUEVO — ConsumerStatefulWidget: FlutterMap +
│               │                                       #   MapController local + TileLayer + capas
│               ├── map_marker_cluster_layer.dart      # NUEVO — MarkerClusterLayer + builders de marcador/clúster
│               ├── report_marker_style.dart           # NUEVO — helpers no-widget: color por estado,
│               │                                       #   ibagueCenter, zooms, entradas de leyenda
│               ├── map_legend.dart                    # NUEVO — leyenda color→estado (FR-007)
│               ├── map_filter_control.dart            # NUEVO — icono embudo + hoja de selección única (FR-012/FR-013)
│               ├── report_summary_card.dart           # NUEVO — tarjeta resumen (FR-017..FR-020)
│               ├── map_empty_overlay.dart             # NUEVO — mensaje sobre el mapa de Ibagué (FR-023/FR-024)
│               └── map_error_state.dart               # NUEVO — error + reintento (FR-025)
└── test/
    ├── data/repositories/
    │   └── report_list_repository_impl_test.dart      # AMPLIADO — verifica mapeo de latitude/longitude
    └── ui/map/
        ├── map_report_filter_provider_test.dart       # NUEVO — ProviderContainer: inicial, select, independencia
        ├── map_markers_provider_test.dart             # NUEVO — ProviderContainer: feliz, sin-coords excluido,
        │                                               #   loading, error, filtro
        └── report_map_screen_test.dart                # NUEVO — WidgetTester: carga/error/vacío/leyenda/
                                                        #   tarjeta/navegación/una-a-la-vez
```

**Structure Decision**: proyecto Flutter único (mobile-app). La feature es casi enteramente
Presentation: se agrega `lib/ui/map/{providers,widgets}` feature-first (mismo patrón que
`lib/ui/reports/`). Los únicos toques fuera de `ui/map/` son: (1) `report.dart` +
`report_dto.dart` para exponer coordenadas ya persistidas — se **modifican**, no se duplican,
porque `Report` es una entidad compartida a nivel de proyecto (mismo criterio con que la 003 la
extendió); (2) un refactor menor que extrae la miniatura de foto de `report_list_item.dart` a
`lib/ui/core/ui/report_photo_thumbnail.dart` para reusarla en la tarjeta del mapa sin duplicar
código. `routes.dart`, `service_locator.dart` y `main.dart` no cambian.

## Complexity Tracking

*Sin violaciones que justificar — todos los gates de la Constitution Check pasaron (PASS). El
riesgo de compatibilidad de `flutter_map_marker_cluster` se rastrea en research.md §1 con un plan B
que, de activarse, dispara una enmienda a la constitución antes de implementar (no es deuda de
arquitectura).*
