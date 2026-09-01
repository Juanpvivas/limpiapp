# Feature Specification: Mapa de Reportes

**Feature Branch**: `004-mapa-de-reportes`

**Created**: 2026-08-31

**Status**: Draft

**Input**: User description: "Mapa de Reportes — Pantalla del tab \"Mapa\" (hoy es un placeholder \"Próximamente\"). Permite al ciudadano ver sus propios reportes ubicados sobre un mapa de Ibagué, para tener una vista geográfica de dónde ha reportado puntos sucios y en qué estado están. Solo muestra los reportes enviados desde el propio dispositivo (mismo conjunto que \"Mis reportes\"), en tiempo real. Encuadre automático (fit-to-bounds) de los marcadores del usuario; si no hay reportes, mapa de Ibagué con un mensaje encima. Marcadores por estado: rojo = Pendiente, naranja = En proceso, verde = Solucionado, con iconos estándar (no hay assets de marca) y una leyenda. Marcadores próximos se agrupan en un grupo con el número de reportes; al acercar el zoom o tocar el grupo se separan. Filtro por estado desde un icono (embudo) en la barra superior, selección única (Todos / Pendiente / En proceso / Solucionado), independiente del filtro de la lista \"Mis reportes\". Tocar un marcador muestra una tarjeta resumen (foto miniatura, número #IL-AAAA-NNNNNN, estado, tipo de residuo, dirección, fecha); tocar la tarjeta abre el \"Detalle del reporte\" de la feature \"Mis Reportes\", saltando al tab \"Mis reportes\". Estados: cargando, vacío, error con reintento. Fuera de alcance: reportes de otros usuarios / mapa público, crear reporte desde el mapa, rutas/indicaciones, mapa de calor, caché offline de mosaicos, marcador de ubicación del usuario. Referencia visual: docs/mocks/6 mapa reporte.jpg. Reutiliza la colección de reportes y los streams en tiempo real de la feature \"Mis Reportes\" (003), la pantalla de Detalle de reporte (003), el patrón de filtro por estado (003) y el identificador anónimo de dispositivo."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver mis reportes sobre el mapa (Priority: P1)

Un ciudadano que ya ha enviado uno o más reportes abre el tab "Mapa" y ve todos sus reportes
ubicados como marcadores sobre un mapa de Ibagué. El mapa se ajusta solo para que todos los
marcadores queden a la vista, y cada marcador tiene un color según el estado del reporte, con una
leyenda que explica qué significa cada color.

**Why this priority**: Es el valor central de la feature: una vista geográfica de dónde ha
reportado el ciudadano y en qué estado va cada punto. Sin el mapa con los marcadores, la feature
no existe.

**Independent Test**: Con al menos un reporte enviado desde el dispositivo (con coordenadas),
abrir el tab "Mapa" y verificar que el reporte aparece como un marcador en su ubicación, que el
mapa encuadra todos los marcadores, que el color del marcador corresponde al estado del reporte, y
que hay una leyenda color→estado visible.

**Acceptance Scenarios**:

1. **Given** el dispositivo ha enviado 2 o más reportes con coordenadas, **When** el usuario abre
   el tab "Mapa", **Then** ve un mapa de Ibagué con un marcador por cada reporte, encuadrado para
   que todos los marcadores queden dentro de la vista, y una leyenda que asocia cada color con un
   estado.
2. **Given** el usuario está viendo el mapa, **When** observa un marcador, **Then** su color
   indica el estado del reporte (Pendiente, En proceso o Solucionado) de forma consistente con la
   leyenda.
3. **Given** el dispositivo no ha enviado ningún reporte mapeable, **When** el usuario abre el tab
   "Mapa", **Then** ve el mapa centrado en Ibagué con un mensaje encima indicando que aún no ha
   enviado reportes, sin marcadores.
