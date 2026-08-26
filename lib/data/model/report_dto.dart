import '../../domain/models/report.dart';
import '../../domain/models/report_location.dart';
import '../../domain/models/waste_category.dart';

/// Mapeo entre el documento Firestore de `reports` (ver
/// `contracts/firestore-reports-contract.md`) y la entidad `Report`.
class ReportDto {
  /// Datos a persistir en el documento (sin `reportNumber`/`createdAt`:
  /// esos los asigna `ReportFirestoreService` dentro de la transacción).
  static Map<String, dynamic> toFirestoreMap({
    required WasteCategory category,
    required String description,
    required ReportLocation location,
    required String address,
    required String photoUrl,
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
    };
  }

  /// Construye el `Report` de dominio devuelto tras un envío exitoso.
  /// `createdAt` se aproxima con la hora del cliente: el valor real
  /// (`FieldValue.serverTimestamp()`) no está disponible de forma síncrona
  /// al terminar la transacción, y no se muestra en la UI (spec.md no lo
  /// requiere en "Confirmación").
  static Report fromSubmission({
    required String reportNumber,
    required WasteCategory category,
    required String description,
    required String address,
    required String photoUrl,
  }) {
    return Report(
      reportNumber: reportNumber,
      category: category,
      description: description,
      address: address,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );
  }
}
