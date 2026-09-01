import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiapp/ui/map/providers/map_report_filter_provider.dart';
import 'package:limpiapp/ui/reports/providers/report_filter.dart';
import 'package:limpiapp/ui/reports/providers/report_filter_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('estado inicial: ReportFilter.todos (FR-013)', () {
    expect(container.read(mapReportFilterProvider), ReportFilter.todos);
  });

  test('select() cambia el filtro del mapa', () {
    container
        .read(mapReportFilterProvider.notifier)
        .select(ReportFilter.pendientes);
    expect(container.read(mapReportFilterProvider), ReportFilter.pendientes);

    container
        .read(mapReportFilterProvider.notifier)
        .select(ReportFilter.solucionados);
    expect(container.read(mapReportFilterProvider), ReportFilter.solucionados);
  });

  test('FR-015: el filtro del mapa es independiente del de "Mis reportes"', () {
    // Cambiar el del mapa no toca el de la lista.
    container
        .read(mapReportFilterProvider.notifier)
        .select(ReportFilter.enProceso);
    expect(container.read(reportFilterProvider), ReportFilter.todos);

    // Cambiar el de la lista no toca el del mapa.
    container
        .read(reportFilterProvider.notifier)
        .select(ReportFilter.solucionados);
    expect(container.read(mapReportFilterProvider), ReportFilter.enProceso);
  });
}
