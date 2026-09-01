# Contrato: Manejo de estado sin conexión

Esta feature no expone una API ni cambia el backend. Los "contratos" relevantes son (A) el
contrato interno de la capa de conectividad y (B) el contrato de UX del comportamiento sin
conexión, que `/speckit-tasks` y los tests usan como fuente de verdad.

## A. Contrato interno de conectividad

### A.1 `ConnectivityRepository.watch() -> Stream<ConnectivityStatus>`

- Emite el estado **actual** al suscribirse y luego en cada cambio, ya **debounced**.
- Reglas de transición (research.md §2):
  - `online → offline`: casi inmediato (~300 ms) cuando (se pierde la interfaz de red) **o** (el
    contador de fallos consecutivos llega al umbral, por defecto 2).
  - `offline → online`: solo tras **~1.5 s de estabilidad** en la condición "hay interfaz **y**
    contador de fallos < umbral".
- **Nunca** emite un evento de error. Un fallo del stream de `connectivity_plus` se captura en el
  `ConnectivityService` y se trata como "sin interfaz" (tiende a `offline`).

### A.2 Alimentación del contador (parte b del híbrido)

| Origen | Cuándo llama `reportBackendUnreachable()` | Cuándo llama `reportBackendReachable()` |
|---|---|---|
| `ReportListRepositoryImpl` (sobre fix #3) | cuando `_failIfNoFirstEvent` inyecta `Left(NetworkFailure)` (no llegó la 1ª emisión en 10 s) | en la **primera** emisión `Right` de `watchReports`/`watchReportById` |
| `ReportRepositoryImpl` | en `TimeoutException` o `NetworkFailure` de `submitReport` (upload o transacción) | en un `submitReport` que retorna `Right` |

- Un `ServerFailure` (el backend responde con error, ej. `permission-denied`) **no** cuenta como
  "unreachable": no toca el contador (FR-005a — un backend que responde no es "sin conexión").

### A.3 `connectivityStatusProvider`

- `@riverpod`, `keepAlive`. Expone el `Stream<ConnectivityStatus>` del Repository.
- Mientras `AsyncLoading` o sin dato: los consumidores lo tratan como **`online`** (no mostrar el
  aviso hasta tener certeza).

## B. Contrato de UX sin conexión

### B.1 Aviso global (`OfflineBanner`)

| # | Regla | FR |
|---|---|---|
| B1 | Con `connectivityStatusProvider == offline`, una franja visible aparece sobre el contenido en **cualquier** pantalla (shell y rutas top-level como "Confirmación"). | FR-001 |
| B2 | La franja desaparece **sola** al volver a `online`, sin acción del usuario. | FR-002 |
| B3 | La franja no intercepta gestos ni bloquea navegación/scroll/controles. | FR-003 |
| B4 | Ante fluctuaciones muy breves, la franja no parpadea (debounce asimétrico de A.1). | FR-004 |
| B5 | El texto de la franja es `kOfflineBannerText`, único en toda la app. | FR-019 |

### B.2 Lectura ("Mis reportes", "Mapa de reportes")

| # | Regla | FR |
|---|---|---|
| B6 | Sin datos previos y sin conexión, la pantalla pasa del indicador de progreso al estado de error `DataErrorState` con "Reintentar" en ≤ 10 s (timeout del fix #3). | FR-006 / SC-001 |
| B7 | El mensaje del `DataErrorState` es `kOfflineReadErrorText` si (`failure is NetworkFailure`) **o** (`connectivityStatusProvider == offline`); si no, `kGenericServerErrorText`. | FR-007 |
| B8 | "Reintentar" reintenta la carga (`ref.invalidate(myReportsProvider)`); con conexión, sale del error. | FR-008 |
| B9 | El estado de error **no** se limpia solo al reconectar: permanece hasta que el usuario toca "Reintentar" (el aviso global sí desaparece solo). | FR-009 |
| B10 | Tras la primera carga exitosa, una pausa larga sin cambios de datos **no** lleva la pantalla a error (el timeout aplica solo a la 1ª emisión). | FR-010 / SC-007 |
| B11 | Si la pantalla ya muestra datos y se pierde la conexión, los datos permanecen; no se reemplaza por el estado de error (solo aparece el aviso global). | FR-011 |

### B.3 Envío ("Crear reporte")

| # | Regla | FR |
|---|---|---|
| B12 | Si `connectivityStatusProvider == offline` al tocar "Enviar", el envío **no** se inicia (no se sube la foto ni se abre la transacción); `submitError = kOfflineSubmitErrorText` y `isSubmitting` no queda en `true`. | FR-013 (pre-check) |
| B13 | Si el envío se inicia y un paso de red no responde, cada paso corta a los ~10 s → `Left(NetworkFailure)` + intento de borrado compensatorio de la foto; el usuario ve el mensaje en ≤ 10 s. | FR-013 / FR-014 / SC-004 |
| B14 | En cualquier fallo de envío, `isSubmitting` vuelve a `false` y el formulario conserva foto, tipo de residuo, descripción y ubicación. | FR-014 / FR-015 / SC-005 |
| B15 | El `submitError` es `kOfflineSubmitErrorText` si (`failure is NetworkFailure`) **o** (offline); si no, el genérico. | FR-018 |
| B16 | Si el envío no se completó contra el backend, no se asigna número ni se navega a "Confirmación". | FR-016 / FR-017 / SC-006 |
| B17 | Un reintento manual con conexión completa el flujo normal (número + "Confirmación"). | FR-016 |

### B.4 Consistencia

| # | Regla | FR |
|---|---|---|
| B18 | El texto de "sin conexión", el mensaje de error y el label "Reintentar" salen de `lib/ui/core/offline_copy.dart`; el estado de error de lectura de ambas pantallas es el mismo widget `DataErrorState`. | FR-019 / SC-008 |

### B.5 Fuera del contrato (no implementar)

Envío diferido automático / bandeja de salida, reintento automático al reconectar, modo offline de
solo lectura de primera clase, caché de mosaicos del mapa, limpieza garantizada del blob huérfano
de foto, indicadores por-elemento de "pendiente de sincronizar".
