---

description: "Task list template for feature implementation"
---

# Tareas: Shell de Navegación Principal

**Input**: Documentos de diseño desde `/specs/001-navegacion-principal/`

**Prerrequisitos**: plan.md (requerido), spec.md (requerido para user stories), research.md,
data-model.md, quickstart.md

**Tests**: Incluidos — el plan (`plan.md`, sección Project Structure) definió explícitamente
archivos de widget test (`home_screen_test.dart`, `app_bottom_nav_bar_test.dart`) para validar
cada user story.

**Organización**: Las tareas se agrupan por user story para permitir implementación y testing
independientes de cada una.

## Formato: `[ID] [P?] [Story] Descripción`

- **[P]**: Puede correr en paralelo (archivos distintos, sin dependencias)
- **[Story]**: A qué user story pertenece la tarea (US1, US2, US3)
- Se incluye la ruta exacta de archivo en cada descripción

## Convención de rutas

Proyecto Flutter único (mobile-app) — todas las rutas son relativas a la raíz de `limpiapp/`:
`lib/` y `test/`, siguiendo la estructura layer-first de
[docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md) y la definida en [plan.md](./plan.md).

---

## Fase 1: Setup (Infraestructura Compartida)

**Propósito**: inicialización del proyecto y estructura base

- [X] T001 Agregar `go_router` a `pubspec.yaml` y correr `flutter pub get`
- [X] T002 [P] Actualizar `analysis_options.yaml` para activar `prefer_const_constructors`,
  `prefer_const_literals_to_create_immutables` y `prefer_const_declarations` en modo `error`
  (Principio III de la constitución)
- [X] T003 [P] Crear la estructura de carpetas vacía: `lib/config/`, `lib/ui/core/ui/`,
  `lib/ui/home/widgets/`, `lib/ui/reports/widgets/`, `lib/ui/map/widgets/`

**Checkpoint**: proyecto listo para agregar código de la feature.

---

## Fase 2: Foundational (Prerrequisitos Bloqueantes)

**Propósito**: infraestructura de ruteo que TODAS las user stories necesitan

**⚠️ CRÍTICO**: ninguna user story puede implementarse hasta completar esta fase

- [X] T004 Definir el enum `AppTab` (home, reportar, mapa) y las rutas base (`/`, `/reportar`,
  `/mapa`) en `lib/config/routes.dart`, según `data-model.md`
- [X] T005 Implementar `StatefulShellRoute.indexedStack` en `lib/config/routes.dart` con 3 ramas
  (home, reportar, mapa), cada una con su propio `Navigator` anidado
- [X] T006 [P] Crear pantalla placeholder `lib/ui/reports/widgets/new_report_screen.dart`
  (`Scaffold` con texto "Próximamente: Crear Reporte")
- [X] T007 [P] Crear pantalla placeholder `lib/ui/reports/widgets/report_list_screen.dart`
  (`Scaffold` con texto "Próximamente: Mis Reportes")
- [X] T008 [P] Crear pantalla placeholder `lib/ui/map/widgets/report_map_screen.dart`
  (`Scaffold` con texto "Próximamente: Mapa de Reportes")
- [X] T009 Registrar `new_report_screen.dart` en la rama `reportar` y `report_map_screen.dart` en
  la rama `mapa` de `lib/config/routes.dart` (depende de T005, T006, T008)
- [X] T010 Configurar `lib/app.dart` con `MaterialApp.router` apuntando al `GoRouter` de
  `lib/config/routes.dart`, y actualizar `lib/main.dart` para llamar `runApp(const App())`
  (depende de T005)

**Checkpoint**: fundación de ruteo lista — las user stories pueden implementarse.

---

## Fase 3: User Story 1 - Llegar a las funciones principales desde la pantalla de inicio (Priority: P1) 🎯 MVP

**Goal**: pantalla de inicio con branding, mensaje y 3 botones que navegan a su destino
correspondiente.

**Independent Test**: abrir la app y tocar cada uno de los 3 botones; cada uno debe navegar a la
pantalla de destino correcta (ver `quickstart.md`, escenario 1).

### Tests para User Story 1

- [X] T011 [P] [US1] Widget test en `test/ui/home/home_screen_test.dart`: verifica que los botones
  "Hacer un reporte", "Mis reportes" y "Mapa de reportes" navegan cada uno a su ruta

### Implementación para User Story 1

- [ ] T012 [US1] Agregar la imagen de fondo y el ícono de marca a `assets/` y declararlos en la
  sección `flutter: assets:` de `pubspec.yaml`
- [X] T013 [US1] Crear `lib/ui/home/widgets/home_screen.dart` (`StatelessWidget`, <200 líneas) con
  el branding "Ibagué Limpia", la imagen de fondo, el mensaje de bienvenida y los 3 botones, en el
  orden definido (FR-001, FR-002)
- [X] T014 [US1] Conectar el botón "Hacer un reporte" a `context.go('/reportar')` (FR-003)
- [X] T015 [US1] Conectar el botón "Mis reportes" a `context.go('/mis-reportes')` (ruta anidada
  dentro de la rama `home`, ver `data-model.md`) (FR-004)
- [X] T016 [US1] Conectar el botón "Mapa de reportes" a `context.go('/mapa')` (FR-005)
- [X] T017 [US1] Registrar `home_screen.dart` como pantalla raíz de la rama `home`, y
  `report_list_screen.dart` como ruta anidada `/mis-reportes` dentro de esa misma rama, en
  `lib/config/routes.dart` (depende de T007, T013)

