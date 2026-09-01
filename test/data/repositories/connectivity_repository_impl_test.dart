import 'package:flutter_test/flutter_test.dart';
import 'package:limpiapp/data/repositories/connectivity_repository_impl.dart';
import 'package:limpiapp/data/services/connectivity_service.dart';
import 'package:limpiapp/domain/models/connectivity_status.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  test('watch() reemite el statusStream del Service tal cual', () async {
    final service = _MockConnectivityService();
    when(() => service.statusStream).thenAnswer(
      (_) => Stream.fromIterable([
        ConnectivityStatus.online,
        ConnectivityStatus.offline,
        ConnectivityStatus.online,
      ]),
    );

    final repo = ConnectivityRepositoryImpl(service);

    expect(await repo.watch().toList(), [
      ConnectivityStatus.online,
      ConnectivityStatus.offline,
      ConnectivityStatus.online,
    ]);
  });
}
