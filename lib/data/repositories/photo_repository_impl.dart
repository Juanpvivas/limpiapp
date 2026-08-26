import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/failure.dart';
import '../../domain/models/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../services/permission_service.dart';
import '../services/photo/photo_capture_service.dart';
import '../services/photo/photo_compressor_service.dart';

/// `permission_handler` → captura → compresión (research.md §5, §7).
class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl({
    required this.permissionService,
    required this.captureService,
    required this.compressorService,
  });

  final PermissionService permissionService;
  final PhotoCaptureService captureService;
  final PhotoCompressorService compressorService;

  @override
  Future<Either<Failure, Photo?>> pickFromCamera() => _pickAndCompress(
    permissionService.requestCamera,
    captureService.pickFromCamera,
  );

  @override
  Future<Either<Failure, Photo?>> pickFromGallery() => _pickAndCompress(
    permissionService.requestPhotos,
    captureService.pickFromGallery,
  );

  Future<Either<Failure, Photo?>> _pickAndCompress(
    Future<bool> Function() requestPermission,
    Future<XFile?> Function() capture,
  ) async {
    final granted = await requestPermission();
    if (!granted) {
      return const Left(PermissionFailure());
    }

    try {
      final file = await capture();
      if (file == null) {
        // Usuario canceló la captura/selección — no es un error (ver
        // domain/repositories/photo_repository.dart).
        return const Right(null);
      }

      final originalBytes = await file.readAsBytes();
      final compressedBytes = await compressorService.compress(originalBytes);

      return Right(
        Photo(bytes: compressedBytes, sizeBytes: compressedBytes.lengthInBytes),
      );
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
