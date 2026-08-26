import 'package:fpdart/fpdart.dart';

import '../models/failure.dart';
import '../models/photo.dart';

/// Un `Left` solo ocurre por permiso denegado o error del picker/compresor;
/// una foto que sigue pesando >2 MB tras comprimirse **no** es un `Left`, es
/// un `Right(Photo)` con `exceedsMaxSize == true` (research.md §7).
///
/// `Right(null)` representa que el usuario canceló la captura/selección
/// después de haber concedido el permiso (`image_picker` retorna `null` en
/// ese caso) — no es un error y no debe disparar la alerta de FR-005, que
/// es exclusiva de un permiso efectivamente denegado.
abstract class PhotoRepository {
  Future<Either<Failure, Photo?>> pickFromCamera();
  Future<Either<Failure, Photo?>> pickFromGallery();
}
