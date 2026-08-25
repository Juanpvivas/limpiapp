# Phase 0 Research: Shell de Navegación Principal

Todos los aspectos del Technical Context quedaron resueltos a partir de la spec, la constitución y
el input técnico del usuario — no quedó ningún `NEEDS CLARIFICATION`. Este documento registra las
decisiones tomadas y sus alternativas descartadas.

## 1. Patrón de navegación con barra inferior persistente

- **Decision**: `go_router` con `StatefulShellRoute.indexedStack`, con 3 ramas (`home`, `reportar`,
  `mapa`), cada una con su propio `Navigator` anidado.
- **Rationale**: cada sección mantiene su propio stack de navegación y su estado de scroll/formulario
  al cambiar de pestaña, sin reconstruir el widget tree completo — es el patrón oficial de go_router
  para bottom nav bars persistentes, y ya es el router aprobado en el Principio I de la constitución.
- **Alternatives considered**:
  - `IndexedStack` manual sin integración con `go_router` — funciona, pero pierde deep-linking nativo
    (no hay una URL por pestaña) y duplica lógica que `go_router` ya resuelve.
  - Reconstruir la pantalla de destino en cada tap (navegación "plana", sin stacks independientes) —
    más simple, pero pierde estado de scroll/formulario al volver a una pestaña visitada, lo cual
    degrada la experiencia de usuario sin necesidad.

## 2. Estado de la pestaña/sección activa

- **Decision**: usar directamente el `currentIndex` que `StatefulNavigationShell` provee al widget
  builder de `go_router` para resaltar el ícono activo en la barra inferior (User Story 3). No se
  introduce ningún provider de Riverpod para esto.
- **Rationale**: `go_router` ya es la fuente de verdad de en qué rama está el usuario; duplicar ese
  valor en un `StateProvider<int>` de Riverpod crearía dos fuentes de verdad que podrían
  desincronizarse (ej. tras un deep link o `context.go()` directo).
- **Alternatives considered**:
  - `StateProvider<int>` en Riverpod para el índice activo — descartado por el riesgo de
    desincronización descrito arriba, y porque el Principio I reserva Riverpod para *estado de
    negocio*, no para estado que el router ya expone nativamente.

## 3. Pantallas placeholder para las features de destino

- **Decision**: `new_report_screen.dart`, `report_list_screen.dart` y `report_map_screen.dart` se
  implementan en esta feature como `Scaffold` mínimos con el nombre de la sección, sin lógica
  interna.
- **Rationale**: permite validar de punta a punta los 3 flujos de navegación (US1 y US2 del spec) sin
  bloquear esta feature a que "Crear Reporte", "Mis Reportes" y "Mapa de Reportes" estén
  implementadas — cada una se especifica y construye por separado, como se acordó en la spec.
- **Alternatives considered**:
  - Esperar a implementar las 3 features de negocio antes de mergear el shell de navegación —
    descartado: retrasa la entrega y rompe la independencia entre features que exige el spec-template
    (cada User Story debe ser testeable de forma independiente).

## 4. Assets estáticos (branding, imagen de fondo)

- **Decision**: ícono e imagen de fondo se declaran como assets locales en `pubspec.yaml` y se
  renderizan con `Image.asset`.
- **Rationale**: consistente con la assumption ya documentada en el spec de que la pantalla de inicio
  debe funcionar sin conexión; al ser elementos puramente decorativos, no justifican una fuente de
  datos remota ni el estado de carga/error que eso implicaría.
- **Alternatives considered**:
  - Cargar la imagen de fondo desde una URL remota (`Image.network`) — descartado: rompe el
    requisito de "funciona sin conexión" del spec y agrega manejo de error/loading innecesario para
    un elemento no funcional.

## Interfaces externas

Esta feature no expone ninguna interfaz externa (API REST, CLI, esquema de datos) — es navegación
interna de UI consumida únicamente por el propio usuario de la app. Por eso no se genera un
directorio `contracts/` en la Fase 1, según lo permitido por el flujo de `/speckit-plan` para
features sin interfaces externas.
