import 'package:flutter/material.dart';

import '../../../domain/models/report.dart';
import 'report_date_format.dart';

/// Línea de tiempo de seguimiento de 3 pasos (FR-012 a FR-014). Recibe el
/// `Report` por constructor y no lee ningún provider (`StatelessWidget`).
/// Estrictamente de solo lectura: no expone ningún control (FR-015).
///
/// Cada paso está "cumplido" si su fecha correspondiente no es `null`
/// (`createdAt` siempre lo está); si no, muestra "Pendiente".
class ReportStatusTimeline extends StatelessWidget {
  const ReportStatusTimeline({required this.report, super.key});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final steps = <({String label, DateTime? at})>[
      (label: 'Reporte recibido', at: report.createdAt),
      (label: 'En proceso', at: report.inProgressAt),
      (label: 'Solucionado', at: report.resolvedAt),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          _Step(
            label: steps[i].label,
            at: steps[i].at,
            isFirst: i == 0,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.at,
    required this.isFirst,
    required this.isLast,
  });

  final String label;
  final DateTime? at;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final reached = at != null;
    final textTheme = Theme.of(context).textTheme;
    final activeColor = Theme.of(context).colorScheme.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  width: 2,
                  color: isFirst
                      ? Colors.transparent
                      : (reached ? activeColor : Colors.black26),
                ),
              ),
              Icon(
                reached ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: reached ? activeColor : Colors.black26,
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.black26,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: reached ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reached ? formatReportDateTime(at!) : 'Pendiente',
                  style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
