# Implementation Plan: Mis Reportes

**Branch**: `003-mis-reportes` | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-mis-reportes/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Construir "Mis reportes" (lista filtrable por estado, en tiempo real) y "Detalle del reporte"
(información completa + línea de tiempo de seguimiento de solo lectura), reutilizando por completo
el backend de Firestore ya creado por "Crear Reporte" — sin backend nuevo. Enfoque técnico: se
extiende el esquema de la colección `reports` con 4 campos (`status`, `deviceId`, `inProgressAt`,
`resolvedAt`, ver `contracts/reports-schema.md`), se agrega un identificador anónimo de
dispositivo persistido con `shared_preferences` (sin dependencias nuevas, generado con
`Random.secure()` de `dart:math`), y se lee la colección con streams de Firestore envueltos en
Services delgados que devuelven tipos propios de Dart (nunca `DocumentSnapshot`/`Query` crudos),
para mantener el Repository testeable con `mocktail` igual que en la feature anterior. Presentation
usa providers de Riverpod basados en `Stream` (no un `Notifier` con `Future`, a diferencia de
"Crear Reporte"), dado que esta feature refleja un flujo continuo de datos, no acciones puntuales
del usuario.

## Technical Context

**Language/Version**: Dart, Flutter SDK `^3.13.1` (ya fijado en `pubspec.yaml`)

**Primary Dependencies**:
- `cloud_firestore` — ya aprobado y en uso; esta feature solo lee (`.snapshots()`), no escribe
  colecciones nuevas.
- `shared_preferences` — ya aprobado en la constitución (v2.2.0) pero nunca agregado como
  dependencia real hasta ahora: esta es la primera feature en usarlo (persistencia del
  identificador anónimo de dispositivo).
- `flutter_riverpod` + `riverpod_annotation` — 2 providers nuevos basados en `Stream`
  (`myReportsProvider`, `reportDetailProvider`) y 1 `Notifier` simple para el filtro de pestaña
  seleccionada.
- `get_it` — registra los 2 Services y 2 Repositories nuevos.
- `fpdart` — `Either<Failure, T>` en las 2 interfaces de Repository nuevas.
- `freezed` + `json_serializable` — extensión de `Report` (5 campos nuevos) y el nuevo enum
  `ReportStatus`.
- `go_router` — ya aprobado; se agrega una ruta nueva anidada (`/mis-reportes/:reportId`) y se
  reemplaza el placeholder de `/mis-reportes`.
- `mocktail` (dev) — tests de los 2 Repository nuevos mockeando sus Services.

Ningún paquete fuera de la lista ya aprobada por la constitución (Principio I) — `shared_preferences`
ya estaba aprobado desde v2.2.0, solo faltaba agregarse vía `flutter pub add`.

**Storage**: Firestore (extensión de la colección `reports` ya existente, ver
`contracts/reports-schema.md`) + `shared_preferences` (un solo valor: el identificador anónimo de
dispositivo, clave local, nunca sincronizado a la nube).

**Testing**: `flutter_test` + `ProviderContainer` para los 2 providers de `Stream` (alimentados con
streams controlados vía Repository mockeado) y el `Notifier` del filtro; `mocktail` para
`ReportListRepositoryImpl`/`DeviceIdentifierRepositoryImpl` mockeando sus Services (no el SDK de
Firebase/`shared_preferences` directamente — ver research.md §8); `WidgetTester` para la lista, los
filtros, el estado vacío, y el detalle con su línea de tiempo.

**Target Platform**: Android + iOS (ya en uso).

**Project Type**: mobile-app — proyecto Flutter único. Extiende `domain/`/`data/` ya poblados por
"Crear Reporte" (no crea las carpetas, agrega archivos dentro de ellas).

**Performance Goals**: la lista debe mostrarse en menos de 3 segundos tras abrir la pantalla
(SC-001) para un volumen típico de reportes por dispositivo (decenas, no miles — research.md §4).

**Constraints**: la pantalla de detalle debe reflejar cambios de estado sin recargar (Assumption de
spec.md) — implica una suscripción activa (`Stream`), no una carga de una sola vez; el filtro por
estado no debe requerir un índice compuesto nuevo de Firestore (research.md §4); "Detalle del
reporte" es estrictamente de solo lectura (FR-015, SC-005) — `ReportListRepository` no expone
ningún método de escritura, lo que hace la restricción verificable a nivel de interfaz.

