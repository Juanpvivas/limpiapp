---

description: "Task list template for feature implementation"
---

# Tareas: Crear Reporte

**Input**: Documentos de diseño desde `/specs/002-crear-reporte/`

**Prerrequisitos**: plan.md (requerido), spec.md (requerido para user stories), research.md,
data-model.md, contracts/, quickstart.md

**Tests**: Incluidos — el plan (`plan.md`, sección Project Structure) definió explícitamente
archivos de test para los 3 Repository (mockeando sus Services con `mocktail`) y para el Notifier
(`ProviderContainer`) y la pantalla (`WidgetTester`) de cada user story.

**Organización**: Las tareas se agrupan por user story para permitir implementación y testing
independientes de cada una.

## Formato: `[ID] [P?] [Story] Descripción`

- **[P]**: Puede correr en paralelo (archivos distintos, sin dependencias)
- **[Story]**: A qué user story pertenece la tarea (US1, US2, US3)
- Se incluye la ruta exacta de archivo en cada descripción

## Convención de rutas

Proyecto Flutter único (mobile-app) — todas las rutas son relativas a la raíz de `limpiapp/`:
`lib/` y `test/`, siguiendo la estructura layer-first de
[docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md) y la definida en [plan.md](./plan.md). Esta es
la primera feature que crea `lib/domain/` y `lib/data/`.

---

## Fase 1: Setup (Infraestructura Compartida)

**Propósito**: agregar las dependencias aprobadas por la constitución que esta feature necesita y
preparar la configuración nativa/de proyecto que todavía no existe

- [X] T001 Agregar dependencias de runtime a `pubspec.yaml` con `flutter pub add flutter_riverpod
  riverpod_annotation get_it fpdart firebase_core cloud_firestore firebase_storage image_picker
  flutter_image_compress geolocator geocoding permission_handler freezed_annotation json_annotation`
  y correr `flutter pub get`
- [X] T002 [P] Agregar dependencias de desarrollo con `flutter pub add --dev riverpod_generator
  build_runner freezed json_serializable mocktail`
- [X] T003 Ejecutar `flutterfire configure` (requiere un proyecto de Firebase ya creado y sesión
  iniciada del equipo) para generar `lib/firebase_options.dart`,
  `android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist` (research.md §9 —
  prerrequisito externo, no automatizable desde este flujo)
- [X] T004 [P] Declarar los permisos nativos requeridos por `image_picker`/`geolocator`/
  `permission_handler`: `CAMERA` y ubicación en `android/app/src/main/AndroidManifest.xml`, y
  `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`,
  `NSLocationWhenInUseUsageDescription` en `ios/Runner/Info.plist`
- [X] T005 [P] Crear la estructura de carpetas vacía: `lib/domain/models/`,
  `lib/domain/repositories/`, `lib/data/repositories/`, `lib/data/services/firebase/`,
  `lib/data/services/photo/`, `lib/data/services/location/`, `lib/data/model/`,
  `lib/ui/reports/providers/`

**Checkpoint**: proyecto listo para agregar código de Domain/Data/Presentation de la feature.

---

## Fase 2: Foundational (Prerrequisitos Bloqueantes)

**Propósito**: Domain + Data completos (entidades, interfaces, Services, Repository impls, DI) que
las 3 user stories necesitan para existir

**⚠️ CRÍTICO**: ninguna user story puede implementarse hasta completar esta fase

- [X] T006 [P] Crear la jerarquía `Failure` (sealed class: `ServerFailure`, `NetworkFailure`,
  `PermissionFailure`, `LocationFailure`) en `lib/domain/models/failure.dart`
- [X] T007 [P] Crear el enum `WasteCategory` (5 valores + `label`, ver `data-model.md`) en
  `lib/domain/models/waste_category.dart` (FR-007)
- [X] T008 [P] Crear la entidad `Photo` (`bytes`, `sizeBytes`, `maxPhotoBytes` = 2 MB,
  `exceedsMaxSize`) en `lib/domain/models/photo.dart` (FR-004, FR-006)
