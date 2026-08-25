# Implementation Plan: Crear Reporte

**Branch**: `002-crear-reporte` | **Date**: 2026-08-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-crear-reporte/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Construir el formulario "Nuevo reporte" (foto obligatoria comprimida a ≤2 MB, tipo de residuo,
descripción opcional, ubicación automática + dirección manual) y la pantalla "Confirmación" que se
alcanza tras un envío exitoso. Enfoque técnico: Firebase (`cloud_firestore` + `firebase_storage`)
como backend — `ReportRepository.submitReport` sube la foto a Storage y crea el documento en
Firestore como una única operación desde Presentation, generando el número de reporte único
(`#IL-{año}-{consecutivo}`) mediante una transacción de contador en Firestore, con reversión manual
de la foto subida si falla la creación del documento. `image_picker` + `flutter_image_compress` para
foto, `geolocator` + `geocoding` para ubicación automática, y `permission_handler` como único punto
de solicitud/verificación de permisos (cámara, galería, ubicación). Esta es la primera feature que
puebla `domain/` y `data/` del proyecto (hasta ahora solo existía `ui/` y `config/routes.dart`), así
como el primer `service_locator.dart` (GetIt) y el primer Riverpod Notifier de la app.

## Technical Context

**Language/Version**: Dart, Flutter SDK `^3.13.1` (fijado en `pubspec.yaml`)

**Primary Dependencies**:
- `flutter_riverpod` + `riverpod_annotation` (`riverpod_generator`/`build_runner` en dev) — único
  Notifier de esta feature (`NewReportNotifier`)
- `get_it` — primer `ServiceLocator` del proyecto, registra Repositories y Services
- `fpdart` — `Either<Failure, T>` en las 3 interfaces de Repository de esta feature
- `firebase_core` + `cloud_firestore` + `firebase_storage` — backend: colección `reports` +
  almacenamiento de fotos
- `image_picker` — capturar/seleccionar foto (cámara o galería)
- `flutter_image_compress` — comprimir/redimensionar la foto a ≤2 MB en el dispositivo
- `geolocator` — coordenadas GPS automáticas
- `geocoding` — reverse geocoding de coordenadas a dirección legible
- `permission_handler` — solicitar/verificar permisos de cámara, galería y ubicación de forma
  unificada
- `freezed` + `json_serializable` — modelos inmutables de Domain (`Report`, `NewReportDraft`, etc.) y
  DTO de Firestore
- `go_router` — ya aprobado y usado; se agrega una ruta nueva (`Confirmación`)
- `mocktail` (dev) — tests de Repository mockeando Services

Ninguno de estos paquetes está aún en `pubspec.yaml` salvo `go_router`: esta feature es la primera en
agregarlos (vía `flutter pub add`, sin pinnear versión exacta, según la política de versiones del
Principio I).

**Storage**: Firebase — colección Firestore `reports` (datos estructurados del reporte + número
único) y Firebase Storage (archivo de la foto ya comprimida). No hay persistencia local ni borrador
guardado entre sesiones (Assumption del spec) — cada envío exitoso vive únicamente en el backend.

**Testing**: `flutter_test` + `ProviderContainer` para `NewReportNotifier` (estado inicial, caso
feliz, cada `Failure`); `mocktail` para los 3 `*RepositoryImpl` mockeando sus Services (no el SDK de
Firebase/plugins nativos directamente — ver `research.md` §8); `WidgetTester` para validar el
habilitado/deshabilitado de "Enviar reporte" y el bloqueo de interacción durante el envío.

**Target Platform**: Android + iOS (carpetas `android/` e `ios/` ya presentes en el proyecto).

**Project Type**: mobile-app — proyecto Flutter único. Primera feature en poblar `domain/` y `data/`
según el layout layer-first de [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md).

**Performance Goals**: la compresión de una foto de cámara típica (~8-12 MP) a ≤2 MB debe completarse
en el dispositivo en pocos segundos, sin bloquear la UI más allá del propio indicador de progreso ya
definido en el spec para el envío.

**Constraints**: foto final ≤2 MB (FR-004/FR-006); el envío es una única operación atómica desde la
perspectiva de Presentation — sin foto huérfana en Storage si falla la creación del documento en
Firestore (requisito explícito del usuario); pantalla de envío bloqueada a toda interacción mientras
el progreso está visible (FR-016); sin inicio de sesión (FR-024); requiere un proyecto de Firebase ya
configurado (`flutterfire configure`) como prerrequisito externo antes de poder ejecutar la app — ver
`research.md` §9.