4. **Given** hay varios reportes muy próximos entre sí para el nivel de zoom actual, **When** el
   usuario abre el mapa, **Then** esos reportes se muestran como un único marcador de grupo con el
   número de reportes que contiene.
5. **Given** el usuario ve un marcador de grupo, **When** acerca el zoom o toca el grupo, **Then**
   el grupo se separa en marcadores individuales (o en subgrupos más pequeños).
6. **Given** el usuario tiene el mapa abierto, **When** el estado de uno de sus reportes cambia (o
   se registra un reporte nuevo desde otra pantalla), **Then** el color del marcador se actualiza
   (o aparece un marcador nuevo) sin que el usuario recargue.

---

### User Story 2 - Consultar un reporte desde su marcador (Priority: P2)

Desde el mapa, el ciudadano toca el marcador de un reporte y ve una tarjeta resumen con los datos
clave de ese reporte. Si quiere más información, toca la tarjeta y llega a la pantalla de detalle
completa del reporte.

**Why this priority**: Convierte la vista geográfica en un punto de entrada útil: permite pasar de
"veo un punto en el mapa" a "sé exactamente qué reporté ahí y en qué va". Depende de que US1 ya
muestre los marcadores.

**Independent Test**: Con un reporte visible como marcador en el mapa, tocar el marcador y
verificar que aparece una tarjeta resumen con miniatura de la foto, número de reporte, estado,
tipo de residuo, dirección y fecha; luego tocar la tarjeta y verificar que se abre el "Detalle del
reporte" correspondiente.

**Acceptance Scenarios**:

1. **Given** el usuario ve un marcador individual, **When** lo toca, **Then** aparece sobre el mapa
   una tarjeta resumen del reporte con miniatura de la foto, número de reporte, estado, tipo de
   residuo, dirección y fecha/hora de envío.
2. **Given** hay una tarjeta resumen visible, **When** el usuario toca otro marcador, **Then** se
   muestra la tarjeta del nuevo reporte y desaparece la anterior (solo una tarjeta a la vez).
3. **Given** hay una tarjeta resumen visible, **When** el usuario toca fuera de la tarjeta o su
   control de cierre, **Then** la tarjeta se oculta y el mapa queda sin tarjeta.
4. **Given** hay una tarjeta resumen visible, **When** el usuario toca la tarjeta, **Then** la app
   abre el "Detalle del reporte" de ese reporte (la misma pantalla de la feature "Mis Reportes"),
   activando la rama **Inicio** (donde está anidada `/mis-reportes/:reportId`; no existe un tab
   "Mis reportes").

---

### User Story 3 - Filtrar el mapa por estado (Priority: P3)

El ciudadano usa el control de filtro del mapa para ver solo los reportes de un estado concreto
(por ejemplo, solo los "Pendiente"), y así concentrarse en los puntos que todavía no se han
atendido.

**Why this priority**: Mejora la utilidad del mapa cuando hay muchos reportes, pero la feature
sigue entregando valor sin el filtro (US1 ya muestra todos con color por estado).

**Independent Test**: Con reportes en al menos dos estados distintos, abrir el filtro del mapa,
elegir un estado y verificar que solo quedan visibles los marcadores/grupos de ese estado; volver
a "Todos" y verificar que reaparecen los demás.

**Acceptance Scenarios**:

1. **Given** el usuario está en el mapa, **When** abre el control de filtro desde el icono de la
   barra superior, **Then** puede elegir entre "Todos" (opción por defecto), "Pendiente", "En
   proceso" y "Solucionado", una sola a la vez.
2. **Given** el usuario elige un estado distinto de "Todos", **When** se aplica el filtro,
   **Then** el mapa muestra únicamente los marcadores y grupos de reportes en ese estado, y el
   encuadre puede reajustarse a los marcadores visibles.
3. **Given** el filtro elegido no tiene ningún reporte, **When** se aplica, **Then** el mapa sigue
   visible y se indica que no hay reportes en ese estado.
