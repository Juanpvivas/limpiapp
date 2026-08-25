# Implementation Plan: Shell de Navegación Principal

**Branch**: `001-navegacion-principal` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-navegacion-principal/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Construir el shell de navegación de "Ibagué Limpia": una pantalla de inicio (branding + mensaje +
3 botones de acción) y una barra de navegación inferior persistente (Inicio/Reportar/Mapa) que dan
acceso a las tres features de negocio de la app (crear reporte, mis reportes, mapa de reportes).
Enfoque técnico: `go_router` con `StatefulShellRoute.indexedStack` para que cada rama de navegación
mantenga su propio stack independiente sin reconstruirse al cambiar de pestaña. Esta feature es
puramente de navegación/UI — no accede a datos, por lo que no introduce código en `domain/` ni
`data/` (ver Constitution Check).

## Technical Context

**Language/Version**: Dart, Flutter SDK `^3.13.1` (fijado en `pubspec.yaml`)

**Primary Dependencies**: `go_router` (`StatefulShellRoute.indexedStack`); `flutter_riverpod` no se
usa en esta feature al no haber estado de negocio que gestionar (ver Constitution Check)

**Storage**: N/A — no hay persistencia ni datos remotos en este shell; los assets (ícono, imagen de
fondo) son estáticos y se empaquetan con la app

**Testing**: `flutter_test` con `WidgetTester` (widget tests de navegación); `ProviderContainer` no
aplica porque no hay ningún `Notifier`/`AsyncNotifier` en esta feature

**Target Platform**: Android + iOS (app Flutter móvil, carpetas `android/` e `ios/` ya presentes en
el proyecto)

**Project Type**: mobile-app (proyecto Flutter único, layout layer-first descrito en
[docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md))

**Performance Goals**: cambio entre pestañas de la barra inferior percibido como instantáneo (sin
I/O de por medio, solo cambio de índice en `StatefulNavigationShell`)

**Constraints**: debe funcionar 100% sin conexión a internet (assumption del spec — assets
estáticos, sin llamadas de red); máximo 200 líneas por archivo de UI (Principio IV / Regla 8 de la
constitución)

**Scale/Scope**: 1 pantalla de inicio + 1 barra de navegación inferior + 3 pantallas placeholder de
destino (a reemplazar por sus propias features); un solo proyecto Flutter, sin backend propio en
este alcance

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Aplica a esta feature | Estado |
|---|---|---|
| I. Stack Tecnológico Oficial | Usa `go_router` (aprobado). `flutter_riverpod`/`get_it`/`fpdart` no se usan porque no hay estado de negocio ni acceso a datos que gestionar — no es una desviación del stack, es la ausencia de necesidad de usarlo en esta feature puntual. | ✅ PASS |
| II. Clean Architecture en Capas | Esta feature no tiene `domain/` ni `data/` propios: no hay entidades, ni repositorios, ni fuentes de datos que envolver. El Principio II exige que *si* existe un repositorio, tenga interfaz en Domain — no exige que toda feature tenga Domain/Data. Al no haber acceso a datos, ambas capas son N/A, no una violación. | ✅ PASS (N/A justificado) |
| III. Convenciones de Código y Estilo Dart | `snake_case.dart`, `PascalCase` en clases, `const` obligatorio donde aplique. La regla de `ConsumerWidget`/`ref.watch` aplica solo cuando hay estado de un provider que leer; al no haberlo, se usan `StatelessWidget`, consistente con la Regla 9 ("StatelessWidget... siempre que sea posible"). | ✅ PASS |
| IV. Restricciones Estrictas | `setState`: N/A (no hay estado de Presentation que gestionar más allá del propio `StatefulNavigationShell` de go_router, que no es estado de negocio). Import `data/` desde `ui/`: N/A (no existe `data/` para esta feature). `BuildContext` tras `await`: N/A (navegación 100% síncrona). Límite de 200 líneas: aplica y se respeta en la estructura propuesta abajo. | ✅ PASS |
| V. Inyección de Dependencias y Manejo de Errores | GetIt: N/A, no hay Repository/Service que registrar. `Either<Failure, T>`: N/A, no hay operaciones falibles (sin red, sin disco). | ✅ PASS (N/A justificado) |

No hay violaciones que requieran entrada en Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-navegacion-principal/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

No se genera `contracts/`: esta feature no expone ninguna interfaz externa (API, CLI, esquema) — es
navegación interna de UI. Ver `research.md` para el detalle de esta decisión.

### Source Code (repository root)

```text
# Mobile-app — proyecto Flutter único (Opción 3 del template no aplica: no hay API/backend propio
# en este alcance). Estructura layer-first ya fijada en docs/ARCHITECTURE.md; esta feature solo
# agrega código en ui/ y config/, sin tocar domain/ ni data/.

limpiapp/lib/
├── config/
│   └── routes.dart                        # StatefulShellRoute.indexedStack (3 ramas: home, reportar, mapa)
├── ui/
│   ├── core/
│   │   └── ui/
│   │       └── app_bottom_nav_bar.dart    # Barra de navegación inferior compartida (widget, <200 líneas)
│   ├── home/
│   │   └── widgets/
│   │       └── home_screen.dart           # Pantalla de inicio: branding + mensaje + 3 botones
│   ├── reports/
│   │   └── widgets/
│   │       ├── new_report_screen.dart     # Placeholder — feature "Crear Reporte" (spec separada)
│   │       └── report_list_screen.dart    # Placeholder — feature "Mis Reportes" (spec separada)
│   └── map/
│       └── widgets/
│           └── report_map_screen.dart     # Placeholder — feature "Mapa de Reportes" (spec separada)
├── app.dart                               # MaterialApp.router apuntando a config/routes.dart
└── main.dart                              # runApp(), sin ProviderScope obligatorio para esta feature (no hay providers)

limpiapp/test/
└── ui/
    ├── home/
    │   └── home_screen_test.dart          # Widget test: los 3 botones navegan a su destino (US1)
    └── navigation/
        └── app_bottom_nav_bar_test.dart   # Widget test: navegación + indicador de sección activa (US2, US3)
```

**Structure Decision**: proyecto Flutter único (mobile-app), sin capas Domain/Data para esta feature
por no haber acceso a datos (ver Constitution Check). Todo el código nuevo vive bajo `ui/` (más el
registro de rutas en `config/routes.dart`), siguiendo el layout layer-first ya establecido en
[docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md). Las tres pantallas de destino se crean como
placeholders mínimos para permitir probar la navegación de punta a punta; serán reemplazadas por su
implementación real cuando se ejecuten las features "Crear Reporte", "Mis Reportes" y "Mapa de
Reportes".

## Complexity Tracking

*Sin violaciones que justificar — todos los gates de la Constitution Check pasaron (PASS o N/A
justificado).*
