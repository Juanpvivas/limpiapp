import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/models/failure.dart';
import '../../domain/models/new_report_draft.dart';
import '../../domain/models/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../model/report_dto.dart';
import '../services/firebase/report_firestore_service.dart';
import '../services/firebase/report_storage_service.dart';

/// Orquesta Storage + Firestore como una única operación desde Presentation
/// (research.md §4): sube la foto, crea el documento en una transacción, y
/// borra la foto como compensación de mejor esfuerzo si la transacción
/// falla. Toda excepción de Firebase se captura y mapea a un `Failure` —
/// nunca cruza como excepción cruda (Principio V de la constitución).
class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({
    required this.firestoreService,
    required this.storageService,
  });

  final ReportFirestoreService firestoreService;
  final ReportStorageService storageService;

  @override
  Future<Either<Failure, Report>> submitReport(NewReportDraft draft) async {
    final docId = firestoreService.reserveDocId();

    final String photoUrl;
    try {
      photoUrl = await storageService.upload(docId, draft.photo.bytes);
    } on FirebaseException catch (e) {
      return Left(_mapFirebaseException(e));
    } catch (_) {
      return const Left(ServerFailure());
    }

    // FR-012/regla de mapeo (data-model.md): manualAddress manda si existe,
    // si no se usa automaticAddress. `hasAnyLocation` ya garantiza que al
    // menos una de las dos existe antes de construir el draft.
    final address =
        draft.location.manualAddress ?? draft.location.automaticAddress ?? '';

    try {
      final reportNumber = await firestoreService.createReport(
        docId: docId,
        reportData: ReportDto.toFirestoreMap(
          category: draft.category,
          description: draft.description,
          location: draft.location,
          address: address,
          photoUrl: photoUrl,
        ),
      );

      return Right(
        ReportDto.fromSubmission(
          reportNumber: reportNumber,
          category: draft.category,
          description: draft.description,
          address: address,
          photoUrl: photoUrl,
        ),
      );
    } on FirebaseException catch (e) {
      await _deleteOrphanPhoto(docId);
      return Left(_mapFirebaseException(e));
    } catch (_) {
      await _deleteOrphanPhoto(docId);
      return const Left(ServerFailure());
    }
  }

  Future<void> _deleteOrphanPhoto(String docId) async {
    try {
      await storageService.delete(docId);
    } catch (_) {
      // Compensación de mejor esfuerzo (research.md §4): el resultado no
      // afecta el Failure ya determinado por el error original.
    }
  }

  Failure _mapFirebaseException(FirebaseException e) {
    if (e.code == 'unavailable' || e.code == 'network-request-failed') {
      return const NetworkFailure();
    }
    return const ServerFailure();
  }
}