- [X] T009 [P] Crear la entidad `ReportLocation` (`latitude`, `longitude`, `automaticAddress`,
  `manualAddress`, `hasAutomaticLocation`, `hasManualAddress`, `hasAnyLocation`) en
  `lib/domain/models/report_location.dart` (FR-012, FR-013, FR-014)
- [X] T010 Crear `NewReportDraft` (freezed) en `lib/domain/models/new_report_draft.dart` (depende
  de T007, T008, T009)
- [X] T011 Crear `Report` (freezed: `reportNumber`, `category`, `description`, `address`,
  `photoUrl`, `createdAt`) en `lib/domain/models/report.dart` (depende de T007)
- [X] T012 [P] Crear la interfaz `ReportRepository` (`submitReport(NewReportDraft)`) en
  `lib/domain/repositories/report_repository.dart` (depende de T006, T010, T011)
- [X] T013 [P] Crear la interfaz `PhotoRepository` (`pickFromCamera`/`pickFromGallery`) en
  `lib/domain/repositories/photo_repository.dart` (depende de T006, T008)
- [X] T014 [P] Crear la interfaz `LocationRepository` (`getCurrentLocation`) en
  `lib/domain/repositories/location_repository.dart` (depende de T006, T009)
- [X] T015 [P] Crear `ReportFirestoreService` (transacción de contador por año + creación del
  documento, ver `contracts/firestore-reports-contract.md` y research.md §2) en
  `lib/data/services/firebase/report_firestore_service.dart`
- [X] T016 [P] Crear `ReportStorageService` (`upload(docId, bytes)` / `delete(docId)`) en
  `lib/data/services/firebase/report_storage_service.dart`
- [X] T017 [P] Crear `PhotoCaptureService` (wrapper de `image_picker`: `pickFromCamera`/
  `pickFromGallery`) en `lib/data/services/photo/photo_capture_service.dart`
- [X] T018 [P] Crear `PhotoCompressorService` (secuencia de compresión con
  `flutter_image_compress`, research.md §7: calidad/dimensión decrecientes hasta ≤2 MB o agotar
  intentos) en `lib/data/services/photo/photo_compressor_service.dart`
- [X] T019 [P] Crear `GeolocationService` (wrapper de `geolocator`: `getCurrentPosition`) en
  `lib/data/services/location/geolocation_service.dart`
- [X] T020 [P] Crear `GeocodingService` (wrapper de `geocoding`: `placemarkFromCoordinates` →
  string de dirección legible) en `lib/data/services/location/geocoding_service.dart`
- [X] T021 [P] Crear `ReportDto` (mapeo documento Firestore ↔ `Report`, ver
  `contracts/firestore-reports-contract.md`) en `lib/data/model/report_dto.dart` (depende de T011)
- [X] T022 [P] Implementar `ReportRepositoryImpl` (sube foto → transacción Firestore → borra la
  foto si la transacción falla, research.md §4) en
  `lib/data/repositories/report_repository_impl.dart` (depende de T012, T015, T016, T021)
- [X] T023 [P] Implementar `PhotoRepositoryImpl` (`permission_handler` → captura → compresión,
  research.md §5, §7) en `lib/data/repositories/photo_repository_impl.dart` (depende de T013,
  T017, T018)
- [X] T024 [P] Implementar `LocationRepositoryImpl` (`permission_handler` → `geolocator` →
  `geocoding`, con respaldo de coordenadas crudas si falla el reverse geocoding, research.md §5,
  §6) en `lib/data/repositories/location_repository_impl.dart` (depende de T014, T019, T020)
- [X] T025 Crear `lib/config/service_locator.dart`: registrar con `registerLazySingleton` los
  clientes (`FirebaseFirestore.instance`, `FirebaseStorage.instance`, `ImagePicker()`), los 6
  Services (T015-T020) y las 3 Repository interfaz→impl (T022-T024)
- [X] T026 Actualizar `lib/main.dart`: `WidgetsFlutterBinding.ensureInitialized()`, `await
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`,
  `setupServiceLocator()`, y envolver `App` en `ProviderScope` antes de `runApp()` (depende de
  T003, T025)

**Checkpoint**: fundación de Domain/Data lista — las user stories pueden implementarse.

---

