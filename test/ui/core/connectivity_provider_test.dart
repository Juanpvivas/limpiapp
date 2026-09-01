import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiapp/config/service_locator.dart';
import 'package:limpiapp/domain/models/connectivity_status.dart';
import 'package:limpiapp/domain/repositories/connectivity_repository.dart';
import 'package:limpiapp/ui/core/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

void main() {
  test('parte en AsyncLoading y luego refleja los valores del stream del '
      'Repository', () async {
    final repo = _MockConnectivityRepository();
    final controller = StreamController<ConnectivityStatus>.broadcast();
    when(() => repo.watch()).thenAnswer((_) => controller.stream);

    await getIt.reset();
    getIt.registerLazySingleton<ConnectivityRepository>(() => repo);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(controller.close);

    final sub = container.listen(
      connectivityStatusProvider,
      (_, _) {},
      onError: (_, _) {},
    );

    expect(sub.read().isLoading, isTrue);

    controller.add(ConnectivityStatus.online);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().value, ConnectivityStatus.online);

    controller.add(ConnectivityStatus.offline);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().value, ConnectivityStatus.offline);
  });
}
