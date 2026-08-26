import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Wrapper delgado sobre `firebase_storage` (research.md §8).
class ReportStorageService {
  ReportStorageService(this._storage);

  final FirebaseStorage _storage;

  Reference _refFor(String docId) => _storage.ref('reports/$docId.jpg');

  /// Sube la foto ya comprimida y retorna su URL de descarga.
  Future<String> upload(String docId, Uint8List bytes) async {
    final ref = _refFor(docId);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Compensación de mejor esfuerzo si la transacción de Firestore falla
  /// después de subir la foto (research.md §4) — no debe quedar un archivo
  /// huérfano sin documento.
  Future<void> delete(String docId) => _refFor(docId).delete();
}
