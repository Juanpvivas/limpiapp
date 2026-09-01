import 'package:flutter/material.dart';

import '../../../domain/models/report.dart';
import '../../core/ui/report_photo_thumbnail.dart';
import '../../reports/widgets/report_date_format.dart';
import '../../reports/widgets/report_status_chip.dart';

/// Tarjeta resumen que aparece sobre el mapa al tocar un marcador (FR-017).
/// Tocarla abre el "Detalle del reporte" (`onTap`); el botón de cierre la
/// oculta (`onClose`). `StatelessWidget`: recibe todo por constructor.
///
/// Nota: `ReportStatusChip` conserva su paleta (ámbar/azul/verde), distinta de
/// la de los marcadores del mapa (rojo/naranja/verde) — divergencia
/// deliberada, ver `research.md` §6.
class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({
    required this.report,
    required this.onTap,
    required this.onClose,
    super.key,
  });

  final Report report;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportPhotoThumbnail(url: report.photoUrl, size: 72),
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
                        ReportStatusChip(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(report.category.label, style: textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      report.address,
                      style: textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatReportDateTime(report.createdAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
