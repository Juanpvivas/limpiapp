import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:limpiapp/config/service_locator.dart';
import 'package:limpiapp/domain/models/report.dart';
import 'package:limpiapp/domain/models/report_status.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/domain/repositories/report_list_repository.dart';
import 'package:limpiapp/ui/reports/widgets/report_detail_screen.dart';
import 'package:limpiapp/ui/reports/widgets/report_status_chip.dart';
import 'package:limpiapp/ui/reports/widgets/report_status_timeline.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportListRepository extends Mock implements ReportListRepository {}

Report _report({
  String description = 'Bolsas rotas junto al parque',
  ReportStatus status = ReportStatus.pendiente,
  DateTime? inProgressAt,
  DateTime? resolvedAt,
}) => Report(
  id: 'r1',
  reportNumber: '#IL-2026-000042',
  category: WasteCategory.residuosVerdes,
  description: description,
  address: 'Carrera 4 # 18-30',
  photoUrl: 'https://storage/r1.jpg',
  createdAt: DateTime(2026, 3, 5, 14, 30),
  status: status,
  deviceId: 'd1',
  inProgressAt: inProgressAt,
  resolvedAt: resolvedAt,
);

void main() {
  late _MockReportListRepository listRepository;

  setUp(() async {
    listRepository = _MockReportListRepository();
    await getIt.reset();
    getIt.registerLazySingleton<ReportListRepository>(() => listRepository);
  });

  Future<void> pumpDetail(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ReportDetailScreen(reportId: 'r1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra número, chip de estado, tipo de residuo, ubicación, '
      'fecha y descripción (FR-011)', (tester) async {
    when(() => listRepository.watchReportById('r1'))
        .thenAnswer((_) => Stream.value(Right(_report())));

    await pumpDetail(tester);

    expect(find.text('#IL-2026-000042'), findsOneWidget);
    expect(find.byType(ReportStatusChip), findsOneWidget);
    expect(find.text('Residuos verdes'), findsOneWidget);
    expect(find.text('Carrera 4 # 18-30'), findsOneWidget);
    // La fecha de envío aparece en la ficha y también en el primer paso de
    // la línea de tiempo ("Reporte recibido").
    expect(find.text('05/03/2026 · 14:30'), findsWidgets);
    expect(find.text('Bolsas rotas junto al parque'), findsOneWidget);
  });

  testWidgets('con descripción vacía no se rompe la pantalla ni muestra la '
      'sección de descripción', (tester) async {
    when(() => listRepository.watchReportById('r1'))
        .thenAnswer((_) => Stream.value(Right(_report(description: ''))));

    await pumpDetail(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('#IL-2026-000042'), findsOneWidget);
    expect(find.text('Descripción'), findsNothing);
  });

  testWidgets('reporte no encontrado (null) muestra un mensaje, no una '
      'pantalla en blanco', (tester) async {
    when(() => listRepository.watchReportById('r1'))
        .thenAnswer((_) => Stream.value(const Right(null)));

    await pumpDetail(tester);

    expect(find.textContaining('No encontramos este reporte'), findsOneWidget);
  });

  group('US3 — sección "Estado del reporte"', () {
    testWidgets('aparece con la línea de tiempo debajo de la información', (
      tester,
    ) async {
      when(() => listRepository.watchReportById('r1')).thenAnswer(
        (_) => Stream.value(
          Right(
            _report(
              status: ReportStatus.enProceso,
              inProgressAt: DateTime(2026, 3, 8, 10),
            ),
          ),
        ),
      );

      await pumpDetail(tester);

      expect(find.text('Estado del reporte'), findsOneWidget);
      expect(find.byType(ReportStatusTimeline), findsOneWidget);
      expect(find.text('Reporte recibido'), findsOneWidget);
      expect(find.text('Solucionado'), findsOneWidget);
    });

    testWidgets('la pantalla es de solo lectura: ningún control de escritura '
        'de estado (FR-015, SC-005)', (tester) async {
      when(() => listRepository.watchReportById('r1'))
          .thenAnswer((_) => Stream.value(Right(_report())));

      await pumpDetail(tester);

      expect(find.byType(Switch), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(DropdownButton<Object?>), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(PopupMenuButton<Object?>), findsNothing);
    });
  });
}
