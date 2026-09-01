# Data Model: Manejo de estado sin conexión

Esta feature **no persiste datos nuevos** ni cambia el esquema de Firestore/Storage. Introduce un
tipo de dominio para el estado de conectividad (efímero, en memoria) y reutiliza tipos existentes.

## 1. `ConnectivityStatus` (domain model — enum)

`lib/domain/models/connectivity_status.dart`

```text
enum ConnectivityStatus { online, offline }
```

- **online**: hay una interfaz de red activa Y no hay una racha de fallos de establecer conexión
  con el backend (contador `< 2`).
- **offline**: no hay interfaz de red, **o** hubo ≥ 2 fallos consecutivos de establecer conexión
  sin ningún éxito intermedio (FR-005 a/b).
- Valor por defecto al arrancar la app, antes del primer evento: `offline` **no** se asume — se
  parte de `online` y el primer evento de `connectivity_plus` corrige en < 1 s (evita un
  parpadeo del aviso en el arranque con conexión). *(Alternativa: exponer un tercer valor
  `unknown` — descartado por simplicidad; ver research.md §3.)*
- Sin transiciones de estado persistidas: es un flujo (`Stream`) reactivo.

## 2. `ConnectivityRepository` (domain interface)

`lib/domain/repositories/connectivity_repository.dart`

| Método | Firma | Descripción |
|---|---|---|
| `watch` | `Stream<ConnectivityStatus> watch()` | Flujo del estado actual, ya **debounced** (research.md §2): online→offline casi inmediato, offline→online tras ~1.5 s de estabilidad. Nunca emite error: un fallo del stream subyacente se degrada a `offline` dentro de la implementación. Devuelve `Stream<T>` crudo (sin `Either`) al amparo del carve-out del Principio V para *flujos de estado observables* (enmienda v2.6.0). |

No expone métodos de escritura ni `Either` (carve-out del Principio V v2.6.0; ver research.md §3).

## 3. `ConnectivityService` (data — sin interfaz propia, wrapper delgado)

`lib/data/services/connectivity_service.dart`

| Miembro | Firma | Descripción |
|---|---|---|
| ctor | `ConnectivityService(Connectivity connectivity, {Duration onlineDebounce, int failureThreshold})` | `connectivity` de `connectivity_plus`; `onlineDebounce` default ~1.5 s; `failureThreshold` default 2. |
| `statusStream` | `Stream<ConnectivityStatus>` | Combina `connectivity.onConnectivityChanged` (parte a) con el contador de fallos (parte b) y aplica el debounce. |
| `reportBackendUnreachable` | `void reportBackendUnreachable()` | Lo llaman los Repositories cuando una operación falla por **no poder establecer conexión** (timeout / host inalcanzable). Incrementa el contador. |
| `reportBackendReachable` | `void reportBackendReachable()` | Lo llaman los Repositories tras una operación exitosa contra el backend. Resetea el contador a 0. |

Regla combinada: `online` ⟺ `hasInterface && consecutiveFailures < failureThreshold`.

## 4. `connectivityStatusProvider` (presentation)

`lib/ui/core/providers/connectivity_provider.dart` — `@riverpod`

| Aspecto | Valor |
|---|---|
| Tipo | Provider de `Stream<ConnectivityStatus>` → `AsyncValue<ConnectivityStatus>` al consumir |
| Fuente | `getIt<ConnectivityRepository>().watch()` |
| Consumidores | `OfflineBanner` (FR-001/FR-002); `ReportListScreen` y `ReportMapScreen` para elegir el mensaje del estado de error (FR-007); `NewReportNotifier.submit()` para el chequeo pre-envío (FR-013) y el mensaje específico (FR-018) |
| Ciclo de vida | `keepAlive` (el estado de red interesa mientras la app viva; evita re-suscripciones al SDK) |
| Fallback mientras carga | tratar `AsyncLoading`/sin dato como `online` (no mostrar el aviso hasta tener certeza — evita parpadeo en el arranque) |

## 5. Tipos reutilizados (sin cambios de forma)

- **`Failure` / `NetworkFailure`** (`lib/domain/models/failure.dart`): `NetworkFailure` ya existe y
  ya se distingue de `ServerFailure`. Los `TimeoutException` del envío y el timeout de primera
  emisión de lectura se mapean a `NetworkFailure` en la capa Data. **No se agrega subtipo nuevo**
  (research.md §5).
- **`NewReportState`** (`lib/ui/reports/providers/new_report_state.dart`): sin campos nuevos. Se
  usa el `submitError` (String?) ya existente; solo cambia **qué texto** se le asigna (mensaje
  específico de "sin conexión" vs. genérico) y se garantiza que `isSubmitting` vuelve a `false`
  también en el camino de timeout.
- **`Report` / colección `reports` / índices**: sin cambios.

## 6. Textos únicos (FR-019)

`lib/ui/core/offline_copy.dart` — constantes de una sola fuente:

| Constante | Uso |
|---|---|
| `kOfflineBannerText` | Franja del aviso global ("Sin conexión a internet") |
| `kOfflineReadErrorText` | Estado de error de lectura cuando offline / `NetworkFailure` |
| `kOfflineSubmitErrorText` | `submitError` de "Crear reporte" cuando offline / `NetworkFailure` ("Sin conexión: el reporte no se envió y no se guardó nada.") |
| `kGenericServerErrorText` | Estado de error de lectura / envío cuando el backend responde con error (`ServerFailure`) |
| `kRetryLabel` | Botón "Reintentar" en `DataErrorState` |

## 7. Flujo

```text
connectivity_plus (onConnectivityChanged)      Repos: reportBackendReachable/Unreachable()
        \                                          /
         v                                        v
      ConnectivityService  ──(combina + debounce)──►  Stream<ConnectivityStatus>
                                   |
                    ConnectivityRepositoryImpl (implements ConnectivityRepository)
                                   |
                      connectivityStatusProvider (@riverpod, keepAlive)
                    /                    |                         \
           OfflineBanner        ReportList/MapScreen        NewReportNotifier.submit()
        (app.dart builder)   (mensaje offline vs genérico)  (pre-check + mensaje específico)
```
