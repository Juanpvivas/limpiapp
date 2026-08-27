# Phase 0 Research: Mis Reportes

El input técnico del usuario para `/speckit-plan` ya fijó las decisiones principales (reutilizar
Firestore, identificador de dispositivo sin dependencias nuevas, lectura en tiempo real, Services
delgados). Este documento registra cómo se resuelven en el diseño y qué alternativas se
descartaron — no quedó ningún `NEEDS CLARIFICATION`.

## 1. Extensión del esquema de `reports` (no un backend nuevo)

- **Decision**: agregar 4 campos al documento existente de `reports` (ver
  `contracts/reports-schema.md`): `status` (string, valor inicial `"pendiente"`), `deviceId`
  (string), `inProgressAt` y `resolvedAt` (timestamp, `null` hasta alcanzarse ese estado).
  `ReportRepositoryImpl.submitReport` (feature "Crear Reporte", ya implementada) se ajusta para
  escribir `status: "pendiente"` y `deviceId` en la misma transacción que ya crea el documento —
  ningún campo nuevo requiere una segunda escritura.
- **Rationale**: el contrato de feature 002 ya anticipó explícitamente esta extensión
  ("Se pueden agregar campos opcionales nuevos... ej. un futuro `status`... sin romper este
  contrato"). Ningún campo existente se renombra ni se elimina.
- **Alternatives considered**: crear una colección separada de "seguimiento" (`report_status`)
  vinculada por `reportNumber` — descartado: obliga a 2 lecturas (el reporte + su seguimiento) para
  mostrar una sola fila de la lista, sin ningún beneficio dado que el volumen de escritura de estos
  campos es mínimo y siempre acompaña al mismo documento.

## 2. Identificador anónimo de dispositivo, sin dependencias nuevas

- **Decision**: `DeviceIdentifierService` (Data) genera el identificador combinando
  `DateTime.now().microsecondsSinceEpoch` con 16 bytes de `Random.secure()` (de `dart:math`,
  criptográficamente seguro, ya incluido en Dart), y lo persiste con `shared_preferences` (primera
  vez que se abre la app). Expuesto a Domain vía `DeviceIdentifierRepository.getDeviceId()`, que
  retorna `Either<Failure, String>` (Principio V) — un fallo de lectura/escritura de
  `shared_preferences` se mapea a un nuevo subtipo `CacheFailure` de la jerarquía `Failure` ya
  existente (la constitución ya lo menciona como ejemplo en el Principio V, no es una jerarquía
  nueva).
- **Rationale**: decisión explícita del usuario — el identificador nunca se muestra ni sale de la
  app, solo sirve como llave de filtro en Firestore, así que no necesita el formato estándar UUID
  ni una dependencia nueva. Esto evita una enmienda a la constitución para este caso de uso
  puntual.
- **Alternatives considered**: paquete `uuid` — descartado por decisión explícita del usuario
  (requeriría enmienda a la constitución para un caso de uso que no la necesita).

## 3. Lectura en tiempo real sin acoplar Domain/Presentation al SDK de Firestore

- **Decision**: `ReportQueryService` (Data) envuelve `.snapshots()` de Firestore y retorna
  únicamente tipos propios de Dart — records `(String id, Map<String, dynamic> data)` para cada
  documento — nunca `DocumentSnapshot`/`QuerySnapshot`/`Query` crudos.
  `ReportListRepositoryImpl` consume ese stream, mapea cada registro a `Report` (vía
  `ReportDto.fromFirestore`), y expone `Stream<Either<Failure, List<Report>>>` /
  `Stream<Either<Failure, Report?>>` — un error del stream subyacente (ej. `permission-denied`) se
  intercepta y se emite como un valor `Left(Failure)` dentro del stream, nunca como un error de
  stream sin capturar.
- **Rationale**: research.md de "Crear Reporte" (§8) ya documentó que `DocumentReference` es
  `sealed` en la versión actual de `cloud_firestore` (no mockeable con `mocktail` fuera del
  paquete). Lo mismo aplica a `Query`/`QuerySnapshot`/`DocumentSnapshot`. Al retornar records
  planos desde el Service, el Repository sigue siendo 100% testeable con `mocktail` mockeando el
  Service (igual que en la feature anterior), sin tocar el SDK de Firestore en los tests.
- **Alternatives considered**: exponer directamente `Stream<QuerySnapshot>` desde el Repository —
  descartado: filtraría un tipo del SDK de Firebase hacia Domain/Presentation, violando el
  Principio II (Domain no debe conocer detalles de infraestructura) y haciendo imposible testear
  el Repository con `mocktail`.

## 4. Filtro por estado: en memoria, no una consulta distinta por pestaña

- **Decision**: la pestaña de filtro ("Todos"/"Pendientes"/"En proceso"/"Solucionados") filtra en
  el cliente sobre la misma lista ya recibida por el stream de "Mis reportes" — no dispara una
  consulta nueva a Firestore por cada pestaña.
- **Rationale**: evita necesitar un índice compuesto de Firestore (`deviceId` + `status` +
  `orderBy(createdAt)`) solo para un filtro de UI; el volumen de reportes por dispositivo es bajo
  (un ciudadano reportando puntos sucios, no miles de documentos), así que filtrar en memoria no
  tiene costo de rendimiento perceptible.
- **Alternatives considered**: una consulta de Firestore distinta por pestaña
  (`.where('status', isEqualTo: ...)`) — descartado por la razón anterior; se puede migrar a esto
  más adelante sin cambiar la interfaz `ReportListRepository` si el volumen de datos lo justifica.

## 5. Identificar el reporte en la ruta de "Detalle" (no por `extra`)

- **Decision**: la ruta `/mis-reportes/:reportId` recibe el ID del documento de Firestore como
  parámetro de ruta (`state.pathParameters['reportId']`), y `ReportDetailScreen` se suscribe a
  `ReportListRepository.watchReportById(reportId)` — no recibe un `Report` ya resuelto por `extra`
  como hace "Confirmación".
- **Rationale**: a diferencia de "Confirmación" (que muestra una instantánea fija de un envío que
  ya terminó), "Detalle del reporte" debe reflejar cambios de estado en tiempo real (Assumption de
  spec.md) — eso requiere una suscripción activa al documento por su ID, no una copia estática
  pasada por navegación.
- **Alternatives considered**: pasar el `Report` completo por `extra` (como en "Confirmación") y
  además suscribirse a actualizaciones — descartado: duplica la fuente de verdad (el `extra`
  inicial vs. el stream) sin necesidad, ya que el ID es suficiente para reconstruir todo desde
  Firestore.

## 6. Presentación: providers basados en `Stream`, no en un Notifier con `Future`

- **Decision**: `myReportsProvider` (`@riverpod Stream<List<Report>>`, funcional) y
  `reportDetailProvider` (`@riverpod Stream<Report?>`, funcional con parámetro `reportId`) —
  ninguno es una clase `Notifier`. Ambos resuelven sus dependencias vía `getIt<T>()` igual que
  `NewReportNotifier`. Un fallo (`Left(Failure)` del Repository) se traduce a una excepción dentro
  del `Stream` para que Riverpod lo represente como `AsyncValue.error` de forma nativa — es la
  única capa donde `Either` se traduce a la idiomática de Riverpod; Domain y Data siguen usando
  `Either` según el Principio V.
- **Rationale**: a diferencia de `NewReportNotifier` (que ejecuta acciones puntuales del usuario:
  elegir foto, enviar), esta feature solo necesita reflejar un flujo continuo de datos — el
  patrón idiomático de Riverpod para eso es un provider de `Stream`, no un `Notifier` con métodos
  imperativos.
- **Alternatives considered**: un `Notifier` que se suscribe manualmente al stream del Repository
  dentro de `build()` y llama `state = ...` en cada evento — descartado: reimplementa a mano lo
  que un provider de `Stream` ya hace de forma nativa en Riverpod, con más código y más riesgo de
  fugas de suscripción.

## 7. Registro de `SharedPreferences` en GetIt: no como singleton síncrono

- **Decision**: `DeviceIdentifierService` no recibe una instancia de `SharedPreferences` ya
  resuelta por constructor; en su lugar, llama a `SharedPreferences.getInstance()` (que retorna un
  `Future`, se cachea internamente por el propio paquete) dentro de su propio método async cada vez
  que se necesita. El Service en sí se sigue registrando síncrono en `service_locator.dart`
  (`registerLazySingleton(() => DeviceIdentifierService())`).
- **Rationale**: `SharedPreferences.getInstance()` es asíncrono, y el resto de
  `setupServiceLocator()` es síncrono (se llama antes de `runApp()`, sin `await` en el `main()`
  actual). Evita introducir `registerLazySingletonAsync` + `getIt.isReady<T>()` solo para este
  caso, cuando el propio paquete `shared_preferences` ya cachea su instancia interna y hace que
  llamar `getInstance()` repetidamente sea barato.
- **Alternatives considered**: registrar `SharedPreferences` como dependencia asíncrona en GetIt
  (`registerSingletonAsync`) y esperarla en `main.dart` antes de `runApp()` — descartado por
  complejidad innecesaria frente al beneficio nulo (un solo Service la usa).

## 8. Estrategia de testing (igual que "Crear Reporte")

- **Decision**: `ReportListRepositoryImpl`/`DeviceIdentifierRepositoryImpl` se testean con
  `mocktail` mockeando sus Services (`ReportQueryService`, `DeviceIdentifierService`), nunca el SDK
  de Firebase/`shared_preferences` directamente. Los providers de `Stream` se testean con
  `ProviderContainer` alimentando streams controlados (`Stream.fromIterable`/`StreamController`) a
  través de los Repository mockeados.
- **Rationale**: mismo racional documentado en research.md de "Crear Reporte" §8 — mantener los
  Services delgados hace que toda la lógica testeable viva en el Repository, que sí se mockea sin
  fricción.
