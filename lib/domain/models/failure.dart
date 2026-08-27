/// Jerarquía sellada de fallos de negocio, compartida por todo el proyecto
/// (Principio V de la constitución). Ninguna excepción cruda de un SDK
/// externo (Firebase, `image_picker`, `geolocator`, etc.) debe cruzar más
/// allá de la capa Data: siempre se mapea a uno de estos subtipos.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// Error del backend (Firestore/Storage) al crear el documento o subir la
/// foto.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Ocurrió un error en el servidor.']);
}

/// Sin conexión a internet durante el envío (FR-017, SC-004).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Se perdió la conexión a internet.']);
}

/// El usuario negó un permiso requerido (cámara, galería o ubicación).
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permiso denegado.']);
}

/// El permiso de ubicación fue concedido pero no se pudo obtener la
/// posición (GPS apagado, timeout, servicio deshabilitado).
class LocationFailure extends Failure {
  const LocationFailure([super.message = 'No se pudo obtener la ubicación.']);
}

/// Falla al leer o escribir en el almacenamiento local del dispositivo
/// (`shared_preferences`) — ej. el identificador anónimo de dispositivo no
/// se pudo generar/persistir (caso raro: almacenamiento local no
/// disponible).
class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'No se pudo acceder al almacenamiento local.',
  ]);
}
