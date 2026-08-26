import 'package:freezed_annotation/freezed_annotation.dart';

import 'photo.dart';
import 'report_location.dart';
import 'waste_category.dart';

part 'new_report_draft.freezed.dart';

/// Agregado inmutable con todo lo capturado en el formulario "Nuevo
/// reporte", pasado a `ReportRepository.submitReport`. No se persiste en
/// ningún lado hasta que el envío es exitoso (Assumption de spec.md).
@freezed
abstract class NewReportDraft with _$NewReportDraft {
  const factory NewReportDraft({
    /// Ya validada como `!exceedsMaxSize` antes de construir el draft.
    required Photo photo,
    required WasteCategory category,

    /// Puede ser cadena vacía (FR-009, opcional).
    required String description,

    /// Debe cumplir `hasAnyLocation == true` antes de construir el draft.
    required ReportLocation location,
  }) = _NewReportDraft;
}
