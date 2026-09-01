# Phase 0 Research: Mapa de Reportes

El input técnico del usuario para `/speckit-plan` ya fijó las decisiones principales (reutilizar el
stream de la 003, `flutter_map` + OpenStreetMap, clustering con conteo, filtro de selección única e
independiente, tarjeta resumen → detalle). Este documento registra cómo se resuelven en el diseño y
qué alternativas se descartaron. No queda ningún `NEEDS CLARIFICATION`; sí queda **un riesgo
registrado** (§1) con plan B explícito.

## 1. Compatibilidad `flutter_map` ↔ `flutter_map_marker_cluster` (RIESGO)

- **Decision**: fijar en `pubspec.yaml`, con `^`, la última versión estable de `flutter_map` que
  tenga un `flutter_map_marker_cluster` compatible publicado; `latlong2` en la versión que exija
  `flutter_map`. Al correr `flutter pub add flutter_map flutter_map_marker_cluster latlong2`, el
  implementador **verifica la resolución**: si `pub` no encuentra un `flutter_map_marker_cluster`
  compatible con la major de `flutter_map` instalada (histórico: el plugin de clustering suele ir
  1 major por detrás), se activa el **plan B**.
- **Plan B**: usar `flutter_map_supercluster` (mismo ecosistema, mantenido, API de clustering
  equivalente: burbuja con conteo, `zoomToBoundsOnClick`). Como `flutter_map_supercluster` **no**
  está en la lista aprobada del Principio I, cambiar a él **exige una enmienda a la constitución**
  (`/speckit-constitution`, versión PATCH o MINOR) *antes* de escribir código de la feature. El
  diseño de widgets (`map_marker_cluster_layer.dart`) queda aislado para que el cambio de plugin
  toque un solo archivo.
- **Rationale**: la agrupación de marcadores es un requisito duro (FR-010/FR-011) y ambos plugins
  cubren el caso; lo único incierto es el emparejamiento de versiones, que solo se puede confirmar
  al instalar. Registrar el plan B ahora evita bloquear `/speckit-tasks`.
- **Alternatives considered**:
  - Implementar clustering a mano (agrupar por celdas de una grilla al `onPositionChanged`) —
    descartado: reinventa un problema resuelto, con peor UX (sin animación de expansión) y más
    código propio que testear.
  - No agrupar en v1 — descartado: contradice FR-010 y el edge case "todos los reportes en la
    misma ubicación" de spec.md.

## 2. Exponer las coordenadas ya persistidas en `Report` (brecha de data-model)

- **Decision**: agregar `double? latitude` y `double? longitude` a `Report`
  (`lib/domain/models/report.dart`, regenerar freezed) y un getter puro
  `bool get isMappable => latitude != null && longitude != null && latitude!.abs() <= 90 &&
  longitude!.abs() <= 180 && !(latitude == 0 && longitude == 0)`.
  `ReportDto.fromFirestore` lee `data['latitude']`/`data['longitude']` como `num?` y aplica
  `?.toDouble()`. `ReportDto.fromSubmission` y `toFirestoreMap` **no cambian** (ya escriben las
  coordenadas).
