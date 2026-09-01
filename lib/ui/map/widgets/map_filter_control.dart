import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reports/providers/report_filter.dart';
import '../providers/map_report_filter_provider.dart';

/// Control de filtro por estado del mapa: icono de embudo en la barra
/// superior que abre un menú de **selección única** (FR-012/FR-013),
/// enlazado a `mapReportFilterProvider` (independiente del filtro de la lista
/// "Mis reportes" — FR-015).
class MapFilterControl extends ConsumerWidget {
  const MapFilterControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(mapReportFilterProvider);
    return PopupMenuButton<ReportFilter>(
      icon: Badge(
        isLabelVisible: selected != ReportFilter.todos,
        smallSize: 8,
        child: const Icon(Icons.filter_list),
      ),
      tooltip: 'Filtrar por estado',
      initialValue: selected,
      onSelected: (filter) =>
          ref.read(mapReportFilterProvider.notifier).select(filter),
      itemBuilder: (context) => [
        for (final filter in ReportFilter.values)
          CheckedPopupMenuItem<ReportFilter>(
            value: filter,
            checked: filter == selected,
            child: Text(filter.label),
          ),
      ],
    );
  }
}
