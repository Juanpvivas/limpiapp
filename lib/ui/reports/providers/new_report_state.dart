import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/photo.dart';
import '../../../domain/models/report_location.dart';
import '../../../domain/models/waste_category.dart';

part 'new_report_state.freezed.dart';

/// Estado de UI de "Nuevo reporte" (concepto de Presentation, no un domain
/// model — ver data-model.md). No incluye un campo de error de foto propio:
/// el texto de "imagen muy grande" (FR-006) se deriva de
/// `photo.exceedsMaxSize`, sin duplicar esa bandera aquí.
@freezed
abstract class NewReportState with _$NewReportState {
  const factory NewReportState({
    Photo? photo,
    WasteCategory? category,
    @Default('') String description,

    /// Resultado de `LocationRepository.getCurrentLocation()`; `null` si
    /// falló o aún no se resuelve (ver `isLoadingLocation`).
    ReportLocation? autoLocation,
    @Default('') String manualAddress,
    @Default(false) bool isLoadingLocation,
    @Default(false) bool isSubmitting,
    String? submitError,
    @Default(false) bool showPermissionDeniedAlert,
  }) = _NewReportState;

  const NewReportState._();

  /// Combina `autoLocation` (Domain) + `manualAddress` (UI) en el
  /// `ReportLocation` efectivo que consumen `canSubmit` y el envío.
  ReportLocation get location => ReportLocation(
    latitude: autoLocation?.latitude,
    longitude: autoLocation?.longitude,
    automaticAddress: autoLocation?.automaticAddress,
    manualAddress: manualAddress.trim().isEmpty ? null : manualAddress,
  );

  /// FR-015: habilitación de "Enviar reporte" — función pura, sin I/O.
  bool get canSubmit =>
      photo != null &&
      !photo!.exceedsMaxSize &&
      category != null &&
      location.hasAnyLocation;
}
