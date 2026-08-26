import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo.freezed.dart';

/// Foto ya procesada (después de compresión), lista para enviarse o para
/// bloquear el envío si sigue pesando de más (FR-004, FR-006).
@freezed
abstract class Photo with _$Photo {
  const factory Photo({required Uint8List bytes, required int sizeBytes}) =
      _Photo;

  const Photo._();

  /// Límite de tamaño de foto: 2 MB (FR-004/FR-006).
  static const int maxPhotoBytes = 2 * 1024 * 1024;

  /// Regla de negocio derivada, pura: decide si se muestra el texto rojo de
  /// "imagen muy grande" y si se bloquea el envío (research.md §7).
  bool get exceedsMaxSize => sizeBytes > maxPhotoBytes;
}
