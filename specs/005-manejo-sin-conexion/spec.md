# Feature Specification: Manejo de estado sin conexión

**Feature Branch**: `005-manejo-sin-conexion`

**Created**: 2026-09-01

**Status**: Draft

**Input**: User description: "Manejo de estado sin conexión — Hoy, sin internet, la app no da feedback claro: en \"Mis reportes\" y \"Mapa de reportes\" la carga se queda en un indicador de progreso indefinidamente (bug #3); en \"Crear reporte\" el envío se cuelga sin avisar. Esta feature define un comportamiento consistente y predecible cuando no hay conexión, reutilizando la UI de error/reintento existente. Aviso global de sin conexión (franja visible en cualquier pantalla, desaparece solo al reconectar, no bloquea). Lectura: si no cargan los datos en un tiempo razonable → estado de error con \"Reintentar\" manual; con conexión estable una pausa larga sin cambios no debe provocar error espurio. Envío atómico: se completa (número + Confirmación) o falla sin guardar nada; informar explícitamente que no se envió; no dejar el formulario bloqueado \"enviando…\"; conservar los datos capturados; reintento manual; sin número ni Confirmación si no se completó. Consistencia de mensaje/tono/reintento entre las 3 pantallas y el aviso global; distinguir \"sin conexión\" de otros errores del servidor cuando se pueda. Fuera de alcance: bandeja de salida / envío diferido automático, limpiar el blob huérfano de foto, caché de mosaicos del mapa, reintento automático al reconectar, modo offline de solo lectura de primera clase. Referencias: bug #3; afecta features 002, 003 y 004 (ya en main)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Saber de inmediato que estoy sin conexión (Priority: P1)

Mientras el dispositivo no tiene conexión a internet, el ciudadano ve un aviso global y persistente
en cualquier pantalla de la app que le indica que está sin conexión. Cuando la conexión vuelve, el
aviso desaparece solo. Así el usuario entiende por qué algo no carga o no se envía, en vez de
quedarse esperando sin explicación.

**Why this priority**: Es la base de toda la feature — sin una señal clara de "no hay internet", el
resto de mensajes de error quedan sueltos y el usuario no sabe si el problema es la app o su
conexión. Es lo que se puede entregar y demostrar primero, y da valor por sí solo.

**Independent Test**: Poner el dispositivo en modo avión y navegar por las pantallas de la app;
verificar que aparece un aviso global de "sin conexión" en todas, que no bloquea la navegación, y
que al salir de modo avión el aviso desaparece sin tocar nada.

**Acceptance Scenarios**:

1. **Given** el dispositivo sin conexión, **When** el usuario abre o navega a cualquier pantalla,
   **Then** ve un aviso global visible que indica que está sin conexión.
2. **Given** el aviso global de "sin conexión" visible, **When** el dispositivo recupera la
   conexión, **Then** el aviso desaparece automáticamente, sin acción del usuario.
2b. **Given** el dispositivo conectado a una WiFi que no tiene internet real, **When** varias
   operaciones seguidas de la app fallan por no poder establecer conexión, **Then** aparece el
   aviso global de "sin conexión" (aunque el dispositivo reporte que tiene red).
3. **Given** el aviso global visible, **When** el usuario intenta desplazarse o tocar controles de
   la pantalla, **Then** la app responde con normalidad (el aviso es informativo, no bloquea).
4. **Given** la conexión fluctúa por un instante muy breve, **When** vuelve enseguida, **Then** el
   aviso no aparece y desaparece de forma abrupta o repetida (se estabiliza antes de mostrarse u
   ocultarse).

---

### User Story 2 - Las pantallas de lectura no se quedan cargando para siempre (Priority: P2)

En "Mis reportes" y "Mapa de reportes", si los datos no se pueden obtener por falta de conexión, en
poco tiempo el usuario ve un estado de error claro con un botón "Reintentar", en vez de un
indicador de progreso infinito. Cuando recupera la conexión y toca "Reintentar", los reportes
cargan.

**Why this priority**: Resuelve el bug #3 (spinner colgado). Depende del aviso global (US1) para
que el mensaje de error tenga contexto, pero entrega valor concreto: elimina una pantalla que
parece rota.

**Independent Test**: Con el dispositivo en modo avión y sin datos cargados previamente, abrir "Mis
reportes" y luego "Mapa de reportes"; verificar que en pocos segundos aparece el estado de error
con "Reintentar" (no el spinner); salir de modo avión, tocar "Reintentar" y verificar que cargan.

**Acceptance Scenarios**:

1. **Given** el dispositivo sin conexión y sin datos cargados antes, **When** el usuario abre "Mis
   reportes" o "Mapa de reportes", **Then** en un tiempo acotado la pantalla deja de mostrar el
   indicador de progreso y muestra un estado de error con "Reintentar".
