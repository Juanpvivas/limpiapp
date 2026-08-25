# Feature Specification: Shell de Navegación Principal

**Feature Branch**: `001-navegacion-principal`

**Created**: 2026-08-24

**Status**: Draft

**Input**: User description: "Quiero el shell de navegación principal de la app "Ibagué Limpia".
Es la pantalla de inicio que ve el usuario al abrir la app. Muestra:
- El branding de la app (nombre "Ibagué Limpia" con ícono) y una imagen de fondo de la ciudad.
- Un mensaje corto: "Reporta, haz seguimiento y juntos mantengamos nuestra ciudad limpia."
- Tres botones de acción principal, en este orden:
  1. "Hacer un reporte" (botón primario, destacado) → lleva al flujo de crear un nuevo reporte.
  2. "Mis reportes" → lleva a la lista de reportes del usuario.
  3. "Mapa de reportes" → lleva al mapa con los reportes ubicados geográficamente.
- Una barra de navegación inferior fija, visible en toda la app, con 3 accesos: "Inicio" (esta pantalla), "Reportar" (acceso directo a crear reporte) y "Mapa" (acceso directo al mapa).
El usuario debe poder llegar a cualquiera de las tres features principales (crear reporte, ver mis reportes, ver mapa) tanto desde los botones grandes de la pantalla de inicio como desde la barra de navegación inferior, sin necesidad de iniciar sesión (la app no tiene login).
Esta spec cubre solo la navegación y el shell visual — no cubre la lógica interna de "crear reporte", "mis reportes" ni "mapa", que se especifican por separado."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Llegar a las funciones principales desde la pantalla de inicio (Priority: P1)

Al abrir la app por primera vez en una sesión, el usuario ve la pantalla de inicio con el branding
de "Ibagué Limpia", un mensaje de bienvenida y tres botones claros. Al tocar cualquiera de ellos,
llega directamente a la función correspondiente.

**Why this priority**: Es el punto de entrada de toda la aplicación. Sin esto, el usuario no tiene
forma de alcanzar ninguna otra funcionalidad de la app.

**Independent Test**: Abrir la app y verificar que cada uno de los tres botones de la pantalla de
inicio navega a la sección correspondiente (aunque esas pantallas de destino existan solo como
placeholders todavía).

**Acceptance Scenarios**:

1. **Given** la app recién abierta en la pantalla de inicio, **When** el usuario toca "Hacer un
   reporte", **Then** se navega al flujo de creación de reporte.
2. **Given** la app recién abierta en la pantalla de inicio, **When** el usuario toca "Mis
   reportes", **Then** se navega a la lista de reportes del usuario.
3. **Given** la app recién abierta en la pantalla de inicio, **When** el usuario toca "Mapa de
   reportes", **Then** se navega al mapa de reportes.

---

### User Story 2 - Moverse entre secciones desde cualquier pantalla vía barra inferior (Priority: P2)

Estando en cualquier pantalla principal de la app, el usuario puede usar la barra de navegación
inferior ("Inicio", "Reportar", "Mapa") para saltar directamente a cualquiera de las tres secciones
principales, sin tener que volver primero a la pantalla de inicio.

**Why this priority**: Mejora significativamente la usabilidad al evitar navegación redundante. La
app ya es utilizable con la Historia 1 sola, pero esto la hace fluida para uso repetido.

**Independent Test**: Desde la pantalla "Mis reportes", tocar "Mapa" en la barra inferior y
confirmar que se llega directo al mapa sin pasar por la pantalla de inicio.

**Acceptance Scenarios**:

1. **Given** el usuario está en cualquier pantalla principal, **When** toca "Inicio" en la barra
   inferior, **Then** vuelve a la pantalla de inicio.
2. **Given** el usuario está en cualquier pantalla principal, **When** toca "Reportar" en la barra
   inferior, **Then** navega directo al flujo de creación de reporte.
3. **Given** el usuario está en cualquier pantalla principal, **When** toca "Mapa" en la barra
   inferior, **Then** navega directo al mapa de reportes.

---

### User Story 3 - Identificar la sección activa (Priority: P3)

Mientras navega, el usuario puede ver cuál de los tres accesos de la barra inferior corresponde a la
sección en la que se encuentra actualmente, gracias a un indicador visual de selección.

**Why this priority**: Es un detalle de orientación/UX que ayuda a la claridad, pero no bloquea el
uso funcional de la navegación si no estuviera presente.

**Independent Test**: Navegar a "Mapa" y verificar visualmente que el ícono "Mapa" de la barra
inferior aparece resaltado como sección activa.

