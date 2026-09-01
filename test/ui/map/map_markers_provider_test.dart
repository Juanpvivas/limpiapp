import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiapp/domain/models/report.dart';
import 'package:limpiapp/domain/models/report_status.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/ui/map/providers/map_markers_provider.dart';
import 'package:limpiapp/ui/map/providers/map_report_filter_provider.dart';
import 'package:limpiapp/ui/reports/providers/my_reports_provider.dart';
import 'package:limpiapp/ui/reports/providers/report_filter.dart';

Report _report(
  String id, {
  ReportStatus status = ReportStatus.pendiente,
  double? lat = 4.44,
  double? lng = -75.23,
}) => Report(
  id: id,
  reportNumber: '#IL-2026-00000$id',
  category: WasteCategory.otros,
  description: '',
  address: 'Calle $id',
  photoUrl: '',
  createdAt: DateTime(2026, 1, int.parse(id)),
  status: status,
  deviceId: 'd1',
  latitude: lat,
  longitude: lng,
);

ProviderContainer _containerWith(Stream<List<Report>> reports) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [myReportsProvider.overrideWith((ref) => reports)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AsyncValue<List<Report>>> _resolve(ProviderContainer c) async {
  final sub = c.listen(mapMarkersProvider, (_, _) {}, onError: (_, _) {});
  for (var i = 0; i < 20 && sub.read().isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return sub.read();
}

void main() {
  test('caso feliz: mapea los reportes con coordenadas, excluye los que no '
      'las tienen (FR-004)', () async {
    final container = _containerWith(
      Stream.value([
        _report('1', status: ReportStatus.pendiente),
        _report('2', status: ReportStatus.solucionado),
        _report('3', lat: null, lng: null), // sin coordenadas
        _report('4', lat: 0, lng: 0), // centinela → no mapeable
      ]),
    );

    final value = await _resolve(container);

    expect(value.hasValue, isTrue);
    expect(value.requireValue.map((r) => r.id), ['1', '2']);
  });

  test('propaga el estado de carga de myReportsProvider', () {
    final completer = Completer<List<Report>>();
    final container = _containerWith(Stream.fromFuture(completer.future));

    expect(container.read(mapMarkersProvider).isLoading, isTrue);
    completer.complete(const []);
  });

  test('propaga el error de myReportsProvider como AsyncError', () async {
    final container = _containerWith(Stream.error(StateError('boom')));

    final value = await _resolve(container);

    expect(value.hasError, isTrue);
  });

  test('FR-014: aplica el filtro del mapa sobre la lista', () async {
    final container = _containerWith(
      Stream.value([
        _report('1', status: ReportStatus.pendiente),
        _report('2', status: ReportStatus.enProceso),
        _report('3', status: ReportStatus.solucionado),
      ]),
    );
    container
        .read(mapReportFilterProvider.notifier)
        .select(ReportFilter.enProceso);

    final value = await _resolve(container);

    expect(value.requireValue.map((r) => r.id), ['2']);
  });

  test('FR-021: una segunda emisión del stream (reporte agregado / estado '
      'cambiado) actualiza la lista sin recrear el provider', () async {
    final controller = StreamController<List<Report>>();
    final container = _containerWith(controller.stream);
    addTearDown(controller.close);

    final sub = container.listen(
      mapMarkersProvider,
      (_, _) {},
      onError: (_, _) {},
    );

    controller.add([_report('1', status: ReportStatus.pendiente)]);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().requireValue.single.status, ReportStatus.pendiente);

    controller.add([
      _report('1', status: ReportStatus.solucionado),
      _report('2'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().requireValue.map((r) => r.id), ['1', '2']);
    expect(sub.read().requireValue.first.status, ReportStatus.solucionado);
  });
}