2. **Given** ese estado de error por falta de conexión, **When** el usuario restablece la conexión
   y toca "Reintentar", **Then** la pantalla carga los reportes y sale del estado de error.
3. **Given** el usuario sigue sin conexión, **When** toca "Reintentar", **Then** vuelve a ver el
   estado de error (no un spinner indefinido).
4. **Given** una pantalla de lectura con conexión estable que ya cargó sus reportes, **When** pasan
   varios minutos sin que cambien los datos, **Then** la pantalla NO cae en estado de error.
5. **Given** una pantalla de lectura mostrando reportes ya cargados, **When** se pierde la
   conexión, **Then** los reportes visibles permanecen en pantalla y aparece el aviso global; la
   pantalla no se reemplaza por el estado de error mientras haya datos mostrados.
6. **Given** ese estado de error de lectura, **When** la conexión se restablece pero el usuario no
   toca "Reintentar", **Then** el estado de error permanece (el aviso global sí desaparece solo; el
   reintento de la carga es manual).

---

### User Story 3 - El envío falla claro y sin perder lo que capturé (Priority: P3)

Al enviar un reporte sin conexión —o si la conexión se corta durante el envío— la app le dice al
usuario explícitamente que el reporte NO se envió y que no se guardó nada. El formulario no queda
atascado en "enviando…". Todo lo que el usuario ya cargó (foto, tipo de residuo, descripción,
ubicación) sigue ahí para reintentar. Cuando vuelve la conexión, reintenta y el envío se completa
normalmente.

**Why this priority**: Es el caso de mayor frustración potencial (el usuario ya hizo el esfuerzo de
capturar el reporte), pero es el más acotado en comportamiento porque el envío es atómico: o se
completa o no pasó nada.

**Independent Test**: Con el dispositivo en modo avión, completar el formulario de "Crear reporte" y
tocar "Enviar"; verificar que en pocos segundos aparece un mensaje explícito de que no se envió y no
se guardó nada, que el formulario no queda bloqueado, y que los datos siguen; salir de modo avión,
reintentar y verificar que el envío se completa con número y pantalla de Confirmación; verificar en
"Mis reportes" y en el "Mapa" que no quedó ningún reporte del intento fallido.

**Acceptance Scenarios**:

1. **Given** el dispositivo sin conexión y el formulario de "Crear reporte" completo, **When** el
   usuario toca "Enviar", **Then** en un tiempo acotado ve un mensaje explícito de que el reporte no
   se envió y no se guardó nada, y el formulario deja de estar en estado "enviando…".
2. **Given** un envío fallido por falta de conexión, **When** el usuario mira el formulario,
   **Then** la foto, el tipo de residuo, la descripción y la ubicación que había cargado siguen
   presentes.
3. **Given** un envío fallido, **When** el usuario restablece la conexión y toca "Enviar" de nuevo,
   **Then** el envío se completa: se asigna un número de reporte y se muestra la pantalla de
   Confirmación.
4. **Given** un envío que no se completó contra el backend, **When** el usuario revisa "Mis
   reportes" y el "Mapa de reportes", **Then** no aparece ningún reporte ni número correspondiente a
   ese intento.
5. **Given** el envío en curso, **When** la conexión se pierde a mitad del proceso, **Then** el
   resultado para el usuario es el mismo que si no hubiera tenido conexión desde el principio
   (mensaje de fallo, nada guardado, datos conservados).

---

### Edge Cases

- **Primera apertura de la app sin conexión y sin datos cacheados**: las pantallas de lectura van
  al estado de error con "Reintentar", nunca a un indicador de progreso indefinido.
- **Backend que responde con error o lentitud** (hay red, el servidor contesta pero falla o
  demora): se trata como un error genérico de servidor con "Reintentar" y su propio mensaje; NO
  dispara el aviso global ni el mensaje de falta de internet.
- **Backend inalcanzable con red presente** (WiFi sin internet real / portal cautivo): los intentos
  de conexión fallan por timeout; tras varios fallos consecutivos el aviso global SÍ aparece
  (FR-005 b), y los mensajes de error de lectura/envío pasan a los específicos de "sin conexión".
- **Conexión intermitente** (entra y sale rápido): el aviso global no debe parpadear; aparece y
  desaparece con un pequeño retardo de estabilización.
- **Pérdida de conexión en la pantalla de Confirmación** (envío ya exitoso): no afecta al reporte
  ya guardado; aparece el aviso global y la pantalla sigue funcionando.
- **Envío en que la foto ya se subió pero la operación atómica falla**: para el usuario, el envío
  falló y no se guardó nada; la limpieza del archivo de foto que pudo quedar huérfano en el
  almacenamiento es una limitación conocida y queda fuera de alcance.
