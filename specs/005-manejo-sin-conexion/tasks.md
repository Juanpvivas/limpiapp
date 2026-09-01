---
description: "Task list for Manejo de estado sin conexión (005)"
---

# Tasks: Manejo de estado sin conexión

**Input**: Design documents from `/specs/005-manejo-sin-conexion/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/offline-contract.md](./contracts/offline-contract.md)

**Tests**: incluidos. La constitución obliga a tests con `ProviderContainer` para todo
Notifier/Provider nuevo y a tests con `mocktail` para todo Repository/Service; el plan y el
quickstart enumeran los archivos de test. Van adyacentes a su implementación y deben pasar antes de
cerrar la tarea.

**Organization**: agrupado por User Story (spec.md). MVP = User Story 1.

**Precondición ya cumplida**: la rama `005-manejo-sin-conexion` está rebasada sobre `main`, que ya
contiene el fix #3 (`ReportListRepositoryImpl._failIfNoFirstEvent`, timeout de 10 s de la primera
emisión → `Left(NetworkFailure)`). Esta feature **no** reimplementa ese timeout. La constitución
está en **v2.5.0** (`connectivity_plus` aprobado).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: puede correr en paralelo (archivo distinto, sin dependencias pendientes)
- **[Story]**: US1 / US2 / US3 (solo en fases de User Story)
- Rutas relativas a la raíz del repo (`limpiapp/`)

## Path Conventions

Proyecto Flutter único (mobile-app). Código en `lib/`, tests en `test/`. La feature agrega una
tríada de conectividad en `domain/`/`data/`, `lib/ui/core/{providers,ui}`, y modifica `app.dart`,
`service_locator.dart` y 4 archivos de features existentes.

---

## Phase 1: Setup (Shared Infrastructure)

- [x] T001 Agregar `connectivity_plus` a `pubspec.yaml` (aprobado en constitución v2.5.0): `flutter pub add connectivity_plus` seguido de `flutter pub get`.
- [x] T002 Verificar que la resolución añade el permiso `ACCESS_NETWORK_STATE` al `AndroidManifest.xml` fusionado (nivel normal, sin prompt) y que iOS no requiere config; `flutter analyze` debe compilar un import de prueba de `package:connectivity_plus/connectivity_plus.dart`.

**Checkpoint**: dependencia instalada y verificada.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: la capacidad transversal de conectividad que consumen las 3 User Stories.

**⚠️ CRITICAL**: ninguna User Story puede empezar hasta terminar esta fase.

- [x] T003 Crear `lib/domain/models/connectivity_status.dart`: `enum ConnectivityStatus { online, offline }` (entidad pura, sin imports de Flutter). Ver [data-model.md](./data-model.md) §1.
- [x] T004 Crear `lib/domain/repositories/connectivity_repository.dart`: interfaz abstracta con `Stream<ConnectivityStatus> watch()`. Sin métodos de escritura, sin `Either` (justificado en [research.md](./research.md) §5). Depende de T003.
- [x] T005 Crear `lib/data/services/connectivity_service.dart`: envuelve `Connectivity()` (`onConnectivityChanged` de `connectivity_plus`), lleva un contador de fallos consecutivos, expone `reportBackendUnreachable()` / `reportBackendReachable()` y un `Stream<ConnectivityStatus>`. Regla combinada: `online` ⟺ (hay interfaz) **y** (fallos < umbral, default 2). Debounce asimétrico: online→offline ~300 ms, offline→online tras ~1.5 s de estabilidad ([research.md](./research.md) §2). Parámetros inyectables (`onlineDebounce`, `failureThreshold`). Depende de T003.
- [x] T006 Crear `lib/data/repositories/connectivity_repository_impl.dart`: `implements ConnectivityRepository`, mapea el stream del `ConnectivityService` a `Stream<ConnectivityStatus>`; un error del stream subyacente se degrada a `offline`, nunca cruza crudo (Principio V). Depende de T004, T005.
- [x] T007 Crear `lib/ui/core/providers/connectivity_provider.dart`: `@riverpod` `keepAlive` que expone `getIt<ConnectivityRepository>().watch()`. Mientras `AsyncLoading`/sin dato, los consumidores lo tratan como `online`. Correr `dart run build_runner build` para el `.g.dart`. Depende de T004.
- [x] T008 Modificar `lib/config/service_locator.dart`: registrar `Connectivity` (SDK), `ConnectivityService` y `ConnectivityRepository` con `registerLazySingleton`; agregar el parámetro `ConnectivityService` al constructor de `ReportListRepositoryImpl` y `ReportRepositoryImpl` (cableado, aún sin llamadas) y pasarlo desde el locator. Ajustar el `setUp` de `test/data/repositories/report_list_repository_impl_test.dart` y `report_repository_impl_test.dart` para inyectar un mock de `ConnectivityService` (que el proyecto siga compilando y verde). Depende de T005.
- [x] T009 [P] Crear `lib/ui/core/offline_copy.dart`: constantes de texto únicas (FR-019) — `kOfflineBannerText`, `kOfflineReadErrorText`, `kOfflineSubmitErrorText` ("Sin conexión: el reporte no se envió y no se guardó nada."), `kGenericServerErrorText`, `kRetryLabel`. Ver [data-model.md](./data-model.md) §6.
- [x] T010 [P] Crear `test/data/services/connectivity_service_test.dart` (`mocktail`): sin interfaz → `offline`; 2 fallos consecutivos sin éxito intermedio → `offline`; un `reportBackendReachable()` resetea el contador; el debounce asimétrico se respeta (usar `fakeAsync`/tiempos controlados). Depende de T005.
- [x] T011 [P] Crear `test/data/repositories/connectivity_repository_impl_test.dart` (`mocktail`): mapea el stream del Service; un error del stream se degrada a `offline`. Depende de T006.
- [x] T012 [P] Crear `test/ui/core/connectivity_provider_test.dart` (`ProviderContainer`): emite los estados del Repository; `AsyncLoading` se consume como `online`. Depende de T007.

**Checkpoint**: `connectivityStatusProvider` disponible y probado — las User Stories pueden empezar.

---

## Phase 3: User Story 1 - Saber de inmediato que estoy sin conexión (Priority: P1) 🎯 MVP

**Goal**: un aviso global persistente y no bloqueante de "sin conexión" en cualquier pantalla, que
desaparece solo al reconectar, con anti-parpadeo.

**Independent Test**: con modo avión, verificar que aparece la franja en Inicio/Reportar/Mapa (y
Confirmación), que no bloquea navegación/scroll, que al salir de modo avión desaparece sola, y que
un ciclo rápido avión on/off no la hace parpadear.

### Implementation for User Story 1

- [x] T013 [US1] Crear `lib/ui/core/ui/offline_banner.dart`: `ConsumerWidget` que observa `connectivityStatusProvider`; cuando `offline` muestra una franja (`AnimatedSize`/`AnimatedSlide`) con `kOfflineBannerText`, dentro de `SafeArea`, envuelta en `IgnorePointer` para no interceptar gestos (FR-001/FR-003/FR-005b). Depende de T007, T009.
- [x] T014 [US1] Modificar `lib/app.dart`: `MaterialApp.router` gana `builder: (context, child)` que compone una `Column`/`Stack` con `OfflineBanner` arriba y el `child` ruteado debajo — cubre el shell y las rutas top-level (Confirmación) sin tocar `routes.dart` (FR-001). Depende de T013.
- [x] T015 [P] [US1] Crear `test/ui/core/offline_banner_test.dart` (`WidgetTester`, `connectivityStatusProvider` sobrescrito): la franja aparece con `offline` y desaparece con `online`; con la franja visible, un tap sobre el contenido detrás sigue llegando (no la intercepta). Depende de T013.
- [x] T016 [US1] Crear/ampliar un test de nivel app (`test/ui/navigation/` o nuevo `test/ui/core/offline_banner_app_test.dart`): pumpeando el router real con `connectivityStatusProvider` = `offline`, la franja se ve sobre una pantalla ruteada; al pasar a `online` desaparece sola. Depende de T014.

**Checkpoint**: MVP — el aviso global funciona en toda la app y se prueba solo.

---

## Phase 4: User Story 2 - Las pantallas de lectura no se quedan cargando (Priority: P2)

**Goal**: "Mis reportes" y "Mapa" muestran un estado de error con "Reintentar" **manual** y mensaje
**específico** de "sin conexión" (reutilizando el timeout del fix #3), sin error espurio con
conexión estable y sin borrar los datos ya mostrados al perder conexión.

**Independent Test**: con modo avión y sin datos previos, abrir "Mis reportes"/"Mapa" → estado de
error con mensaje de "sin conexión" en ≤ 10 s; reconectar y "Reintentar" → cargan; forzar un error
de servidor → mensaje genérico; con datos ya en pantalla, activar modo avión → los datos permanecen.

### Implementation for User Story 2

- [x] T017 [US2] Crear `lib/ui/core/ui/data_error_state.dart`: `DataErrorState({required String message, required VoidCallback onRetry})`, `StatelessWidget`, botón con `kRetryLabel`. Depende de T009.
- [x] T018 [US2] Modificar `lib/ui/map/widgets/report_map_screen.dart`: reemplazar `MapErrorState` por `DataErrorState`; el `message` se elige leyendo `connectivityStatusProvider` y el `Failure` del `AsyncError` (`failure is NetworkFailure` **o** offline → `kOfflineReadErrorText`; si no → `kGenericServerErrorText`). El estado de error sigue saliendo solo con "Reintentar" (`ref.invalidate(myReportsProvider)`), no al reconectar (FR-007/FR-008/FR-009). **Eliminar** `lib/ui/map/widgets/map_error_state.dart`. Depende de T017, T007.
- [x] T019 [US2] Modificar `lib/ui/reports/widgets/report_list_screen.dart`: borrar la clase privada `_ErrorState` y usar `DataErrorState` con la misma lógica de mensaje (offline vs genérico) que T018. Depende de T017, T007.
- [x] T020 [US2] Modificar `lib/data/repositories/report_list_repository_impl.dart` (sobre el fix #3): en el fallback de `_failIfNoFirstEvent` (inyección de `Left(NetworkFailure)`) llamar `connectivityService.reportBackendUnreachable()`; en la primera emisión `Right` de `watchReports`/`watchReportById`, llamar `reportBackendReachable()`. Un `ServerFailure` no toca el contador (FR-005a). Depende de T008.
- [x] T021 [P] [US2] Ampliar `test/ui/map/report_map_screen_test.dart`: `DataErrorState` con `kOfflineReadErrorText` cuando el `Failure` es `NetworkFailure` / `connectivityStatusProvider` offline; `kGenericServerErrorText` con `ServerFailure`; el estado de error NO se limpia al pasar `connectivityStatusProvider` a `online` (solo "Reintentar"); con datos ya renderizados, un cambio a `offline` no reemplaza la pantalla por el error (FR-011). Depende de T018.
- [x] T022 [P] [US2] Ampliar `test/ui/reports/report_list_screen_test.dart`: mismos casos que T021 para "Mis reportes". Depende de T019.
- [x] T023 [P] [US2] Ampliar `test/data/repositories/report_list_repository_impl_test.dart` (con el mock de `ConnectivityService` de T008): verificar `reportBackendUnreachable()` en el timeout de primera emisión y `reportBackendReachable()` en la primera emisión `Right`; un `Left(ServerFailure)` no llama a ninguno; y (FR-010/SC-007) un stream que emite `Right` y luego queda **quieto más allá de `firstSnapshotTimeout`** NO produce un `Left(NetworkFailure)` posterior (el temporizador se desarma tras la 1ª emisión). Depende de T020.

**Checkpoint**: US1 + US2 funcionan de forma independiente.

---

## Phase 5: User Story 3 - El envío falla claro y sin perder el borrador (Priority: P3)

**Goal**: "Crear reporte" tiene un timeout acotado del envío, un chequeo pre-envío de conectividad
y un mensaje específico de "sin conexión"; el formulario nunca queda en "enviando…" indefinido y
conserva el borrador (el resto del comportamiento atómico ya está en la feature 002).

**Independent Test**: con modo avión, completar el formulario y "Enviar" → mensaje específico en
≤ 10 s, botón liberado, datos conservados; reconectar y reintentar → número + Confirmación; revisar
que el intento fallido no dejó ningún reporte.

### Implementation for User Story 3

- [x] T024 [US3] Modificar `lib/data/repositories/report_repository_impl.dart`: agregar parámetro inyectable `Duration sendTimeout` (default 10 s); envolver `storageService.upload(...)` y `firestoreService.createReport(...)` en `.timeout(sendTimeout)`; en `TimeoutException` → `_deleteOrphanPhoto` (con su propio timeout corto) + `Left(NetworkFailure())`. Llamar `connectivityService.reportBackendUnreachable()` en `TimeoutException`/`NetworkFailure` y `reportBackendReachable()` cuando `submitReport` retorna `Right` (FR-013/FR-014). Depende de T008.
- [x] T025 [US3] Modificar `lib/ui/reports/providers/new_report_provider.dart` (`NewReportNotifier.submit()`): (1) chequeo pre-envío — si `ref.read(connectivityStatusProvider)` está `offline`, fijar `submitError = kOfflineSubmitErrorText` y **no** llamar al Repository, sin dejar `isSubmitting` en `true` (FR-013); (2) en `Left`, elegir `submitError` = `kOfflineSubmitErrorText` si `failure is NetworkFailure` / offline, si no el genérico (FR-018); (3) confirmar que `isSubmitting` vuelve a `false` también en el camino de timeout (FR-014). Depende de T007, T009.
- [x] T026 [P] [US3] Ampliar `test/data/repositories/report_repository_impl_test.dart`: un paso de red que no responde dentro de `sendTimeout` → `Left(NetworkFailure)` + `_deleteOrphanPhoto` intentado; `reportBackendUnreachable()` llamado en timeout y `reportBackendReachable()` en `Right`. Depende de T024.
- [x] T027 [P] [US3] Ampliar `test/ui/reports/new_report_provider_test.dart` (`ProviderContainer`, `connectivityStatusProvider` sobrescrito + `ReportRepository` mock): pre-check offline no llama al Repository, fija `submitError` específico, `isSubmitting` no queda en `true`; `Left(NetworkFailure)` → mensaje específico; `Left(ServerFailure)` → mensaje genérico; `isSubmitting` vuelve a `false` en el camino de timeout; y (FR-015/SC-005) tras un `Left(NetworkFailure)` del timeout, `NewReportState` conserva `photo`, `category`, `description` y la ubicación (mismo comportamiento que en cualquier otro `Left`). Depende de T025.

**Checkpoint**: las 3 User Stories funcionan de forma independiente.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T028 [P] Actualizar `docs/ARCHITECTURE.md`: mencionar `connectivity_plus` en la lista de wrappers de SDK del párrafo de inversión de dependencias (igual que se hizo con `flutter_map`), y anotar el `DataErrorState` compartido en `lib/ui/core/ui/`. Verificar coherencia con la constitución v2.5.0.
- [x] T029 [P] Actualizar `README.md`: agregar la fila `Conectividad → connectivity_plus` en la tabla "Stack técnico"; agregar "Manejo de estado sin conexión" (005) a la tabla de features como en progreso.
- [x] T030 Ejecutar `dart format .` y `flutter analyze` — sin errores ni warnings.
- [x] T031 Ejecutar `flutter test` — toda la suite en verde (incluye los archivos nuevos y los ampliados; `dart run build_runner build` primero si hiciera falta por el `.g.dart` del provider).
- [~] T032 Ejecutar los escenarios 1–3 de [quickstart.md](./quickstart.md) en un dispositivo con toggles de red reales: modo avión, WiFi sin internet real, y pérdida de conexión a mitad de un envío. Medir SC-002 (≤ 3 s aparece), SC-003 (≤ 5 s desaparece), SC-001/SC-004 (≤ 10 s). PARCIAL: smoke test en iOS Simulator OK (la app arranca con el `builder:` de conectividad, "Mis reportes"/"Mapa" cargan sin romperse, sin excepciones Dart, sin aviso con red presente). Falta el QA manual con toggles de red reales.
- [x] T033 [P] Actualizar la memoria del proyecto: nota de la feature 005 y su pointer en `MEMORY.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias.
- **Foundational (Phase 2)**: depende de Setup. BLOQUEA las 3 User Stories.
- **User Stories (Phase 3–5)**: dependen de Foundational. US1 no depende de US2 ni US3. US2 y US3
  tocan archivos distintos (US2: pantallas de lectura + `report_list_repository_impl.dart`; US3:
  `report_repository_impl.dart` + `new_report_provider.dart`) → pueden ir en paralelo tras
  Foundational. Ambas comparten `DataErrorState` solo en US2 (US3 usa un `String submitError`, no el
  widget).
