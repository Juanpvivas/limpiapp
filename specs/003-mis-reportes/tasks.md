---

description: "Task list template for feature implementation"
---

# Tareas: Mis Reportes

**Input**: Documentos de diseño desde `/specs/003-mis-reportes/`

**Prerrequisitos**: plan.md (requerido), spec.md (requerido para user stories), research.md,
data-model.md, contracts/, quickstart.md

**Tests**: Incluidos — el plan (`plan.md`, sección Technical Context/Testing) definió
explícitamente archivos de test para los Repository nuevos (mockeando sus Services con
`mocktail`), los providers (`ProviderContainer`) y las pantallas (`WidgetTester`), mismo patrón
que "Crear Reporte".

**Organización**: Las tareas se agrupan por user story para permitir implementación y testing
independientes de cada una.

## Formato: `[ID] [P?] [Story] Descripción`

- **[P]**: Puede correr en paralelo (archivos distintos, sin dependencias)
- **[Story]**: A qué user story pertenece la tarea (US1, US2, US3)
- Se incluye la ruta exacta de archivo en cada descripción

## Convención de rutas

Proyecto Flutter único (mobile-app) — todas las rutas son relativas a la raíz de `limpiapp/`:
`lib/` y `test/`, siguiendo la estructura layer-first de
[docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md) y la definida en [plan.md](./plan.md). Esta
feature extiende `lib/domain/` y `lib/data/` ya poblados por "Crear Reporte" (002) — no crea
carpetas nuevas a nivel de proyecto.

---

## Fase 1: Setup (Infraestructura Compartida)

**Propósito**: agregar la única dependencia nueva que esta feature necesita (ya aprobada por la
constitución desde v2.2.0, nunca agregada como dependencia real hasta ahora)

- [X] T001 Agregar `shared_preferences` con `flutter pub add shared_preferences` y correr
  `flutter pub get`

**Checkpoint**: proyecto listo para agregar código de Domain/Data/Presentation de la feature.

---

## Fase 2: Foundational (Prerrequisitos Bloqueantes)

**Propósito**: extender Domain + Data (entidades, interfaces, Services, Repository impls, DI) que
las 3 user stories necesitan para existir

**⚠️ CRÍTICO**: ninguna user story puede implementarse hasta completar esta fase

- [X] T002 [P] Crear el enum `ReportStatus` (`pendiente`, `enProceso`, `solucionado` + `label`,
  ver `data-model.md`) en `lib/domain/models/report_status.dart` (FR-008, FR-011 a FR-014)
- [X] T003 Extender `Report` (freezed, ya existente de "Crear Reporte") agregando `id` (String),
  `status` (`ReportStatus`), `deviceId` (String), `inProgressAt` (`DateTime?`), `resolvedAt`
  (`DateTime?`) en `lib/domain/models/report.dart` (depende de T002)
- [X] T004 [P] Agregar `CacheFailure` a la jerarquía sellada `Failure` (ya existente) en
  `lib/domain/models/failure.dart` (data-model.md — falla al leer/escribir
  `DeviceIdentifierService`)
- [X] T005 [P] Crear la interfaz `ReportListRepository` (`watchReports(deviceId)`,
  `watchReportById(reportId)`, ambos `Stream<Either<Failure, T>>`) en
  `lib/domain/repositories/report_list_repository.dart` (depende de T003, T004)
- [X] T006 [P] Crear la interfaz `DeviceIdentifierRepository` (`getDeviceId()`, retorna
  `Future<Either<Failure, String>>`) en `lib/domain/repositories/device_identifier_repository.dart`
  (depende de T004)
- [X] T007 [P] Crear `ReportQueryService` con 2 métodos (wrapper delgado sobre `cloud_firestore`,
  ver research.md §3): `watchReportsByDevice(deviceId)` — stream filtrado por `deviceId` y
  ordenado por `createdAt` descendente, retorna `Stream<List<(String id, Map<String, dynamic> data)>>` —
  y `watchReportById(reportId)` — stream de un solo documento, retorna
  `Stream<(String id, Map<String, dynamic> data)?>` (`null` si no existe). Ninguno retorna
  `DocumentSnapshot`/`Query` crudos. En `lib/data/services/firebase/report_query_service.dart`