**Checkpoint**: User Story 1 funcional y testeable de forma independiente.

---

## Fase 4: User Story 2 - Moverse entre secciones desde cualquier pantalla vía barra inferior (Priority: P2)

**Goal**: barra de navegación inferior fija y visible en toda la app, con acceso directo a cada
sección.

**Independent Test**: desde cualquier pantalla, tocar cada ícono de la barra inferior y confirmar
que navega directo a su sección sin pasar por Inicio (ver `quickstart.md`, escenario 2).

### Tests para User Story 2

- [X] T018 [P] [US2] Widget test en `test/ui/navigation/app_bottom_nav_bar_test.dart`: verifica que
  tocar cada uno de los 3 íconos ("Inicio", "Reportar", "Mapa") navega a la rama correspondiente
  desde cualquier pantalla

### Implementación para User Story 2

- [X] T019 [US2] Crear `lib/ui/core/ui/app_bottom_nav_bar.dart` (<200 líneas): recibe el
  `StatefulNavigationShell` y renderiza una barra con 3 ítems (Inicio, Reportar, Mapa) (FR-006)
- [X] T020 [US2] Conectar cada ítem de la barra a `navigationShell.goBranch(index)` para navegar
  directo a su rama (FR-007)
- [X] T021 [US2] Integrar `app_bottom_nav_bar.dart` como `bottomNavigationBar` del `Scaffold`
  builder del `StatefulShellRoute.indexedStack` en `lib/config/routes.dart`, para que sea visible
  en las 3 ramas (depende de T005, T019)

**Checkpoint**: User Story 1 y 2 funcionan juntas de forma independiente.

---

## Fase 5: User Story 3 - Identificar la sección activa (Priority: P3)

**Goal**: la barra de navegación inferior resalta visualmente la sección actualmente visible.

**Independent Test**: navegar a cada sección (por botón o por barra inferior) y verificar que el
ícono correspondiente en la barra inferior se muestra activo/seleccionado (ver `quickstart.md`,
escenario 3).

### Tests para User Story 3

- [X] T022 [US3] Ampliar `test/ui/navigation/app_bottom_nav_bar_test.dart` (creado en T018) con un
  caso que verifica que el ítem resaltado visualmente coincide con el `currentIndex` del
  `StatefulNavigationShell` (depende de T018)

### Implementación para User Story 3

- [X] T023 [US3] En `lib/ui/core/ui/app_bottom_nav_bar.dart`, usar el `currentIndex` del
  `StatefulNavigationShell` para marcar visualmente el ítem activo (FR-008) (depende de T019)

**Checkpoint**: las 3 user stories funcionan de forma independiente y en conjunto.

---

## Fase Final: Polish & Cross-Cutting Concerns

- [ ] T024 [P] Validar manualmente los casos límite de `quickstart.md` (doble tap, modo avión, sin
  login, y re-tocar una sección ya activa sin duplicar navegación)
- [X] T025 [P] Correr `dart format .` y `flutter analyze`, corregir cualquier hallazgo (Regla 10 de
  la constitución)
- [ ] T026 Ejecutar `quickstart.md` de punta a punta en un emulador Android y un simulador iOS

---

## Dependencias y Orden de Ejecución

### Dependencias entre Fases

- **Setup (Fase 1)**: sin dependencias — puede empezar de inmediato
- **Foundational (Fase 2)**: depende de que Setup esté completo — BLOQUEA todas las user stories
- **User Stories (Fase 3+)**: todas dependen de que Foundational esté completo
  - Pueden avanzar en paralelo si hay más de una persona, o en orden P1 → P2 → P3
- **Polish (Fase Final)**: depende de que las user stories deseadas estén completas

### Dependencias entre User Stories

- **US1 (P1)**: puede empezar tras Foundational — sin dependencia de otras stories
- **US2 (P2)**: puede empezar tras Foundational — usa el `StatefulNavigationShell` que ya expone la
  Fase 2, pero es independientemente testeable sin US1 implementada
- **US3 (P3)**: depende de que exista `app_bottom_nav_bar.dart` (creado en US2, T019) — es una
  ampliación visual sobre ese mismo widget, no una feature separada

### Dentro de cada User Story

- Los tests se escriben antes de la implementación y deben fallar primero
- Pantallas/widgets antes que su integración en `routes.dart`
- Story completa antes de pasar a la siguiente prioridad

### Oportunidades de Paralelismo

- T002 y T003 (Fase 1) en paralelo
- T006, T007, T008 (Fase 2, pantallas placeholder) en paralelo
- T011 (test US1) puede avanzar en paralelo con T012 (assets) mientras no se implemente T013
- T018 (test US2) es independiente de la implementación de US1
- T024 y T025 (Fase Final) en paralelo

---

## Ejemplo de Paralelismo: User Story 1

```bash
# Lanzar en paralelo:
Task: "Widget test en test/ui/home/home_screen_test.dart"
Task: "Agregar assets de imagen de fondo e ícono en pubspec.yaml"
```

---

## Estrategia de Implementación

### MVP primero (solo User Story 1)

1. Completar Fase 1: Setup
2. Completar Fase 2: Foundational (CRÍTICO — bloquea todas las stories)
3. Completar Fase 3: User Story 1
4. **Detenerse y validar**: probar User Story 1 de forma independiente (escenario 1 de
   `quickstart.md`)
5. Demo si está listo

### Entrega incremental

1. Setup + Foundational → fundación de ruteo lista
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
