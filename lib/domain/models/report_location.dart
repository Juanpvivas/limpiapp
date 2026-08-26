import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_location.freezed.dart';

/// Agrega la ubicación automática (si se obtuvo) y/o la dirección manual
/// escrita por el usuario (FR-010 a FR-014).
@freezed
abstract class ReportLocation with _$ReportLocation {
  const factory ReportLocation({
    double? latitude,
    double? longitude,
    String? automaticAddress,
    String? manualAddress,
  }) = _ReportLocation;

  const ReportLocation._();

  /// `true` si la ubicación automática se obtuvo (research.md §6: las
  /// coordenadas cuentan como ubicación automática aunque falle el reverse
  /// geocoding, siempre que haya un `automaticAddress` de respaldo).
  bool get hasAutomaticLocation => automaticAddress != null;

  bool get hasManualAddress =>
      manualAddress != null && manualAddress!.trim().isNotEmpty;

  /// Fuente de verdad de FR-014/FR-015: al menos una de las dos ubicaciones
  /// debe existir para poder enviar el reporte.
  bool get hasAnyLocation => hasAutomaticLocation || hasManualAddress;
}
