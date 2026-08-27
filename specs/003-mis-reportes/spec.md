# Feature Specification: Mis Reportes

**Feature Branch**: `003-mis-reportes`

**Created**: 2026-08-27

**Status**: Draft

**Input**: User description: "Quiero la feature "Mis Reportes" de la app "Ibagué Limpia": la lista de reportes ya
enviados desde este dispositivo y el detalle de cada uno.

Pantalla "Mis reportes" (se llega aquí desde "Mis reportes" en la pantalla de inicio, o desde el
botón "Ver mis reportes" de la pantalla de Confirmación, ya implementados):
1. Pestañas de filtro: "Todos" (seleccionada por defecto), "Pendientes", "En proceso",
   "Solucionados" — filtran la lista según el estado del reporte.
2. Lista de reportes ordenada por fecha de envío (más reciente primero). Cada elemento muestra:
   miniatura de la foto, una etiqueta de color con el estado ("Pendiente", "En proceso" o
   "Solucionado"), el número de reporte, la dirección, y la fecha/hora de envío.
3. Solo se muestran los reportes enviados desde este mismo dispositivo. Como la app no tiene
   login, esto se logra con un identificador anónimo generado y guardado localmente la primera vez
   que se abre la app (no es una cuenta de usuario ni requiere ningún dato personal).
4. Si no hay ningún reporte (o ninguno en la pestaña filtrada), se muestra un estado vacío con un
   mensaje apropiado, sin lista.
5. Tocar un reporte de la lista navega a "Detalle del reporte".

Pantalla "Detalle del reporte":
1. Muestra la foto completa, el número de reporte, una etiqueta con el estado actual, el tipo de
   residuo, la ubicación, la fecha/hora de envío, y la descripción (si el usuario la escribió al
   crearlo).
2. Debajo, una sección "Estado del reporte" con una línea de tiempo de 3 pasos: "Reporte recibido"
   (siempre cumplido, con la fecha/hora del envío), "En proceso" y "Solucionado" — cada paso
   muestra su fecha/hora si ya se alcanzó, o "Pendiente" si todavía no.
3. Esta pantalla es de solo lectura: no existe ninguna forma de cambiar el estado desde aquí. El
   mecanismo real para que el estado avance (ej. un panel administrativo) es una feature futura,
   fuera de alcance — aquí el estado y sus fechas simplemente se leen de Firestore tal como estén.

Cambios necesarios sobre el backend de Firestore ya existente (colección `reports` de la feature
"Crear Reporte"):
- Agregar un campo de estado al documento, con valor inicial "pendiente" al crear el reporte (esto
  requiere un ajuste menor a la feature "Crear Reporte" ya implementada, para que el envío inicial
  escriba ese valor por defecto).
- Agregar un campo con el identificador anónimo del dispositivo que envió el reporte, para poder
  filtrar "Mis reportes" por él.
- Agregar campos de fecha/hora para cuándo el reporte pasó a "en proceso" y a "solucionado" (nulos
  hasta que ese estado se alcance) — necesarios para la línea de tiempo del detalle.

Fuera de alcance de esta spec: cualquier mecanismo para cambiar el estado de un reporte (panel
administrativo, fuera de alcance), el mapa de reportes, notificaciones push reales, y compartir o
exportar un reporte individual.

No requiere inicio de sesión, igual que el resto de la app."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver la lista de mis reportes enviados (Priority: P1)

Un usuario que ya ha reportado uno o más puntos sucios abre "Mis reportes" (desde la pantalla de
inicio o desde el botón "Ver mis reportes" al final de un envío) y ve la lista de todos los
reportes que él mismo ha enviado desde su dispositivo, cada uno con su foto, número, dirección,
fecha y estado actual, ordenados del más reciente al más antiguo.

**Why this priority**: Es el valor central de la feature: permitir que el ciudadano vea qué ha
reportado y en qué va. Sin esta lista, la feature no existe.

**Independent Test**: Con al menos un reporte ya enviado desde el dispositivo, abrir "Mis
reportes" y verificar que aparece en la lista con su foto, número, dirección, fecha y estado;
verificar que el más reciente aparece primero si hay más de uno.

**Acceptance Scenarios**:

1. **Given** el dispositivo ha enviado 2 o más reportes, **When** el usuario abre "Mis reportes",
   **Then** los ve listados con el más reciente primero, cada uno mostrando miniatura, estado,
   número, dirección y fecha/hora de envío.
2. **Given** el dispositivo no ha enviado ningún reporte, **When** el usuario abre "Mis reportes",
   **Then** ve un estado vacío con un mensaje apropiado, sin ninguna lista.
3. **Given** el usuario está viendo la lista, **When** toca un reporte, **Then** navega a "Detalle
   del reporte" de ese reporte específico.

---

### User Story 2 - Filtrar mis reportes por estado (Priority: P2)

Un usuario con varios reportes en distintos estados quiere ver solo los que están "Pendientes",
"En proceso" o "Solucionados", usando las pestañas de filtro sobre la lista.