- **Polish (Phase 6)**: depende de las User Stories que se entreguen.

### User Story Dependencies

- **US1**: solo Foundational (T007 provider, T009 copy).
- **US2**: Foundational + `DataErrorState` (T017) + provider (T007). T020 necesita el
  `ConnectivityService` inyectado (T008).
- **US3**: Foundational + provider (T007) + copy (T009). T024 necesita T008.

### Within Each User Story

- Helpers/providers/constantes antes de los widgets que los consumen.
- La implementación antes de su test; el test verde antes de cerrar la tarea.

### Parallel Opportunities

- **Foundational**: T009 ‖ (T003→T004→{T005,T006,T007}); T010 ‖ T011 ‖ T012 (tras sus targets).
- **US1**: T015 ‖ (tras T013); T016 tras T014.
- **US2**: T017 primero; luego T018 ‖ T019 (archivos distintos) y T020 (repo) en paralelo; T021 ‖
  T022 ‖ T023 tras sus targets.
- **US3**: T024 y T025 (archivos distintos, pero T025 no depende de T024) en paralelo; T026 ‖ T027.
- **US2 ‖ US3**: equipos distintos pueden llevarlas a la vez tras Foundational.
- **Polish**: T028 ‖ T029 ‖ T033; T030 → T031 → T032.

