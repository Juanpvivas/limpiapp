# Implementation Plan: Manejo de estado sin conexión

**Branch**: `005-manejo-sin-conexion` | **Date**: 2026-09-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-manejo-sin-conexion/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Dar feedback consistente y acotado en el tiempo cuando la app no tiene conexión, en tres frentes:
(1) un **aviso global** de "sin conexión" en cualquier pantalla, con disparo **híbrido** (sin red
del dispositivo **o** varios fallos consecutivos de establecer conexión con el backend) y ocultado
automático; (2) las **pantallas de lectura** ("Mis reportes", "Mapa") dejan de colgarse en el
spinner y muestran un estado de error con "Reintentar" **manual** con mensaje específico de "sin
conexión"; (3) el **envío** ("Crear reporte") tiene un **timeout acotado** y un mensaje específico,
conservando el borrador — el resto de su comportamiento atómico ya está cubierto por la feature 002.

Enfoque técnico: se agrega una capacidad transversal de **conectividad** en Clean Architecture
(`ConnectivityStatus` en domain, `ConnectivityRepository`/`ConnectivityService` en data, un
provider Riverpod debounced en Presentation). El `ConnectivityService` combina el estado de
interfaz de red (`connectivity_plus`, **dependencia nueva → enmienda a la constitución**) con un
contador de fallos consecutivos de establecer conexión que le reportan `ReportListRepositoryImpl` y
`ReportRepositoryImpl`. El aviso global se inserta en el `builder:` de `MaterialApp.router`. El
timeout de lectura **ya existe** en la rama `fix/issue-3-offline-read-hang` (bug #3) y esta feature
**se rebasa sobre esa rama** y no lo reimplementa: solo le añade el reporte de conectividad y el
mensaje específico. El envío gana un `.timeout()` inyectable por paso de red y un chequeo
pre-envío. Se unifican los dos widgets de estado de error duplicados (003/004) en uno compartido y
una única fuente de textos.

## Technical Context

**Language/Version**: Dart, Flutter SDK `^3.13.1` (ya fijado en `pubspec.yaml`).

**Primary Dependencies**:
- `connectivity_plus` — **NUEVA**, requiere enmienda a la constitución (Principio I) — ver
  research.md §1. Estado de interfaz de red del dispositivo (WiFi/datos/ninguna) + stream de
  cambios, para la parte (a) del disparo híbrido del aviso (FR-005). Android + iOS soportados;
  añade el permiso `ACCESS_NETWORK_STATE` vía manifest merge, sin config adicional en iOS.
- `flutter_riverpod` + `riverpod_annotation` — 1 provider nuevo (`connectivityStatusProvider`,
  stream debounced); consumo en el aviso global y en los estados de error.
- `get_it` — registra `Connectivity`, `ConnectivityService` y `ConnectivityRepository`; inyecta el
  `ConnectivityService` en los 2 Repositories que reportan fallos de conexión.
- `fpdart` — `Either<Failure, T>`; los timeouts se mapean a `NetworkFailure` (ya existe).
- `cloud_firestore` / `firebase_storage` — ya en uso; esta feature **no** agrega consultas ni
  índices, solo acota con `.timeout()` las llamadas de red del envío.
- `freezed` — `ConnectivityStatus` es un `enum` simple (sin freezed); no hay modelo nuevo con
  `freezed`.
- `mocktail` (dev) — tests del `ConnectivityService`/Repository y de la ampliación de
  `ReportRepositoryImpl`.

**Storage**: N/A — esta feature no persiste nada nuevo. El estado de conectividad es efímero
(en memoria). Firestore/Storage sin cambios de esquema.

**Testing**: `ProviderContainer` para `connectivityStatusProvider` (estados + debounce); `mocktail`
para `ConnectivityService`/`ConnectivityRepositoryImpl` (sin interfaz → offline; N fallos
consecutivos → offline; un éxito resetea) y para la ampliación de `ReportRepositoryImpl` (timeout
del envío); `WidgetTester` para el `OfflineBanner` (aparece/desaparece, no bloquea) y para los
mensajes específicos en los estados de error de lectura y en "Crear reporte". Los tests del timeout
de lectura ya viven en `fix/issue-3-offline-read-hang`.

**Target Platform**: Android + iOS (ya en uso). Sin permisos nuevos que el usuario deba conceder
(`ACCESS_NETWORK_STATE` es de nivel normal, no runtime).

**Project Type**: mobile-app — proyecto Flutter único. Agrega `lib/ui/core/{providers,ui}` (hoy
`lib/ui/core/ui/` solo tiene `app_bottom_nav_bar.dart` y `report_photo_thumbnail.dart`), una
tríada domain/data de conectividad, y modifica `app.dart` + 4 archivos de features existentes.

**Performance Goals**: el aviso global aparece en ≤ 3 s sin conexión y se oculta solo en ≤ 5 s al
reconectar (SC-002/SC-003); las pantallas de lectura llegan al estado de error en ≤ 10 s
(SC-001); el envío falla visible en ≤ 10 s sin conexión (SC-004). El estado de conectividad es
un stream de baja frecuencia (eventos de `connectivity_plus` + reportes de fallos), coste
despreciable.

**Constraints**:
- El aviso global se estabiliza ~1–2 s antes de cambiar (FR-004) — no debe parpadear.
- El reintento es **manual** en las 3 pantallas (FR-009): el estado de error de lectura no se
  limpia solo al reconectar (el aviso global sí).
- Con conexión estable y sin cambios de datos, ninguna pantalla de lectura cae en error espurio
  (FR-010) — el timeout de lectura aplica **solo hasta la primera emisión** (ya garantizado por el
  fix #3).
- Los datos ya mostrados no se reemplazan por el estado de error al perder conexión (FR-011).
- El envío es atómico frente al usuario y no queda "enviando…" indefinido (FR-012/FR-014).
- Distinguir "sin conexión" de un error de servidor que sí responde (FR-007/FR-018).

**Scale/Scope**: ~3 archivos nuevos de dominio/datos + 1 provider + 3 widgets nuevos
(`OfflineBanner`, `DataErrorState` compartido, textos) + `app.dart` + `service_locator.dart` + 4
archivos de features (2 repos, `new_report_provider.dart`, y las 2 pantallas de lectura que pasan a
usar el widget de error compartido). 1 enmienda a la constitución (`connectivity_plus`).
Dependencia de proceso: la rama `fix/issue-3-offline-read-hang` se mergea a `main` antes.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Aplica a esta feature | Estado |
|---|---|---|
| I. Stack Tecnológico Oficial | Todos los paquetes están aprobados. `connectivity_plus` se agregó a la lista en la enmienda **v2.5.0** (misma vía que `flutter_map` en v2.4.0): necesario para saber, de forma pasiva y dirigida por eventos, si el dispositivo tiene interfaz de red (parte (a) del disparo híbrido). Se eligió sobre la alternativa pura-Dart (`InternetAddress.lookup` periódico), que es un sondeo activo con polling y tráfico de red — peor para una franja global siempre presente (research.md §1). | ✅ PASS |
| II. Clean Architecture en Capas | Domain: `connectivity_status.dart` (enum puro) + `connectivity_repository.dart` (interfaz, expone `Stream<ConnectivityStatus>`). Data: `connectivity_repository_impl.dart` + `connectivity_service.dart` (envuelve `connectivity_plus` y lleva el contador de fallos). Presentation: `connectivityStatusProvider` (`@riverpod` stream debounced) que consumen `OfflineBanner` y las pantallas de lectura. `ReportListRepositoryImpl`/`ReportRepositoryImpl` dependen del **Service** `ConnectivityService` (un Repository puede coordinar Services — no dependen de otro Repository). Ningún archivo de `lib/ui/` importa `lib/data/`. | ✅ PASS |
| III. Convenciones de Código y Estilo Dart | `OfflineBanner` es `ConsumerWidget` (lee `connectivityStatusProvider`). `DataErrorState` (compartido, reemplaza `MapErrorState` y el `_ErrorState` privado de `report_list_screen.dart`) es `StatelessWidget` — recibe `message` + `onRetry` por constructor. `App` sigue `StatelessWidget`: el `builder:` de `MaterialApp.router` envuelve el child con un `Consumer`/`OfflineBanner`. `snake_case.dart`, `PascalCase`, `const` obligatorio. | ✅ PASS |
| IV. Restricciones Estrictas | Sin `setState` para estado de negocio (conectividad y `submitError` viven en providers/notifiers de Riverpod). Ningún archivo de `lib/ui/` importa `lib/data/`. Archivos de widget bajo 200 líneas (banner y estado de error son pequeños). `context.mounted` se verifica tras los `await` de `NewReportNotifier.submit()` que ya existen (no se agregan usos nuevos de `BuildContext` tras `await`). | ✅ PASS |
| V. Inyección de Dependencias y Manejo de Errores | `service_locator.dart` registra `Connectivity` (SDK), `ConnectivityService` y `ConnectivityRepository` con `registerLazySingleton`, igual que el resto. `ConnectivityRepository.watch()` devuelve `Stream<ConnectivityStatus>` crudo (sin `Either`): la enmienda **v2.6.0** del Principio V agregó el carve-out para *flujos de estado observables* — un error del stream de `connectivity_plus` se degrada a `offline` dentro del `ConnectivityService` (nunca cruza crudo), y "no se puede determinar" ya es un estado válido, así que no hay un `Failure` con significado que envolver. Sigue siendo un carve-out acotado: los `TimeoutException` del envío y el timeout de la primera emisión de lectura (operaciones puntuales falibles) **sí** se mapean a `NetworkFailure` dentro de la capa Data. No se agrega subtipo nuevo de `Failure` (research.md §5). | ✅ PASS |

Ambas enmiendas necesarias ya están aplicadas: `connectivity_plus` en el Principio I (v2.5.0) y el
carve-out de flujos de estado observables en el Principio V (v2.6.0). Sin gates abiertos ni
violaciones que requieran Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/005-manejo-sin-conexion/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output — contrato de conectividad + contrato de UX offline
└── tasks.md             # Phase 2 output (/speckit-tasks — NO lo crea /speckit-plan)
```

### Source Code (repository root)

```text
# Mobile-app — proyecto Flutter único, layout layer-first (docs/ARCHITECTURE.md).
# Se rebasa sobre fix/issue-3-offline-read-hang (bug #3, ya mergeado a main para entonces).

limpiapp/
├── pubspec.yaml                                       # MODIFICADO — +connectivity_plus
│                                                       #   (aprobado en constitución v2.5.0)
├── lib/
│   ├── app.dart                                       # MODIFICADO — MaterialApp.router gana
│   │                                                   #   builder: que envuelve el child con OfflineBanner
│   ├── config/
│   │   └── service_locator.dart                       # MODIFICADO — registra Connectivity +
│   │                                                   #   ConnectivityService + ConnectivityRepository;
│   │                                                   #   inyecta el Service en los 2 repos de reportes
│   ├── domain/
│   │   ├── models/
│   │   │   ├── connectivity_status.dart               # NUEVO — enum online/offline
│   │   │   └── failure.dart                           # (evaluar) subtipo p/ timeout — ver research §5
│   │   └── repositories/
│   │       └── connectivity_repository.dart           # NUEVO — watch() -> Stream<ConnectivityStatus>
│   ├── data/
│   │   ├── repositories/
│   │   │   ├── connectivity_repository_impl.dart      # NUEVO
│   │   │   ├── report_list_repository_impl.dart       # MODIFICADO (sobre fix #3) — reporta al
│   │   │   │                                           #   ConnectivityService en timeout/éxito
│   │   │   └── report_repository_impl.dart            # MODIFICADO — .timeout() por paso de red del
│   │   │                                               #   envío → NetworkFailure; reporta al Service
│   │   └── services/
│   │       └── connectivity_service.dart              # NUEVO — envuelve connectivity_plus + contador
│   │                                                   #   de fallos consecutivos; reachable/unreachable
│   └── ui/
│       ├── core/
│       │   ├── providers/
│       │   │   └── connectivity_provider.dart         # NUEVO — @riverpod stream debounced (~1–2 s)
│       │   ├── ui/
│       │   │   ├── offline_banner.dart                # NUEVO — ConsumerWidget, franja no bloqueante
│       │   │   └── data_error_state.dart              # NUEVO — StatelessWidget compartido (message +
│       │   │                                           #   onRetry); reemplaza MapErrorState y _ErrorState
│       │   └── offline_copy.dart                      # NUEVO — textos únicos: aviso, mensaje offline,
│       │                                               #   label "Reintentar" (FR-019)
│       ├── reports/
│       │   ├── providers/
│       │   │   └── new_report_provider.dart           # MODIFICADO — chequeo pre-envío de conectividad;
│       │   │                                           #   mensaje específico según Failure/conectividad
│       │   └── widgets/
│       │       └── report_list_screen.dart            # MODIFICADO — usa DataErrorState; mensaje según
│       │                                               #   conectividad/Failure
│       └── map/
│           └── widgets/
│               ├── report_map_screen.dart             # MODIFICADO — usa DataErrorState
│               └── map_error_state.dart               # ELIMINADO — reemplazado por DataErrorState
└── test/
    ├── data/
    │   ├── services/
    │   │   └── connectivity_service_test.dart         # NUEVO — mocktail: sin interfaz, N fallos, reset
    │   └── repositories/
    │       ├── connectivity_repository_impl_test.dart # NUEVO
    │       └── report_repository_impl_test.dart       # AMPLIADO — timeout del envío → NetworkFailure
    └── ui/
        ├── core/
        │   ├── connectivity_provider_test.dart        # NUEVO — ProviderContainer: estados + debounce
        │   └── offline_banner_test.dart               # NUEVO — WidgetTester: aparece/desaparece, no bloquea
        ├── reports/
        │   ├── new_report_provider_test.dart          # AMPLIADO — pre-envío offline, mensaje específico
        │   └── report_list_screen_test.dart           # AMPLIADO — mensaje offline vs genérico
        └── map/
            └── report_map_screen_test.dart            # AMPLIADO — mensaje offline vs genérico
```

**Structure Decision**: proyecto Flutter único (mobile-app). La feature agrega una capacidad
transversal de conectividad en las 3 capas (`domain/`, `data/`, `ui/core/`) y **modifica** 4
archivos de features ya entregadas para colgar de ella el mensaje específico y el aviso global —
se modifican, no se duplican, porque el manejo de errores y los textos son transversales (mismo
criterio con que la 003/004 extendieron `Report`/`Failure`). El widget de estado de error se
**unifica**: `MapErrorState` (004) y el `_ErrorState` privado de `report_list_screen.dart` (003)
se reemplazan por un único `DataErrorState` en `lib/ui/core/ui/`. `routes.dart` no cambia (el
aviso global entra por `app.dart`); `main.dart` no cambia. La feature se construye **sobre** la
rama `fix/issue-3-offline-read-hang` (bug #3), que se mergea a `main` primero — el timeout de
lectura no se reimplementa.

## Complexity Tracking

*Sin violaciones que justificar — todos los gates de la Constitution Check pasan (PASS). Las dos
enmiendas que la feature necesitaba ya están aplicadas: `connectivity_plus` (Principio I, v2.5.0) y
el carve-out de flujos de estado observables (Principio V, v2.6.0).*
