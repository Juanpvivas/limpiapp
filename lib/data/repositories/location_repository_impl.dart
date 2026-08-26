import 'package:fpdart/fpdart.dart';

import '../../domain/models/failure.dart';
import '../../domain/models/report_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../services/location/geocoding_service.dart';
import '../services/location/geolocation_service.dart';
import '../services/permission_service.dart';

/// `permission_handler` → `geolocator` → `geocoding`, con respaldo de
/// coordenadas crudas si falla el reverse geocoding (research.md §5, §6).
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl({
    required this.permissionService,
    required this.geolocationService,
    required this.geocodingService,
  });

  final PermissionService permissionService;
  final GeolocationService geolocationService;
  final GeocodingService geocodingService;

  @override
  Future<Either<Failure, ReportLocation>> getCurrentLocation() async {
    final granted = await permissionService.requestLocation();
    if (!granted) {
      return const Left(PermissionFailure());
    }

    try {
      final position = await geolocationService.getCurrentPosition();

      String? address;
      try {
        address = await geocodingService.addressFromCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (_) {
        address = null;
      }
      // research.md §6: las coordenadas ya son una ubicación automática
      // válida aunque falle el reverse geocoding — se usa un respaldo
      // legible con las coordenadas crudas en vez de tratarlo como fallo.
      address ??= '${position.latitude}, ${position.longitude}';

      return Right(
        ReportLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          automaticAddress: address,
        ),
      );
    } catch (_) {
      // GPS deshabilitado, timeout, u otro error de `geolocator`.
      return const Left(LocationFailure());
    }
  }
}