- [X] T008 [P] Crear `DeviceIdentifierService` (genera el ID combinando
  `DateTime.now().microsecondsSinceEpoch` + 16 bytes de `Random.secure()` de `dart:math`, lo
  persiste con `shared_preferences` la primera vez, lo reutiliza después — ver research.md §2/§7)
  en `lib/data/services/device_identifier_service.dart`
- [X] T009 Actualizar `ReportDto` en `lib/data/model/report_dto.dart`: `toFirestoreMap` agrega
  `status`/`deviceId`; `fromSubmission` agrega `id`/`status`/`deviceId`/`inProgressAt`/
  `resolvedAt` (estos 2 últimos siempre `null` en un envío nuevo); nuevo método
  `fromFirestore({required String id, required Map<String, dynamic> data})` que mapea un
  documento leído (incluyendo conversión de `Timestamp` de Firestore a `DateTime` para
  `createdAt`/`inProgressAt`/`resolvedAt`, y de `String` a `ReportStatus` para `status`) a `Report`
  (depende de T003)
- [X] T010 [P] Implementar `ReportListRepositoryImpl` (mapea los streams de
  `ReportQueryService` a `Report` vía `ReportDto.fromFirestore`, envueltos en `Either`; un error
  del stream subyacente se intercepta y se emite como `Left(Failure)`, nunca como error de stream
  sin capturar — ver research.md §3) en `lib/data/repositories/report_list_repository_impl.dart`
  (depende de T005, T007, T009)
- [X] T011 [P] Implementar `DeviceIdentifierRepositoryImpl` en
  `lib/data/repositories/device_identifier_repository_impl.dart` (depende de T006, T008)
- [X] T012 Ajustar `ReportRepositoryImpl.submitReport` (feature "Crear Reporte", ya implementada)
  en `lib/data/repositories/report_repository_impl.dart`: resolver
  `DeviceIdentifierRepository.getDeviceId()` antes de construir el mapa, y pasar
  `status: ReportStatus.pendiente`, el `deviceId` resuelto, y el `id` (el mismo `docId` ya
  reservado) a `ReportDto.toFirestoreMap`/`fromSubmission` — `id` es un campo nuevo `required` de
  `Report` (T009) (depende de T009, T011)
- [X] T013 Registrar en `lib/config/service_locator.dart` los 2 Services nuevos
  (`registerLazySingleton`) y las 2 Repository nuevas (interfaz → impl), y actualizar el registro
  de `ReportRepositoryImpl` para inyectarle `DeviceIdentifierRepository` (depende de T007, T008,
  T010, T011, T012)

**Checkpoint**: fundación de Domain/Data lista — las user stories pueden implementarse.

---

## Fase 3: User Story 1 - Ver la lista de mis reportes enviados (Priority: P1) 🎯 MVP

**Goal**: pantalla "Mis reportes" mostrando todos los reportes del dispositivo (sin filtros aún,
implícitamente "Todos"), ordenados del más reciente al más antiguo, y navegación funcional a un
"Detalle del reporte" básico (foto, número, estado, tipo, ubicación, fecha, descripción — FR-011).

**Independent Test**: con al menos un reporte ya enviado desde el dispositivo, abrir "Mis
reportes", verificar que aparece listado con sus datos, y que tocarlo navega a su detalle (ver
`quickstart.md`, escenario 1).

### Tests para User Story 1

- [X] T014 [P] [US1] Test de `ReportListRepositoryImpl` (mocktail sobre `ReportQueryService`) en
  `test/data/repositories/report_list_repository_impl_test.dart`: stream feliz (lista mapeada
  correctamente a `Report`), stream con error → se emite `Left(Failure)`, y
  `verify(() => reportQueryService.watchReportsByDevice(deviceId))` para confirmar que el
  `deviceId` exacto se reenvía al Service (única parte de FR-004/SC-002 testeable sin Firestore
  real)
