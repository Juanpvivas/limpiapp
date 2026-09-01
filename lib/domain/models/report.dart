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

    /// Latitud del punto reportado. `null` si el reporte no registró
    /// ubicación automática. Ya persistido por "Crear Reporte"
    /// (`reports.latitude`); "Mapa de Reportes" (004) lo lee de vuelta para
    /// posicionar el marcador (FR-003).
    double? latitude,

    /// Longitud del punto reportado. Mismo origen que [latitude].
    double? longitude,

    /// `null` hasta que el reporte pase a "en proceso" (FR-014). Solo
    /// lectura en esta feature.
    DateTime? inProgressAt,

    /// `null` hasta que el reporte pase a "solucionado" (FR-014). Solo
    /// lectura en esta feature.
    DateTime? resolvedAt,
  }) = _Report;

  const Report._();

  /// `true` si el reporte tiene coordenadas válidas para dibujarse como
  /// marcador en el mapa (feature 004, FR-004). Descarta `null`, valores
  /// fuera de rango y el centinela `(0, 0)` (un reporte de Ibagué está en
  /// ~`(4.44, -75.23)`, nunca en el golfo de Guinea).
  bool get isMappable =>
      latitude != null &&
      longitude != null &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);
}