**Scale/Scope**: 1 pantalla de formulario (reemplaza el placeholder `new_report_screen.dart`) + 1
pantalla nueva de confirmación + fundación de Domain/Data (3 entidades, 1 `Failure` compartido, 3
interfaces de Repository, 3 implementaciones, 6 Services) reutilizable por futuras features ("Mis
Reportes", "Mapa de Reportes") que lean la misma colección `reports`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Aplica a esta feature | Estado |
|---|---|---|
| I. Stack Tecnológico Oficial | Usa exactamente los paquetes recién aprobados para backend (`firebase_core`, `cloud_firestore`, `firebase_storage`) y captura de foto/ubicación (`image_picker`, `flutter_image_compress`, `geolocator`, `geocoding`, `permission_handler`), más los ya aprobados (`flutter_riverpod`, `get_it`, `fpdart`, `freezed`/`json_serializable`, `go_router`, `mocktail`). Ningún paquete fuera de la lista aprobada. | ✅ PASS |
| II. Clean Architecture en Capas | Primera feature con Domain real: `domain/models/` (Report, NewReportDraft, Photo, ReportLocation, WasteCategory, Failure) y `domain/repositories/` (3 interfaces). Data implementa esas interfaces (`*_repository_impl.dart`) y coordina Services delgados. Presentation (`NewReportNotifier`) solo depende de las interfaces de Domain, nunca de `data/`. | ✅ PASS |
| III. Convenciones de Código y Estilo Dart | `NewReportScreen`/`ConfirmationScreen` son `ConsumerWidget` (leen `NewReportNotifier` vía `ref.watch`). `snake_case.dart`, `PascalCase` en clases, `const` obligatorio donde el compilador lo permita. El campo de texto de dirección manual usa un `TextEditingController` como estado efímero local (no de negocio), consistente con la excepción ya documentada para estado puramente local. | ✅ PASS |
| IV. Restricciones Estrictas | Sin `setState` para estado de negocio (todo vive en `NewReportNotifier`). Ningún archivo de `lib/ui/reports/` importa `lib/data/`: el provider resuelve `getIt<ReportRepository>()` (tipo interfaz) en su constructor. `context.mounted` se verifica antes de navegar a "Confirmación" tras el `await` del envío. Archivos de widget se dividen en sub-widgets (`photo_picker_card.dart`, `waste_category_field.dart`, `location_section.dart`) para respetar el límite de 200 líneas en `new_report_screen.dart`. | ✅ PASS |
| V. Inyección de Dependencias y Manejo de Errores | Primer `service_locator.dart` del proyecto: registra `FirebaseFirestore.instance`, `FirebaseStorage.instance`, `ImagePicker()` y las 3 Repository con `registerLazySingleton`. Los 3 métodos de Repository retornan `Future<Either<Failure, T>>`. Toda excepción de Firebase, `image_picker`, `flutter_image_compress`, `geolocator`, `geocoding` y `permission_handler` se captura y mapea a un `Failure` (`ServerFailure`, `NetworkFailure`, `PermissionFailure`, `LocationFailure`) dentro de la implementación del Repository — nunca cruza como excepción cruda. | ✅ PASS |

No hay violaciones que requieran entrada en Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/002-crear-reporte/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command) — contrato de datos con Firebase
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
# Mobile-app — proyecto Flutter único, layout layer-first ya fijado en docs/ARCHITECTURE.md.
# Esta feature agrega las primeras carpetas domain/ y data/ del proyecto, además de config/service_locator.dart.

