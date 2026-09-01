import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/models/report.dart';
import '../../reports/providers/my_reports_provider.dart';
import 'map_report_filter_provider.dart';

part 'map_markers_provider.g.dart';

/// Reportes que se dibujan como marcadores en el mapa: los del propio
/// dispositivo (reutiliza `myReportsProvider` de "Mis Reportes", sin tocar la
/// capa Data), tras aplicar el filtro por estado del mapa (FR-014) y descartar
/// los que no tienen coordenadas válidas (FR-004).
///
/// Devuelve un `AsyncValue` (vía `whenData`) para propagar tal cual los
/// estados de carga y error de `myReportsProvider` (FR-022/FR-025).
@riverpod
AsyncValue<List<Report>> mapMarkers(Ref ref) {
  final filter = ref.watch(mapReportFilterProvider);
  final async = ref.watch(myReportsProvider);
  // `myReportsProvider` puede quedar en `AsyncLoading` *con* un error adjunto
  // (recarga tras error); `whenData` perdería ese error. El error manda.
  if (async.hasError) {
    return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
  }
  return async.whenData(
    (reports) =>
        filter.apply(reports).where((report) => report.isMappable).toList(),
  );
}
