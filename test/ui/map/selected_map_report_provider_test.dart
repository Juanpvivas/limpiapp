import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiapp/ui/map/providers/selected_map_report_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('estado inicial: null (sin tarjeta)', () {
    expect(container.read(selectedMapReportProvider), isNull);
  });

  test('select() fija el id; select(otro) lo reemplaza (FR-018)', () {
    container.read(selectedMapReportProvider.notifier).select('a');
    expect(container.read(selectedMapReportProvider), 'a');

    container.read(selectedMapReportProvider.notifier).select('b');
    expect(container.read(selectedMapReportProvider), 'b');
  });

  test('clear() vuelve a null (FR-019)', () {
    container.read(selectedMapReportProvider.notifier).select('a');
    container.read(selectedMapReportProvider.notifier).clear();
    expect(container.read(selectedMapReportProvider), isNull);
  });
}
