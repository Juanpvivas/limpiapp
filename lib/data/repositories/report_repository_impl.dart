import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/models/failure.dart';
import '../../domain/models/new_report_draft.dart';
import '../../domain/models/report.dart';
import '../../domain/models/report_status.dart';
import '../../domain/repositories/device_identifier_repository.dart';
import '../../domain/repositories/report_repository.dart';
import '../model/report_dto.dart';
import '../services/connectivity_service.dart';
import '../services/firebase/report_firestore_service.dart';
import '../services/firebase/report_storage_service.dart';

/// Orquesta Storage + Firestore como una única operación desde Presentation
/// (research.md §4): sube la foto, crea el documento en una transacción, y
/// borra la foto como compensación de mejor esfuerzo si la transacción
/// falla. Toda excepción de Firebase se captura y mapea a un `Failure` —
/// nunca cruza como excepción cruda (Principio V de la constitución).
///
/// Feature 005: cada paso de red se acota con [_sendTimeout]; un
/// `TimeoutException` se trata como falta de conexión (`Left(NetworkFailure)`)
/// para que el usuario nunca quede en "enviando…" indefinido (FR-013/FR-014).
/// El resultado se reporta al [ConnectivityService] (llegó / no llegó al
/// backend).
class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({
    required this.firestoreService,
    required this.storageService,
    required this.deviceIdentifierRepository,
    required this.connectivityService,
    Duration sendTimeout = const Duration(seconds: 10),
    // ignore: prefer_initializing_formals
  }) : _sendTimeout = sendTimeout;

  final ReportFirestoreService firestoreService;
  final ReportStorageService storageService;
  final DeviceIdentifierRepository deviceIdentifierRepository;
  final ConnectivityService connectivityService;
  final Duration _sendTimeout;

  @override
  Future<Either<Failure, Report>> submitReport(NewReportDraft draft) async {
    // "Mis Reportes" (003): cada reporte se etiqueta con el identificador
    // anónimo del dispositivo que lo envía (FR-003). Si el almacenamiento
    // local falla, el envío falla con ese mismo `Failure`.
    final deviceIdResult = await deviceIdentifierRepository.getDeviceId();
    final deviceId = deviceIdResult.match((_) => null, (id) => id);
    if (deviceId == null) {
      return deviceIdResult.match(
        (failure) => Left<Failure, Report>(failure),
        (_) => const Left(CacheFailure()),
      );
    }

    final docId = firestoreService.reserveDocId();

    final String photoUrl;
    try {
      photoUrl = await storageService
          .upload(docId, draft.photo.bytes)
          .timeout(_sendTimeout);
    } on TimeoutException {
      connectivityService.reportBackendUnreachable();
      return const Left(NetworkFailure());
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
      final reportNumber = await firestoreService
          .createReport(
            docId: docId,
            reportData: ReportDto.toFirestoreMap(
              category: draft.category,
              description: draft.description,
              location: draft.location,
              address: address,
              photoUrl: photoUrl,
              status: ReportStatus.pendiente,
              deviceId: deviceId,
            ),
          )
          .timeout(_sendTimeout);

      connectivityService.reportBackendReachable();
      return Right(
        ReportDto.fromSubmission(
          id: docId,
          reportNumber: reportNumber,
          category: draft.category,
          description: draft.description,
          address: address,
          photoUrl: photoUrl,
          status: ReportStatus.pendiente,
          deviceId: deviceId,
        ),
      );
    } on TimeoutException {
      await _deleteOrphanPhoto(docId);
      connectivityService.reportBackendUnreachable();
      return const Left(NetworkFailure());
    } on FirebaseException catch (e) {
      await _deleteOrphanPhoto(docId);
      final failure = _mapFirebaseException(e);
      if (failure is NetworkFailure) {
        connectivityService.reportBackendUnreachable();
      }
      return Left(failure);
    } catch (_) {
      await _deleteOrphanPhoto(docId);
      return const Left(ServerFailure());
    }
  }

  Future<void> _deleteOrphanPhoto(String docId) async {
    try {
      await storageService.delete(docId).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Compensación de mejor esfuerzo (research.md §4): el resultado no
      // afecta el Failure ya determinado por el error original. Sin conexión
      // puede quedar un blob huérfano — limitación aceptada (feature 002).
    }
  }

  Failure _mapFirebaseException(FirebaseException e) {
    if (e.code == 'unavailable' || e.code == 'network-request-failed') {
      return const NetworkFailure();
    }
    return const ServerFailure();
  }
}