**Scale/Scope**: 2 pantallas (reemplaza el placeholder `report_list_screen.dart` + agrega
`report_detail_screen.dart`), 2 interfaces de Repository nuevas + sus implementaciones, 2 Services
nuevos, 1 enum nuevo (`ReportStatus`), extensión de `Report` (5 campos) y de `Failure` (1 subtipo),
y un ajuste puntual a `ReportRepositoryImpl.submitReport` (feature "Crear Reporte") para escribir
el estado inicial y el `deviceId`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Aplica a esta feature | Estado |
|---|---|---|
| I. Stack Tecnológico Oficial | Usa exclusivamente paquetes ya aprobados: `cloud_firestore` (ya en uso), `shared_preferences` (aprobado desde v2.2.0, primera vez que se agrega como dependencia real), `flutter_riverpod`, `get_it`, `fpdart`, `freezed`/`json_serializable`, `go_router`, `mocktail`. El identificador de dispositivo se genera con `dart:math` (parte del SDK de Dart, no una dependencia) por decisión explícita del usuario, evitando una enmienda innecesaria para agregar `uuid`. Ningún paquete fuera de la lista aprobada. | ✅ PASS |
| II. Clean Architecture en Capas | `domain/models/report_status.dart` (nuevo), `report.dart` extendido, `failure.dart` extendido con `CacheFailure`; `domain/repositories/report_list_repository.dart` y `device_identifier_repository.dart` (nuevas interfaces). Data implementa esas interfaces (`report_list_repository_impl.dart`, `device_identifier_repository_impl.dart`) coordinando Services delgados (`report_query_service.dart`, `device_identifier_service.dart`) que nunca filtran tipos del SDK de Firestore hacia Domain/Presentation (research.md §3). Presentation (providers de `Stream`) solo depende de las interfaces de Domain. | ✅ PASS |
| III. Convenciones de Código y Estilo Dart | `ReportListScreen`/`ReportDetailScreen` son `ConsumerWidget` (leen providers vía `ref.watch`). Los sub-widgets que solo reciben datos ya resueltos por constructor (`ReportStatusChip`, `ReportFilterTabs`, `ReportListItem`, `ReportListEmptyState`, `ReportStatusTimeline`) son `StatelessWidget`: no leen ningún provider (Excepción del Principio III, mismo criterio que `ConfirmationScreen` en "Crear Reporte"). `snake_case.dart`, `PascalCase` en clases, `const` obligatorio donde el compilador lo permita. | ✅ PASS |
| IV. Restricciones Estrictas | Sin `setState` para estado de negocio (todo vive en providers de Riverpod). Ningún archivo de `lib/ui/reports/` importa `lib/data/`: los providers resuelven `getIt<T>()` (tipo interfaz) en su cuerpo. Archivos de widget se dividen en sub-widgets para respetar el límite de 200 líneas. `ReportListRepository` no expone ningún método de escritura (FR-015/SC-005 verificable a nivel de interfaz, no solo de convención). | ✅ PASS |
| V. Inyección de Dependencias y Manejo de Errores | `service_locator.dart` (ya existente) registra los 2 Services nuevos y las 2 Repository nuevas con `registerLazySingleton`, igual que las ya existentes — `SharedPreferences` no se registra como singleton síncrono (research.md §7: se resuelve de forma perezosa dentro de `DeviceIdentifierService`, ya que `getInstance()` es async y el resto del locator es síncrono). Los 4 métodos de Repository nuevos retornan `Either<Failure, T>` o `Stream<Either<Failure, T>>`. Toda excepción de Firestore/`shared_preferences` se captura y mapea a un `Failure` (`ServerFailure`, `NetworkFailure`, `CacheFailure` — nuevo) dentro de la implementación del Repository. | ✅ PASS |

No hay violaciones que requieran entrada en Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/003-mis-reportes/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command) — extensión del esquema de Firestore
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
# Mobile-app — proyecto Flutter único, layout layer-first ya fijado en docs/ARCHITECTURE.md.
# Esta feature extiende domain/ y data/ ya poblados por "Crear Reporte" (002).