4. **Given** el usuario cambió el filtro del mapa, **When** vuelve a la lista "Mis reportes",
   **Then** el filtro de esa lista no cambió (los dos filtros son independientes).
5. **Given** el usuario aplicó un filtro y abrió el detalle de un reporte, **When** regresa al
   mapa, **Then** el filtro que había elegido sigue aplicado.

---

### Edge Cases

- **Reporte sin coordenadas válidas**: no se dibuja como marcador y no impide mostrar el resto; si
  ningún reporte del dispositivo tiene coordenadas, la pantalla se comporta como el estado vacío.
- **Un solo reporte mapeable**: el encuadre lo centra con un nivel de zoom legible, sin aplicar un
  acercamiento máximo.
- **Todos los reportes en (casi) la misma ubicación**: se agrupan en un único grupo con el conteo
  correcto; el usuario puede acercar el zoom para separarlos.
- **Filtro que deja cero marcadores**: se mantiene el mapa visible con un aviso de "sin reportes en
  este estado", sin tratarlo como error.
- **Fallo al cargar el mapa base (sin conexión o proveedor caído)**: los mosaicos pueden no
  aparecer, pero los marcadores, el filtro y la navegación siguen operativos; la atribución del
  proveedor se mantiene visible.
- **Fallo al cargar los reportes**: se muestra un mensaje de error con opción de reintentar,
  consistente con "Mis Reportes".
- **Actualización en vivo mientras hay una tarjeta abierta**: si cambia el estado del reporte cuya
  tarjeta está visible, la tarjeta y el marcador reflejan el nuevo estado.
- **Regreso desde el detalle**: al volver al tab "Mapa", el filtro seleccionado se conserva; el
  mapa puede re-encuadrar a los marcadores visibles.
- **Permisos de ubicación**: la feature no usa la ubicación del dispositivo, por lo que no solicita
  ningún permiso nuevo ni muestra un marcador de "estás aquí".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El tab "Mapa" MUST mostrar un mapa interactivo (desplazable y con zoom) de Ibagué,
  reemplazando el placeholder "Próximamente" actual.
- **FR-002**: El mapa MUST mostrar únicamente los reportes enviados desde el propio dispositivo,
  identificados por el mismo identificador anónimo de dispositivo que usa "Mis Reportes"; NO MUST
  mostrar reportes de otros dispositivos.
- **FR-003**: Cada reporte con coordenadas válidas MUST representarse como un marcador ubicado en
  esas coordenadas.
- **FR-004**: Un reporte sin coordenadas válidas MUST NOT mostrarse como marcador y MUST NOT
  impedir que se muestren los demás reportes.
- **FR-005**: El color del marcador MUST indicar el estado del reporte, con un color distinto y
  consistente por estado: Pendiente = rojo, En proceso = naranja, Solucionado = verde.
- **FR-006**: Los marcadores MUST usar formas o iconos genéricos de la plataforma; la feature MUST
  NOT depender de imágenes o iconos de marca propios.
- **FR-007**: La pantalla MUST mostrar una leyenda visible que asocie cada color con su estado.
- **FR-008**: Al abrir la pantalla con uno o más reportes mapeables, el mapa MUST ajustar
  automáticamente su centro y zoom (encuadre) para que todos los marcadores visibles queden dentro
  de la vista.
- **FR-009**: Cuando solo hay un marcador visible, el encuadre MUST centrarlo con un nivel de zoom
  legible, no con un acercamiento máximo.
- **FR-010**: Cuando varios marcadores están suficientemente próximos para el nivel de zoom actual,
  MUST agruparse en un único marcador de grupo que muestre el número de reportes que contiene.
- **FR-011**: Acercar el zoom o seleccionar un marcador de grupo MUST separar o expandir los
  marcadores agrupados.
- **FR-012**: La pantalla MUST ofrecer un control de filtro por estado accesible desde un icono en
  la barra superior.
