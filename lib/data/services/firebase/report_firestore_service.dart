import 'package:cloud_firestore/cloud_firestore.dart';

/// Wrapper delgado sobre `cloud_firestore` (research.md §8: sin lógica
/// condicional propia más allá de la transacción misma). Toda la lógica de
/// negocio (mapeo de errores, orquestación con Storage) vive en
/// `ReportRepositoryImpl`.
class ReportFirestoreService {
  ReportFirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  static const _reportsCollection = 'reports';
  static const _countersCollection = 'counters';

  /// Reserva un ID de documento *antes* de subir la foto (research.md §3),
  /// para poder nombrar el archivo de Storage con el mismo ID. Expone solo
  /// el `String` (no el `DocumentReference`, sellado por `cloud_firestore`
  /// y por eso no mockeable en tests) para que `ReportRepositoryImpl` sea
  /// testeable con `mocktail` (research.md §8).
  String reserveDocId() => _firestore.collection(_reportsCollection).doc().id;

  /// Ejecuta la transacción del contador anual (`counters/reports_{año}`) +
  /// crea el documento del reporte en la misma transacción, devolviendo el
  /// número de reporte único asignado (research.md §2).
  Future<String> createReport({
    required String docId,
    required Map<String, dynamic> reportData,
  }) {
    final year = DateTime.now().year;
    final counterRef = _firestore
        .collection(_countersCollection)
        .doc('reports_$year');
    final docRef = _firestore.collection(_reportsCollection).doc(docId);

    return _firestore.runTransaction<String>((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);
      final currentCount = (counterSnapshot.data()?['count'] as int?) ?? 0;
      final nextCount = currentCount + 1;
      final reportNumber = '#IL-$year-${nextCount.toString().padLeft(6, '0')}';

      transaction.set(counterRef, {'count': nextCount});
      transaction.set(docRef, {
        ...reportData,
        'reportNumber': reportNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return reportNumber;
    });
  }
}
