import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../config/service_locator.dart';
import '../../../domain/models/report.dart';
import '../../../domain/repositories/device_identifier_repository.dart';
import '../../../domain/repositories/report_list_repository.dart';
import 'reports_failure.dart';

part 'my_reports_provider.g.dart';

/// Stream de todos los reportes de este dispositivo (FR-004), ordenados del
/// más reciente al más antiguo (el orden lo garantiza `ReportQueryService`).
///
/// Resuelve el `deviceId` vía `DeviceIdentifierRepository` y delega en
/// `ReportListRepository.watchReports`. Cualquier `Left` (de cualquiera de
/// los 2 Repository) se traduce a una excepción para que Riverpod lo
/// represente como `AsyncError` (research.md §6). El filtro por pestaña
/// (FR-005) se aplica en la pantalla sobre esta lista, no aquí.
@riverpod
Stream<List<Report>> myReports(Ref ref) async* {
  final deviceId = (await getIt<DeviceIdentifierRepository>().getDeviceId())
      .getOrElse((failure) => throw ReportsFailureException(failure));

  yield* getIt<ReportListRepository>()
      .watchReports(deviceId)
      .map(
        (result) => result.getOrElse(
          (failure) => throw ReportsFailureException(failure),
        ),
      );
}
