import 'package:fpdart/fpdart.dart';

import '../../domain/models/failure.dart';
import '../../domain/repositories/device_identifier_repository.dart';
import '../services/device_identifier_service.dart';

/// Implementa `DeviceIdentifierRepository` sobre `DeviceIdentifierService`.
/// Cualquier excepción del almacenamiento local se captura y se mapea a
/// `CacheFailure` (Principio V) — nunca cruza como excepción cruda.
class DeviceIdentifierRepositoryImpl implements DeviceIdentifierRepository {
  DeviceIdentifierRepositoryImpl(this._service);

  final DeviceIdentifierService _service;

  @override
  Future<Either<Failure, String>> getDeviceId() async {
    try {
      return Right(await _service.getOrCreateDeviceId());
    } catch (_) {
      return const Left(CacheFailure());
    }
  }
}
