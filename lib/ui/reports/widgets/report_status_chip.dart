import 'package:flutter/material.dart';

import '../../../domain/models/report_status.dart';

/// Etiqueta de color con el estado de un reporte (FR-008). Recibe el
/// `ReportStatus` por constructor y no lee ningún provider, por lo que es
/// `StatelessWidget` (Excepción del Principio III). Reutilizada en la lista
/// y en el detalle.
class ReportStatusChip extends StatelessWidget {
  const ReportStatusChip({required this.status, super.key});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// (fondo, texto) según el estado — data-model.md: pendiente=ámbar,
  /// enProceso=azul, solucionado=verde.
  (Color, Color) get _colors => switch (status) {
    ReportStatus.pendiente => (
      const Color(0xFFFFF3E0),
      const Color(0xFFE65100),
    ),
    ReportStatus.enProceso => (
      const Color(0xFFE3F2FD),
      const Color(0xFF0D47A1),
    ),
    ReportStatus.solucionado => (
      const Color(0xFFE8F5E9),
      const Color(0xFF1B5E20),
    ),
  };
}
