# Changelog

Todas las versiones de "Ibagué Limpia" distribuidas a testers vía Firebase App Distribution se
documentan aquí. El formato de versión es `X.Y.Z+B` (`pubspec.yaml`): `X.Y.Z` es la versión
visible para el usuario, `B` es el número de build — se sube en cada build nuevo distribuido a
testers, aunque `X.Y.Z` no cambie.

## 1.0.0+5 — Prueba del pipeline de distribución (reintento iOS #2)

Mismo build, se repite el número otra vez: en la 1.0.0+4 forzar `CODE_SIGN_IDENTITY=Apple
Distribution` sin también fijar `DEVELOPMENT_TEAM` como override de línea de comandos dejó
sin equipo asignado a los targets generados por Swift Package Manager (gRPC, Firebase, etc.),
que fallaron con "requires a development team".

## 1.0.0+4 — Prueba del pipeline de distribución (reintento iOS)

Mismo build que la 1.0.0+3, solo se repite el número para reintentar la distribución a
TestFlight — la 1.0.0+3 llegó bien a Firebase App Distribution (Android) pero el job de iOS
falló por firma (perfil de aprovisionamiento de desarrollo en vez de distribución).

### Notas para testers

- Sin cambios visibles respecto a la 1.0.0+2 (mismo alcance funcional).

## 1.0.0+3 — Prueba del pipeline de distribución

Build sin cambios funcionales — sirve para probar el nuevo pipeline de CI que distribuye
automáticamente a testers al pushear un tag. Primer intento de llegar a TestFlight además de
Firebase App Distribution (Android sí llegó; iOS falló por firma, ver 1.0.0+4).

### Notas para testers

- Sin cambios visibles respecto a la 1.0.0+2 (mismo alcance funcional).

## 1.0.0+2 — Manejo de estado sin conexión

### Cambios

- **Aviso global de sin conexión**: una franja visible en cualquier pantalla mientras el
  dispositivo no tiene internet, que desaparece sola al reconectar (no bloquea la app).
- **Lectura ("Mis reportes"/"Mapa")**: si los datos no cargan en un tiempo razonable, se muestra
  un estado de error con botón "Reintentar" manual, en vez de quedarse cargando indefinidamente
  (corrige el bug #3 reportado en la versión anterior).
- **Envío de reportes**: ahora es atómico frente a fallas de red — se completa por completo
  (con número y pantalla de Confirmación) o falla explícitamente sin dejar el formulario
  "enviando…" ni datos a medio guardar; el usuario conserva lo que ya había escrito y puede
  reintentar manualmente.
- Mensaje y tono de "sin conexión" consistentes entre el aviso global y las 3 pantallas
  afectadas (Crear reporte, Mis reportes, Mapa de reportes).

### Fuera de alcance de esta versión

Bandeja de salida / envío diferido automático, reintento automático al reconectar (sigue siendo
manual), modo offline de solo lectura, caché de mosaicos del mapa.

## 1.0.0+1 — Primera versión de pruebas

Primer build enviado a testers vía Firebase App Distribution.

### Funcionalidad incluida

- **Navegación principal**: pantalla de inicio + barra de navegación inferior (Inicio/Reportar/Mapa).
- **Crear reporte**: foto (cámara o galería, comprimida automáticamente a ≤2 MB), tipo de residuo,
  descripción opcional, ubicación automática o manual, envío a Firebase, confirmación con número
  de reporte único.
- **Mis reportes**: lista de reportes enviados desde este dispositivo (en tiempo real, filtrable
  por estado: Pendiente/En proceso/Solucionado) y detalle de cada uno con línea de tiempo de
  seguimiento (de solo lectura — el cambio de estado se hace fuera de la app).
- **Mapa de reportes**: reportes ubicados en un mapa (OpenStreetMap).
- **Manejo de conexión intermitente**: timeout en operaciones de red para evitar que la app se
  quede "cargando" indefinidamente sin conexión.

### Notas para testers

- No requiere ninguna cuenta ni inicio de sesión.
- "Mis reportes" solo muestra los reportes enviados desde el mismo dispositivo/instalación.
