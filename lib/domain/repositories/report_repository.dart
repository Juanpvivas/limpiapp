import 'package:fpdart/fpdart.dart';

import '../models/failure.dart';
import '../models/new_report_draft.dart';
import '../models/report.dart';

/// Único punto de entrada desde Presentation para enviar un reporte
/// (sube la foto y crea el documento como una única operación, ver
/// research.md §4).
abstract class ReportRepository {
  Future<Either<Failure, Report>> submitReport(NewReportDraft draft);
}