limpiapp/lib/
├── config/
│   ├── routes.dart                              # MODIFICADO — nueva ruta anidada de "Confirmación"
│   └── service_locator.dart                      # NUEVO — primer ServiceLocator (GetIt) del proyecto
├── domain/
│   ├── models/
│   │   ├── failure.dart                          # NUEVO — sealed Failure (Server/Network/Permission/Location)
│   │   ├── waste_category.dart                   # NUEVO — enum de las 5 categorías (FR-007)
│   │   ├── photo.dart                            # NUEVO — bytes + sizeBytes + exceedsMaxSize (FR-004/006)
│   │   ├── report_location.dart                  # NUEVO — coords + automaticAddress + manualAddress
│   │   ├── new_report_draft.dart                 # NUEVO — agregado inmutable del formulario
│   │   └── report.dart                           # NUEVO — entidad devuelta tras envío exitoso
│   └── repositories/
│       ├── report_repository.dart                # NUEVO — interfaz: submitReport(NewReportDraft)
│       ├── photo_repository.dart                 # NUEVO — interfaz: pickFromCamera/pickFromGallery
│       └── location_repository.dart              # NUEVO — interfaz: getCurrentLocation
├── data/
│   ├── repositories/
│   │   ├── report_repository_impl.dart           # NUEVO — orquesta Storage + Firestore, rollback de foto
│   │   ├── photo_repository_impl.dart            # NUEVO — permission_handler + captura + compresión
│   │   └── location_repository_impl.dart         # NUEVO — permission_handler + geolocator + geocoding
│   ├── services/
│   │   ├── firebase/
│   │   │   ├── report_firestore_service.dart      # NUEVO — doc + transacción de contador (número único)
│   │   │   └── report_storage_service.dart        # NUEVO — upload/delete de foto en Storage
│   │   ├── photo/
│   │   │   ├── photo_capture_service.dart         # NUEVO — wrapper de image_picker
│   │   │   └── photo_compressor_service.dart      # NUEVO — wrapper de flutter_image_compress
│   │   └── location/
│   │       ├── geolocation_service.dart           # NUEVO — wrapper de geolocator
│   │       └── geocoding_service.dart             # NUEVO — wrapper de geocoding
│   └── model/
│       └── report_dto.dart                        # NUEVO — mapeo documento Firestore ↔ Report
├── ui/reports/
│   ├── providers/
│   │   ├── new_report_provider.dart               # NUEVO — @riverpod NewReportNotifier
│   │   └── new_report_state.dart                  # NUEVO — freezed state (foto, categoría, ubicación, flags)
│   └── widgets/
│       ├── new_report_screen.dart                 # REEMPLAZA el placeholder (FR-001 a FR-018)
│       ├── photo_picker_card.dart                  # NUEVO — sub-widget: foto + alerta permiso + error 2MB
│       ├── waste_category_field.dart               # NUEVO — sub-widget: selector de categoría
│       ├── location_section.dart                   # NUEVO — sub-widget: dirección automática + manual
│       └── confirmation_screen.dart                # NUEVO — pantalla "Confirmación" (FR-019 a FR-025)
├── app.dart                                        # MODIFICADO — envuelto en ProviderScope
└── main.dart                                       # MODIFICADO — Firebase.initializeApp() + setupServiceLocator()

limpiapp/lib/firebase_options.dart                  # GENERADO por `flutterfire configure` (prerrequisito
                                                     # externo, no se crea a mano en esta feature — ver research.md §9)

limpiapp/test/
├── data/
│   └── repositories/
│       ├── report_repository_impl_test.dart        # mocktail: Services mockeados, rollback de foto
│       ├── photo_repository_impl_test.dart         # mocktail: permiso denegado, foto grande tras comprimir
│       └── location_repository_impl_test.dart      # mocktail: permiso denegado, GPS sin señal, éxito
└── ui/
    └── reports/
        ├── new_report_provider_test.dart           # ProviderContainer: canSubmit, envío feliz, Failure
        └── new_report_screen_test.dart             # WidgetTester: botón habilitado/deshabilitado, bloqueo de loading
```

**Structure Decision**: proyecto Flutter único (mobile-app). Esta es la primera feature que ejercita
las 3 capas completas (`ui/` → `domain/` → `data/`) descritas en el Principio II y en
[docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md); `domain/` y `data/` se crean como carpetas
compartidas a nivel de proyecto (no anidadas bajo `reports/`), listas para que futuras features
("Mis Reportes", "Mapa de Reportes") reutilicen `Report`, `ReportRepository` y `Failure` sin
duplicarlos. Solo `ui/reports/` es feature-first, siguiendo el mismo patrón ya usado por el shell de
navegación. La ruta de "Confirmación" se agrega como hija de la rama `reportar` en
`config/routes.dart` (`/reportar/confirmacion`), guardada para que solo sea alcanzable con un
`Report` recibido como `extra` de navegación (FR-025) — ver `data-model.md` y `research.md` §6.

## Complexity Tracking

*Sin violaciones que justificar — todos los gates de la Constitution Check pasaron (PASS).*
