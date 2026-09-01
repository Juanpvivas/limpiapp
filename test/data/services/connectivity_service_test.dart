import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiapp/data/services/connectivity_service.dart';
import 'package:limpiapp/domain/models/connectivity_status.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  late _MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> changes;

  setUp(() {
    connectivity = _MockConnectivity();
    changes = StreamController<List<ConnectivityResult>>.broadcast();
    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  ConnectivityService build({
    List<ConnectivityResult> initial = const [ConnectivityResult.wifi],
  }) {
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => initial);
    final service = ConnectivityService(
      connectivity,
      onlineDebounce: const Duration(milliseconds: 20),
      offlineDebounce: const Duration(milliseconds: 20),
      failureThreshold: 2,
    );
    addTearDown(service.dispose);
    return service;
  }

  Future<ConnectivityStatus> latest(ConnectivityService s) async {
    ConnectivityStatus? last;
    final sub = s.statusStream.listen((v) => last = v);
    addTearDown(sub.cancel);
    for (var i = 0; i < 10 && last == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return last!;
  }

  test('sin interfaz de red → offline', () async {
    final s = build(initial: const [ConnectivityResult.none]);
    expect(await latest(s), ConnectivityStatus.offline);
  });

  test('con interfaz → online', () async {
    final s = build(initial: const [ConnectivityResult.mobile]);
    expect(await latest(s), ConnectivityStatus.online);
  });

  test(
    '2 fallos consecutivos de conexión con interfaz presente → offline',
    () async {
      final s = build();
      await latest(s); // arranca online
      s.reportBackendUnreachable();
      s.reportBackendUnreachable();
      expect(await latest(s), ConnectivityStatus.offline);
    },
  );

  test('un solo fallo no cambia el estado (umbral 2)', () async {
    final s = build();
    await latest(s);
    s.reportBackendUnreachable();
    expect(await latest(s), ConnectivityStatus.online);
  });

  test(
    'reportBackendReachable() resetea el contador → vuelve a online',
    () async {
      final s = build();
      await latest(s);
      s.reportBackendUnreachable();
      s.reportBackendUnreachable();
      expect(await latest(s), ConnectivityStatus.offline);

      s.reportBackendReachable();
      expect(await latest(s), ConnectivityStatus.online);
    },
  );

  test('un cambio transitorio no emite: volver a la posición estable antes de '
      'que venza el debounce cancela el cambio', () async {
    final s = build();
    final seen = <ConnectivityStatus>[];
    final sub = s.statusStream.listen(seen.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 40));

    // Dispara offline y lo revierte antes de los 20 ms de debounce.
    s.reportBackendUnreachable();
    s.reportBackendUnreachable();
    s.reportBackendReachable();
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(seen, isNot(contains(ConnectivityStatus.offline)));
  });
}
