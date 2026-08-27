import 'package:freezed_annotation/freezed_annotation.dart';

import 'report_status.dart';
import 'waste_category.dart';

part 'report.freezed.dart';

/// Un reporte ya persistido. Lo retorna un envío exitoso (consumido por
/// "Confirmación", FR-019 a FR-023 de "Crear Reporte") y también lo emiten
/// los streams de "Mis Reportes" al leer la colección `reports`.
@freezed
abstract class Report with _$Report {
  const factory Report({
    /// ID del documento de Firestore. Necesario para la ruta
    /// `/mis-reportes/:reportId` y para `watchReportById`.
    required String id,

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

    /// Estado de seguimiento. `pendiente` al crearse; solo lo cambia un
    /// mecanismo futuro fuera de alcance (FR-015).
    required ReportStatus status,

    /// Identificador anónimo del dispositivo que envió el reporte (FR-003),
    /// llave de filtro de "Mis Reportes" (FR-004).
    required String deviceId,

    /// `null` hasta que el reporte pase a "en proceso" (FR-014). Solo
    /// lectura en esta feature.
    DateTime? inProgressAt,

    /// `null` hasta que el reporte pase a "solucionado" (FR-014). Solo
    /// lectura en esta feature.
    DateTime? resolvedAt,
  }) = _Report;
}
