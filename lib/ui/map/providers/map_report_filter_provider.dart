import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../reports/providers/report_filter.dart';

part 'map_report_filter_provider.g.dart';

/// Estado del filtro por estado del "Mapa de Reportes" (FR-012/FR-013).
///
/// Reutiliza el enum [ReportFilter] de "Mis Reportes" pero es una instancia de
/// estado **independiente** de `reportFilterProvider` (FR-015): cambiar el
/// filtro del mapa no toca el de la lista y viceversa.
///
/// `keepAlive` para que la selección sobreviva al cambio de tab y al
/// ida-y-vuelta al "Detalle del reporte" (FR-028) — la rama "Mapa" permanece
/// montada en el `IndexedStack` del shell, pero el provider igual se marca
/// `keepAlive` para no depender de ese detalle de montaje.
@Riverpod(keepAlive: true)
class MapReportFilter extends _$MapReportFilter {
  @override
  ReportFilter build() => ReportFilter.todos;

  void select(ReportFilter filter) => state = filter;
}