- [X] T015 [P] [US1] Test de `DeviceIdentifierRepositoryImpl` (mocktail sobre
  `DeviceIdentifierService`) en `test/data/repositories/device_identifier_repository_impl_test.dart`:
  genera y persiste un ID nuevo la primera vez, reutiliza el ya persistido después
- [X] T016 [P] [US1] Ampliar el test de `ReportRepositoryImpl` (creado en la feature "Crear
  Reporte") en `test/data/repositories/report_repository_impl_test.dart`: verifica que el mapa
  enviado a Firestore incluye `status: 'pendiente'` y el `deviceId` resuelto desde
  `DeviceIdentifierRepository`
- [X] T017 [P] [US1] Test de `myReportsProvider` con `ProviderContainer` (alimentado con un
  `ReportListRepository` mockeado) en `test/ui/reports/my_reports_provider_test.dart`: emite la
  lista mapeada en el caso feliz, se representa como `AsyncError` si el Repository emite `Left`
- [X] T018 [P] [US1] Test de `reportDetailProvider` con `ProviderContainer` en
  `test/ui/reports/report_detail_provider_test.dart`: emite el reporte encontrado, emite `null`
  si `watchReportById` retorna `Right(null)` (no encontrado)
- [X] T019 [P] [US1] Widget test en `test/ui/reports/report_list_screen_test.dart`: con reportes
  mockeados, se listan con miniatura/chip de estado/número/dirección/fecha, el más reciente
  primero; sin reportes, se ve el estado vacío general; tocar un reporte navega a su detalle
- [X] T020 [P] [US1] Widget test en `test/ui/reports/report_detail_screen_test.dart`: con un
  reporte mockeado, se muestran foto, número, chip de estado, tipo de residuo, ubicación, fecha y
  descripción (FR-011); con descripción vacía, no se rompe la pantalla

### Implementación para User Story 1

- [X] T021 [US1] Crear `myReportsProvider` (`@riverpod Stream<List<Report>>`, funcional, no un
  `Notifier`) en `lib/ui/reports/providers/my_reports_provider.dart`: resuelve
  `getIt<DeviceIdentifierRepository>().getDeviceId()`, y si es `Right(deviceId)` delega a
  `getIt<ReportListRepository>().watchReports(deviceId)`; cualquier `Left` (de cualquiera de los 2
  Repository) se traduce a una excepción para que Riverpod la represente como `AsyncError`
  (research.md §6) (depende de T013)
- [X] T022 [US1] Crear `reportDetailProvider` (`@riverpod Stream<Report?>`, funcional con
  parámetro `reportId`) en `lib/ui/reports/providers/report_detail_provider.dart`: delega a
  `getIt<ReportListRepository>().watchReportById(reportId)`, traduciendo `Left` a `AsyncError`
  igual que T021 (depende de T013)
- [X] T023 [P] [US1] Crear `ReportStatusChip` (`StatelessWidget` — no lee ningún provider, recibe
  el `ReportStatus` por constructor; sub-widget reutilizado en lista y detalle: etiqueta de color
  según el estado) en `lib/ui/reports/widgets/report_status_chip.dart`
- [X] T024 [P] [US1] Crear `ReportListItem` (`StatelessWidget`: fila con miniatura,
  `ReportStatusChip`, número, dirección y fecha/hora de envío) en
  `lib/ui/reports/widgets/report_list_item.dart` (depende de T023)
- [X] T025 [P] [US1] Crear `ReportListEmptyState` (`StatelessWidget`: mensaje general de "aún no
  tienes reportes") en `lib/ui/reports/widgets/report_list_empty_state.dart`
- [X] T026 [US1] Reescribir `report_list_screen.dart` (`ConsumerWidget`, reemplaza el placeholder
  de la feature 001) en `lib/ui/reports/widgets/report_list_screen.dart`: lee `myReportsProvider`;
  muestra un `ReportListItem` por cada reporte (el orden más-reciente-primero ya viene del stream,
  ver `ReportQueryService`) o `ReportListEmptyState` si la lista está vacía; tocar un item navega a
  `/mis-reportes/${report.id}` (depende de T021, T024, T025)
- [X] T027 [US1] Crear `report_detail_screen.dart` (`ConsumerWidget`) en
  `lib/ui/reports/widgets/report_detail_screen.dart`: lee `reportDetailProvider(reportId)`;
  muestra foto completa, número de reporte, `ReportStatusChip`, tipo de residuo, ubicación,
  fecha/hora de envío y descripción si existe (FR-011); si el valor emitido es `null` (reporte no
  encontrado), muestra un mensaje apropiado en vez de una pantalla en blanco (depende de T022,
  T023)
- [X] T028 [US1] Agregar la ruta anidada `/mis-reportes/:reportId` bajo la ruta existente
  `/mis-reportes` (anidada en la rama `home` desde la feature 001) en `lib/config/routes.dart`,
  leyendo `reportId` desde `state.pathParameters['reportId']` (research.md §5) (depende de T027)
- [X] T045 [US1] Actualizar `test/ui/home/home_screen_test.dart` y
  `test/ui/navigation/app_bottom_nav_bar_test.dart`: envolver `pumpAppAt` en `ProviderScope` y
  registrar mocks de `ReportListRepository`/`DeviceIdentifierRepository` en GetIt (mismo patrón ya
  aplicado en esos 2 archivos para "Crear Reporte"), y reemplazar la aserción
  `find.text('Próximamente: Mis Reportes')` por lo que la pantalla real de "Mis reportes" muestre
  (depende de T026)

**Checkpoint**: User Story 1 funcional y testeable de forma independiente (lista + navegación a
detalle básico).

---

## Fase 4: User Story 2 - Filtrar mis reportes por estado (Priority: P2)

**Goal**: pestañas de filtro ("Todos"/"Pendientes"/"En proceso"/"Solucionados") sobre la lista ya
funcional de la Historia 1.

**Independent Test**: con reportes en al menos 2 estados distintos, tocar cada pestaña y confirmar
que la lista se filtra correctamente, incluyendo el estado vacío específico de una pestaña sin
reportes (ver `quickstart.md`, escenario 2).

### Tests para User Story 2

- [X] T029 [P] [US2] Test de `ReportFilterNotifier` con `ProviderContainer` en
  `test/ui/reports/report_filter_provider_test.dart`: estado inicial `ReportFilter.todos`, cambia
  correctamente al seleccionar otra pestaña
- [X] T030 [P] [US2] Ampliar el test de `myReportsProvider` (creado en T017): verificar que la
  función de filtrado (aplicada en Presentation, no en el stream — research.md §4) retorna la
  sublista correcta para cada valor de `ReportFilter`
- [X] T031 [P] [US2] Ampliar el widget test de `report_list_screen` (creado en T019): tocar cada
  pestaña filtra la lista mostrada; una pestaña sin reportes en ese estado muestra el estado vacío
  específico, no el general

### Implementación para User Story 2

- [X] T032 [P] [US2] Crear el enum `ReportFilter` (`todos`, `pendientes`, `enProceso`,
  `solucionados`, con un getter que mapea a `ReportStatus?` — `null` para `todos`) en
  `lib/ui/reports/providers/report_filter.dart` (data-model.md)
- [X] T033 [US2] Crear `ReportFilterNotifier` (`@riverpod`, estado inicial
  `ReportFilter.todos`, expone `select(ReportFilter)`) en
  `lib/ui/reports/providers/report_filter_provider.dart` (depende de T032)
- [X] T034 [US2] Crear `ReportFilterTabs` (`ConsumerWidget` — lee `reportFilterProvider`: 4
  pestañas) en `lib/ui/reports/widgets/report_filter_tabs.dart` (depende de T033)
- [X] T035 [US2] En `ReportListEmptyState` (creado en T025), distinguir el mensaje general ("aún
  no tienes reportes") del mensaje específico por filtro ("no tienes reportes en este estado"),
  recibiendo por constructor si hay reportes en otros estados o no (FR-009) (depende de T025)
- [X] T036 [US2] En `report_list_screen.dart` (creado en T026), agregar `ReportFilterTabs` sobre
  la lista y filtrar el resultado de `myReportsProvider` según `reportFilterProvider` antes de
  mostrarlo — función pura en memoria, sin disparar una consulta nueva a Firestore (depende de
  T026, T034, T035)

**Checkpoint**: User Story 1 y 2 funcionan juntas de forma independiente.

---

## Fase 5: User Story 3 - Ver el detalle y seguimiento de un reporte (Priority: P3)

**Goal**: sección "Estado del reporte" en el detalle, con la línea de tiempo de 3 pasos
(FR-012 a FR-015), estrictamente de solo lectura.

**Independent Test**: abrir el detalle de reportes en cada uno de los 3 estados y verificar que la
línea de tiempo muestra la fecha correcta en cada paso alcanzado y "Pendiente" en los que no;
confirmar que no existe ningún control para cambiar el estado (ver `quickstart.md`, escenario 3).

### Tests para User Story 3

- [X] T037 [P] [US3] Test de `ReportStatusTimeline` (widget test aislado, sin provider) en
  `test/ui/reports/report_status_timeline_test.dart`: con un `Report` en cada uno de los 3
  estados, verifica que los pasos alcanzados muestran su fecha y los no alcanzados muestran
  "Pendiente"
- [X] T038 [P] [US3] Ampliar el test de `reportDetailProvider` (creado en T018): al recibir
  actualizaciones sucesivas del stream mockeado (ej. `pendiente` → `enProceso` → `solucionado`),
  cada emisión se refleja en el `AsyncValue` sin necesidad de recrear el provider
- [X] T039 [P] [US3] Ampliar el widget test de `report_detail_screen` (creado en T020): la
  sección "Estado del reporte" aparece con la línea de tiempo; recorriendo todo el árbol de
  widgets de la pantalla, no se encuentra ningún botón/control de escritura de estado (FR-015,
  SC-005)

### Implementación para User Story 3

- [X] T040 [P] [US3] Crear `ReportStatusTimeline` (`StatelessWidget` — recibe el `Report` por
  constructor, no lee ningún provider: línea de tiempo de 3 pasos usando
  `createdAt`/`inProgressAt`/`resolvedAt`, ver data-model.md) en
  `lib/ui/reports/widgets/report_status_timeline.dart`
- [X] T041 [US3] En `report_detail_screen.dart` (creado en T027), agregar la sección "Estado del
  reporte" con `ReportStatusTimeline` debajo de la información del reporte (FR-012) (depende de
  T027, T040)

**Checkpoint**: las 3 user stories funcionan de forma independiente y en conjunto.

---

## Fase Final: Polish & Cross-Cutting Concerns

- [ ] T042 [P] Validar manualmente los casos límite de `quickstart.md` (dispositivo sin reportes,
  reporte sin descripción, sin conexión, cambios de estado en tiempo real editando Firestore
  directamente desde la consola) — **QA manual pendiente**: requiere dispositivo/emulador y un
  proyecto de Firebase real; no ejecutable en este entorno.
- [X] T043 [P] Correr `dart format .` y `flutter analyze`, corregir cualquier hallazgo (Regla 10
  de la constitución)
- [ ] T044 Ejecutar `quickstart.md` de punta a punta en un emulador Android y un simulador iOS,
  contra un proyecto de Firebase real, incluyendo editar manualmente `status`/`inProgressAt`/
  `resolvedAt` de un documento desde la consola para verificar que la lista y el detalle se
  actualizan solos — **QA manual pendiente**: requiere emulador/simulador y Firebase real; no
  ejecutable en este entorno.

---

## Dependencias y Orden de Ejecución

### Dependencias entre Fases

- **Setup (Fase 1)**: sin dependencias — puede empezar de inmediato
- **Foundational (Fase 2)**: depende de que Setup esté completo — BLOQUEA todas las user stories
- **User Stories (Fase 3+)**: todas dependen de que Foundational esté completo
  - Pueden avanzar en paralelo si hay más de una persona, o en orden P1 → P2 → P3
- **Polish (Fase Final)**: depende de que las user stories deseadas estén completas

### Dependencias entre User Stories

- **US1 (P1)**: puede empezar tras Foundational — sin dependencia de otras stories; entrega la
  lista + navegación a un detalle básico (MVP)
- **US2 (P2)**: puede empezar tras Foundational — modifica `report_list_screen.dart` y
  `report_list_empty_state.dart` ya creados en US1 (T026, T025), pero es independientemente
  testeable: el filtrado es una función pura sobre datos ya recibidos
- **US3 (P3)**: puede empezar tras Foundational — modifica `report_detail_screen.dart` ya creado
  en US1 (T027); es independientemente testeable con un `Report` mockeado en cada estado, sin
  necesitar US2 implementada

### Dentro de cada User Story

- Los tests se escriben antes de la implementación y deben fallar primero
- Modelos/interfaces/Services (Foundational) antes que los Repository impl
- Providers antes que los widgets que los leen
- Sub-widgets antes que la pantalla que los compone
- Story completa antes de pasar a la siguiente prioridad

### Oportunidades de Paralelismo

- T002, T004 (Fase 2, entidades sin dependencias entre sí) en paralelo
- T005, T006 (Fase 2, interfaces de Repository) en paralelo entre sí
- T007, T008 (Fase 2, Services) en paralelo entre sí
- T010, T011 (Fase 2, Repository impl) en paralelo entre sí una vez listos sus Services/interfaces
- T014-T020 (tests de US1) en paralelo entre sí
- T023, T024, T025 (sub-widgets de US1) en paralelo entre sí (T024 depende de T023)
- T029-T031 (tests de US2) y T037-T039 (tests de US3) en paralelo entre sí, e incluso entre ambas
  stories si hay más de una persona trabajando

---

## Ejemplo de Paralelismo: User Story 1

```bash
# Lanzar en paralelo (tests):
Task: "Test de ReportListRepositoryImpl en test/data/repositories/report_list_repository_impl_test.dart"
Task: "Test de DeviceIdentifierRepositoryImpl en test/data/repositories/device_identifier_repository_impl_test.dart"
Task: "Test de myReportsProvider en test/ui/reports/my_reports_provider_test.dart"
Task: "Test de reportDetailProvider en test/ui/reports/report_detail_provider_test.dart"

# Lanzar en paralelo (sub-widgets, tras T023):
Task: "Crear ReportListItem en lib/ui/reports/widgets/report_list_item.dart"
Task: "Crear ReportListEmptyState en lib/ui/reports/widgets/report_list_empty_state.dart"
```

---

## Estrategia de Implementación

### MVP primero (solo User Story 1)

1. Completar Fase 1: Setup
2. Completar Fase 2: Foundational (CRÍTICO — bloquea todas las stories)
3. Completar Fase 3: User Story 1
4. **Detenerse y validar**: probar User Story 1 de forma independiente (escenario 1 de
   `quickstart.md`) contra un proyecto de Firebase real
5. Demo si está listo

### Entrega incremental

1. Setup + Foundational → Domain/Data listos
2. Agregar US1 → probar independientemente → demo (¡MVP!)
3. Agregar US2 → probar independientemente → demo
4. Agregar US3 → probar independientemente → demo
5. Cada story agrega valor sin romper las anteriores

---

## Notas

- `[P]` = archivos distintos, sin dependencias entre sí
- La etiqueta `[Story]` mapea cada tarea a su user story para trazabilidad
- Cada user story debe ser completable y testeable de forma independiente
- Verificar que los tests fallan antes de implementar
- Hacer commit después de cada tarea o grupo lógico de tareas
- Detenerse en cualquier checkpoint para validar la story de forma independiente
