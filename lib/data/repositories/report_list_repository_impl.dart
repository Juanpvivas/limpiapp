import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/models/failure.dart';
import '../../domain/models/report.dart';
import '../../domain/repositories/report_list_repository.dart';
import '../model/report_dto.dart';
import '../services/connectivity_service.dart';
import '../services/firebase/report_query_service.dart';

/// Mapea los streams planos de `ReportQueryService` a `Report` (vía
/// `ReportDto.fromFirestore`), envueltos en `Either`. Un error del stream
/// subyacente (ej. `permission-denied`, sin conexión) se intercepta con un
/// `StreamTransformer` y se emite como `Left(Failure)` dentro del stream —
/// nunca como un error de stream sin capturar (research.md §3).
///
/// Además, si `.snapshots()` no entrega su **primera** emisión dentro de
/// [defaultFirstSnapshotTimeout], se inyecta un `Left(NetworkFailure())`
/// (issue #3). Sin conexión y sin caché local previa (instalación nueva que
/// nunca sincronizó), `.snapshots()` ni emite ni falla: espera conectividad
/// indefinidamente y la pantalla se queda en el spinner. El timeout se
/// desarma tras la primera emisión: un stream en tiempo real puede quedarse
/// legítimamente quieto sin que eso sea un fallo (`watchReportById` incluido:
/// `Right(null)` de "no existe" también cuenta como primera emisión).
///
/// Feature 005: cada emisión reporta al [ConnectivityService] si se pudo o no
/// llegar al backend — `Left(NetworkFailure)` → `reportBackendUnreachable()`,
/// cualquier `Right` → `reportBackendReachable()`, `Left(ServerFailure)` no
/// toca el contador (el backend respondió).
class ReportListRepositoryImpl implements ReportListRepository {
  // Param con nombre público a propósito: Dart no permite
  // `this._firstSnapshotTimeout` como parámetro con nombre privado, así que
  // no se puede usar un initializing formal aquí.
  ReportListRepositoryImpl(
    this._queryService,
    this._connectivity, {
    Duration firstSnapshotTimeout = defaultFirstSnapshotTimeout,
    // ignore: prefer_initializing_formals
  }) : _firstSnapshotTimeout = firstSnapshotTimeout;

  /// Ventana máxima para la primera emisión de `.snapshots()` antes de
  /// asumir "sin conexión" (issue #3). 10 s cubre un arranque en frío con
  /// red pobre y sigue por debajo del umbral de paciencia del usuario
  /// (criterio de aceptación del issue: estado de error en ≤ ~10 s).
  static const defaultFirstSnapshotTimeout = Duration(seconds: 10);

  final ReportQueryService _queryService;
  final ConnectivityService _connectivity;
  final Duration _firstSnapshotTimeout;

  @override
  Stream<Either<Failure, List<Report>>> watchReports(String deviceId) {
    final reports = _queryService
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
    return _failIfNoFirstEvent(
      reports,
      const Left<Failure, List<Report>>(NetworkFailure()),
    ).map(_reportConnectivity);
  }

  @override
  Stream<Either<Failure, Report?>> watchReportById(String reportId) {
    final report = _queryService
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
    return _failIfNoFirstEvent(
      report,
      const Left<Failure, Report?>(NetworkFailure()),
    ).map(_reportConnectivity);
  }

  /// Alimenta el contador de conectividad (feature 005) a partir de cada
  /// emisión, y la reemite tal cual.
  Either<Failure, T> _reportConnectivity<T>(Either<Failure, T> result) {
    result.match((failure) {
      if (failure is NetworkFailure) _connectivity.reportBackendUnreachable();
    }, (_) => _connectivity.reportBackendReachable());
    return result;
  }

  Failure _mapError(Object error) {
    if (error is FirebaseException &&
        (error.code == 'unavailable' ||
            error.code == 'network-request-failed')) {
      return const NetworkFailure();
    }
    return const ServerFailure();
  }

  /// Reemite [source] tal cual, pero si no produce ningún evento (dato, error
  /// o cierre) dentro de [_firstSnapshotTimeout], inyecta [fallback] una sola
  /// vez. Tras el primer evento real el temporizador se cancela para
  /// siempre; si más tarde llega conectividad, los eventos `Right` posteriores
  /// se propagan y la UI se recupera. Single-subscription, igual que el
  /// stream de Firestore que envuelve.
  Stream<T> _failIfNoFirstEvent<T>(Stream<T> source, T fallback) {
    final controller = StreamController<T>();
    var firstEventSeen = false;
    Timer? timer;
    StreamSubscription<T>? subscription;

    void markFirstEvent() {
      if (firstEventSeen) return;
      firstEventSeen = true;
      timer?.cancel();
      timer = null;
    }

    controller.onListen = () {
      timer = Timer(_firstSnapshotTimeout, () {
        if (firstEventSeen || controller.isClosed) return;
        markFirstEvent();
        controller.add(fallback);
      });
      subscription = source.listen(
        (event) {
          markFirstEvent();
          controller.add(event);
        },
        onError: (Object error, StackTrace stackTrace) {
          markFirstEvent();
          controller.addError(error, stackTrace);
        },
        onDone: () {
          markFirstEvent();
          controller.close();
        },
      );
    };
    controller.onCancel = () {
      timer?.cancel();
      timer = null;
      return subscription?.cancel();
    };

    return controller.stream;
  }
}
