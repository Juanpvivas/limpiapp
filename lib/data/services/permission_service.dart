import 'package:permission_handler/permission_handler.dart';

/// Wrapper delgado sobre `permission_handler` (research.md §5, §8) — punto
/// único de solicitud de permisos, inyectable para poder mockearse con
/// `mocktail` en los tests de `PhotoRepositoryImpl`/`LocationRepositoryImpl`
/// sin depender de canales de plataforma reales.
class PermissionService {
  Future<bool> requestCamera() async =>
      (await Permission.camera.request()).isGranted;

  Future<bool> requestPhotos() async =>
      (await Permission.photos.request()).isGranted;

  Future<bool> requestLocation() async =>
      (await Permission.location.request()).isGranted;
}
