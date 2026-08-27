import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/models/failure.dart';
import '../../domain/models/report.dart';
import '../../domain/repositories/report_list_repository.dart';
import '../model/report_dto.dart';
import '../services/firebase/report_query_service.dart';

/// Mapea los streams planos de `ReportQueryService` a `Report` (vía
/// `ReportDto.fromFirestore`), envueltos en `Either`. Un error del stream
/// subyacente (ej. `permission-denied`, sin conexión) se intercepta con un
/// `StreamTransformer` y se emite como `Left(Failure)` dentro del stream —
/// nunca como un error de stream sin capturar (research.md §3).
class ReportListRepositoryImpl implements ReportListRepository {
  ReportListRepositoryImpl(this._queryService);

  final ReportQueryService _queryService;

  @override
  Stream<Either<Failure, List<Report>>> watchReports(String deviceId) {
    return _queryService
        .watchReportsByDevice(deviceId)
        .transform(
          StreamTransformer<
            List<FirestoreRecord>,
            Either<Failure, List<Report>>
          >.fromHandlers(
            handleData: (records, sink) => sink.add(
              Right(
                records
                    .map(
                      (record) => ReportDto.fromFirestore(
                        id: record.id,
                        data: record.data,
                      ),
                    )
                    .toList(),
              ),
            ),
            handleError: (error, stackTrace, sink) =>
                sink.add(Left(_mapError(error))),
          ),
        );
  }

  @override
  Stream<Either<Failure, Report?>> watchReportById(String reportId) {
    return _queryService
        .watchReportById(reportId)
        .transform(
          StreamTransformer<
            FirestoreRecord?,
            Either<Failure, Report?>
          >.fromHandlers(
            handleData: (record, sink) => sink.add(
              Right(
                record == null
                    ? null
                    : ReportDto.fromFirestore(id: record.id, data: record.data),
              ),
            ),
            handleError: (error, stackTrace, sink) =>
                sink.add(Left(_mapError(error))),
          ),
        );
  }

  Failure _mapError(Object error) {
    if (error is FirebaseException &&
        (error.code == 'unavailable' ||
            error.code == 'network-request-failed')) {
      return const NetworkFailure();
    }
    return const ServerFailure();
  }
}
