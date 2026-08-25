# Ibagué Limpia

App móvil (Flutter, Android + iOS) para que los ciudadanos de Ibagué reporten, hagan seguimiento y
ayuden a mantener limpia su ciudad.

> Reporta, haz seguimiento y juntos mantengamos nuestra ciudad limpia.

## Qué hace la app

- **Hacer un reporte**: el usuario reporta un punto sucio o un problema de aseo en la ciudad.
- **Mis reportes**: consulta el listado y el detalle de los reportes que ha creado.
- **Mapa de reportes**: visualiza los reportes ubicados geográficamente en un mapa.

No requiere inicio de sesión. Los mockups de referencia están en
[`docs/mocks/`](docs/mocks).

## Stack técnico

| Categoría | Paquete |
|---|---|
| Framework | Flutter / Dart `^3.13.1` |
| Manejo de estado | `flutter_riverpod` + `riverpod_annotation` |
| Inyección de dependencias | `get_it` |
| Manejo de errores | `fpdart` (`Either<Failure, Success>`) |
| Networking (API REST propia/terceros) | `dio` |
| Backend administrado (Firebase) | `firebase_core` + `cloud_firestore` + `firebase_storage` |
| Foto (cámara/galería + compresión) | `image_picker` + `flutter_image_compress` |
| Ubicación (GPS + reverse geocoding) | `geolocator` + `geocoding` |
| Permisos (cámara/galería/ubicación) | `permission_handler` |
| Ruteo | `go_router` |
| Modelos/serialización | `freezed` + `json_serializable` |
| Persistencia local | `shared_preferences` / `isar` |
| Testing | `flutter_test`, `mocktail`, `ProviderContainer` |

La lista completa y las reglas de uso de cada paquete están en la
[constitución del proyecto](.specify/memory/constitution.md).

## Arquitectura

Clean Architecture en 3 capas (Presentation / Domain / Data) con inversión de dependencias: Domain
define interfaces de Repository, Data las implementa. Ver el detalle completo, el diagrama y la
estructura de carpetas en [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

```text
lib/
├── config/     # Configuración global (routes.dart, service_locator.dart, theme.dart)
├── ui/         # Capa Presentation — feature-first (ui/<feature>/providers, ui/<feature>/widgets)
├── domain/     # Capa Domain — entidades puras + interfaces de repositorio (compartido)
├── data/       # Capa Data — implementaciones de repositorio + services (compartido)
├── app.dart
└── main.dart
```

## Cómo correr el proyecto

```bash
flutter pub get
flutter run
```

**Features que usan Firebase como backend** (ej. "Crear Reporte") requieren además un proyecto de
Firebase configurado antes de compilar:

1. Crear un proyecto en [Firebase Console](https://console.firebase.google.com).
2. Correr `flutterfire configure` desde la raíz del proyecto (requiere login con la cuenta de
   Google del proyecto) — esto genera `lib/firebase_options.dart`,
   `android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist`.

Antes de cada commit:

```bash
dart format .
flutter analyze
```

## Gobernanza y desarrollo (Spec Kit)

Este proyecto sigue **Spec-Driven Development** con [Spec Kit](https://github.com/github/spec-kit):
las reglas no-negociables del proyecto viven en la
[constitución](.specify/memory/constitution.md), y cada feature se desarrolla como una spec
independiente en [`specs/`](specs) siguiendo el flujo:

```
/speckit-constitution → /speckit-specify → /speckit-plan → /speckit-tasks → /speckit-implement
```

| Feature | Spec | Estado |
|---|---|---|
| Shell de Navegación Principal | [`specs/001-navegacion-principal`](specs/001-navegacion-principal) | Implementada — pendientes assets reales de marca/fondo (T012) y validación manual de edge cases (T024) |
| Crear Reporte | [`specs/002-crear-reporte`](specs/002-crear-reporte) | Spec lista (0 `NEEDS CLARIFICATION`) — pendiente `/speckit-plan` |

## Documentación

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — arquitectura detallada del proyecto.
- [`.specify/memory/constitution.md`](.specify/memory/constitution.md) — principios y reglas no-negociables.
- [`docs/mocks/`](docs/mocks) — mockups de referencia de cada pantalla.
