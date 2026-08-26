import 'package:freezed_annotation/freezed_annotation.dart';

import 'waste_category.dart';

part 'report.freezed.dart';

/// Lo que retorna un envío exitoso; consumido por la pantalla
/// "Confirmación" (FR-019 a FR-023).
@freezed
abstract class Report with _$Report {
  const factory Report({
    /// Formato completo `#IL-{año}-{consecutivo}` (research.md §2), ya
    /// listo para mostrar (FR-020).
    required String reportNumber,
    required WasteCategory category,
    required String description,

    /// Dirección final mostrable — `manualAddress` si existe, si no
    /// `automaticAddress` (regla de mapeo en data-model.md).
    required String address,

    /// URL de descarga de Firebase Storage de la foto ya subida.
    required String photoUrl,
    required DateTime createdAt,
  }) = _Report;
}