limpiapp/lib/
├── config/
│   ├── routes.dart                                # MODIFICADO — reemplaza placeholder de
│   │                                               # /mis-reportes, agrega /mis-reportes/:reportId
│   └── service_locator.dart                       # MODIFICADO — registra 2 Services + 2 Repository nuevas
├── domain/
│   ├── models/
│   │   ├── report_status.dart                     # NUEVO — enum pendiente/enProceso/solucionado
│   │   ├── report.dart                            # MODIFICADO — +id, status, deviceId, inProgressAt, resolvedAt
│   │   └── failure.dart                           # MODIFICADO — +CacheFailure
│   └── repositories/
│       ├── report_list_repository.dart            # NUEVO — watchReports(deviceId), watchReportById(id)
│       └── device_identifier_repository.dart      # NUEVO — getDeviceId()
├── data/
│   ├── repositories/
│   │   ├── report_repository_impl.dart            # MODIFICADO — escribe status/deviceId al enviar
│   │   ├── report_list_repository_impl.dart       # NUEVO
│   │   └── device_identifier_repository_impl.dart # NUEVO
│   ├── services/
│   │   ├── firebase/
│   │   │   └── report_query_service.dart          # NUEVO — streams de solo lectura, tipos planos
│   │   └── device_identifier_service.dart         # NUEVO — genera/persiste el ID con shared_preferences
│   └── model/
│       └── report_dto.dart                        # MODIFICADO — +fromFirestore, toFirestoreMap +status/deviceId
├── ui/reports/
│   ├── providers/
│   │   ├── report_filter.dart                     # NUEVO — enum de UI (todos/pendientes/en proceso/solucionados)
│   │   ├── report_filter_provider.dart             # NUEVO — @riverpod Notifier simple (pestaña seleccionada)
│   │   ├── my_reports_provider.dart                # NUEVO — @riverpod Stream<List<Report>>
│   │   └── report_detail_provider.dart             # NUEVO — @riverpod Stream<Report?> (family por reportId)
│   └── widgets/
│       ├── report_list_screen.dart                 # REEMPLAZA el placeholder (FR-001 a FR-010)
│       ├── report_filter_tabs.dart                 # NUEVO — sub-widget: 4 pestañas
│       ├── report_list_item.dart                   # NUEVO — sub-widget: fila de la lista
│       ├── report_list_empty_state.dart            # NUEVO — sub-widget: estado vacío (general y por filtro)
│       ├── report_status_chip.dart                 # NUEVO — sub-widget: etiqueta de color reutilizada en lista+detalle
│       ├── report_detail_screen.dart               # NUEVO — pantalla "Detalle del reporte" (FR-011 a FR-016)
│       └── report_status_timeline.dart             # NUEVO — sub-widget: línea de tiempo de 3 pasos
└── main.dart                                        # SIN CAMBIOS

limpiapp/test/
├── data/
│   └── repositories/
│       ├── report_repository_impl_test.dart         # AMPLIADO — verifica status/deviceId al crear
│       ├── report_list_repository_impl_test.dart    # NUEVO — mocktail: stream feliz, error mapeado a Left
│       └── device_identifier_repository_impl_test.dart # NUEVO — mocktail: genera y reutiliza el ID
└── ui/
    └── reports/
        ├── report_filter_provider_test.dart          # NUEVO — ProviderContainer: selección de pestaña
        ├── my_reports_provider_test.dart              # NUEVO — ProviderContainer: stream feliz, error, filtro
        ├── report_detail_provider_test.dart            # NUEVO — ProviderContainer: stream feliz, "no encontrado"
        ├── report_list_screen_test.dart                # NUEVO — WidgetTester: lista, filtros, estado vacío
        └── report_detail_screen_test.dart              # NUEVO — WidgetTester: detalle + línea de tiempo
```

**Structure Decision**: proyecto Flutter único (mobile-app). Esta feature extiende las 3 capas ya
creadas por "Crear Reporte" (`ui/` → `domain/` → `data/`) sin crear ninguna carpeta nueva a nivel
de proyecto — solo agrega archivos dentro de las ya existentes, y feature-first dentro de
`ui/reports/` (mismo patrón ya usado). `report.dart`, `report_dto.dart`, `failure.dart` y
`report_repository_impl.dart` se modifican en lugar de duplicarse, porque `Report`/`Failure` son
entidades compartidas a nivel de proyecto (mismo criterio documentado en el plan de "Crear
Reporte" para que "Mis Reportes"/"Mapa de Reportes" las reutilizaran sin duplicarlas). La ruta de
"Detalle del reporte" se agrega como hija de `/mis-reportes` (que ya vive anidada bajo la rama
`home` desde la feature 001) — a diferencia de "Confirmación" en "Crear Reporte" (issue #28, ya
corregido), aquí SÍ corresponde que ambas pantallas muestren la barra de navegación inferior, por
lo que no se sacan del `StatefulShellRoute.indexedStack`.

## Complexity Tracking

*Sin violaciones que justificar — todos los gates de la Constitution Check pasaron (PASS).*
