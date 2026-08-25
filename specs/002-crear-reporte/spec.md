# Feature Specification: Crear Reporte

**Feature Branch**: `002-crear-reporte`

**Created**: 2026-08-25

**Status**: Draft

**Input**: User description: "Quiero la feature "Crear Reporte" de la app "Ibagué Limpia": el formulario para reportar un punto sucio y la confirmación de envío.

Pantalla "Nuevo reporte" (se llega aquí desde el botón "Hacer un reporte" de la pantalla de inicio o desde "Reportar" en la barra inferior, ya implementados):
1. "Toma una foto" — el usuario captura o selecciona una foto del punto sucio. Es obligatoria: no se puede enviar el reporte sin foto. El sistema intenta comprimir/redimensionar automáticamente la foto a un máximo de 2 MB antes de enviarla, sin que el usuario tenga que hacer nada para lograrlo.
   - Si el usuario niega el permiso de cámara o de galería, se muestra una alerta simple indicando que agregar una foto es obligatoria, y no se puede continuar ni crear el reporte sin ella.
   - Si, después de comprimirla, la foto sigue pesando más de 2 MB, se muestra un texto en rojo en la parte inferior del recuadro de la foto indicando que la imagen es muy grande, y no se permite enviar el reporte mientras esa foto siga así (el usuario debe tomar/elegir otra).
2. "¿Qué tipo de residuo es?" — el usuario elige una categoría de una lista predefinida (ej. "Basura acumulada", "Escombros", "Muebles/enseres", "Residuos verdes", "Otros").
3. "Descripción" — texto libre, opcional, para dar contexto adicional (ej. "Basura acumulada desde hace varios días, genera malos olores y atrae animales").
4. "Ubicación" — el sistema intenta capturar automáticamente la ubicación del usuario y mostrar la dirección aproximada resultante. Además hay un campo de "Dirección manual" donde el usuario puede escribir o complementar la dirección:
   - Si la ubicación automática SÍ se obtiene: el campo de dirección manual es opcional.
   - Si la ubicación automática NO se puede obtener (permiso denegado, sin GPS, error, etc.): el campo de dirección manual pasa a ser obligatorio.
   - En cualquier caso, debe existir al menos una de las dos (automática o manual) para poder enviar el reporte; si no hay ninguna, no se puede enviar.
Botón "Enviar reporte" al final, habilitado solo cuando: hay foto (ya comprimida a 2 MB o menos), hay tipo de residuo, y hay al menos una ubicación (automática o manual). La descripción sigue siendo opcional.

Envío del reporte:
- Al tocar "Enviar reporte", se muestra un indicador de progreso (loading) mientras se procesa el envío. Mientras el progreso está visible, el usuario NO puede salir de la pantalla ni tocar ninguna otra parte de la pantalla — el loading bloquea toda interacción hasta que el envío termine (con éxito o con error).
- Si el envío falla (ej. se pierde la conexión a internet), se oculta el progreso, se muestra un mensaje indicando que el envío falló, y el usuario se queda en la pantalla "Nuevo reporte" con los datos que ya había ingresado — no avanza a la confirmación y puede intentar enviar de nuevo.
- Si el envío es exitoso, se navega a la pantalla "Confirmación".

Pantalla "Confirmación" (solo se alcanza tras un envío exitoso):
- Ícono de éxito y mensaje "¡Reporte enviado con éxito! Tu reporte ha sido registrado correctamente."
- Un número de reporte único generado por el sistema, mostrado al usuario (formato tipo "#IL-2026-000125").
- Mensaje indicando que se notificará al usuario cuando haya novedades sobre su reporte.
- Botón "Ver mis reportes" (navega a la feature "Mis Reportes", fuera de alcance aquí).
- Enlace "Volver al inicio" (navega a la pantalla de inicio ya implementada).

Fuera de alcance de esta spec: el contenido de "Mis Reportes", el detalle de un reporte, el mapa, el seguimiento/cambio de estado del reporte después de enviado, y cualquier panel administrativo. Tampoco se define aquí el mecanismo real de notificaciones — solo que el usuario ve el mensaje de que será notificado.

No requiere inicio de sesión, igual que el resto de la app."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enviar un reporte completo con éxito (Priority: P1)

Un usuario ve un punto sucio en la calle, abre "Nuevo reporte" desde la pantalla de inicio o desde
la barra inferior, toma una foto, elige un tipo de residuo, deja que el sistema capture su ubicación
automáticamente, y toca "Enviar reporte". El sistema procesa el envío y lo lleva a la pantalla de
"Confirmación" con un número de reporte único.

**Why this priority**: Es el flujo central de toda la feature y el que entrega el valor principal:
permitir que un ciudadano reporte un punto sucio. Sin este flujo funcionando de punta a punta, la
feature no existe.

