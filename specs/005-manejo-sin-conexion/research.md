# Phase 0 Research: Manejo de estado sin conexión

El input técnico del usuario para `/speckit-plan` fijó lo esencial (aviso global híbrido,
reutilizar el timeout del fix #3, timeout acotado del envío, unificar la UI de error). Este
documento registra las decisiones y las alternativas descartadas. Queda **1 gate** (§1: enmienda a
la constitución por `connectivity_plus`).

## 1. Detección del estado de red — `connectivity_plus` vs. pura-Dart (GATE)

- **Decision**: usar **`connectivity_plus`** (`^7.x`, última estable compatible con el SDK) para
  la **parte (a)** del disparo híbrido de FR-005 (¿tiene el dispositivo alguna interfaz de red
  activa?), y una alternancia dirigida por eventos con su `onConnectivityChanged`. La **parte (b)**
  (WiFi sin internet real / portal cautivo) NO se resuelve con un sondeo dedicado: se cubre con un
  **contador de fallos consecutivos de establecer conexión** que los Repositories reportan al
  `ConnectivityService` (§3). Agregar `connectivity_plus` **requiere enmienda a la constitución**
  (Principio I) — `/speckit-constitution`, bump MINOR a **v2.5.0**, antes de `/speckit-implement`.
- **Rationale**: el aviso global es una franja **siempre presente** que reacciona a cambios de
  red; necesita una señal **pasiva y dirigida por eventos**, no un poller. `connectivity_plus` es
  el paquete estándar del ecosistema, mantenido, multiplataforma (Android/iOS), y solo añade el
  permiso `ACCESS_NETWORK_STATE` (nivel normal, sin prompt) vía manifest merge; en iOS no requiere
  config. El híbrido ya se eligió (spec Q1, opción C) justamente para **no** depender de un sondeo
  de alcanzabilidad real.
- **Alternatives considered**:
  - `InternetAddress.lookup('...')` periódico (dart:io, sin paquete): sondeo activo con polling
    (consumo de batería/datos, latencia de decisión atada al intervalo), y de todos modos hay que
    elegir un host y manejar DNS/timeout. Descartado para la señal principal; el híbrido ya nos da
    "alcanzabilidad" gratis vía los fallos reales de las operaciones de la app.
  - No detectar interfaz y basar el aviso solo en el contador de fallos (parte b): el aviso
    tardaría en aparecer (hay que acumular N fallos) y no reflejaría "WiFi/datos apagados" al
    instante. Peor UX para el caso más común.
  - `internet_connection_checker` / `internet_connection_checker_plus`: hacen sondeo activo a
    hosts fijos; mismo problema que `InternetAddress.lookup`, más una dependencia con menos
    tracción. Descartado.
- **Follow-up**: en `/speckit-constitution`, agregar a la tabla del Principio I una fila
  "Conectividad → `connectivity_plus` → señal de estado de red del dispositivo para el aviso
  global sin conexión" y una nota de racional. Igual que se hizo con `flutter_map` en v2.4.0.

## 2. Umbrales y tiempos (valores concretos)

- **Decision**:
  - Timeout de primera emisión de lectura: **10 s** — ya fijado en el fix #3
    (`ReportListRepositoryImpl.defaultFirstSnapshotTimeout`). No se cambia.
  - Timeout por paso de red del envío: **10 s** para `storageService.upload` y **10 s** para
    `firestoreService.createReport` (transacción). Alineado con SC-004 (error visible en ≤ 10 s).
    Inyectable en `ReportRepositoryImpl` (parámetro con nombre, `Duration`, default 10 s), igual
    patrón que `firstSnapshotTimeout` del fix #3.
  - Contador de fallos consecutivos para la parte (b) del aviso: **umbral = 2**. Un fallo aislado
    puede ser ruido; 2 seguidos sin ningún éxito intermedio indican que no se llega al backend.
  - Debounce/estabilización del aviso (FR-004): **online→offline** casi inmediato (~300 ms, para
    que SC-002 ≤ 3 s se cumpla con holgura) y **offline→online con 1.5 s de estabilidad** (evita
    el parpadeo al recuperar señal de forma intermitente). Asimétrico a propósito: mostrar rápido,
    ocultar con calma.
- **Rationale**: los 10 s vienen del criterio de aceptación del issue #3 y de SC-001/SC-004.
  El umbral 2 y el debounce asimétrico son heurísticas conservadoras; se pueden ajustar sin tocar
  la arquitectura porque viven como constantes en el `ConnectivityService`/provider.
- **Alternatives considered**: timeout único global del envío envolviendo todo `submitReport`
  (incluida la compensación) — descartado: el `await _deleteOrphanPhoto` podría a su vez colgar y
  el timeout global lo mataría a mitad; mejor acotar cada llamada de red y hacer la compensación
  con su propio timeout corto.

## 3. Dónde vive el estado de conectividad y cómo se alimenta (arquitectura)

- **Decision**:
  - `ConnectivityStatus` (`enum { online, offline }`) en `lib/domain/models/`.
  - `ConnectivityRepository` (interfaz, `lib/domain/repositories/`): `Stream<ConnectivityStatus>
    watch()`. Devuelve un `Stream` crudo, **no** `Either<Failure, …>`: no es una operación falible
    puntual, es un flujo de estado observable; un error del stream subyacente se captura en el
    Service y se degrada a `offline` ("no se puede determinar" ya es un estado válido), nunca cruza
    como excepción. Esto es exactamente el **carve-out del Principio V agregado en la enmienda
    v2.6.0** de la constitución ("Flujos de estado observables"), acotado a flujos de estado que
    degradan a un valor por defecto de `T` dentro de la capa Data — no exime a ninguna operación
    puntual falible (ver §5).
  - `ConnectivityService` (`lib/data/services/`): envuelve `Connectivity()` de `connectivity_plus`
    (interfaz + `onConnectivityChanged`), lleva el **contador de fallos consecutivos**, y expone
    `reportBackendReachable()` / `reportBackendUnreachable()`. Combina: `online` ⟺ (hay interfaz)
    **y** (`consecutiveFailures < 2`). Aplica el debounce de §2.
  - `ConnectivityRepositoryImpl` mapea el stream del Service a `Stream<ConnectivityStatus>`.
  - `connectivityStatusProvider` (`@riverpod`, `lib/ui/core/providers/`): expone el
    `Stream<ConnectivityStatus>` a Presentation (aviso global + estados de error).
  - **Alimentación de la parte (b)**: `ReportListRepositoryImpl` (rebasado sobre el fix #3) llama
    `reportBackendUnreachable()` cuando `_failIfNoFirstEvent` inyecta el `NetworkFailure`, y
    `reportBackendReachable()` en la primera emisión `Right`. `ReportRepositoryImpl` llama
    `reportBackendUnreachable()` en `TimeoutException`/`NetworkFailure` del envío y
    `reportBackendReachable()` en un envío `Right`. Ambos Repos reciben el `ConnectivityService`
    inyectado por GetIt.
- **Rationale**: un Repository puede depender de un Service (Principio II — "los Repositories no se
  conocen entre sí"; el Service no es un Repository). Reportar el resultado de las operaciones
  reales es más fiable y barato que un sondeo, y es lo que hace útil la parte (b) del híbrido.
- **Alternatives considered**:
  - Un `NetworkFailureReporter` como interfaz separada que los repos toman, implementada por el
    Service — más ceremonia sin beneficio; el `ConnectivityService` ya es la abstracción correcta.
  - Que el provider observe los `AsyncError` de `myReportsProvider`/envío para inferir el estado —
    frágil (mezcla capas, y el envío no es un provider observable globalmente). Descartado.
  - Registrar el estado en `shared_preferences` — innecesario, el estado es efímero por
    definición.

## 4. Punto de inserción del aviso global

- **Decision**: en `lib/app.dart`, `MaterialApp.router` gana un `builder: (context, child) =>
  OfflineBannerScaffold(child: child)` que compone una `Column`/`Stack` con la franja arriba (o
  como overlay superior respetando el `SafeArea`) y el `child` ruteado debajo. `OfflineBanner` es
  un `ConsumerWidget` que observa `connectivityStatusProvider`; cuando `offline`, muestra una
  franja `AnimatedSize`/`AnimatedSlide` no interactiva (`IgnorePointer` sobre la franja, sin
  interceptar gestos del contenido).
- **Rationale**: el `builder:` de `MaterialApp.router` envuelve **toda** ruta —el shell
  (`StatefulShellRoute.indexedStack`) y las rutas top-level como "Confirmación"— con un solo punto
  de inserción, sin tocar `routes.dart`. `ProviderScope` está por encima de `App` (en `main.dart`),
  así que el `Consumer` dentro de `builder:` funciona.
- **Alternatives considered**:
  - Insertarlo en el `Scaffold` del `StatefulShellRoute.indexedStack` — no cubriría "Confirmación"
    ni futuras rutas top-level. Descartado.
  - Un `Overlay`/`OverlayEntry` global manejado imperativamente — más complejo y propenso a fugas;
    el `builder:` declarativo es suficiente.

## 5. Taxonomía de `Failure` para el matiz del mensaje

- **Decision**: **no** agregar un subtipo nuevo de `Failure`. Se reutiliza `NetworkFailure` (ya
  existe) para todos los timeouts y fallos de conexión, y el **mensaje específico** en la UI se
  decide combinando: `failure is NetworkFailure` **o** `connectivityStatusProvider == offline`.
  Los textos ("Sin conexión: …" para lectura y envío, "Reintentar") viven en
  `lib/ui/core/offline_copy.dart` como única fuente (FR-019).
- **Rationale**: `NetworkFailure` ya distingue el caso de red de `ServerFailure` (backend que
  responde con error). Añadir `TimeoutFailure` no aporta: el usuario no distingue "timeout" de
  "sin red", y la UI ya tiene la señal de conectividad para el matiz. Menos superficie que testear
  y sin tocar la jerarquía sellada compartida por todo el proyecto.
- **Alternatives considered**: subtipo `ConnectionTimeoutFailure` — descartado por lo anterior.
  Poner el texto en cada widget — descartado, viola FR-019 (consistencia).

## 6. Envío ("Crear reporte") — qué falta y qué ya está

- **Ya cubierto por la feature 002** (verificado en el código): `NewReportNotifier.submit()` en
  `Left` pone `isSubmitting: false` + `submitError` y **conserva** `photo`/`category`/
  `description`/`location` (FR-015); en `Right` navega a Confirmación; el número se asigna dentro
  de la transacción, así que un fallo no deja número ni Confirmación (FR-012/FR-016/FR-017).
- **Decision (lo nuevo)**:
  1. `ReportRepositoryImpl.submitReport`: envolver `storageService.upload(...)` y
     `firestoreService.createReport(...)` en `.timeout(_sendTimeout)`; en `TimeoutException` →
     compensación (`_deleteOrphanPhoto`, con su propio timeout corto) + `Left(NetworkFailure())`.
     `_sendTimeout` inyectable (default 10 s).
  2. `NewReportNotifier.submit()`: antes de llamar `submitReport`, si
     `ref.read(connectivityStatusProvider)` está en `offline`, fijar `submitError` con el mensaje
     específico y **no** llamar al Repository (fast-fail sin tocar Storage/Firestore).
  3. `NewReportNotifier.submit()`: en `Left`, elegir el `submitError` según
     `failure is NetworkFailure` / conectividad → mensaje específico "Sin conexión: el reporte no
     se envió y no se guardó nada." vs. el genérico actual (FR-018).
  4. Confirmar (test) que `isSubmitting` vuelve a `false` en el camino de timeout.
- **Rationale**: el timeout en el Repo es el "cinturón de seguridad" (cubre WiFi sin internet, que
  el chequeo pre-envío no detecta al instante); el chequeo pre-envío evita subir la foto para nada
  cuando ya se sabe que no hay red.

## 7. Unificación de la UI de estado de error (FR-019)

- **Decision**: crear `lib/ui/core/ui/data_error_state.dart` — `DataErrorState({required String
  message, required VoidCallback onRetry})`, `StatelessWidget`. Reemplaza:
  - `lib/ui/map/widgets/map_error_state.dart` (se elimina; `report_map_screen.dart` usa el nuevo).
  - el `_ErrorState` privado dentro de `lib/ui/reports/widgets/report_list_screen.dart` (se borra
    la clase privada; la pantalla usa el nuevo).
  Cada pantalla calcula el `message` (offline vs. genérico) leyendo `connectivityStatusProvider` y
  el `Failure`, y lo pasa al widget. El label "Reintentar" y los textos salen de `offline_copy.dart`.
- **Rationale**: hoy los dos widgets son casi idénticos y con texto fijo distinto — esta feature
  ya necesita tocar ambos para el mensaje específico, así que es el momento de unificarlos
  (Principio IV, límite de líneas y DRY).
- **Alternatives considered**: dejar los dos widgets y solo compartir las constantes de texto —
  cumple FR-019 pero mantiene duplicación de layout; se prefiere unificar ahora que ambos se tocan.

## 8. Dependencia de proceso con `fix/issue-3-offline-read-hang`

- **Decision**: la rama `005-manejo-sin-conexion` (creada desde `main`) se **rebasa sobre
  `main` una vez que `fix/issue-3-offline-read-hang` esté mergeado** (PR de ese fix primero). El
  timeout de lectura (`_failIfNoFirstEvent`, 10 s → `Left(NetworkFailure)`) NO se reimplementa en
  esta feature: solo se le añade la llamada a `connectivityService.reportBackendUnreachable()` en
  el camino del fallback y `reportBackendReachable()` en la primera emisión `Right`.
- **Contingencia**: si por lo que sea el fix #3 no se mergea antes, `/speckit-tasks` debe incluir
  una tarea extra para portar `_failIfNoFirstEvent` (86 líneas en `report_list_repository_impl.dart`
  + 49 de tests) desde `fix/issue-3-offline-read-hang`.
- **Rationale**: evita conflictos y trabajo duplicado; el fix #3 es autónomo y ya está probado.