## Fase 3: User Story 1 - Enviar un reporte completo con éxito (Priority: P1) 🎯 MVP

**Goal**: formulario "Nuevo reporte" completo (foto, tipo de residuo, descripción, ubicación
automática) que se envía con éxito y navega a "Confirmación" con un número de reporte único.

**Independent Test**: completar foto + tipo de residuo + ubicación automática disponible, enviar, y
verificar que se llega a "Confirmación" con ícono de éxito, mensaje y número de reporte (ver
`quickstart.md`, escenario 1).

### Tests para User Story 1

- [X] T027 [P] [US1] Test de `ReportRepositoryImpl` (mocktail sobre los Services) en
  `test/data/repositories/report_repository_impl_test.dart`: caso feliz (sube foto, crea
  documento, retorna `Report` con `reportNumber`) y rollback de la foto si falla la creación del
  documento
- [X] T028 [P] [US1] Test de `PhotoRepositoryImpl` (mocktail) en
  `test/data/repositories/photo_repository_impl_test.dart`: caso feliz de permiso concedido +
  captura + compresión ≤2 MB
- [X] T029 [P] [US1] Test de `LocationRepositoryImpl` (mocktail) en
  `test/data/repositories/location_repository_impl_test.dart`: caso feliz de permiso concedido +
  coordenadas + reverse geocoding exitoso
- [X] T030 [P] [US1] Test de `NewReportNotifier` con `ProviderContainer` en
  `test/ui/reports/new_report_provider_test.dart`: estado inicial, `canSubmit` se habilita con
  foto válida + categoría + ubicación automática, `submit()` exitoso deja el `Report` listo para
  navegar a Confirmación
- [X] T031 [P] [US1] Widget test en `test/ui/reports/new_report_screen_test.dart`: completar foto +
  categoría + ubicación automática habilita "Enviar reporte"; al tocarlo se bloquea la interacción
  con el resto de la pantalla mientras el envío está en curso (FR-016), incluyendo un intento de
  `Navigator.pop` (simulando el botón atrás) que no debe sacar al usuario de la pantalla mientras
  `isSubmitting == true`

### Implementación para User Story 1

- [X] T032 [US1] Crear `NewReportState` (freezed: `photo`, `category`,
  `description`, `autoLocation`, `manualAddress`, `isLoadingLocation`, `isSubmitting`,
  `submitError`, `showPermissionDeniedAlert`) en
  `lib/ui/reports/providers/new_report_state.dart`. No incluye un campo de error de foto propio:
  el texto de "imagen muy grande" (FR-006) se deriva directamente de `photo.exceedsMaxSize`
  (`data-model.md`), sin duplicar esa bandera en el state.
- [X] T033 [US1] Implementar `NewReportNotifier` (`@riverpod`) en
  `lib/ui/reports/providers/new_report_provider.dart`: `build()` dispara
  `LocationRepository.getCurrentLocation()` automáticamente; expone `pickPhotoFromCamera`/
  `pickPhotoFromGallery`, `setCategory`, `setDescription`, `setManualAddress`; `canSubmit`
  computado según `data-model.md`; `submit()` es `Future<Report?>` — llama
  `ReportRepository.submitReport`, y si el resultado es `Right(report)` lo **retorna directamente
  al caller** (no se guarda ningún `Report` en `NewReportState`); si es `Left(failure)`, setea
  `submitError` en el state y retorna `null`. El widget que llama `await
  notifier.submit()` en `new_report_screen.dart` usa ese valor de retorno para decidir si navega
  (depende de T032; resuelve dependencias vía `getIt<T>()`)
- [X] T034 [P] [US1] Crear `photo_picker_card.dart` (sub-widget, <200 líneas) en
  `lib/ui/reports/widgets/photo_picker_card.dart`: recuadro de foto con botones "Tomar foto"/
  "Elegir de galería" (FR-002)
- [X] T035 [P] [US1] Crear `waste_category_field.dart` en
  `lib/ui/reports/widgets/waste_category_field.dart`: selector con las 5 categorías de
  `WasteCategory` (FR-007, FR-008)