**Acceptance Scenarios**:

1. **Given** el usuario navega a una sección (vía barra inferior o botón de la pantalla de inicio),
   **When** la pantalla termina de cargar, **Then** el ícono correspondiente en la barra inferior se
   muestra en estado "activo/seleccionado".

---

### Edge Cases

- ¿Qué pasa si el usuario toca varios accesos de navegación casi al mismo tiempo (doble tap
  accidental)? El sistema debe procesar solo la navegación solicitada más reciente, sin apilar
  pantallas duplicadas.
- ¿Qué pasa si el dispositivo no tiene conexión a internet al abrir la app? La pantalla de inicio y
  la navegación entre secciones deben funcionar igual, ya que no dependen de datos remotos.
- ¿Qué pasa si el usuario ya está en la sección "Mapa" y vuelve a tocar el ícono "Mapa" de la barra
  inferior? El sistema no debe crear una nueva instancia de la pantalla ni duplicar la navegación.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mostrar una pantalla de inicio con el branding "Ibagué Limpia", una
  imagen de fondo representativa de la ciudad, y el mensaje "Reporta, haz seguimiento y juntos
  mantengamos nuestra ciudad limpia."
- **FR-002**: El sistema DEBE mostrar en la pantalla de inicio tres botones de acción, en este
  orden: "Hacer un reporte", "Mis reportes" y "Mapa de reportes", con "Hacer un reporte" destacado
  visualmente como acción primaria.
- **FR-003**: Al tocar "Hacer un reporte" (en la pantalla de inicio o en la barra inferior como
  "Reportar"), el sistema DEBE navegar al flujo de creación de reporte.
- **FR-004**: Al tocar "Mis reportes", el sistema DEBE navegar a la lista de reportes del usuario.
- **FR-005**: Al tocar "Mapa de reportes" (en la pantalla de inicio o en la barra inferior como
  "Mapa"), el sistema DEBE navegar al mapa de reportes.
- **FR-006**: El sistema DEBE mostrar una barra de navegación inferior fija, visible en todas las
  pantallas principales de la app, con tres accesos: "Inicio", "Reportar" y "Mapa".
- **FR-007**: Al tocar cualquier acceso de la barra de navegación inferior, el sistema DEBE navegar
  directamente a la sección correspondiente, sin exigir pasar antes por la pantalla de inicio.
- **FR-008**: El sistema DEBE indicar visualmente cuál sección de la barra de navegación inferior
  corresponde a la pantalla actualmente visible.
- **FR-009**: El sistema NO DEBE requerir inicio de sesión ni registro para acceder a la pantalla de
  inicio ni para navegar entre secciones.
- **FR-010**: El sistema DEBE permitir alcanzar cualquiera de las tres funciones principales (crear
  reporte, mis reportes, mapa) tanto desde los botones de la pantalla de inicio como desde la barra
  de navegación inferior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un usuario nuevo puede identificar y alcanzar cualquiera de las tres funciones
  principales de la app en menos de 5 segundos desde que la abre, sin instrucciones adicionales.
- **SC-002**: El 100% de los accesos de navegación (3 botones de inicio + 3 accesos de la barra
  inferior) llevan a la sección correcta en cada intento.
- **SC-003**: El usuario puede moverse entre cualquiera de las tres secciones principales usando la
  barra inferior sin necesidad de regresar antes a la pantalla de inicio, en el 100% de los casos.
- **SC-004**: El indicador de selección en la barra inferior distingue visualmente la sección
  activa de las otras dos (color, ícono relleno/contorno, o equivalente) en cualquier estado de la
  app, sin necesidad de instrucciones adicionales para interpretarlo. No se mide con una prueba de
  usabilidad formal para esta feature.

## Assumptions

- La imagen de fondo y el ícono de marca de la pantalla de inicio son recursos estáticos incluidos
  en la app (no se descargan de internet), por lo que la pantalla de inicio se muestra completa
  incluso sin conexión.
- El botón "atrás" nativo de Android, estando en la pantalla de inicio (raíz de la navegación),
  sigue el comportamiento estándar de la plataforma; esta spec no define un comportamiento
  personalizado para él.
- El acceso "Reportar" de la barra de navegación inferior es equivalente al botón "Hacer un
  reporte" de la pantalla de inicio: misma acción, dos puntos de entrada distintos.
- Esta spec cubre únicamente el shell de navegación y la pantalla de inicio. La lógica interna,
  contenido y datos de "Crear Reporte", "Mis Reportes" y "Mapa de Reportes" se definen en features
  separadas y están fuera de alcance aquí.
