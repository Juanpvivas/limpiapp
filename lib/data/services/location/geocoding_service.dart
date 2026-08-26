import 'package:geocoding/geocoding.dart';

/// Wrapper delgado sobre `geocoding` (research.md §8): convierte
/// coordenadas en una dirección legible (reverse geocoding).
class GeocodingService {
  final Geocoding _geocoding = Geocoding();

  /// `null` si no se encuentra ningún resultado — research.md §6 indica que
  /// esto no invalida la ubicación automática: el repositorio usa las
  /// coordenadas crudas como respaldo en ese caso.
  Future<String?> addressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final placemarks = await _geocoding.placemarkFromCoordinates(
      latitude,
      longitude,
    );
    if (placemarks.isEmpty) return null;

    final placemark = placemarks.first;
    final parts = [
      placemark.street,
      placemark.subLocality,
      placemark.locality,
    ].where((part) => part != null && part.trim().isNotEmpty);

    return parts.isEmpty ? null : parts.join(', ');
  }
}
