import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../domain/models/photo.dart';

/// Secuencia fija de intentos de compresión hasta lograr ≤2 MB o agotar los
/// intentos (research.md §7): degrada primero calidad y luego resolución,
/// para preservar mejor el detalle útil de la foto de un punto sucio.
class PhotoCompressorService {
  static const _attempts = [
    (quality: 88, minWidth: 1920),
    (quality: 70, minWidth: 1920),
    (quality: 50, minWidth: 1280),
    (quality: 35, minWidth: 1024),
  ];

  /// El resultado final (haya o no bajado de 2 MB) siempre se retorna: la
  /// compresión en sí nunca produce un `Failure` (research.md §7) — es
  /// `Photo.exceedsMaxSize` quien decide si bloquea el envío.
  Future<Uint8List> compress(Uint8List originalBytes) async {
    var bestResult = originalBytes;

    for (final attempt in _attempts) {
      final result = await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: attempt.quality,
        minWidth: attempt.minWidth,
      );
      bestResult = result;
      if (result.lengthInBytes <= Photo.maxPhotoBytes) {
        return result;
      }
    }

    return bestResult;
  }
}
