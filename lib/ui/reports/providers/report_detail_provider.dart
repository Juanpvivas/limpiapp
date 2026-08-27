import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../config/service_locator.dart';
import '../../../domain/models/report.dart';
import '../../../domain/repositories/report_list_repository.dart';
import 'reports_failure.dart';

part 'report_detail_provider.g.dart';

/// Stream de un reporte por su `id` de documento, para "Detalle del
/// reporte". Se suscribe (no una carga única) para reflejar cambios de
/// estado en tiempo real sin recargar (Assumption de spec.md).
///
/// Emite `null` si el documento no existe (reporte no encontrado). Un `Left`
/// del Repository se traduce a `AsyncError` igual que en `myReports`.
@riverpod
Stream<Report?> reportDetail(Ref ref, String reportId) async* {
  yield* getIt<ReportListRepository>()
      .watchReportById(reportId)
      .map(
        (result) => result.getOrElse(
          (failure) => throw ReportsFailureException(failure),
        ),
      );
}
