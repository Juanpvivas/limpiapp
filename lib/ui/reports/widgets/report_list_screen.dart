import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../domain/models/report.dart';
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
        error: (error, _) =>
            _ErrorState(onRetry: () => ref.invalidate(myReportsProvider)),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar tus reportes.\n'
              'Revisa tu conexión e intenta de nuevo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
