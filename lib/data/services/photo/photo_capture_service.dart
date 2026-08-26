import 'package:image_picker/image_picker.dart';

/// Wrapper delgado sobre `image_picker` (research.md §8). Se invoca
/// únicamente después de confirmar el permiso concedido vía
/// `permission_handler` (research.md §5) — nunca dispara su propio flujo de
/// solicitud de permiso.
class PhotoCaptureService {
  PhotoCaptureService(this._picker);

  final ImagePicker _picker;

  /// `null` si el usuario cancela la captura sin tomar ninguna foto.
  Future<XFile?> pickFromCamera() =>
      _picker.pickImage(source: ImageSource.camera);

  /// `null` si el usuario cancela la selección sin elegir ninguna foto.
  Future<XFile?> pickFromGallery() =>
      _picker.pickImage(source: ImageSource.gallery);
}
