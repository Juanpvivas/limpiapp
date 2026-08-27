import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/report_detail_provider.dart';
import 'report_detail_body.dart';

/// Pantalla "Detalle del reporte" (FR-011 a FR-016). `ConsumerWidget`: lee
/// `reportDetailProvider(reportId)` vía `ref.watch`. Estrictamente de solo
/// lectura — no expone ningún control para cambiar el estado (FR-015).
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportDetailProvider(reportId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del reporte')),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const _CenteredMessage(
          icon: Icons.cloud_off_outlined,
          text:
              'No se pudo cargar el reporte.\n'
              'Revisa tu conexión e intenta de nuevo.',
        ),
        data: (report) => report == null
            ? const _CenteredMessage(
                icon: Icons.search_off_outlined,
                text: 'No encontramos este reporte.',
              )
            : ReportDetailBody(report: report),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.black38),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