**Independent Test**: Completar foto + tipo de residuo + ubicación automática disponible y enviar;
verificar que se llega a "Confirmación" con ícono de éxito, mensaje y número de reporte visibles.

**Acceptance Scenarios**:

1. **Given** el usuario está en "Nuevo reporte" sin ningún campo lleno, **When** agrega una foto,
   elige un tipo de residuo, y el sistema obtiene su ubicación automáticamente, **Then** el botón
   "Enviar reporte" se habilita.
2. **Given** el formulario está completo y válido, **When** el usuario toca "Enviar reporte",
   **Then** se muestra un indicador de progreso y el usuario no puede interactuar con ninguna otra
   parte de la pantalla mientras dura el envío.
3. **Given** el envío se procesó exitosamente, **When** el progreso termina, **Then** el sistema
   navega a la pantalla "Confirmación" mostrando el ícono de éxito, el mensaje "¡Reporte enviado con
   éxito! Tu reporte ha sido registrado correctamente.", un número de reporte único, el mensaje de
   que se notificará al usuario, el botón "Ver mis reportes" y el enlace "Volver al inicio".

---

### User Story 2 - Completar el reporte cuando la ubicación automática no está disponible (Priority: P2)

Un usuario abre "Nuevo reporte" pero su ubicación automática no se puede obtener (permiso denegado,
sin GPS, o error). El sistema le exige entonces escribir una dirección manual para poder continuar,
y una vez la escribe, puede enviar el reporte con normalidad.

**Why this priority**: Cubre una condición realista y frecuente (GPS no disponible o permiso
denegado) sin la cual una parte significativa de los reportes no podría enviarse nunca. Depende del
flujo base de la Historia 1, por eso es P2.

**Independent Test**: Simular que la ubicación automática falla, dejar el campo de dirección manual
vacío y confirmar que "Enviar reporte" permanece deshabilitado; luego escribir una dirección manual y
confirmar que se habilita y el envío se completa igual que en la Historia 1.

**Acceptance Scenarios**:

1. **Given** la ubicación automática no se pudo obtener, **When** el usuario revisa el formulario,
   **Then** el campo "Dirección manual" se indica como obligatorio.
2. **Given** la ubicación automática no se pudo obtener y el campo de dirección manual está vacío,
   **When** el usuario ya completó foto y tipo de residuo, **Then** el botón "Enviar reporte"
   permanece deshabilitado.
3. **Given** la ubicación automática no se pudo obtener, **When** el usuario escribe una dirección
   manual y ya tiene foto y tipo de residuo, **Then** el botón "Enviar reporte" se habilita.
4. **Given** la ubicación automática SÍ se obtuvo, **When** el usuario revisa el formulario, **Then**
   el campo "Dirección manual" se muestra como opcional y puede enviar el reporte sin llenarlo.

---

### User Story 3 - Manejar errores de foto y de envío sin perder los datos (Priority: P3)

Un usuario intenta agregar una foto pero niega el permiso de cámara/galería, o su foto sigue pesando
más de 2 MB después de comprimirse; en ambos casos el sistema le impide continuar hasta resolverlo.
Más adelante, si el envío del reporte falla por pérdida de conexión, el sistema se lo indica y lo deja
en la misma pantalla con todos los datos que ya había ingresado, para que pueda reintentar sin volver
a llenar el formulario.

**Why this priority**: Son condiciones de error que mejoran la robustez y la confianza del usuario en
la app, pero el flujo principal (Historias 1 y 2) ya es utilizable sin que estas condiciones estén
cubiertas explícitamente.

**Independent Test**: (a) Denegar el permiso de cámara/galería y confirmar que aparece la alerta y no
se puede continuar sin foto; (b) simular una foto que, tras comprimirse, sigue pesando más de 2 MB, y
confirmar el texto en rojo y que "Enviar reporte" no se habilita con esa foto; (c) simular una falla
de red durante el envío y confirmar que el usuario permanece en "Nuevo reporte" con sus datos intactos
y puede reintentar.

**Acceptance Scenarios**:

1. **Given** el usuario intenta agregar una foto, **When** niega el permiso de cámara o de galería,
   **Then** se muestra una alerta simple indicando que agregar una foto es obligatoria y no puede
   continuar ni crear el reporte sin ella.
2. **Given** el usuario agregó una foto, **When** el sistema la comprime automáticamente y el
   resultado sigue pesando más de 2 MB, **Then** se muestra un texto en rojo bajo el recuadro de la
   foto indicando que la imagen es muy grande, y "Enviar reporte" no se habilita mientras esa foto
   siga así.
3. **Given** el formulario está completo y válido, **When** el usuario toca "Enviar reporte" y el
   envío falla (por ejemplo, se pierde la conexión a internet), **Then** el indicador de progreso se
   oculta, se muestra un mensaje indicando que el envío falló, y el usuario permanece en "Nuevo
   reporte" con todos los datos que ya había ingresado (foto, tipo de residuo, descripción,
   ubicación).
