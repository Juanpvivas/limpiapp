# Quickstart: Validar Mapa de Reportes

Guía para verificar manualmente, de punta a punta, que las 3 User Stories del
[spec.md](./spec.md) funcionan antes de dar la feature por completa. Detalles de comportamiento en
[contracts/map-contract.md](./contracts/map-contract.md); decisiones técnicas en
[research.md](./research.md).

## Prerrequisitos

- Flutter SDK `^3.13.1`; dependencias instaladas con las 3 nuevas: `flutter pub add flutter_map
  latlong2 flutter_map_marker_cluster` y luego `flutter pub get`.
  - **Verificación de compatibilidad (research.md §1)**: si `pub` no resuelve
    `flutter_map_marker_cluster` contra la major de `flutter_map` instalada, detener e ir al plan B
    (`flutter_map_supercluster` + enmienda a la constitución) antes de seguir.
- `dart run build_runner build --delete-conflicting-outputs` tras agregar `latitude`/`longitude` a
  `Report`.
- Proyecto de Firebase con Firestore ya configurado (desde "Crear Reporte").
- Al menos 3 reportes enviados desde el dispositivo de prueba, con ubicación (el flujo de "Crear
  Reporte" captura coordenadas automáticamente). Idealmente en **estados distintos**: edita
  `status` de algún documento desde la consola de Firebase (Firestore → `reports`) a `"enProceso"`
  y `"solucionado"` para cubrir los 3 colores.
- Para el caso "sin coordenadas": crea o edita un documento con `latitude`/`longitude` en `null` (o
  ambos en `0`) y confirma que **no** aparece en el mapa.

## Levantar la app

```bash
cd limpiapp
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Escenarios a validar

### 1. Ver mis reportes sobre el mapa (US1, P1)

1. Abre el tab **"Mapa"**.
2. Confirma que se carga un mapa de Ibagué (teselas OpenStreetMap) con la atribución
   "OpenStreetMap contributors" visible.
3. Confirma que hay un marcador por cada reporte del dispositivo **con coordenadas**, y que el
   mapa quedó encuadrado para que todos se vean (fit-to-bounds).
4. Confirma que el color de cada marcador corresponde al estado: **rojo** = Pendiente, **naranja**
   = En proceso, **verde** = Solucionado, y que hay una **leyenda** visible con esa correspondencia.
5. Con un solo reporte mapeable: confirma que el mapa lo centra con un zoom legible (no un
   acercamiento máximo).
6. Sin ningún reporte mapeable (dispositivo nuevo, o todos sin coordenadas): confirma que se ve el
   mapa de Ibagué con un mensaje encima ("aún no has enviado reportes"), sin marcadores.
7. Junta 3+ reportes muy cerca (mismo barrio) y confirma que se agrupan en **una burbuja con el
   número**; acércate el zoom o toca la burbuja y confirma que se separan.
8. Con el mapa abierto, cambia el `status` de un reporte desde la consola de Firebase y confirma
   que el color de su marcador cambia **sin recargar** (< 5 s). Crea un reporte nuevo y confirma
   que aparece un marcador nuevo.

**Resultado esperado**: FR-001 a FR-011, FR-021, FR-022, FR-023, FR-026; SC-001, SC-002, SC-004,
SC-006, SC-007, SC-008.

### 2. Consultar un reporte desde su marcador (US2, P2)

1. Toca un marcador individual y confirma que aparece una **tarjeta resumen** sobre el mapa con:
   miniatura de la foto, número de reporte (`#IL-AAAA-NNNNNN`), chip de estado, tipo de residuo,
   dirección y fecha/hora.
2. Toca otro marcador y confirma que la tarjeta cambia de contenido (nunca dos tarjetas a la vez).
3. Toca fuera de la tarjeta (sobre el mapa) o su control de cierre y confirma que desaparece.
4. Vuelve a abrir una tarjeta y **tócala**: confirma que se abre el "Detalle del reporte" de ese
   reporte (la misma pantalla de "Mis reportes") y que la barra inferior muestra ahora
   **"Inicio"** seleccionado.
5. Pulsa "atrás": confirma que vuelve a la lista "Mis reportes" y luego a Inicio; toca el tab
   **"Mapa"** y confirma que el mapa sigue como lo dejaste.

**Resultado esperado**: FR-017 a FR-020.

### 3. Filtrar el mapa por estado (US3, P3)

1. Con reportes en al menos 2 estados, toca el **icono de filtro (embudo)** en la barra superior.
2. Confirma que las opciones son "Todos" (seleccionada por defecto), "Pendiente", "En proceso",
   "Solucionado", y que solo se puede elegir **una**.
3. Elige "Pendiente" y confirma que solo quedan marcadores/burbujas de reportes pendientes, y que
   el mapa se reajusta a los visibles.
4. Elige un estado sin ningún reporte y confirma el aviso "sin reportes en este estado", con el
   mapa aún visible (no es un error).
5. Vuelve a la lista "Mis reportes" (tab Inicio → "Mis reportes"), confirma que **su** filtro
   sigue como estaba (no se contagió del filtro del mapa).
6. Aplica un filtro en el mapa, abre un detalle desde una tarjeta y regresa al tab "Mapa":
   confirma que el filtro que habías elegido **sigue aplicado**.

**Resultado esperado**: FR-012 a FR-016, FR-024, FR-028; SC-005.

### 4. Degradación sin conexión (edge case)

1. Activa modo avión (o corta la red) y abre el tab "Mapa".
2. Confirma que, aunque los mosaicos no carguen (mapa gris/en blanco), los **marcadores**, la
   **leyenda**, el **filtro** y la **tarjeta** siguen funcionando, y que la pantalla **no** muestra
   un estado de error por las teselas.
3. Si además Firestore no tenía caché, confirma que el estado de error de **datos** (no de mapa)
   aparece con botón "Reintentar".

**Resultado esperado**: constitución v2.4.0 Principio V; edge case "fallo al cargar el mapa base"
de spec.md; FR-025.

## Checks automatizados

```bash
flutter analyze
flutter test
```

Cobertura esperada (ver plan.md → Project Structure):
- `test/ui/map/map_report_filter_provider_test.dart` — valor inicial, `select`, independencia de
  `reportFilterProvider`.
- `test/ui/map/map_markers_provider_test.dart` — caso feliz (mezcla de estados), reporte sin
  coordenadas excluido, `loading`, `error` propagado, filtro aplicado.
- `test/ui/map/report_map_screen_test.dart` — carga / error+reintento / vacío sobre el mapa /
  leyenda presente / tap en marcador → tarjeta / una tarjeta a la vez / tap en tarjeta → navegación
  invocada.
- `test/data/repositories/report_list_repository_impl_test.dart` (ampliado) — `latitude`/`longitude`
  mapeados desde el registro de Firestore; ausentes/inválidos → `null`.