**Why this priority**: Mejora la utilidad de la lista a medida que crece, pero la Historia 1 ya es
funcional y útil sin filtros (mostrando "Todos" por defecto).

**Independent Test**: Con reportes en al menos dos estados distintos, tocar cada pestaña de filtro
y confirmar que la lista solo muestra los reportes de ese estado; tocar "Todos" y confirmar que
vuelven a verse todos.

**Acceptance Scenarios**:

1. **Given** el usuario abre "Mis reportes", **When** la pantalla carga, **Then** la pestaña
   "Todos" está seleccionada por defecto y se ven todos los reportes.
2. **Given** hay reportes en distintos estados, **When** el usuario toca "Pendientes" (o "En
   proceso", o "Solucionados"), **Then** la lista se filtra para mostrar solo los reportes en ese
   estado.
3. **Given** una pestaña de filtro no tiene ningún reporte, **When** el usuario la toca, **Then**
   ve un estado vacío específico para esa pestaña, sin mezclar reportes de otros estados.

---

### User Story 3 - Ver el detalle y seguimiento de un reporte (Priority: P3)

Un usuario toca uno de sus reportes en la lista y ve toda la información que registró al crearlo
(foto, tipo de residuo, ubicación, fecha, descripción), junto con una línea de tiempo que muestra
en qué punto va su seguimiento: recibido, en proceso, y solucionado.

**Why this priority**: Da contexto y confianza de seguimiento, pero depende de que la lista
(Historia 1) ya funcione — es un complemento, no el flujo central.

**Independent Test**: Tocar un reporte desde la lista y verificar que el detalle muestra toda la
información original más la línea de tiempo de estado con las fechas correctas (o "Pendiente" en
los pasos aún no alcanzados).

**Acceptance Scenarios**:

1. **Given** un reporte con estado "Pendiente", **When** el usuario abre su detalle, **Then** ve
   la foto, número, tipo de residuo, ubicación, fecha/hora de envío y descripción (si existe), y en
   la línea de tiempo solo "Reporte recibido" tiene fecha — "En proceso" y "Solucionado" muestran
   "Pendiente".
2. **Given** un reporte con estado "En proceso", **When** el usuario abre su detalle, **Then** la
   línea de tiempo muestra fecha en "Reporte recibido" y "En proceso", y "Pendiente" en
   "Solucionado".
3. **Given** un reporte con estado "Solucionado", **When** el usuario abre su detalle, **Then** la
   línea de tiempo muestra fecha en los 3 pasos.
4. **Given** el usuario está en el detalle de un reporte, **When** revisa la pantalla completa,
   **Then** no encuentra ningún botón o control para cambiar el estado del reporte.

---

### Edge Cases

- ¿Qué pasa si el dispositivo nunca ha enviado un reporte? "Mis reportes" muestra el estado vacío
  general (no una de las pestañas de filtro) al abrir por primera vez.
- ¿Qué pasa si una pestaña de filtro no tiene reportes pero otras sí? Se muestra un estado vacío
  específico de esa pestaña; el usuario puede volver a "Todos" o probar otra pestaña.
- ¿Qué pasa si el usuario reinstala la app o borra los datos de la aplicación? Al no existir cuenta
  ni login, el identificador anónimo del dispositivo se genera de nuevo y los reportes enviados
  antes de ese punto dejan de aparecer en "Mis reportes" de ese dispositivo (ver Assumptions).
- ¿Qué pasa si un reporte no tiene descripción? El detalle omite esa sección o la muestra vacía,
  sin generar error.
- ¿Qué pasa si la miniatura o la foto completa de un reporte no cargan (ej. sin conexión)? Se
  muestra un estado de carga o un ícono de reemplazo en vez de fallar toda la pantalla.
- ¿Qué pasa si llegan nuevos reportes o cambios de estado mientras el usuario tiene la lista o el
  detalle abiertos? Se reflejan automáticamente sin que el usuario tenga que salir y volver a
  entrar (ver Assumptions).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mostrar la pantalla "Mis reportes" al llegar desde "Mis reportes"
  (pantalla de inicio) o desde "Ver mis reportes" (pantalla de Confirmación), ambas ya
  implementadas.
- **FR-002**: El sistema DEBE generar un identificador anónimo de dispositivo la primera vez que
  se abre la app, y conservarlo localmente entre sesiones, sin pedir ningún dato personal ni
  requerir inicio de sesión.
- **FR-003**: Al enviar un reporte exitosamente (feature "Crear Reporte"), el sistema DEBE
  etiquetar ese reporte con el identificador anónimo del dispositivo que lo envió.
- **FR-004**: El sistema DEBE mostrar en "Mis reportes" únicamente los reportes etiquetados con el
  identificador anónimo de este dispositivo.
- **FR-005**: El sistema DEBE ofrecer 4 pestañas de filtro sobre la lista: "Todos", "Pendientes",
  "En proceso", "Solucionados".
- **FR-006**: La pestaña "Todos" DEBE estar seleccionada por defecto al abrir la pantalla.
- **FR-007**: El sistema DEBE ordenar la lista de reportes por fecha de envío, del más reciente al
  más antiguo.
- **FR-008**: Cada elemento de la lista DEBE mostrar: una miniatura de la foto, una etiqueta visual
  del estado ("Pendiente", "En proceso" o "Solucionado"), el número de reporte, la dirección, y la
  fecha/hora de envío.
- **FR-009**: Si no hay ningún reporte que mostrar (en general, o en la pestaña de filtro
  seleccionada), el sistema DEBE mostrar un estado vacío con un mensaje apropiado en vez de una
  lista vacía sin explicación.
- **FR-010**: Tocar un reporte de la lista DEBE navegar a la pantalla "Detalle del reporte" de ese
  reporte.
- **FR-011**: La pantalla "Detalle del reporte" DEBE mostrar la foto completa, el número de
  reporte, una etiqueta con el estado actual, el tipo de residuo, la ubicación, la fecha/hora de
  envío, y la descripción si el usuario la escribió al crear el reporte.
- **FR-012**: La pantalla "Detalle del reporte" DEBE mostrar una sección "Estado del reporte" con
  una línea de tiempo de 3 pasos: "Reporte recibido", "En proceso", "Solucionado".
- **FR-013**: El paso "Reporte recibido" DEBE mostrarse siempre cumplido, con la fecha/hora de
  envío del reporte.
- **FR-014**: Los pasos "En proceso" y "Solucionado" DEBEN mostrar su fecha/hora si ese estado ya
  se alcanzó, o el texto "Pendiente" si todavía no.
- **FR-015**: La pantalla "Detalle del reporte" DEBE ser de solo lectura: el sistema NO DEBE
  ofrecer ningún control para cambiar el estado de un reporte desde esta feature.
- **FR-016**: El sistema NO DEBE requerir inicio de sesión ni registro para ver "Mis reportes" ni
  el detalle de un reporte.

### Key Entities *(include if feature involves data)*

- **Reporte (extendido)**: la misma entidad de la feature "Crear Reporte", con 3 atributos nuevos
  necesarios para esta feature: estado actual ("pendiente", "en proceso" o "solucionado"),
  identificador anónimo del dispositivo que lo envió, y las fechas/hora en que pasó a "en proceso"
  y a "solucionado" (ausentes mientras no se alcance ese estado).
- **Identificador de dispositivo**: valor anónimo generado y guardado localmente en el
  dispositivo la primera vez que se usa la app; no identifica a una persona, solo permite
  distinguir "mis reportes" de los de otros dispositivos.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un usuario con reportes ya enviados puede ver su lista completa en "Mis reportes" en
  menos de 3 segundos tras abrir la pantalla.
- **SC-002**: El 100% de los reportes mostrados en "Mis reportes" pertenecen al mismo dispositivo
  que los envió — ningún reporte de otro dispositivo aparece en la lista.
- **SC-003**: El 100% de las veces que el usuario toca una pestaña de filtro, la lista mostrada
  contiene únicamente reportes en ese estado (o el estado vacío correspondiente si no hay
  ninguno).
- **SC-004**: El 100% de los reportes muestran en su detalle una línea de tiempo consistente con
  su estado actual (ej. un reporte "Solucionado" siempre muestra fecha en los 3 pasos).
- **SC-005**: El 100% de los intentos de encontrar un control para cambiar el estado desde el
  detalle no encuentran ninguno — la pantalla es verificablemente de solo lectura.

## Assumptions

- El identificador anónimo de dispositivo se genera y guarda con el mecanismo de persistencia
  local ya aprobado en el proyecto (no una cuenta de usuario); si el usuario reinstala la app o
  borra los datos de la aplicación, se genera un identificador nuevo y los reportes enviados con
  el identificador anterior dejan de asociarse a "Mis reportes" en ese dispositivo — esto es
  aceptable dado que la app no tiene login ni recuperación de cuenta.
- El campo de estado de un reporte se inicializa en "pendiente" en el momento del envío exitoso
  (ajuste menor a la feature "Crear Reporte" ya implementada); ningún flujo de esta spec permite
  cambiarlo — el mecanismo para que avance a "en proceso" o "solucionado" es una feature futura
  (ej. un panel administrativo) fuera de alcance aquí.
- La lista y el detalle reflejan el estado de los reportes en tiempo real (o casi): si el estado de
  un reporte cambia mientras el usuario tiene la pantalla abierta, se refleja sin que tenga que
  salir y volver a entrar.
- Los reportes enviados por la feature "Crear Reporte" antes de este cambio (sin identificador de
  dispositivo ni estado inicial) no aparecerán en "Mis reportes" de ningún dispositivo; no se
  define aquí una migración de datos retroactiva para ellos.
- No se define un límite máximo de reportes a mostrar en la lista más allá de un comportamiento de
  scroll estándar.
- Esta spec cubre únicamente "Mis reportes" y "Detalle del reporte" en modo lectura. El mecanismo
  para cambiar el estado de un reporte (panel administrativo), el mapa de reportes, notificaciones
  push reales, y compartir o exportar un reporte individual están fuera de alcance y se definen en
  features separadas.