4. **Given** un envío falló y el usuario sigue en "Nuevo reporte" con sus datos intactos, **When**
   toca "Enviar reporte" nuevamente, **Then** el sistema reintenta el envío con el mismo indicador de
   progreso bloqueante.

---

### Edge Cases

- ¿Qué pasa si ni la ubicación automática ni la dirección manual están disponibles? El botón "Enviar
  reporte" permanece deshabilitado; no se puede enviar el reporte sin al menos una de las dos.
- ¿Qué pasa si el usuario toca "Enviar reporte" mientras el indicador de progreso ya está visible de
  un intento anterior? El sistema lo ignora: no se pueden disparar envíos duplicados ni se puede
  interactuar con la pantalla mientras el progreso está visible.
- ¿Qué pasa si el usuario intenta salir de la pantalla (por ejemplo con el botón atrás) mientras el
  envío está en progreso? El sistema lo bloquea hasta que el envío termine, con éxito o con error.
- ¿Qué pasa si el usuario reemplaza una foto que estaba marcada como "muy grande" por una nueva? El
  sistema comprime la nueva foto y, si queda en 2 MB o menos, retira el texto de error y permite
  habilitar el envío (si el resto de los campos obligatorios también está completo).
- ¿Qué pasa si el usuario deja la descripción vacía? El reporte se puede enviar igual, ya que la
  descripción es opcional.
- ¿Qué pasa si el usuario no interactúa con el campo de dirección manual pero la ubicación automática
  sí se obtuvo? El envío procede usando solo la ubicación automática.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mostrar la pantalla "Nuevo reporte" al llegar desde "Hacer un reporte"
  (pantalla de inicio) o desde "Reportar" (barra de navegación inferior).
- **FR-002**: El sistema DEBE permitir al usuario capturar una foto con la cámara o seleccionar una
  foto existente de la galería para el reporte.
- **FR-003**: La foto DEBE ser obligatoria: el sistema NO DEBE permitir enviar el reporte sin una
  foto agregada.
- **FR-004**: El sistema DEBE comprimir/redimensionar automáticamente la foto agregada a un máximo de
  2 MB antes de enviarla, sin requerir ninguna acción adicional del usuario para lograrlo.
- **FR-005**: Si el usuario niega el permiso de cámara o de galería, el sistema DEBE mostrar una
  alerta simple indicando que agregar una foto es obligatoria, y NO DEBE permitir continuar ni crear
  el reporte sin ella.
- **FR-006**: Si, después de comprimirse, la foto sigue pesando más de 2 MB, el sistema DEBE mostrar
  un texto en rojo en la parte inferior del recuadro de la foto indicando que la imagen es muy
  grande, y NO DEBE permitir enviar el reporte mientras esa foto siga en ese estado.
- **FR-007**: El sistema DEBE permitir al usuario elegir un tipo de residuo de una lista predefinida
  de categorías: "Basura acumulada", "Escombros", "Muebles/enseres", "Residuos verdes" y "Otros".
- **FR-008**: El tipo de residuo DEBE ser obligatorio: el sistema NO DEBE permitir enviar el reporte
  sin una categoría seleccionada.
- **FR-009**: El sistema DEBE ofrecer un campo de descripción de texto libre, opcional, para que el
  usuario agregue contexto adicional sobre el punto sucio.
- **FR-010**: El sistema DEBE intentar capturar automáticamente la ubicación del usuario y mostrarle
  la dirección aproximada resultante.
- **FR-011**: El sistema DEBE ofrecer un campo de "Dirección manual" donde el usuario pueda escribir o
  complementar la dirección del punto sucio.
- **FR-012**: Si la ubicación automática se obtiene exitosamente, el campo "Dirección manual" DEBE
  ser opcional.
- **FR-013**: Si la ubicación automática no se puede obtener (permiso denegado, sin GPS, error u otra
  causa), el campo "Dirección manual" DEBE pasar a ser obligatorio.
- **FR-014**: El sistema DEBE exigir que exista al menos una ubicación (automática o manual) para
  poder enviar el reporte; si no hay ninguna, NO DEBE permitir el envío.
- **FR-015**: El botón "Enviar reporte" DEBE estar habilitado únicamente cuando existan, a la vez: una
  foto válida (comprimida a 2 MB o menos), un tipo de residuo seleccionado, y al menos una ubicación
  (automática o manual) disponible.
- **FR-016**: Al tocar "Enviar reporte", el sistema DEBE mostrar un indicador de progreso que bloquee
  toda interacción con la pantalla —incluyendo salir de ella— hasta que el envío termine, ya sea con
  éxito o con error.