- **Rationale**: la colección `reports` **ya guarda** `latitude`/`longitude` (`number | null`,
  documentado en `specs/003-mis-reportes/contracts/reports-schema.md`, heredado de "Crear
  Reporte"). El único motivo por el que el mapa no puede posicionar marcadores hoy es que
  `Report`/`fromFirestore` no leen esos campos de vuelta. Es la extensión mínima: 2 campos
  nullable en una entidad que la 003 ya extendió por el mismo motivo.
- **Regla de "mapeable"**: un reporte sin `latitude`/`longitude`, o con `(0, 0)` (centinela de "no
  seteado" — Ibagué está en ~`(4.4389, -75.2322)`, jamás en el golfo de Guinea), o fuera de rango,
  se **excluye** del mapa (FR-004) y no cuenta para el encuadre ni para el estado vacío.
- **Alternatives considered**:
  - Añadir `ReportLocation? location` a `Report` en vez de 2 doubles — descartado: `ReportLocation`
    también carga `automaticAddress`/`manualAddress`, que `Report` ya aplana en `address`; sería
    redundante y ambiguo tener dos fuentes de dirección en la misma entidad.
  - Un provider/consulta nuevos que traigan solo coordenadas — descartado: duplicaría el stream de
    `myReportsProvider` sin ningún beneficio (los documentos ya vienen completos).

## 3. Origen de datos: reutilizar `myReportsProvider` tal cual

- **Decision**: la capa de datos del mapa es `myReportsProvider` (feature 003) **sin cambios**. Ya
  resuelve el `deviceId` vía `DeviceIdentifierRepository`, delega en
  `ReportListRepository.watchReports(deviceId)` (stream en tiempo real de Firestore) y traduce
  cualquier `Left(Failure)` a `ReportsFailureException` → `AsyncError`. El mapa lo consume con
  `ref.watch(myReportsProvider)` y trabaja sobre el `AsyncValue<List<Report>>` resultante.
- **Rationale**: el spec exige exactamente el mismo conjunto de reportes que "Mis reportes"
  (FR-002) y la misma semántica en tiempo real (FR-021). Reutilizar el provider garantiza que las
  dos pantallas nunca diverjan y evita registrar nada nuevo en `service_locator.dart`.
- **Alternatives considered**: un `mapReportsProvider` paralelo que llame a los mismos Repositories
  — descartado: es `myReportsProvider` copiado, con el riesgo de que las dos vistas se
  desincronicen si una cambia.

## 4. Providers de Presentation del mapa

- **Decision**: 3 providers en `lib/ui/map/providers/`:
  1. `mapReportFilterProvider` — `@Riverpod(keepAlive: true)` `Notifier<ReportFilter>`, inicia en
     `ReportFilter.todos`, método `select(ReportFilter)`. Reutiliza el **enum** `ReportFilter` de
     la 003 (`todos/pendientes/enProceso/solucionados` + `.apply(list)` puro) pero es una
     **instancia de estado propia** (FR-015: cambiar el filtro del mapa no toca el de la lista).
     `keepAlive` para que sobreviva al cambio de tab y al ida-y-vuelta al detalle (FR-028).
  2. `mapMarkersProvider` — derivado: `ref.watch(myReportsProvider)` → `.whenData` → aplica
     `mapReportFilterProvider.apply(...)` → filtra por `report.isMappable` → expone
     `AsyncValue<List<Report>>`. Es la fuente única de la capa de marcadores y del cálculo de
     encuadre.
  3. `selectedMapReportProvider` — `@riverpod` `Notifier<String?>` con el `reportId` de la tarjeta
     resumen abierta (`null` = sin tarjeta). Métodos `select(id)` / `clear()`. Auto-dispose (la
     selección no debe sobrevivir a salir del mapa).
- **Rationale**: separa el estado de UI (filtro, selección) del flujo de datos (`myReports`) y
  mantiene cada widget leyendo un provider chico y testeable (Principio III/IV).
- **Alternatives considered**: un único `MapNotifier` con filtro + selección + lista + señal de
  encuadre en un `freezed` state — descartado: mezcla responsabilidades, obliga a reconstruir todo
  el estado ante cualquier cambio y complica los tests; el patrón de la 003 (providers chicos +
  filtro en memoria) ya está probado.

## 5. Navegación del mapa al "Detalle del reporte" (el gotcha de `goBranch`)

- **Hecho del código**: `routes.dart` define **3 ramas** en el `StatefulShellRoute.indexedStack`:
  Inicio (`/`), Reportar (`/reportar`), Mapa (`/mapa`). **No existe un "tab Mis reportes"**:
  `/mis-reportes` y `/mis-reportes/:reportId` están anidadas **bajo la rama Inicio**. La lista
  (`report_list_screen.dart`) navega al detalle con `context.push('$misReportesPath/${report.id}')`
  porque ya está dentro de esa rama.
- **Decision**: desde la tarjeta del mapa, navegar con
  `context.go('$misReportesPath/${report.id}')` (ruta `/mis-reportes/<id>`). Con
  `StatefulShellRoute.indexedStack`, `go` a una ubicación que pertenece a la rama Inicio **activa
  esa rama** y fija su pila en `HomeScreen → ReportListScreen → ReportDetailScreen`. El botón
  "atrás" hace pop a la lista y luego a Inicio; la rama Mapa conserva su propia pila (el
  `IndexedStack` la mantiene montada), así que tocar el tab "Mapa" devuelve el mapa tal como
  estaba. Antes de navegar se limpia la tarjeta (`selectedMapReportProvider.clear()`).
- **FR-028 (filtro conservado al volver)**: sale gratis — `mapReportFilterProvider` es `keepAlive`
  y la rama Mapa nunca se desmonta.
- **Rationale**: `context.go` declarativo deja que go_router elija la rama dueña de la ruta; no
  necesitamos pasar el `StatefulNavigationShell` hasta el widget del mapa ni llamar `goBranch`
  manualmente. El bug de la feature 001 fue precisamente en `goBranch(index, initialLocation: ...)`
  dentro de `AppBottomNavBar`; evitarlo aquí elimina esa clase de error.
- **Nota de redacción de la spec**: donde el spec dice "salta al tab Mis reportes" / "sección Mis
  reportes", léase "activa la rama **Inicio** y abre `/mis-reportes/:reportId`". No hay cambio de
  comportamiento respecto a lo acordado; solo se precisa que el destino vive bajo Inicio.
- **Alternatives considered**:
  - `navigationShell.goBranch(0)` + `context.push('/mis-reportes/<id>')` — descartado: obliga a
    inyectar el shell o un `GlobalKey` hasta el mapa y reintroduce la sutileza de `initialLocation`
    del issue 001.
  - `context.push` desde el mapa — descartado: apilaría el detalle **dentro de la rama Mapa** (tab
    "Mapa" seguiría seleccionado, "atrás" volvería al mapa), contradiciendo la decisión del spec.

## 6. Colores de los marcadores vs. `ReportStatusChip` (divergencia conocida y aceptada)

- **Hecho del código**: `ReportStatusChip` (003) ya define colores por estado: **pendiente =
  ámbar**, **enProceso = azul**, **solucionado = verde** (data-model de la 003).
- **Hecho del spec**: FR-005 + el mock `docs/mocks/6 mapa reporte.jpg` piden marcadores **rojo =
  Pendiente**, **naranja = En proceso**, **verde = Solucionado**.
- **Decision**: cada superficie usa su propia paleta según su fuente. Los **marcadores** siguen la
  spec/mock del mapa (rojo/naranja/verde), definidos en
  `lib/ui/map/widgets/report_marker_style.dart` (`Color markerColorFor(ReportStatus)` + entradas de
  leyenda). La **tarjeta resumen** reutiliza `ReportStatusChip` **sin tocarlo** (ámbar/azul/verde).
  La leyenda del mapa (FR-007) desambigua los colores de los marcadores.
- **Consecuencia visible**: en la tarjeta de un reporte "Pendiente" el marcador es rojo y el chip
  es ámbar. Es una inconsistencia menor y **deliberada** (cada elemento respeta su mock). Queda
  marcada para que el equipo confirme en review si prefiere unificar (fuera de alcance de esta
  feature).
- **Rationale**: cambiar `ReportStatusChip` afectaría la lista y el detalle de la 003 (ya
  entregados) sin que ninguna spec lo pida; cambiar los colores del marcador contradiría FR-005.
  La leyenda existe justo para este propósito.
- **Alternatives considered**: unificar todo a rojo/naranja/verde — descartado: toca UI de la 003
  fuera de alcance. Unificar a ámbar/azul/verde — descartado: contradice FR-005 y el mock.

## 7. Manejo de fallos de teselas + política OSM + tests de widget con mapa

- **Decision (fallos de teselas)**: `TileLayer` con
  `errorTileCallback: (tile, error, stackTrace) { /* log en debug, no-op en release */ }` y
  `evictErrorTileStrategy: EvictErrorTileStrategy.notVisible`. No se lanza ni se mapea a `Failure`:
  el mapa queda gris/en blanco pero marcadores, clustering, leyenda y filtro siguen operativos
  (constitución v2.4.0, Principio V; FR — edge case "fallo al cargar el mapa base").
- **Decision (OSM)**: `TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.juanpvivas.limpiapp')`. Atribución con `RichAttributionWidget` +
  `TextSourceAttribution('OpenStreetMap contributors', onTap: ...)` visible siempre (FR-026,
  condición de la constitución v2.4.0). Se respeta la
  [tile usage policy](https://operations.osmfoundation.org/policies/tiles/) de OSM: tráfico bajo
  (app ciudadana, decenas de marcadores), `User-Agent` identificable, sin descargas masivas. Si a
  futuro el volumen crece, migrar a un proveedor de teselas con plan propio (fuera de alcance).
- **Decision (tests)**: los tests de `WidgetTester` inyectan un `TileProvider` falso que devuelve
  una imagen 1×1 en memoria (no red), y fijan un tamaño de viewport. Así se verifica el árbol de
  widgets (leyenda, tarjeta, estados, navegación) sin depender de teselas reales. La lógica de
  marcadores/filtro/encuadre se prueba en los tests de `ProviderContainer`, no en el widget.
- **Rationale**: cumple el Principio V al pie de la letra y mantiene los tests herméticos (mismo
  criterio que la 003 con Firestore).
- **Alternatives considered**: `NetworkTileProvider` real en tests — descartado: tests no
  deterministas y dependientes de red.

## 8. Encuadre automático (fit-to-bounds) y estado vacío

- **Decision**: `map_view.dart` es `ConsumerStatefulWidget` con un `MapController` local. Un
  `ref.listen(mapMarkersProvider, ...)` recalcula el encuadre cuando cambia el conjunto visible
  (carga inicial y cambio de filtro, FR-008/FR-016):
  - ≥ 2 marcadores mapeables → `mapController.fitCamera(CameraFit.bounds(bounds:
    LatLngBounds.fromPoints(points), padding: EdgeInsets.all(48)))`.
  - exactamente 1 → `mapController.move(point, 15.0)` (zoom fijo legible, FR-009 — no usar
    `fitCamera` con un bounds degenerado).
  - 0 mapeables → `mapController.move(kIbagueCenter, 12.0)` y se muestra `MapEmptyOverlay` encima
    (FR-023). Si el 0 viene de un filtro que no matchea nada pero el dispositivo sí tiene reportes,
    el overlay dice "sin reportes en este estado" y el mapa permanece (FR-024).
  - `kIbagueCenter = LatLng(4.4389, -75.2322)` y las constantes de zoom viven en
    `report_marker_style.dart`.
- **Rationale**: `CameraFit.bounds` es la API idiomática de `flutter_map` v6+; el caso de 1 punto
  se trata aparte porque un bounds de un solo punto no define zoom.
- **Alternatives considered**: encuadrar solo al abrir y no al filtrar — descartado: FR-016 lo
  permite explícitamente y mejora la UX cuando el filtro deja los marcadores fuera de vista.

## 9. Tarjeta resumen (una a la vez, cierre, contenido)

- **Decision**: `ReportSummaryCard` es un overlay (`Align(bottomCenter)` + `Padding`) dentro del
  `Stack` de `report_map_screen.dart`, visible solo cuando `selectedMapReportProvider != null`.
  Contenido (FR-017): `ReportPhotoThumbnail` (miniatura extraída de `report_list_item.dart`),
  `report.reportNumber`, `ReportStatusChip(status)`, `report.category.label`, `report.address`
  (1–2 líneas, elipsis), `formatReportDateTime(report.createdAt)`. El `Report` se toma de la lista
  ya en memoria de `mapMarkersProvider` (buscar por `id`), no de una consulta nueva.
  - Tap en otro marcador → `select(otroId)` reemplaza el contenido (FR-018, una a la vez).
  - Tap fuera (un `GestureDetector` transparente sobre el mapa cuando hay tarjeta) o el botón de
    cierre → `clear()` (FR-019).
  - Tap en la tarjeta → `clear()` y `context.go('/mis-reportes/${report.id}')` (§5).
- **Rationale**: el overlay evita un `showModalBottomSheet` (que taparía el mapa y complicaría
  "una a la vez" + actualización en vivo del estado). Reusar `ReportStatusChip`/`formatReportDateTime`
  mantiene consistencia con la lista.
- **Alternatives considered**: `showModalBottomSheet` — descartado: peor para el requisito de
  actualización en vivo (SC-006) y para descartar tocando el mapa.

## 10. Clustering: parámetros y color del clúster

- **Decision**: `MarkerClusterLayerWidget`/`MarkerClusterLayerOptions` (o el equivalente del plan
  B) con `maxClusterRadius: 45`, `size: Size(44, 44)`, `padding: EdgeInsets.all(48)`,
  `zoomToBoundsOnClick: true`, y un `builder` que dibuja un círculo **neutro** (gris oscuro del
  tema, no un color de estado) con el conteo en blanco. Un marcador individual usa
  `Icon(Icons.location_pin, size: 36, color: markerColorFor(status))`.
- **Rationale**: un clúster puede agrupar reportes de estados distintos, así que colorearlo por
  estado sería engañoso; el conteo es la información relevante (FR-010). `zoomToBoundsOnClick`
  cubre "tocar el grupo lo expande" (FR-011).
- **Alternatives considered**: clúster coloreado por el estado predominante — descartado: ambiguo y
  no lo pide el spec.

## 11. Sin permisos ni ubicación del usuario

- **Decision**: la feature no importa `geolocator` ni `permission_handler` y no dibuja marcador de
  "estás aquí" (FR-027). El centro por defecto es la constante `kIbagueCenter`, nunca la posición
  del dispositivo.
- **Rationale**: el spec lo excluye explícitamente; además evita el flujo de permisos de la
  feature 002.