---

## Parallel Example: Foundational

```bash
# Tras T003→T004:
Task: "T005 Crear lib/data/services/connectivity_service.dart"
Task: "T009 Crear lib/ui/core/offline_copy.dart"          # independiente

# Tras sus targets, en paralelo:
Task: "T010 test/data/services/connectivity_service_test.dart"
Task: "T011 test/data/repositories/connectivity_repository_impl_test.dart"
Task: "T012 test/ui/core/connectivity_provider_test.dart"
```

---

## Implementation Strategy

### MVP First (solo User Story 1)

1. Phase 1: Setup (T001–T002).
2. Phase 2: Foundational (T003–T012) — la capacidad de conectividad.
3. Phase 3: User Story 1 (T013–T016) — el aviso global.
4. **PARAR y VALIDAR**: Independent Test de US1 + escenario 1 del quickstart.
5. Entregar/demo (MVP).

### Incremental Delivery

1. Setup + Foundational → conectividad lista y probada.
2. US1 → aviso global → demo (MVP).
3. US2 → mensaje específico + `DataErrorState` unificado en lectura → demo.
4. US3 → timeout de envío + chequeo pre-envío + mensaje específico → demo.
5. Polish → README/ARCHITECTURE/memoria, `analyze`/`test`/quickstart completos.

---

## Notes

- `[P]` = archivos distintos, sin dependencias pendientes.
- La rama ya tiene el fix #3 (`_failIfNoFirstEvent`) — **no** se reimplementa; solo se le añade el
  reporte a `ConnectivityService` (T020).
- `NO` se agrega un subtipo nuevo de `Failure`: se reutiliza `NetworkFailure` + el
  `connectivityStatusProvider` para el matiz del mensaje ([research.md](./research.md) §5).
- Correr `dart run build_runner build` tras T007 (provider con `@riverpod`).
- `routes.dart` y `main.dart` NO se tocan.
- `dart format .` + `flutter analyze` antes de cada commit; commit por tarea o grupo lógico.