- **FR-017**: Si el envío del reporte falla, el sistema DEBE ocultar el indicador de progreso, mostrar
  un mensaje indicando que el envío falló, y mantener al usuario en la pantalla "Nuevo reporte" con
  todos los datos que ya había ingresado, permitiéndole reintentar el envío.
- **FR-018**: Si el envío del reporte es exitoso, el sistema DEBE navegar a la pantalla
  "Confirmación".
- **FR-019**: La pantalla "Confirmación" DEBE mostrar un ícono de éxito y el mensaje "¡Reporte enviado
  con éxito! Tu reporte ha sido registrado correctamente."
- **FR-020**: La pantalla "Confirmación" DEBE mostrar un número de reporte único generado por el
  sistema, en un formato tipo "#IL-2026-000125".
- **FR-021**: La pantalla "Confirmación" DEBE mostrar un mensaje indicando que se notificará al
  usuario cuando haya novedades sobre su reporte.
- **FR-022**: La pantalla "Confirmación" DEBE mostrar un botón "Ver mis reportes" que navegue a la
  feature "Mis Reportes".
- **FR-023**: La pantalla "Confirmación" DEBE mostrar un enlace "Volver al inicio" que navegue a la
  pantalla de inicio.
- **FR-024**: El sistema NO DEBE requerir inicio de sesión ni registro para crear ni enviar un
  reporte.
- **FR-025**: La pantalla "Confirmación" solo DEBE ser alcanzable como resultado de un envío de
  reporte exitoso, nunca por navegación directa sin un envío previo.

### Key Entities *(include if feature involves data)*

- **Reporte**: Representa un punto sucio reportado por un usuario. Atributos: foto (obligatoria, ≤2
  MB), tipo de residuo (una de las categorías predefinidas), descripción (texto libre, opcional),
  ubicación automática (coordenadas y/o dirección aproximada, si se obtuvo), dirección manual (si el
  usuario la escribió), número de reporte único asignado al enviarse con éxito.
- **Tipo de residuo**: Categoría fija que clasifica el punto sucio. Valores: "Basura acumulada",
  "Escombros", "Muebles/enseres", "Residuos verdes", "Otros".

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un usuario con foto, tipo de residuo y ubicación disponibles puede completar y enviar un
  reporte en menos de 2 minutos.
- **SC-002**: El 100% de los intentos de envío sin foto válida, sin tipo de residuo, o sin ninguna
  ubicación (automática ni manual) son bloqueados por el sistema antes de iniciar el envío.
- **SC-003**: El 100% de los envíos exitosos muestran al usuario un número de reporte único, sin
  duplicados entre reportes distintos.
- **SC-004**: El 100% de los envíos fallidos (por ejemplo, por pérdida de conexión) dejan al usuario
  en la pantalla "Nuevo reporte" con los datos ya ingresados intactos, sin necesidad de volver a
  llenar el formulario para reintentar.
- **SC-005**: El 100% de las fotos agregadas que originalmente pesan más de 2 MB se comprimen
  automáticamente en el dispositivo sin ninguna acción manual del usuario.
- **SC-006**: Mientras el indicador de progreso de envío está visible, el 100% de los intentos de
  interactuar con otra parte de la pantalla o de salir de ella son bloqueados por el sistema.

## Assumptions

- El formato de número de reporte ("#IL-2026-000125") es ilustrativo: el requisito es que cada número
  sea único y visible para el usuario, no un algoritmo de generación específico.
- Existe un backend o servicio capaz de recibir el envío del reporte (foto, tipo, descripción,
  ubicación) y devolver un número de reporte único; el diseño de ese servicio está fuera de alcance de
  esta spec, que se enfoca en el comportamiento visible para el usuario.
- No se define un límite máximo de caracteres para la descripción más allá de los límites razonables
  de un campo de texto estándar.
- La lista de categorías de tipo de residuo ("Basura acumulada", "Escombros", "Muebles/enseres",
  "Residuos verdes", "Otros") es fija para esta feature; agregar, quitar o editar categorías no está
  contemplado aquí.
- Si el dispositivo no tiene cámara o no tiene fotos en la galería, se trata como parte del mismo
  flujo de "no se pudo obtener foto" cubierto por la alerta de permiso obligatorio.
- No se define guardado de borrador del reporte entre sesiones: si el usuario sale de la app antes de
  enviar (fuera del bloqueo durante el envío en progreso), los datos ingresados no necesariamente se
  conservan.
- El mecanismo real de notificaciones al usuario sobre novedades de su reporte no se define en esta
  spec, solo el mensaje que confirma que ocurrirá.
- Esta spec cubre únicamente el formulario "Nuevo reporte" y la pantalla "Confirmación". El contenido
  de "Mis Reportes", el detalle de un reporte, el mapa, el seguimiento o cambio de estado posterior al
  envío, y cualquier panel administrativo están fuera de alcance y se definen en features separadas.