- **"Reintentar" repetido sin conexión**: cada intento vuelve al mismo estado de error, sin colgar
  la pantalla.

## Requirements *(mandatory)*

### Functional Requirements

#### Aviso global de sin conexión

- **FR-001**: Mientras el dispositivo no tenga conexión a una red, la app MUST mostrar un aviso
  global persistente y visible en cualquier pantalla, indicando el estado sin conexión.
- **FR-002**: El aviso global MUST ocultarse automáticamente, sin acción del usuario, cuando la
  conexión se restablece.
- **FR-003**: El aviso global MUST ser informativo y MUST NOT bloquear la navegación, el
  desplazamiento ni ninguna acción de la app.
- **FR-004**: El aviso global MUST NOT aparecer ni desaparecer ante fluctuaciones de conectividad
  muy breves; MUST estabilizarse durante un intervalo corto antes de mostrarse u ocultarse.
- **FR-005**: El aviso global MUST mostrarse cuando se cumpla **cualquiera** de estas condiciones:
  (a) el dispositivo no tiene ninguna red disponible (WiFi/datos inactivos o fuera de cobertura), o
  (b) el dispositivo tiene red pero **varias operaciones consecutivas contra el backend fallan por
  no poder establecer conexión** (timeout de conexión / host inalcanzable) — este segundo caso
  cubre estar en una WiFi sin internet real o con portal cautivo, sin requerir un sondeo dedicado.
- **FR-005a**: El aviso global MUST ocultarse cuando (a) vuelve a haber una red disponible **y**
  (b) la siguiente operación contra el backend se completa con éxito, o cuando la detección de red
  del dispositivo vuelve a indicar conexión y no hay fallos de conexión recientes. Un fallo del
  backend que **sí responde** (respuesta de error del servidor, lentitud) NO cuenta como "no poder
  establecer conexión" y por tanto no mantiene ni dispara el aviso.

#### Lectura de datos ("Mis reportes", "Mapa de reportes")

- **FR-006**: Si una pantalla de lectura no obtiene sus datos dentro de un tiempo acotado por falta
  de conexión, MUST dejar de mostrar el indicador de progreso y mostrar un estado de error con un
  control de "Reintentar".
- **FR-007**: El estado de error de lectura MUST distinguir el caso "sin conexión" de otros errores
  del servidor, con un mensaje específico para la falta de internet cuando se pueda determinar.
- **FR-008**: "Reintentar" en una pantalla de lectura MUST volver a intentar la carga; con conexión
  disponible, MUST cargar los datos y salir del estado de error.
- **FR-009**: El reintento de la carga es MANUAL: el estado de error de lectura MUST permanecer
  hasta que el usuario toque "Reintentar", aunque la conexión se haya restablecido.
- **FR-010**: Con conexión estable, una pantalla de lectura que ya realizó su carga inicial MUST
  NOT caer en estado de error por una pausa prolongada sin cambios en los datos (el límite de
  tiempo aplica solo hasta la primera carga).
- **FR-011**: Si una pantalla de lectura ya muestra datos y luego se pierde la conexión, los datos
  visibles MUST permanecer en pantalla; la app MUST NOT reemplazar la pantalla por el estado de
  error mientras haya datos mostrados (el aviso global sí aparece).

#### Envío de un reporte ("Crear reporte")

- **FR-012**: El envío de un reporte MUST ser atómico frente al usuario: termina en éxito completo
  (número asignado + pantalla de Confirmación) o en error visible sin nada guardado; MUST NOT haber
  un estado intermedio observable.
- **FR-013**: Si no hay conexión al iniciar el envío, o si se pierde durante el envío, la app MUST
  informar de forma explícita que el reporte NO se envió y que no se guardó nada.
- **FR-014**: Todo intento de envío MUST terminar (éxito o error visible) dentro de un tiempo
  acotado; el usuario MUST NOT quedar con el formulario en estado "enviando…" de forma indefinida.
- **FR-015**: Tras un envío fallido, los datos ya capturados (foto, tipo de residuo, descripción,
  ubicación) MUST conservarse para reintentar sin volver a capturarlos.
- **FR-016**: El usuario MUST poder reintentar el envío manualmente; con conexión disponible, un
  reintento exitoso MUST completar el flujo normal (número + Confirmación).
- **FR-017**: Si el envío no se completó contra el backend, MUST NOT asignarse un número de reporte
  ni mostrarse la pantalla de Confirmación.
- **FR-018**: El mensaje de error de envío por falta de conexión MUST ser específico de ese caso
  (distinto del error genérico de servidor) cuando se pueda determinar.

#### Consistencia

