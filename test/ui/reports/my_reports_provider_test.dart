import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:limpiapp/config/service_locator.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:limpiapp/domain/models/report.dart';
import 'package:limpiapp/domain/models/report_status.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/domain/repositories/device_identifier_repository.dart';
import 'package:limpiapp/domain/repositories/report_list_repository.dart';
import 'package:limpiapp/ui/reports/providers/my_reports_provider.dart';
import 'package:limpiapp/ui/reports/providers/report_filter.dart';
import 'package:limpiapp/ui/reports/providers/reports_failure.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportListRepository extends Mock implements ReportListRepository {}

class _MockDeviceIdentifierRepository extends Mock
    implements DeviceIdentifierRepository {}

/// Suscribe el provider (autoDispose) y espera hasta que salga del estado
/// de carga, devolviendo el `AsyncValue` resuelto (data o error).
Future<AsyncValue<List<Report>>> _resolve(ProviderContainer container) async {
  final sub = container.listen(
    myReportsProvider,
    (_, _) {},
    onError: (_, _) {},
  );
  for (var i = 0; i < 20 && sub.read().isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return sub.read();
}

Report _report(String id, {ReportStatus status = ReportStatus.pendiente}) =>
    Report(
      id: id,
      reportNumber: '#IL-2026-00000$id',
      category: WasteCategory.otros,
      description: '',
      address: 'Calle $id',
      photoUrl: 'https://storage/$id.jpg',
      createdAt: DateTime(2026, 1, int.parse(id)),
      status: status,
      deviceId: 'd1',
    );

void main() {
  late _MockReportListRepository listRepository;
  late _MockDeviceIdentifierRepository deviceRepository;
  late ProviderContainer container;

  setUp(() async {
    listRepository = _MockReportListRepository();
    deviceRepository = _MockDeviceIdentifierRepository();

    await getIt.reset();
    getIt.registerLazySingleton<ReportListRepository>(() => listRepository);
    getIt.registerLazySingleton<DeviceIdentifierRepository>(
      () => deviceRepository,
    );

    when(() => deviceRepository.getDeviceId())
        .thenAnswer((_) async => const Right('d1'));

    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  // `myReportsProvider` es autoDispose: sin un listener activo Riverpod lo
  // destruye antes de que resuelva su Future. Se mantiene vivo por test.
  void keepAlive() => container.listen(myReportsProvider, (_, _) {});

  test('caso feliz: emite la lista mapeada desde el Repository', () async {
    keepAlive();
    when(() => listRepository.watchReports('d1'))
        .thenAnswer((_) => Stream.value(Right([_report('2'), _report('1')])));

    final reports = await container.read(myReportsProvider.future);

    expect(reports.map((r) => r.id), ['2', '1']);
  });

  test('reenvía el deviceId resuelto al Repository', () async {
    keepAlive();
    when(() => listRepository.watchReports(any()))
        .thenAnswer((_) => Stream.value(const Right(<Report>[])));

    await container.read(myReportsProvider.future);

    verify(() => listRepository.watchReports('d1')).called(1);
  });

  test('si el Repository emite Left, se representa como AsyncError', () async {
    when(() => listRepository.watchReports('d1'))
        .thenAnswer((_) => Stream.value(const Left(ServerFailure())));

    final value = await _resolve(container);

    expect(value.hasError, isTrue);
    expect(value.error, isA<ReportsFailureException>());
  });

  test(
    'si no se puede resolver el deviceId, se representa como AsyncError',
    () async {
      when(() => deviceRepository.getDeviceId())
          .thenAnswer((_) async => const Left(CacheFailure()));

      final value = await _resolve(container);

      expect(value.hasError, isTrue);
      expect(value.error, isA<ReportsFailureException>());
    },
  );

  // US2 (T030): el filtro por pestaña es una función pura sobre la lista ya
  // emitida por el provider (research.md §4), no una consulta nueva.
  group('filtrado en Presentation sobre la lista emitida', () {
    test('cada ReportFilter devuelve la sublista correcta', () async {
      keepAlive();
      when(() => listRepository.watchReports('d1')).thenAnswer(
        (_) => Stream.value(
          Right([
            _report('1', status: ReportStatus.pendiente),
            _report('2', status: ReportStatus.enProceso),
            _report('3', status: ReportStatus.solucionado),
          ]),
        ),
      );

      final all = await container.read(myReportsProvider.future);

      expect(ReportFilter.todos.apply(all).map((r) => r.id), ['1', '2', '3']);
      expect(ReportFilter.pendientes.apply(all).map((r) => r.id), ['1']);
      expect(ReportFilter.enProceso.apply(all).map((r) => r.id), ['2']);
      expect(ReportFilter.solucionados.apply(all).map((r) => r.id), ['3']);
    });
  });
}