- **FR-013**: El filtro MUST permitir un único valor a la vez, entre: "Todos" (por defecto),
  "Pendiente", "En proceso", "Solucionado".
- **FR-014**: Al aplicar un filtro distinto de "Todos", el mapa MUST mostrar solo los marcadores y
  grupos de reportes en ese estado.
- **FR-015**: El estado del filtro del mapa MUST ser independiente del filtro de la lista "Mis
  Reportes"; cambiar uno MUST NOT afectar al otro.
- **FR-016**: Al cambiar el filtro, el encuadre MAY reajustarse a los marcadores visibles
  resultantes.
- **FR-017**: Tocar un marcador individual MUST mostrar sobre el mapa una tarjeta resumen del
  reporte con: miniatura de la foto, número de reporte, estado, tipo de residuo, dirección y
  fecha/hora de envío.
- **FR-018**: MUST haber como máximo una tarjeta resumen visible a la vez.
- **FR-019**: La tarjeta resumen MUST poder cerrarse tocando fuera de ella o mediante un control de
  cierre.
- **FR-020**: Tocar la tarjeta resumen MUST abrir la pantalla "Detalle del reporte" (la misma de
  "Mis Reportes") para ese reporte. Como esa pantalla vive anidada bajo la rama **Inicio** (no hay
  un tab "Mis reportes"), abrirla desde el mapa activa la rama Inicio.
- **FR-021**: Los marcadores MUST reflejar en tiempo real los cambios en los reportes del
  dispositivo: un reporte nuevo aparece como marcador y un cambio de estado actualiza el color del
  marcador sin que el usuario recargue.
- **FR-022**: Mientras se cargan los reportes por primera vez, la pantalla MUST mostrar un
  indicador de carga.
- **FR-023**: Si el dispositivo no tiene reportes mapeables, la pantalla MUST mostrar el mapa
  centrado en Ibagué con un mensaje encima indicando que aún no se han enviado reportes,
  consistente en tono con el estado vacío de "Mis Reportes".
- **FR-024**: Si el filtro activo deja cero marcadores, la pantalla MUST indicar que no hay
  reportes en ese estado, manteniendo el mapa visible y sin tratarlo como error.
- **FR-025**: Si la carga de los reportes falla, la pantalla MUST mostrar un mensaje de error con
  una opción para reintentar, consistente con "Mis Reportes".
- **FR-026**: El mapa base MUST mostrar la atribución requerida por su proveedor de datos
  cartográficos.
- **FR-027**: La feature MUST NOT solicitar permisos de ubicación del dispositivo ni mostrar la
  posición actual del usuario.
- **FR-028**: Al regresar desde "Detalle del reporte" al tab "Mapa", el filtro previamente
  seleccionado en el mapa MUST conservarse.

### Key Entities *(include if feature involves data)*

- **Reporte**: entidad ya existente (feature "Crear Reporte" / "Mis Reportes"). Para el mapa son
  relevantes: sus coordenadas (posición del marcador), su estado —Pendiente / En proceso /
  Solucionado— (color del marcador), y los campos que se muestran en la tarjeta resumen (foto,
  número de reporte, tipo de residuo, dirección, fecha/hora de envío). El identificador del
  dispositivo de origen se usa para filtrar los reportes propios.
- **Identificador anónimo de dispositivo**: valor local ya existente que asocia los reportes a este
  dispositivo. Es la misma llave de filtrado que usa "Mis Reportes"; no se crea uno nuevo.
- **Marcador de mapa**: representación visual de un reporte en una posición geográfica, con color
  según el estado del reporte.
- **Grupo de marcadores**: agregación visual de marcadores próximos entre sí, con un conteo de
  cuántos reportes contiene.
- **Filtro de estado del mapa**: selección única (Todos / Pendiente / En proceso / Solucionado) que
  determina qué marcadores se muestran; su valor es propio de esta pantalla.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un usuario con reportes enviados abre el tab "Mapa" y ve todos sus reportes mapeables
  como marcadores sin realizar ninguna acción adicional (el encuadre es automático).