- **FR-019**: El mensaje de "sin conexión", el tono y el mecanismo de "Reintentar" MUST ser
  coherentes entre "Mis reportes", "Mapa de reportes", "Crear reporte" y el aviso global.

### Key Entities *(include if feature involves data)*

- **Estado de conectividad**: señal observable por la app de si hay o no conexión utilizable.
  Alimenta el aviso global (FR-001/FR-002) y el mensaje específico de "sin internet" en los estados
  de error (FR-007/FR-018). No es un dato que se persista.
- **Borrador de reporte** (ya existente): el conjunto de datos que el usuario capturó en "Crear
  reporte" (foto, tipo de residuo, descripción, ubicación). Debe sobrevivir a un envío fallido
  (FR-015).
- **Reporte / Número de reporte** (ya existentes): solo se crean cuando el envío se completa contra
  el backend (FR-012/FR-017).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Con el dispositivo en modo avión y sin datos cargados previamente, abrir "Mis
  reportes" o "Mapa de reportes" muestra un estado de error con "Reintentar" en ≤ 10 segundos, y
  nunca un indicador de progreso indefinido.
- **SC-002**: Con el dispositivo en modo avión, en cualquier pantalla, el aviso global de "sin
  conexión" es visible en ≤ 3 segundos.
- **SC-003**: Al restablecer la conexión, el aviso global desaparece solo en ≤ 5 segundos, sin
  acción del usuario.
- **SC-004**: Con el dispositivo en modo avión, tocar "Enviar" en "Crear reporte" produce un
  mensaje de error explícito ("no se envió, no se guardó nada") en ≤ 10 segundos, y el formulario
  nunca queda bloqueado en "enviando…" de forma indefinida.
- **SC-005**: Tras un envío fallido por falta de conexión, el 100% de los datos del formulario
  (foto, tipo, descripción, ubicación) siguen presentes al reintentar.
- **SC-006**: Tras un envío fallido, no existe ningún reporte ni número asignado para ese intento
  (verificable: no aparece en "Mis reportes" ni en el "Mapa de reportes").
- **SC-007**: Con conexión estable y sin cambios de datos durante 5 minutos, ninguna pantalla de
  lectura cae en estado de error de forma espuria.
- **SC-008**: Los textos de "sin conexión" y el control "Reintentar" son idénticos o claramente
  equivalentes en "Mis reportes", "Mapa de reportes", "Crear reporte" y el aviso global
  (verificable por inspección).

## Out of Scope

- Bandeja de salida persistente / envío diferido que reenvíe automáticamente los reportes
  pendientes cuando vuelva la conexión.
- Reintento automático (sin acción del usuario) en cualquiera de las 3 pantallas.
- Modo offline de solo lectura con datos cacheados como experiencia de primera clase.
- Caché de mosaicos del mapa para uso sin conexión.
- Limpiar el archivo de foto que puede quedar huérfano en el almacenamiento cuando el envío falla
  tras subir la foto (limitación best-effort ya aceptada en la feature 002).
- Indicadores por-elemento de "pendiente de sincronizar" en la lista o el mapa.

## Assumptions

- Las pantallas "Mis reportes" (003) y "Mapa de reportes" (004) ya tienen una UI de estado de error
  con "Reintentar"; esta feature la hace dispararse en el caso sin conexión y le añade el mensaje
  específico, sin rediseñarla.
- El bug #3 (spinner colgado en lectura sin conexión) puede corregirse antes, como una corrección
  puntual en una rama aparte, y esta feature entonces se limita a verificar ese comportamiento y a
  cubrir el resto (aviso global, envío, consistencia). El alcance de la spec no cambia según cómo
  se entregue.
- "Sin conexión" se determina de forma híbrida (FR-005): ausencia de red del dispositivo, o
  varios fallos consecutivos de establecer conexión con el backend. Un backend que responde pero
  con error/lentitud NO es "sin conexión": es un error genérico de servidor con "Reintentar".
- El envío de un reporte usa una operación atómica contra el backend que no se completa
  parcialmente ni queda encolada de forma transparente; por eso "sin conexión desde el inicio" y
  "conexión perdida a mitad" producen el mismo resultado observable (nada guardado). A confirmar en
  `/speckit-plan`.
- Los valores concretos de "tiempo acotado" (lectura y envío) y del "intervalo de estabilización"
  del aviso se fijan en `/speckit-plan` (sugerencia de partida: ~8–10 s para lectura y envío,
  ~1–2 s de estabilización del aviso).
- Detectar el estado de red del dispositivo puede requerir una dependencia nueva fuera del stack
  aprobado; si es así, se tramita como enmienda a la constitución antes de `/speckit-plan` o
  `/speckit-implement`.
