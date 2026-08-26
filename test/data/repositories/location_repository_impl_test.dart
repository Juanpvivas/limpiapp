import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:limpiapp/data/repositories/location_repository_impl.dart';
import 'package:limpiapp/data/services/location/geocoding_service.dart';
import 'package:limpiapp/data/services/location/geolocation_service.dart';
import 'package:limpiapp/data/services/permission_service.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:mocktail/mocktail.dart';

class _MockPermissionService extends Mock implements PermissionService {}

class _MockGeolocationService extends Mock implements GeolocationService {}

class _MockGeocodingService extends Mock implements GeocodingService {}

Position _fakePosition({double lat = 4.44, double lng = -75.23}) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late _MockPermissionService permissionService;
  late _MockGeolocationService geolocationService;
  late _MockGeocodingService geocodingService;
  late LocationRepositoryImpl repository;

  setUp(() {
    permissionService = _MockPermissionService();
    geolocationService = _MockGeolocationService();
    geocodingService = _MockGeocodingService();
    repository = LocationRepositoryImpl(
      permissionService: permissionService,
      geolocationService: geolocationService,
      geocodingService: geocodingService,
    );
  });

  group('getCurrentLocation', () {
    test('caso feliz: permiso concedido + coordenadas + reverse geocoding '
        'exitoso', () async {
      when(() => permissionService.requestLocation())
          .thenAnswer((_) async => true);
      when(() => geolocationService.getCurrentPosition())
          .thenAnswer((_) async => _fakePosition());
      when(
        () => geocodingService.addressFromCoordinates(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => 'Calle 5 # 10-20');

      final result = await repository.getCurrentLocation();

      expect(result.isRight(), isTrue);
      result.match((_) => fail('esperaba Right'), (location) {
        expect(location.hasAutomaticLocation, isTrue);
        expect(location.automaticAddress, 'Calle 5 # 10-20');
      });
    });

    test('si el reverse geocoding falla, usa coordenadas crudas como respaldo '
        '(sigue siendo ubicación automática válida)', () async {
      when(() => permissionService.requestLocation())
          .thenAnswer((_) async => true);
      when(() => geolocationService.getCurrentPosition())
          .thenAnswer((_) async => _fakePosition(lat: 4.44, lng: -75.23));
      when(
        () => geocodingService.addressFromCoordinates(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenThrow(Exception('sin señal'));

      final result = await repository.getCurrentLocation();

      expect(result.isRight(), isTrue);
      result.match((_) => fail('esperaba Right'), (location) {
        expect(location.hasAutomaticLocation, isTrue);
        expect(location.automaticAddress, '4.44, -75.23');
      });
    });

    test('permiso denegado retorna Left(PermissionFailure)', () async {
      when(() => permissionService.requestLocation())
          .thenAnswer((_) async => false);

      final result = await repository.getCurrentLocation();

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<PermissionFailure>()),
        (_) => fail('esperaba Left'),
      );
      verifyNever(() => geolocationService.getCurrentPosition());
    });

    test(
      'GPS deshabilitado/error de geolocator retorna Left(LocationFailure)',
      () async {
        when(() => permissionService.requestLocation())
            .thenAnswer((_) async => true);
        when(() => geolocationService.getCurrentPosition())
            .thenThrow(Exception('GPS deshabilitado'));

        final result = await repository.getCurrentLocation();

        expect(result.isLeft(), isTrue);
        result.match(
          (failure) => expect(failure, isA<LocationFailure>()),
          (_) => fail('esperaba Left'),
        );
      },
    );
  });
}