- **SC-002**: En el 100% de los marcadores visibles, el usuario puede identificar el estado del
  reporte solo por el color del marcador y la leyenda, sin abrir ningún reporte.
- **SC-003**: Desde el mapa, el usuario llega al detalle de un reporte concreto en no más de 2
  toques (marcador → tarjeta → detalle).
- **SC-004**: Tras abrir el tab "Mapa" en condiciones normales de red, la pantalla muestra su
  estado inicial (marcadores o estado vacío) en menos de 3 segundos.
- **SC-005**: Al filtrar por un estado, se muestran exclusivamente reportes de ese estado (cero
  falsos positivos) y la suma de marcadores individuales y reportes contenidos en grupos coincide
  con el número de reportes del dispositivo en ese estado.
- **SC-006**: Un cambio de estado de un reporte se refleja en el color de su marcador, con el mapa
  abierto, en menos de 5 segundos y sin que el usuario recargue.
- **SC-007**: Cuando dos o más reportes quedan a una distancia en pantalla que haría ilegibles sus
  marcadores, se muestran como un único grupo con el conteo correcto (cero marcadores superpuestos
  ilegibles).
- **SC-008**: Un usuario sin reportes ve el mapa de Ibagué con un mensaje claro, sin marcadores y
  sin ningún error.

## Out of Scope

- Reportes de otros usuarios o un mapa público de toda la ciudad.
- Crear un reporte desde el mapa (por ejemplo, mantener pulsado para soltar un pin): pertenece a la
  feature "Crear Reporte".
- Indicaciones, rutas o navegación asistida hacia la ubicación de un reporte.
- Mapa de calor o de densidad de reportes.
- Almacenamiento en caché de los mosaicos del mapa para uso sin conexión.
- Mostrar la ubicación actual del usuario ("estás aquí") o solicitar permisos de ubicación.
- Cualquier mecanismo para cambiar el estado de un reporte: sigue siendo de solo lectura, igual que
  en "Mis Reportes".

## Assumptions

- Todos los reportes creados por la feature "Crear Reporte" incluyen coordenadas (captura
  automática o ajuste manual), por lo que en la práctica todos los reportes del dispositivo son
  mapeables; el manejo de reportes sin coordenadas es una salvaguarda defensiva.
- Se reutilizan el mismo origen de datos en tiempo real y el mismo identificador anónimo de
  dispositivo de la feature "Mis Reportes" (003); no se crean colecciones, campos ni identificadores
  nuevos.
- La pantalla "Detalle del reporte" de la feature 003 se reutiliza tal cual como destino de
  navegación y no se modifica en esta feature.
- El centro por defecto del mapa ("Ibagué") se define con un punto o área fija de la ciudad; no se
  calcula dinámicamente.
- La feature necesita un proveedor de mapa base y una capacidad de agrupación de marcadores.
  Incorporar esa librería es un cambio de dependencia que requiere una enmienda a la constitución
  del proyecto antes de la fase de planificación/implementación.
- El mapa base se sirve por red; sin conexión los mosaicos pueden no cargar, pero la lista de
  marcadores y la navegación siguen funcionando. La caché offline de mosaicos está fuera de alcance.
- El rendimiento se dimensiona para el volumen esperado de reportes por dispositivo (decenas, no
  miles).
- Los colores rojo / naranja / verde siguen el mock (`docs/mocks/6 mapa reporte.jpg`); los tonos
  exactos se alinean con el tema visual de la app durante la implementación.
- La navegación al detalle desde el mapa activa la rama **Inicio** y abre `/mis-reportes/:reportId`
  (ruta anidada bajo Inicio desde la feature 001; no existe un tab "Mis reportes"). Comportamiento
  aceptado explícitamente, en lugar de abrir el detalle dentro del tab "Mapa".