- [X] T036 [P] [US1] Crear `location_section.dart` en
  `lib/ui/reports/widgets/location_section.dart`: muestra la dirección automática obtenida y el
  campo "Dirección manual" (FR-010, FR-011)
- [X] T037 [P] [US1] Crear `confirmation_screen.dart` en
  `lib/ui/reports/widgets/confirmation_screen.dart`: ícono de éxito, mensaje "¡Reporte enviado con
  éxito!...", número de reporte, mensaje de notificación futura, botón "Ver mis reportes", enlace
  "Volver al inicio" (FR-019 a FR-023). No lee ningún provider — recibe el `Report` ya resuelto
  por constructor (`extra` de navegación), así que es `StatelessWidget`, no `ConsumerWidget`. La
  verificación de "sin `Report` → redirigir a Inicio" (FR-025) es responsabilidad del guard de
  ruta en T039, no de este widget: si `routes.dart` ya garantiza que nunca se construye sin un
  `Report`, este widget puede asumir que siempre lo recibe y renderizarlo directamente, sin
  duplicar el guard
- [X] T038 [US1] Reescribir `new_report_screen.dart` (`ConsumerWidget`, reemplaza el placeholder de
  001) en `lib/ui/reports/widgets/new_report_screen.dart`: compone `photo_picker_card`,
  `waste_category_field`, campo de descripción, `location_section` y el botón "Enviar reporte"
  habilitado según `canSubmit`; mientras `isSubmitting` muestra un overlay de progreso que impide
  salir de la pantalla o tocar cualquier otra parte (FR-016). Envolver la pantalla en
  `PopScope(canPop: !isSubmitting, ...)` para bloquear explícitamente el botón/gesto "atrás" del
  sistema (Android) y el swipe-back (iOS) mientras `isSubmitting == true` — el overlay por sí solo
  bloquea toques pero no intercepta la navegación por gesto/hardware (depende de T033-T037)
- [X] T039 [US1] Agregar la ruta anidada de "Confirmación" (`/reportar/confirmacion`) dentro de la
  rama `reportar` en `lib/config/routes.dart`, con guard que redirige a Inicio si se accede sin un
  `Report` como `extra` (FR-025). Este guard es la **única fuente de verdad** para FR-025 —
  `confirmation_screen.dart` (T037) no repite esta validación (depende de T037)
- [X] T040 [US1] En `new_report_screen.dart`, llamar `final report = await notifier.submit();`;
  si `report != null` (envío exitoso), verificar `context.mounted` y navegar con
  `context.push('/reportar/confirmacion', extra: report)` (FR-018); si `report == null`, no
  navegar — `submitError` ya quedó seteado en el state por T033 y lo maneja T053 (depende de T038,
  T039)

**Checkpoint**: User Story 1 funcional y testeable de forma independiente (flujo feliz de punta a
punta).

---

## Fase 4: User Story 2 - Completar el reporte cuando la ubicación automática no está disponible (Priority: P2)

**Goal**: cuando la ubicación automática falla, la "Dirección manual" pasa a ser obligatoria y
bloquea el envío hasta llenarse.

**Independent Test**: simular que la ubicación automática falla, dejar "Dirección manual" vacío y
confirmar que "Enviar reporte" permanece deshabilitado; escribirla y confirmar que se habilita (ver
`quickstart.md`, escenario 2).

### Tests para User Story 2

- [X] T041 [P] [US2] Ampliar el test de `LocationRepositoryImpl` (creado en T029) con los casos:
  permiso denegado (`Left(PermissionFailure)`) y GPS/error (`Left(LocationFailure)`)
- [X] T042 [P] [US2] Ampliar el test de `NewReportNotifier` (creado en T030) con el caso: la
  ubicación automática falla → `canSubmit` permanece `false` hasta llenar "Dirección manual",
  luego se habilita
- [X] T043 [P] [US2] Ampliar el widget test de `new_report_screen` (creado en T031): con ubicación
  automática no disponible, "Dirección manual" se muestra como obligatoria y bloquea el envío
  hasta llenarla

### Implementación para User Story 2

- [X] T044 [US2] En `location_section.dart` (creado en T036), mostrar "Dirección manual" como
  obligatoria (indicador visual) cuando `autoLocation` no está disponible, y como opcional cuando
  sí lo está (FR-012, FR-013)
