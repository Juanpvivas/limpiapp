import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:limpiapp/config/service_locator.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:limpiapp/domain/models/report.dart';
import 'package:limpiapp/domain/models/report_status.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/domain/repositories/report_list_repository.dart';
import 'package:limpiapp/ui/reports/providers/report_detail_provider.dart';
import 'package:limpiapp/ui/reports/providers/reports_failure.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportListRepository extends Mock implements ReportListRepository {}

Report _report({ReportStatus status = ReportStatus.pendiente}) => Report(
  id: 'r1',
  reportNumber: '#IL-2026-000001',
  category: WasteCategory.otros,
  description: '',
  address: 'Calle 1',
  photoUrl: 'https://storage/r1.jpg',
  createdAt: DateTime(2026),
  status: status,
  deviceId: 'd1',
);

void main() {
  late _MockReportListRepository listRepository;
  late ProviderContainer container;

  setUp(() async {
    listRepository = _MockReportListRepository();
    await getIt.reset();
    getIt.registerLazySingleton<ReportListRepository>(() => listRepository);
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  // Provider autoDispose: se mantiene vivo mientras el test lo consulta.
  void keepAlive(String reportId) =>
      container.listen(reportDetailProvider(reportId), (_, _) {});

  test('emite el reporte encontrado', () async {
    keepAlive('r1');
    when(() => listRepository.watchReportById('r1'))
        .thenAnswer((_) => Stream.value(Right(_report())));

    final report = await container.read(reportDetailProvider('r1').future);

    expect(report, isNotNull);
    expect(report!.id, 'r1');
  });

  test(
    'emite null si watchReportById retorna Right(null) (no encontrado)',
    () async {
      keepAlive('missing');
      when(() => listRepository.watchReportById('missing'))
          .thenAnswer((_) => Stream.value(const Right(null)));

      final report = await container.read(
        reportDetailProvider('missing').future,
      );

      expect(report, isNull);
    },
  );

  test('un Left del Repository se representa como AsyncError', () async {
    when(() => listRepository.watchReportById('r1'))
        .thenAnswer((_) => Stream.value(const Left(ServerFailure())));

    final sub = container.listen(
      reportDetailProvider('r1'),
      (_, _) {},
      onError: (_, _) {},
    );
    for (var i = 0; i < 20 && sub.read().isLoading; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(sub.read().hasError, isTrue);
    expect(sub.read().error, isA<ReportsFailureException>());
  });

  test('emisiones sucesivas del stream se reflejan sin recrear el provider '
      '(US3 — pendiente → enProceso → solucionado)', () async {
    final controller = StreamController<Either<Failure, Report?>>();
    addTearDown(controller.close);
    when(() => listRepository.watchReportById('r1'))
        .thenAnswer((_) => controller.stream);

    final emissions = <ReportStatus?>[];
    container.listen(reportDetailProvider('r1'), (_, next) {
      if (next.hasValue) emissions.add(next.asData?.value?.status);
    }, fireImmediately: true);

    controller.add(Right(_report(status: ReportStatus.pendiente)));
    await Future<void>.delayed(Duration.zero);
    controller.add(Right(_report(status: ReportStatus.enProceso)));
    await Future<void>.delayed(Duration.zero);
    controller.add(Right(_report(status: ReportStatus.solucionado)));
    await Future<void>.delayed(Duration.zero);

    expect(
      emissions,
      containsAllInOrder([
        ReportStatus.pendiente,
        ReportStatus.enProceso,
        ReportStatus.solucionado,
      ]),
    );
  });
}
