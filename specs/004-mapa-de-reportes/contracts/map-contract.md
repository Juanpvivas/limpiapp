# Contrato: Mapa de Reportes

Esta feature no expone una API ni cambia el esquema de Firestore. Los "contratos" relevantes son
(A) qué lee del backend ya existente y (B) el contrato de interacción de la pantalla del mapa, que
`/speckit-tasks` y los tests usan como fuente de verdad.

## A. Contrato de lectura (backend existente)

- **Colección**: `reports` — esquema completo vigente en
  `specs/003-mis-reportes/contracts/reports-schema.md`. Esta feature **no lo modifica**.
- **Campos consumidos por el mapa** (todos ya presentes):

  | Campo | Uso en el mapa |
  |---|---|
  | `latitude`, `longitude` (`number \| null`) | Posición del marcador. `null` / `(0,0)` / fuera de rango → reporte no mapeable (FR-004). |
  | `status` (`string`) | Color del marcador (FR-005) y chip de la tarjeta. |
  | `reportNumber`, `wasteCategory`, `address`, `photoUrl`, `createdAt` | Contenido de la tarjeta resumen (FR-017). |
  | `deviceId` (`string`) | Filtro "solo mis reportes" — aplicado por `ReportQueryService.watchReportsByDevice` (reutilizado). |

- **Consulta**: `collection('reports').where('deviceId', isEqualTo: <id>).orderBy('createdAt',
  descending: true)` — reutilizada de la 003. **Sin índice compuesto nuevo.**
- **Tiempo real**: `.snapshots()` (ya envuelto por `ReportListRepositoryImpl`). Un reporte nuevo o
  un cambio de `status` se refleja en los marcadores sin recargar (FR-021, SC-006).
- **Errores**: un `Left(Failure)` del stream llega a la pantalla como `AsyncError` vía
  `myReportsProvider` → estado de error con reintento (FR-025). "0 reportes" es un `data` válido,
  no un error (FR-023).

## B. Contrato de UI de la pantalla del mapa

### B.1 Estados de la pantalla

| Estado | Condición | UI esperada |
|---|---|---|
| Cargando | `mapMarkersProvider` en `loading` (antes de la 1ª emisión) | Indicador de progreso centrado (FR-022). |
| Error | `mapMarkersProvider` en `error` | `MapErrorState`: mensaje + botón "Reintentar" que hace `ref.invalidate(myReportsProvider)` (FR-025). |
| Vacío (sin reportes) | `data` y 0 reportes mapeables en total | Mapa centrado en `kIbagueCenter` (zoom `kCityZoom`) + `MapEmptyOverlay` con mensaje "aún no has enviado reportes" (FR-023). Sin marcadores. |
| Vacío (por filtro) | `data`, hay reportes mapeables pero el filtro activo deja 0 | Mapa visible + aviso "sin reportes en este estado" (FR-024). No es error. |
| Con datos | `data` con ≥ 1 marcador visible | Mapa + marcadores/clusters + leyenda + control de filtro. Encuadre automático (B.3). |

### B.2 Marcadores y clustering

- 1 marcador por reporte con `isMappable == true` (FR-003/FR-004).
- Color: `markerColorFor(status)` → `pendiente=rojo`, `enProceso=naranja`, `solucionado=verde`
  (FR-005). Ícono estándar de Flutter (`Icons.location_pin`), sin assets (FR-006).
- Leyenda visible con las 3 entradas color→estado (FR-007).
- Marcadores próximos (según zoom) → 1 burbuja de clúster con el **conteo** de reportes contenidos
  (FR-010). Color de la burbuja: neutro (no un color de estado). Acercar zoom o tocar la burbuja →
  se expande (FR-011).

### B.3 Encuadre (fit-to-bounds)

| Marcadores visibles | Comportamiento |
|---|---|
| ≥ 2 | `fitCamera(CameraFit.bounds(...))` con padding, todos dentro de la vista (FR-008). |
| exactamente 1 | `move(punto, kSingleMarkerZoom)` — centrado, zoom legible, no máximo (FR-009). |
| 0 | `move(kIbagueCenter, kCityZoom)` + overlay (FR-023/FR-024). |

Se recalcula al abrir la pantalla y al cambiar el filtro (FR-016). Al volver del detalle **no** se
fuerza un re-encuadre nuevo más allá del que dispare el estado actual; el filtro se conserva
(FR-028).

### B.4 Filtro

- Disparado desde un ícono (embudo) en la barra superior (FR-012).
- Opciones, **selección única**: "Todos" (default), "Pendiente", "En proceso", "Solucionado"
  (FR-013). Mapea a `ReportFilter.{todos,pendientes,enProceso,solucionados}`.
- Al elegir ≠ "Todos": solo marcadores/clusters de ese estado (FR-014).
- Estado del filtro **independiente** del de "Mis reportes" (FR-015). Se conserva al volver del
  detalle (FR-028).

### B.5 Tarjeta resumen y navegación

- Tap en un marcador individual → `ReportSummaryCard` sobre el mapa con: miniatura de foto,
  `reportNumber`, chip de estado, tipo de residuo, dirección, fecha/hora (FR-017).
- Como máximo **una** tarjeta a la vez (FR-018). Tap en otro marcador la reemplaza.
- Cierre: tap fuera de la tarjeta o control de cierre → sin tarjeta (FR-019).
- Tap en la tarjeta → `context.go('/mis-reportes/<reportId>')`: activa la rama **Inicio** y abre
  `ReportDetailScreen` (la de la feature 003, sin cambios) (FR-020). Antes de navegar se limpia la
  selección.

### B.6 Mapa base

- Teselas OSM (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`),
  `userAgentPackageName = com.juanpvivas.limpiapp`.
- Atribución "OpenStreetMap contributors" visible siempre (FR-026, condición de la constitución
  v2.4.0).
- Fallo de teselas (sin conexión / proveedor caído) → mapa sin mosaicos pero con marcadores y
  controles operativos; **no** es un estado de error de la pantalla (constitución v2.4.0,
  Principio V).

### B.7 Fuera del contrato (no implementar)

Reportes de otros dispositivos / mapa público, crear reporte desde el mapa, rutas/indicaciones,
mapa de calor, caché offline de teselas, marcador de ubicación del usuario, cualquier escritura de
estado de reporte.