- [X] T045 [US2] En `NewReportNotifier` (creado en T033), manejar el `Left` de
  `LocationRepository.getCurrentLocation()` dejando `autoLocation` en `null` sin bloquear el resto
  del formulario, de modo que `canSubmit` dependa de `location.hasAnyLocation` (FR-014, FR-015)

**Checkpoint**: User Story 1 y 2 funcionan juntas de forma independiente.

---

## Fase 5: User Story 3 - Manejar errores de foto y de envío sin perder los datos (Priority: P3)

**Goal**: permiso de foto denegado, foto que sigue pesando >2 MB tras comprimirse, y fallo de envío
por red se manejan sin perder los datos ya ingresados.

**Independent Test**: (a) negar permiso de cámara/galería y confirmar la alerta; (b) forzar una
foto que siga >2 MB tras comprimirse y confirmar el texto rojo; (c) simular una falla de red al
enviar y confirmar que los datos ingresados se conservan y se puede reintentar (ver
`quickstart.md`, escenario 3).

### Tests para User Story 3

- [X] T046 [P] [US3] Ampliar el test de `PhotoRepositoryImpl` (creado en T028) con los casos:
  permiso denegado (`Left(PermissionFailure)`) y foto que sigue >2 MB tras comprimirse
  (`Right(Photo)` con `exceedsMaxSize == true`)
- [X] T047 [P] [US3] Ampliar el test de `NewReportNotifier` (creado en T030) con el caso: `submit()`
  falla (`Left`) → `isSubmitting` vuelve a `false`, `submitError` se setea, y el resto del `state`
  (foto, categoría, descripción, ubicación) permanece intacto
- [X] T048 [P] [US3] Ampliar el widget test de `new_report_screen` con: alerta de permiso
  denegado, texto rojo de "imagen muy grande", y mensaje de fallo de envío que no navega a
  Confirmación y conserva los datos ingresados

### Implementación para User Story 3

- [X] T049 [US3] En `photo_picker_card.dart` (creado en T034), mostrar el texto en rojo bajo el
  recuadro de foto cuando `photo.exceedsMaxSize == true` y deshabilitar el envío mientras esa foto
  siga así (FR-006)
- [X] T050 [US3] En `NewReportNotifier`, ante un `Left(PermissionFailure)` de
  `PhotoRepository.pickFromCamera`/`pickFromGallery`, setear `showPermissionDeniedAlert = true`
  (FR-005). Exponer también `dismissPermissionAlert()`, que resetea `showPermissionDeniedAlert =
  false` (lo consume T051)
- [X] T051 [US3] En `new_report_screen.dart`, escuchar `showPermissionDeniedAlert` y mostrar un
  `AlertDialog` simple indicando que agregar una foto es obligatoria (FR-005). Al cerrarse el
  diálogo (botón de confirmación o `onDismiss`), llamar a un método del Notifier que resetee
  `showPermissionDeniedAlert = false` — de lo contrario, la bandera sigue en `true` en el `state`
  y el diálogo puede reaparecer en cualquier rebuild posterior (depende de T050)
- [X] T052 [US3] En `NewReportNotifier.submit()`, capturar el `Left` de
  `ReportRepository.submitReport`, setear `isSubmitting = false` y `submitError` con un mensaje de
  fallo, sin limpiar ningún otro campo del `state` (FR-017)
- [X] T053 [US3] En `new_report_screen.dart`, mostrar `submitError` (ej. `SnackBar`) cuando esté
  presente, permitiendo volver a tocar "Enviar reporte" sin perder los datos (FR-017, SC-004)
  (depende de T052)

**Checkpoint**: las 3 user stories funcionan de forma independiente y en conjunto.

---

## Fase 6: Hallazgos de /speckit-analyze (correcciones pendientes)

- [ ] T057 [P] Test de concurrencia para `ReportFirestoreService` (SC-003): dos llamadas
  simultáneas a la transacción del contador `reports_{año}` deben producir `reportNumber`
  consecutivos y distintos — sin duplicados ni consecutivos perdidos — en
  `test/data/services/firebase/report_firestore_service_test.dart` (contra el emulador de
  Firestore, no un mock: una transacción simulada con mocktail no reproduce la condición de
  carrera real) (depende de T015)

