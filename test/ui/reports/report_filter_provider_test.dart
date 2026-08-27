import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiapp/domain/models/report.dart';
import 'package:limpiapp/domain/models/report_status.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/ui/reports/providers/report_filter.dart';
import 'package:limpiapp/ui/reports/providers/report_filter_provider.dart';

Report _report(String id, ReportStatus status) => Report(
  id: id,
  reportNumber: '#IL-2026-00000$id',
  category: WasteCategory.otros,
  description: '',
  address: 'Calle $id',
  photoUrl: '',
  createdAt: DateTime(2026, 1, int.parse(id)),
  status: status,
  deviceId: 'd1',
);

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('estado inicial: ReportFilter.todos (FR-006)', () {
    expect(container.read(reportFilterProvider), ReportFilter.todos);
  });

  test('select() cambia la pestaña seleccionada', () {
    container
        .read(reportFilterProvider.notifier)
        .select(ReportFilter.enProceso);
    expect(container.read(reportFilterProvider), ReportFilter.enProceso);

    container
        .read(reportFilterProvider.notifier)
        .select(ReportFilter.solucionados);
    expect(container.read(reportFilterProvider), ReportFilter.solucionados);
  });

  group('ReportFilter.apply', () {
    final reports = [
      _report('1', ReportStatus.pendiente),
      _report('2', ReportStatus.enProceso),
      _report('3', ReportStatus.solucionado),
      _report('4', ReportStatus.pendiente),
    ];

    test('todos devuelve la lista completa', () {
      expect(ReportFilter.todos.apply(reports), hasLength(4));
    });

    test('pendientes devuelve solo los pendientes', () {
      expect(ReportFilter.pendientes.apply(reports).map((r) => r.id), [
        '1',
        '4',
      ]);
    });

    test('enProceso devuelve solo los en proceso', () {
      expect(ReportFilter.enProceso.apply(reports).map((r) => r.id), ['2']);
    });

    test('solucionados devuelve solo los solucionados', () {
      expect(ReportFilter.solucionados.apply(reports).map((r) => r.id), ['3']);
    });

    test('una pestaña sin reportes devuelve lista vacía', () {
      final soloPendientes = [_report('1', ReportStatus.pendiente)];
      expect(ReportFilter.solucionados.apply(soloPendientes), isEmpty);
    });
  });
}
