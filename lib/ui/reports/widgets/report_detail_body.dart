import 'package:flutter/material.dart';

import '../../../domain/models/report.dart';
import 'report_date_format.dart';
import 'report_status_chip.dart';
import 'report_status_timeline.dart';

/// Cuerpo del detalle cuando el reporte existe (FR-011). Extraído de
/// `report_detail_screen.dart` para respetar el límite de 200 líneas por
/// archivo de UI (Principio IV.4).
class ReportDetailBody extends StatelessWidget {
  const ReportDetailBody({required this.report, super.key});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final hasDescription = report.description.trim().isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Photo(url: report.photoUrl),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.reportNumber,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ReportStatusChip(status: report.status),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Tipo de residuo',
                  value: report.category.label,
                ),
                _DetailRow(
                  icon: Icons.place_outlined,
                  label: 'Ubicación',
                  value: report.address,
                ),
                _DetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Fecha de envío',
                  value: formatReportDateTime(report.createdAt),
                ),
                if (hasDescription)
                  _DetailRow(
                    icon: Icons.notes_outlined,
                    label: 'Descripción',
                    value: report.description,
                  ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Estado del reporte',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ReportStatusTimeline(report: report),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: url.isEmpty
          ? const ColoredBox(
              color: Color(0xFFEEEEEE),
              child: Icon(Icons.image_not_supported_outlined, size: 48),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const ColoredBox(
                      color: Color(0xFFEEEEEE),
                      child: Center(child: CircularProgressIndicator()),
                    ),
              errorBuilder: (context, error, stack) => const ColoredBox(
                color: Color(0xFFEEEEEE),
                child: Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(value, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