---

## Fase Final: Polish & Cross-Cutting Concerns

- [ ] T054 [P] Validar manualmente los casos límite de `quickstart.md` (doble tap en "Enviar
  reporte", descripción vacía, ninguna ubicación disponible, acceso directo a la ruta de
  Confirmación sin `extra`)
- [X] T055 [P] Correr `dart format .` y `flutter analyze`, corregir cualquier hallazgo (Regla 10 de
  la constitución)
- [ ] T056 Ejecutar `quickstart.md` de punta a punta en un emulador Android y un simulador iOS,
  contra un proyecto de Firebase real (Firestore + Storage)

---

## Dependencias y Orden de Ejecución

### Dependencias entre Fases

- **Setup (Fase 1)**: sin dependencias — puede empezar de inmediato
- **Foundational (Fase 2)**: depende de que Setup esté completo (en particular T001-T003) —
  BLOQUEA todas las user stories
- **User Stories (Fase 3+)**: todas dependen de que Foundational esté completo
  - Pueden avanzar en paralelo si hay más de una persona, o en orden P1 → P2 → P3
- **Polish (Fase Final)**: depende de que las user stories deseadas estén completas

### Dependencias entre User Stories

- **US1 (P1)**: puede empezar tras Foundational — sin dependencia de otras stories; entrega el
  flujo feliz completo (MVP)
- **US2 (P2)**: puede empezar tras Foundational — modifica `location_section.dart` y
  `NewReportNotifier` ya creados en US1 (T036, T033), pero es independientemente testeable: el
  `canSubmit` basado en `hasAnyLocation` (Foundational) ya rige el bloqueo de envío
- **US3 (P3)**: puede empezar tras Foundational — modifica `photo_picker_card.dart` y
  `NewReportNotifier` ya creados en US1 (T034, T033); es independientemente testeable con mocks de
  permiso denegado/foto grande/envío fallido sin necesitar US2 implementada

### Dentro de cada User Story

- Los tests se escriben antes de la implementación y deben fallar primero
- Modelos/interfaces/Services (Foundational) antes que los Repository impl
- Notifier y sub-widgets antes que `new_report_screen.dart` los componga
- Story completa antes de pasar a la siguiente prioridad

### Oportunidades de Paralelismo

- T002, T004, T005 (Fase 1) en paralelo
- T006-T009 (Fase 2, entidades sin dependencias entre sí) en paralelo
- T012-T014 (Fase 2, interfaces de Repository) en paralelo entre sí
- T015-T021 (Fase 2, Services + DTO) en paralelo entre sí
- T022-T024 (Fase 2, Repository impl) en paralelo entre sí una vez listos sus Services/interfaces
- T027-T031 (tests de US1) en paralelo entre sí
- T034-T037 (sub-widgets de US1) en paralelo entre sí
- T041-T043 (tests de US2) y T046-T048 (tests de US3) en paralelo entre sí, e incluso entre ambas
  stories si hay más de una persona trabajando
- T054 y T055 (Fase Final) en paralelo

---

## Ejemplo de Paralelismo: User Story 1

```bash
# Lanzar en paralelo (tests):
Task: "Test de ReportRepositoryImpl en test/data/repositories/report_repository_impl_test.dart"
Task: "Test de PhotoRepositoryImpl en test/data/repositories/photo_repository_impl_test.dart"
Task: "Test de LocationRepositoryImpl en test/data/repositories/location_repository_impl_test.dart"

# Lanzar en paralelo (sub-widgets, tras T033):
Task: "Crear photo_picker_card.dart en lib/ui/reports/widgets/photo_picker_card.dart"
Task: "Crear waste_category_field.dart en lib/ui/reports/widgets/waste_category_field.dart"
Task: "Crear location_section.dart en lib/ui/reports/widgets/location_section.dart"
Task: "Crear confirmation_screen.dart en lib/ui/reports/widgets/confirmation_screen.dart"
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
