import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro plano de un documento leído: su `id` y sus `data` crudos. Nunca
/// se expone un `DocumentSnapshot`/`QuerySnapshot` del SDK de Firestore
/// hacia el Repository (research.md §3), para que
/// `ReportListRepositoryImpl` siga siendo testeable con `mocktail`.
typedef FirestoreRecord = ({String id, Map<String, dynamic> data});

/// Wrapper delgado de solo lectura sobre `cloud_firestore` (research.md §3):
/// envuelve `.snapshots()` y devuelve únicamente tipos propios de Dart. Toda
/// la lógica (mapeo a `Report`, manejo de errores) vive en
/// `ReportListRepositoryImpl`.
class ReportQueryService {
  ReportQueryService(this._firestore);

  final FirebaseFirestore _firestore;

  static const _reportsCollection = 'reports';

  /// Stream de los reportes de un dispositivo, filtrado por `deviceId` y
  /// ordenado por `createdAt` descendente (índice de campo único, ver
  /// `contracts/reports-schema.md` — no requiere índice compuesto).
  Stream<List<FirestoreRecord>> watchReportsByDevice(String deviceId) {
    return _firestore
        .collection(_reportsCollection)
        .where('deviceId', isEqualTo: deviceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => (id: doc.id, data: doc.data()))
              .toList(),
        );
  }

  /// Stream de un solo documento. Emite `null` si el documento no existe.
  Stream<FirestoreRecord?> watchReportById(String reportId) {
    return _firestore
        .collection(_reportsCollection)
        .doc(reportId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (!doc.exists || data == null) return null;
          return (id: doc.id, data: data);
        });
  }
}
