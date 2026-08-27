import 'package:flutter/material.dart';

import '../../../domain/models/report.dart';
import 'report_date_format.dart';
import 'report_status_chip.dart';

/// Fila de la lista de "Mis Reportes" (FR-008): miniatura, chip de estado,
/// número de reporte, dirección y fecha/hora de envío. Recibe el `Report`
/// por constructor y no lee ningún provider (`StatelessWidget`).
class ReportListItem extends StatelessWidget {
  const ReportListItem({required this.report, required this.onTap, super.key});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(url: report.photoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.reportNumber,
                          style: textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ReportStatusChip(status: report.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.address,
                    style: textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatReportDateTime(report.createdAt),
                    style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: url.isEmpty
            ? const ColoredBox(
                color: Color(0xFFEEEEEE),
                child: Icon(Icons.image_not_supported_outlined, size: 24),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const ColoredBox(
                        color: Color(0xFFEEEEEE),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                errorBuilder: (context, error, stack) => const ColoredBox(
                  color: Color(0xFFEEEEEE),
                  child: Icon(Icons.broken_image_outlined, size: 24),
                ),
              ),
      ),
    );
  }
}
