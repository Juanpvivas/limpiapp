import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:limpiapp/data/repositories/photo_repository_impl.dart';
import 'package:limpiapp/data/services/permission_service.dart';
import 'package:limpiapp/data/services/photo/photo_capture_service.dart';
import 'package:limpiapp/data/services/photo/photo_compressor_service.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:limpiapp/domain/models/photo.dart';
import 'package:mocktail/mocktail.dart';

class _MockPermissionService extends Mock implements PermissionService {}

class _MockPhotoCaptureService extends Mock implements PhotoCaptureService {}

class _MockPhotoCompressorService extends Mock
    implements PhotoCompressorService {}

class _FakeXFile extends Fake implements XFile {
  _FakeXFile(this._bytes);
  final Uint8List _bytes;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}

void main() {
  late _MockPermissionService permissionService;
  late _MockPhotoCaptureService captureService;
  late _MockPhotoCompressorService compressorService;
  late PhotoRepositoryImpl repository;

  setUp(() {
    permissionService = _MockPermissionService();
    captureService = _MockPhotoCaptureService();
    compressorService = _MockPhotoCompressorService();
    repository = PhotoRepositoryImpl(
      permissionService: permissionService,
      captureService: captureService,
      compressorService: compressorService,
    );
  });

  group('pickFromCamera', () {
    test(
      'caso feliz: permiso concedido + captura + compresión ≤2 MB',
      () async {
        final originalBytes = Uint8List.fromList(List.filled(10, 1));
        final compressedBytes = Uint8List.fromList(List.filled(5, 1));

        when(() => permissionService.requestCamera())
            .thenAnswer((_) async => true);
        when(() => captureService.pickFromCamera())
            .thenAnswer((_) async => _FakeXFile(originalBytes));
        when(() => compressorService.compress(originalBytes))
            .thenAnswer((_) async => compressedBytes);

        final result = await repository.pickFromCamera();

        expect(result.isRight(), isTrue);
        result.match((_) => fail('esperaba Right'), (photo) {
          expect(photo, isNotNull);
          expect(photo!.sizeBytes, 5);
          expect(photo.exceedsMaxSize, isFalse);
        });
      },
    );

    test('permiso denegado retorna Left(PermissionFailure)', () async {
      when(() => permissionService.requestCamera())
          .thenAnswer((_) async => false);

      final result = await repository.pickFromCamera();

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<PermissionFailure>()),
        (_) => fail('esperaba Left'),
      );
      verifyNever(() => captureService.pickFromCamera());
    });

    test('foto que sigue pesando >2 MB tras comprimirse es Right con '
        'exceedsMaxSize == true (no es un Failure)', () async {
      final originalBytes = Uint8List.fromList(List.filled(10, 1));
      final tooLargeBytes = Uint8List(Photo.maxPhotoBytes + 1);

      when(() => permissionService.requestCamera())
          .thenAnswer((_) async => true);
      when(() => captureService.pickFromCamera())
          .thenAnswer((_) async => _FakeXFile(originalBytes));
      when(() => compressorService.compress(originalBytes))
          .thenAnswer((_) async => tooLargeBytes);

      final result = await repository.pickFromCamera();

      expect(result.isRight(), isTrue);
      result.match((_) => fail('esperaba Right'), (photo) {
        expect(photo!.exceedsMaxSize, isTrue);
      });
    });

    test('cancelación del usuario (XFile null) retorna Right(null)', () async {
      when(() => permissionService.requestCamera())
          .thenAnswer((_) async => true);
      when(() => captureService.pickFromCamera()).thenAnswer((_) async => null);

      final result = await repository.pickFromCamera();

      expect(result.isRight(), isTrue);
      result.match((_) => fail('esperaba Right'), (photo) {
        expect(photo, isNull);
      });
    });
  });
}
