# Changelog

Todas las versiones de "Ibagué Limpia" distribuidas a testers vía Firebase App Distribution se
documentan aquí. El formato de versión es `X.Y.Z+B` (`pubspec.yaml`): `X.Y.Z` es la versión
visible para el usuario, `B` es el número de build — se sube en cada build nuevo distribuido a
testers, aunque `X.Y.Z` no cambie.

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
