<!--
Sync Impact Report
- Version change: 1.0.0 → 2.0.0
- Modified principles (content, titles unchanged):
  - I. Stack Tecnológico Oficial — `flutter_bloc` reemplazado por `flutter_riverpod` +
    `riverpod_annotation` (+ `riverpod_generator`/`build_runner` en dev); `bloc_test` reemplazado
    por testing directo con `ProviderContainer`.
  - II. Clean Architecture en Capas — la capa Presentation ya no usa Bloc/Cubit
    (`*_bloc.dart`/`*_event.dart`/`*_state.dart`); ahora usa Riverpod Notifier/AsyncNotifier
    (`*_provider.dart`, opcionalmente `*_state.dart` con `freezed` para estado UI-only). Diagrama y
    descripción del flujo de datos actualizados de "Bloc" a "Notifier (Riverpod)".
  - III. Convenciones de Código y Estilo Dart — regla de desacoplamiento UI/estado reescrita para
    `ConsumerWidget` + `ref.watch`/`ref.read` en vez de `BlocBuilder`/`context.read<Bloc>()`.
  - IV. Restricciones Estrictas — prohibición de `setState` ahora referencia estado gestionado por
    un Riverpod Notifier/AsyncNotifier en vez de un Bloc/Cubit.
  - V. Inyección de Dependencias y Manejo de Errores — GetIt ya no registra el manejador de estado
    (antes `registerFactory` para Blocs/Cubits); Repositories/Services se siguen registrando en
    GetIt, y los Providers de Riverpod los resuelven internamente. Manejo de errores
    (`Either<Failure, Success>` con `fpdart`) no cambia.
- Added sections: ninguna
- Removed sections: ninguna
- Also updated: sección "Flujo de Desarrollo y Calidad de Código" (tests de Bloc → tests de
  Notifier con `ProviderContainer`).
- Follow-up TODOs: ninguno. Fuera del alcance de esta enmienda (solo constitución): sincronizar
  `docs/ARCHITECTURE.md`, que aún documenta Bloc — ver Next Actions.
-->

# LimpiApp Constitution

## Core Principles

### I. Stack Tecnológico Oficial (NON-NEGOTIABLE)

Todo código nuevo DEBE usar exclusivamente los paquetes aprobados listados abajo. Añadir una
dependencia fuera de esta lista requiere una enmienda a esta constitución (ver Governance), no una
decisión ad-hoc en un PR.

| Categoría | Paquete aprobado | Propósito |
|---|---|---|
| SDK | `flutter` / Dart `^3.13.1` | Base del proyecto (ya fijado en `pubspec.yaml`) |
| Gestión de estado | `flutter_riverpod` + `riverpod_annotation` (`riverpod_generator`/`build_runner` en dev) | Único mecanismo de estado en la capa de Presentación, vía `@riverpod` Notifier/AsyncNotifier |
| Inyección de dependencias | `get_it` (+ `injectable` opcional para generación de código) | Registro y resolución de Repositories/Services |
| Manejo de errores | `fpdart` (`Either<Failure, Success>`) | Resultado explícito de operaciones falibles en Domain/Data |
| Networking | `dio` | Cliente HTTP, interceptores, manejo de tokens |
| Ruteo | `go_router` | Navegación declarativa y guards de ruta |
| Modelos/serialización | `freezed` + `json_serializable` | Inmutabilidad, `copyWith`, `==`, unions, DTOs |
| Persistencia local | `shared_preferences` (config simple) / `isar` (datos estructurados) | Cache y almacenamiento offline |
| Testing | `flutter_test`, `mocktail`, `ProviderContainer` (de `flutter_riverpod`) | Unit, widget y tests de Providers |
| Lint | `flutter_lints` | Base de reglas estáticas (ver Principio III) |

**Política de versiones**: se fija siempre con `^` a la última versión estable compatible con el SDK
del proyecto al momento de instalarla (`dart pub add <paquete>`); no se pinnean versiones exactas
salvo que un paquete introduzca un breaking change documentado que rompa el build.

**Racional**: una lista cerrada de paquetes evita fragmentación (ej. mezclar dos manejadores de
estado o dos librerías de manejo de errores en distintas features) y garantiza que cualquier
desarrollador pueda leer código de cualquier feature sin aprender un patrón nuevo. Riverpod se elige
sobre Bloc por decisión explícita del equipo (menos boilerplate por feature — sin archivos
`*_event.dart` separados — y DI de providers integrada en el propio framework de estado).

### II. Clean Architecture en Capas (Data / Domain / Presentation)

Cada feature en `lib/ui/<feature>/` con su contraparte en `lib/domain/` y `lib/data/` DEBE respetar
la siguiente responsabilidad por capa, a nivel de archivo:

- **Presentation** (`lib/ui/<feature>/`): `*_screen.dart` y `*_widget.dart` (solo árbol de widgets,
  cero lógica de negocio) + `*_provider.dart` con la clase `@riverpod` `Notifier`/`AsyncNotifier`
  (lógica de presentación: mapea inputs de usuario, expuestos como métodos públicos del Notifier, a
  llamadas a Use Cases/Repositorios y transforma el resultado en el `state` del provider). Si el
  estado UI necesita campos que no vienen directo del dominio (ej. flags de UI, posición de un
  carrusel), se define en un `*_state.dart` inmutable con `freezed`.
- **Domain** (`lib/domain/`): `models/*.dart` (entidades puras, sin imports de Flutter),
  `repositories/*_repository.dart` (**interfaces abstractas**, no implementación) y
  `use_cases/*_use_case.dart` (opcional — solo cuando la lógica combina más de un repositorio o se
  reutiliza entre múltiples Notifiers).
- **Data** (`lib/data/`): `repositories/*_repository_impl.dart` (implementa la interfaz definida en
  Domain), `services/*_service.dart` (fuente de datos remota/local, sin lógica de negocio) y
  `model/*_dto.dart` (modelos de request/response, mapeados a entidades de Domain dentro del
  repositorio).

**Flujo de dependencias e inversión de dependencias**:

```
Presentation (Riverpod Notifier)  ──depende de──>  Domain (interfaces + entidades)
Data (impl)                        ──implementa──>  Domain (interfaces)
```

- Presentation DEPENDE de Domain (nunca al revés).
- Data IMPLEMENTA las interfaces de Domain (Dependency Inversion Principle) — Domain nunca importa
  Data.
- El flujo de datos es unidireccional: evento de usuario → método del Notifier → Use
  Case/Repository (interfaz) → implementación concreta en Data → Service → fuente externa, y la
  respuesta regresa como `Either<Failure, Entity>` hasta el Notifier, que actualiza su `state`
  (frecuentemente envuelto en `AsyncValue`), consumido por la UI vía `ref.watch`.

**Racional**: definir el repositorio como interfaz en Domain (en vez de una clase concreta, como
sugiere la guía base de Flutter) permite sustituir la implementación de Data en tests sin tocar
Domain ni Presentation, y hace explícito que Domain es la capa estable de la que todo depende.

### III. Convenciones de Código y Estilo Dart

- **Archivos**: `snake_case.dart` (ej. `report_detail_provider.dart`).
- **Clases, enums, extensions, typedefs**: `PascalCase` (ej. `ReportDetailNotifier`,
  `ReportStatus`).
- **Métodos y variables**: `camelCase` (ej. `submitReport()`, `isLoading`).
- **Constantes**: `camelCase` con `const`/`static const` (Effective Dart); evitar `SCREAMING_CASE`.
- **Constructores `const`**: OBLIGATORIO usar `const` en todo widget/objeto inmutable donde el
  compilador lo permita. Se aplica automáticamente vía lint (`prefer_const_constructors`,
  `prefer_const_literals_to_create_immutables`, `prefer_const_declarations`) en modo `error` en
  `analysis_options.yaml`.
- **Desacoplamiento UI/Estado**: los widgets en `lib/ui/<feature>/widgets/` DEBEN ser
  `ConsumerWidget`/`ConsumerStatefulWidget` (o usar `Consumer`) y SOLO leen estado vía
  `ref.watch(xProvider)`, disparando acciones vía `ref.read(xProvider.notifier).metodo()`. Ningún
  `build()` DEBE contener lógica de negocio, llamadas a repositorios/servicios, ni cálculos que no
  sean puramente de presentación (formateo simple, layout). `ref.watch` DEBE usarse únicamente
  dentro de `build()`; para leer un valor una sola vez fuera de `build()` (ej. en un callback) se usa
  `ref.read`.

**Racional**: convenciones uniformes y `const` obligatorio reducen rebuilds innecesarios y hacen que
el código sea revisable por cualquier miembro del equipo sin fricción de estilo.

### IV. Restricciones Estrictas (NON-NEGOTIABLE)

Estas reglas son bloqueantes en code review; un PR que las viole NO se aprueba sin excepción
documentada y aprobada explícitamente por el equipo:

1. **Prohibido `setState`** dentro de `lib/ui/<feature>/` en cualquier widget cuyo estado esté
   gestionado por un Riverpod Notifier/AsyncNotifier. `setState` solo se permite para estado efímero
   puramente local que nunca se expone a un provider (ej. posición de un `PageController`, un
   `AnimationController`).
