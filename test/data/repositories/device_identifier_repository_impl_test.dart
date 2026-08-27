import 'package:flutter_test/flutter_test.dart';
import 'package:limpiapp/data/repositories/device_identifier_repository_impl.dart';
import 'package:limpiapp/data/services/device_identifier_service.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeviceIdentifierService extends Mock
    implements DeviceIdentifierService {}

void main() {
  late _MockDeviceIdentifierService service;
  late DeviceIdentifierRepositoryImpl repository;

  setUp(() {
    service = _MockDeviceIdentifierService();
    repository = DeviceIdentifierRepositoryImpl(service);
  });

  test(
    'retorna el identificador que provee el Service, envuelto en Right',
    () async {
      when(() => service.getOrCreateDeviceId())
          .thenAnswer((_) async => '123-abc');

      final result = await repository.getDeviceId();

      result.match(
        (_) => fail('esperaba Right'),
        (id) => expect(id, '123-abc'),
      );
    },
  );

  test(
    'llamadas sucesivas reutilizan el mismo identificador persistido',
    () async {
      when(() => service.getOrCreateDeviceId())
          .thenAnswer((_) async => 'persisted-id');

      final first = await repository.getDeviceId();
      final second = await repository.getDeviceId();

      expect(first.getOrElse((_) => 'x'), second.getOrElse((_) => 'y'));
      expect(first.getOrElse((_) => 'x'), 'persisted-id');
    },
  );

  test(
    'si el almacenamiento local falla, retorna Left(CacheFailure)',
    () async {
      when(() => service.getOrCreateDeviceId())
          .thenThrow(Exception('no storage'));

      final result = await repository.getDeviceId();

      result.match(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('esperaba Left'),
      );
    },
  );
}
