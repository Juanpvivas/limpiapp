import 'package:geolocator/geolocator.dart';

/// Wrapper delgado sobre `geolocator` (research.md §8). Se invoca
/// únicamente después de confirmar el permiso concedido vía
/// `permission_handler` (research.md §5).
class GeolocationService {
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
}