2. **Prohibido importar `lib/data/`** desde cualquier archivo en `lib/ui/`. Presentation solo conoce
   Domain (entidades + interfaces de repositorio/use cases).
3. **Prohibido usar `BuildContext`** después de un `await` sin verificar `context.mounted` (o el
   equivalente en `State`) inmediatamente antes de usarlo.
4. **Límite de líneas**: máximo 200 líneas por archivo de widget/UI (`*_screen.dart`,
   `*_widget.dart`). Al superarlo, extraer sub-widgets a archivos propios.

**Racional**: son las fuentes más comunes de bugs de estado inconsistente, fugas de capa y crashes
por `BuildContext` desactualizado en apps Flutter con Riverpod; hacerlas explícitas y no-negociables
evita que se filtren en review por "parece funcionar".

### V. Inyección de Dependencias y Manejo de Errores

- **GetIt**: un único `ServiceLocator` (`lib/config/service_locator.dart`) registra Repositories y
  Services en `main.dart` antes de `runApp()`, con `registerLazySingleton`. El estado de
  Presentation (Notifier/AsyncNotifier) **no** se registra en GetIt: se expone como Riverpod
  Provider (`@riverpod` sobre la clase `Notifier`/`AsyncNotifier`), y dentro de su constructor (o de
  un Provider intermedio, ej. `Provider((ref) => getIt<ReportRepository>())`) resuelve sus
  dependencias leyendo `getIt<T>()`. Los widgets NUNCA instancian un Notifier/Repository
  directamente — el estado se obtiene vía `ref.watch`/`ref.read`, y un Repository/Service usado
  fuera de un provider se obtiene vía `getIt<T>()`.
- **Manejo de errores**: todo método de Use Case y de la interfaz de Repository en Domain DEBE
  retornar `Future<Either<Failure, T>>` (o `Stream<Either<Failure, T>>`). `Failure` es una jerarquía
  sellada (`sealed class Failure`) en `lib/domain/models/failure.dart` (ej. `ServerFailure`,
  `CacheFailure`, `NetworkFailure`). Está prohibido propagar excepciones (`throw`) fuera de la capa
  Data — toda excepción capturada en un Service/Repository DEBE mapearse a un `Failure` antes de
  cruzar hacia Domain/Presentation.

**Racional**: `Either` hace el manejo de errores parte de la firma del método (visible en tiempo de
compilación), evitando `try/catch` dispersos e inconsistentes en los Notifiers.

## Estructura de Directorios y Organización de Archivos

La organización de carpetas y el reparto Domain/Data descritos en el Principio II son la fuente de
verdad y DEBEN mantenerse alineados con [`ARCHITECTURE.md`](../../docs/ARCHITECTURE.md) en la
raíz del repositorio. Cualquier cambio a la estructura de capas se propone primero como enmienda a
esta constitución (Governance) y luego se refleja en `ARCHITECTURE.md`; nunca al revés.

## Flujo de Desarrollo y Calidad de Código

- Antes de cada commit: `dart format .` y `flutter analyze` DEBEN pasar sin errores ni warnings.
- Todo PR que agregue o modifique un Notifier/AsyncNotifier DEBE incluir tests usando
  `ProviderContainer` cubriendo al menos el estado inicial, el caso feliz y un caso de `Failure`.
- Todo PR que agregue un Repository DEBE incluir tests unitarios mockeando el/los Service(s)
  subyacentes con `mocktail`.
- Un PR no se fusiona si viola cualquier regla del Principio IV (Restricciones Estrictas) sin una
  excepción documentada y aprobada en la descripción del PR.

## Governance

Esta constitución tiene precedencia sobre cualquier otra guía, convención informal o preferencia
individual dentro del proyecto, incluyendo `ARCHITECTURE.md` en caso de conflicto (este último debe
actualizarse para reflejar la constitución, no al revés).

- **Enmiendas**: se proponen documentando el cambio, su justificación y su impacto en código
  existente; requieren aprobación explícita antes de fusionarse y se registran incrementando la
  versión de este documento.
- **Versionado semántico** de esta constitución:
  - MAJOR: eliminación o redefinición incompatible de un principio existente.
  - MINOR: nuevo principio o sección, o expansión material de una guía existente.
  - PATCH: aclaraciones, correcciones de redacción, cambios no semánticos.
- **Revisión de cumplimiento**: cada PR debe verificarse contra los Principios I–V antes de
  aprobarse; cualquier complejidad que se desvíe de esta constitución debe justificarse
  explícitamente en la descripción del PR.

**Version**: 2.0.0 | **Ratified**: 2026-08-24 | **Last Amended**: 2026-08-24
