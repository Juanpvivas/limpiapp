import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../domain/models/report.dart';
import '../../reports/providers/my_reports_provider.dart';
import '../providers/map_markers_provider.dart';
import '../providers/selected_map_report_provider.dart';
import 'map_empty_overlay.dart';
import 'map_error_state.dart';
import 'map_filter_control.dart';
import 'map_legend.dart';
import 'map_view.dart';
import 'report_summary_card.dart';

/// Pantalla del tab "Mapa" (FR-001..FR-028). Reemplaza el placeholder de la
/// feature 001. `ConsumerWidget`: solo lee providers vía `ref.watch`; el
/// `MapController` vive en `MapView`.
class ReportMapScreen extends ConsumerWidget {
  const ReportMapScreen({this.tileProvider, super.key});

  /// Inyectable en widget tests para no pegarle a la red (research.md §7).
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markersAsync = ref.watch(mapMarkersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de reportes'),
        actions: const [MapFilterControl()],
      ),
      body: markersAsync.hasError
          ? MapErrorState(onRetry: () => ref.invalidate(myReportsProvider))
          : markersAsync.maybeWhen(
              data: (reports) =>
                  _MapBody(reports: reports, tileProvider: tileProvider),
              orElse: () => const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

class _MapBody extends ConsumerWidget {
  const _MapBody({required this.reports, this.tileProvider});

  final List<Report> reports;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedMapReportProvider);
    final selected = selectedId == null
        ? null
        : reports.where((r) => r.id == selectedId).firstOrNull;

    // FR-024: distinguir "sin reportes" de "el filtro no deja ninguno".
    final hasAnyMappable =
        ref.watch(myReportsProvider).asData?.value.any((r) => r.isMappable) ??
        false;

    return Stack(
      children: [
        MapView(reports: reports, tileProvider: tileProvider),

        // Cierre de la tarjeta al tocar el mapa (FR-019).
        if (selected != null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => ref.read(selectedMapReportProvider.notifier).clear(),
            ),
          ),

        const Align(alignment: Alignment.bottomLeft, child: MapLegend()),

        if (reports.isEmpty) MapEmptyOverlay(filtered: hasAnyMappable),

        if (selected != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: ReportSummaryCard(
              report: selected,
              onClose: () =>
                  ref.read(selectedMapReportProvider.notifier).clear(),
              onTap: () {
                ref.read(selectedMapReportProvider.notifier).clear();
                context.go('$misReportesPath/${selected.id}');
              },
            ),
          ),
      ],
    );
  }
}
