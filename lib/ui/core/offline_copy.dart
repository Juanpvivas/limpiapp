/// Fuente única de los textos de "sin conexión" y del control "Reintentar",
/// reutilizada por el aviso global, los estados de error de lectura y el
/// error de envío de "Crear reporte" (FR-019 / SC-008).
library;

/// Franja del aviso global (`OfflineBanner`).
const String kOfflineBannerText = 'Sin conexión a internet';

/// Estado de error de "Mis reportes" / "Mapa de reportes" cuando el fallo es
/// por falta de conexión.
const String kOfflineReadErrorText =
    'Sin conexión a internet.\nRevisa tu conexión e intenta de nuevo.';

/// `submitError` de "Crear reporte" cuando el envío falla por falta de
/// conexión.
const String kOfflineSubmitErrorText =
    'Sin conexión: el reporte no se envió y no se guardó nada.';

/// Estado de error de lectura / envío cuando el backend responde con un error
/// (no es falta de conexión).
const String kGenericServerErrorText =
    'No se pudieron cargar tus reportes.\nRevisa tu conexión e intenta de nuevo.';

/// Botón de reintento en `DataErrorState`.
const String kRetryLabel = 'Reintentar';
