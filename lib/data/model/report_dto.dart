import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/report.dart';
import '../../domain/models/report_location.dart';
import '../../domain/models/report_status.dart';
import '../../domain/models/waste_category.dart';

/// Mapeo entre el documento Firestore de `reports` (ver
/// `specs/003-mis-reportes/contracts/reports-schema.md`) y la entidad
/// `Report`.
class ReportDto {
  /// Datos a persistir en el documento (sin `reportNumber`/`createdAt`:
  /// esos los asigna `ReportFirestoreService` dentro de la transacción).
  /// `inProgressAt`/`resolvedAt` se escriben `null` al crear — solo un
  /// mecanismo futuro fuera de alcance los actualiza (FR-014/FR-015).
  static Map<String, dynamic> toFirestoreMap({
    required WasteCategory category,
    required String description,
    required ReportLocation location,
    required String address,
    required String photoUrl,
    required ReportStatus status,
    required String deviceId,
  }) {
    return {
      'wasteCategory': category.name,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'automaticAddress': location.automaticAddress,
      'manualAddress': location.manualAddress,
      'address': address,
      'photoUrl': photoUrl,
      'status': status.name,
      'deviceId': deviceId,
      'inProgressAt': null,
      'resolvedAt': null,
    };
  }

  /// Construye el `Report` de dominio devuelto tras un envío exitoso.
  /// `createdAt` se aproxima con la hora del cliente: el valor real
  /// (`FieldValue.serverTimestamp()`) no está disponible de forma síncrona
  /// al terminar la transacción, y no se muestra en "Confirmación".
  /// `inProgressAt`/`resolvedAt` siempre son `null` en un envío nuevo.
  static Report fromSubmission({
    required String id,
    required String reportNumber,
    required WasteCategory category,
    required String description,
    required String address,
    required String photoUrl,
    required ReportStatus status,
    required String deviceId,
  }) {
    return Report(
      id: id,
      reportNumber: reportNumber,
      category: category,
      description: description,
      address: address,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
      status: status,
      deviceId: deviceId,
    );
  }

  /// Mapea un documento leído de Firestore (id + data crudos, ver
  /// `ReportQueryService`) a un `Report`. Convierte los `Timestamp` de
  /// Firestore a `DateTime` y el string de `status` a `ReportStatus`.
  /// Tolera campos ausentes/mal formados para no romper la lista por un
  /// solo documento inconsistente.
  static Report fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return Report(
      id: id,
      reportNumber: data['reportNumber'] as String? ?? '',
      category: _categoryFrom(data['wasteCategory'] as String?),
      description: data['description'] as String? ?? '',
      address: data['address'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      createdAt: _dateFrom(data['createdAt']) ?? DateTime.now(),
      status: _statusFrom(data['status'] as String?),
      deviceId: data['deviceId'] as String? ?? '',
      inProgressAt: _dateFrom(data['inProgressAt']),
      resolvedAt: _dateFrom(data['resolvedAt']),
    );
  }

  static DateTime? _dateFrom(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  static WasteCategory _categoryFrom(String? raw) =>
      WasteCategory.values.firstWhere(
        (category) => category.name == raw,
        orElse: () => WasteCategory.otros,
      );

  static ReportStatus _statusFrom(String? raw) =>
      ReportStatus.values.firstWhere(
        (status) => status.name == raw,
        orElse: () => ReportStatus.pendiente,
      );
}
