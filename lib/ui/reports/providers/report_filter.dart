import '../../../domain/models/report.dart';
import '../../../domain/models/report_status.dart';

/// Pestaña de filtro de "Mis reportes" (FR-005). Es un concepto de UI, no un
/// domain model (mismo criterio que `AppTab`): `todos` no corresponde a
/// ningún `ReportStatus` (es "sin filtro"), por eso es un tipo separado en
/// vez de reutilizar `ReportStatus?`.
enum ReportFilter {
  todos('Todos', null),
  pendientes('Pendientes', ReportStatus.pendiente),
  enProceso('En proceso', ReportStatus.enProceso),
  solucionados('Solucionados', ReportStatus.solucionado);

  const ReportFilter(this.label, this.status);

  /// Texto de la pestaña.
  final String label;

  /// Estado que deja pasar, o `null` para "Todos" (sin filtro).
  final ReportStatus? status;

  /// Filtra en memoria sobre la lista ya recibida del stream (research.md
  /// §4): función pura, sin disparar una consulta nueva a Firestore.
  List<Report> apply(List<Report> reports) {
    final target = status;
    if (target == null) return reports;
    return reports.where((report) => report.status == target).toList();
  }
}
