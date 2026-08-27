import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'report_filter.dart';

part 'report_filter_provider.g.dart';

/// Pestaña de filtro seleccionada en "Mis reportes". `Notifier` simple
/// (estado efímero de UI, no de negocio): arranca en `ReportFilter.todos`
/// (FR-006) y solo cambia al tocar otra pestaña.
@riverpod
class ReportFilterNotifier extends _$ReportFilterNotifier {
  @override
  ReportFilter build() => ReportFilter.todos;

  void select(ReportFilter filter) => state = filter;
}
