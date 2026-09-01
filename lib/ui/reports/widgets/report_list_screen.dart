import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../domain/models/report.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/read_error_message.dart';
import '../../core/ui/data_error_state.dart';
import '../providers/my_reports_provider.dart';
import '../providers/report_filter_provider.dart';
import 'report_filter_tabs.dart';
import 'report_list_empty_state.dart';
import 'report_list_item.dart';

/// Pantalla "Mis reportes" (FR-001 a FR-010). `ConsumerWidget`: lee
/// `myReportsProvider` vía `ref.watch` (Principio III). Reemplaza el
/// placeholder de la feature 001.
class ReportListScreen extends ConsumerWidget {
  const ReportListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes')),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => DataErrorState(
          message: readErrorMessage(
            error,
            ref.watch(connectivityStatusProvider).value,
          ),
          onRetry: () => ref.invalidate(myReportsProvider),
        ),
        data: (reports) => _ReportListView(reports: reports),
      ),
    );
  }
}

class _ReportListView extends ConsumerWidget {
  const _ReportListView({required this.reports});

  final List<Report> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dispositivo sin ningún reporte: estado vacío general, sin pestañas
    // (FR-009 — Edge case de spec.md).
    if (reports.isEmpty) return const ReportListEmptyState();

    final filter = ref.watch(reportFilterProvider);
    // Filtro en memoria sobre la lista ya recibida — sin consulta nueva a
    // Firestore (research.md §4).
    final visible = filter.apply(reports);

    return Column(
      children: [
        const ReportFilterTabs(),
        const Divider(height: 1),
        Expanded(
          child: visible.isEmpty
              ? const ReportListEmptyState(filtered: true)
              : ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final report = visible[index];
                    return ReportListItem(
                      report: report,
                      onTap: () =>
                          context.push('$misReportesPath/${report.id}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
