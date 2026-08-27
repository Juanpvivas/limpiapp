import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:limpiapp/data/repositories/report_repository_impl.dart';
import 'package:limpiapp/data/services/firebase/report_firestore_service.dart';
import 'package:limpiapp/data/services/firebase/report_storage_service.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:limpiapp/domain/models/new_report_draft.dart';
import 'package:limpiapp/domain/models/photo.dart';
import 'package:limpiapp/domain/models/report_location.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/domain/repositories/device_identifier_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportFirestoreService extends Mock
    implements ReportFirestoreService {}

class _MockReportStorageService extends Mock implements ReportStorageService {}

class _MockDeviceIdentifierRepository extends Mock
    implements DeviceIdentifierRepository {}

void main() {
  late _MockReportFirestoreService firestoreService;
  late _MockReportStorageService storageService;
  late _MockDeviceIdentifierRepository deviceIdentifierRepository;
  late ReportRepositoryImpl repository;

  final draft = NewReportDraft(
    photo: Photo(bytes: Uint8List.fromList([1, 2, 3]), sizeBytes: 3),
    category: WasteCategory.basuraAcumulada,
    description: 'Basura acumulada hace días',
    location: const ReportLocation(automaticAddress: 'Calle 5 # 10-20'),
  );

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    firestoreService = _MockReportFirestoreService();
    storageService = _MockReportStorageService();
    deviceIdentifierRepository = _MockDeviceIdentifierRepository();
    repository = ReportRepositoryImpl(
      firestoreService: firestoreService,
      storageService: storageService,
      deviceIdentifierRepository: deviceIdentifierRepository,
    );

    when(() => firestoreService.reserveDocId()).thenReturn('doc123');
    when(() => deviceIdentifierRepository.getDeviceId())
        .thenAnswer((_) async => const Right('device-abc'));
  });

  group('submitReport', () {
    test('caso feliz: sube la foto, crea el documento y retorna Report con '
        'reportNumber', () async {
      when(() => storageService.upload('doc123', draft.photo.bytes))
          .thenAnswer((_) async => 'https://storage/doc123.jpg');
      when(
        () => firestoreService.createReport(
          docId: 'doc123',
          reportData: any(named: 'reportData'),
        ),
      ).thenAnswer((_) async => '#IL-2026-000125');

      final result = await repository.submitReport(draft);

      expect(result.isRight(), isTrue);
      result.match((_) => fail('esperaba Right'), (report) {
        expect(report.id, 'doc123');
        expect(report.reportNumber, '#IL-2026-000125');
        expect(report.photoUrl, 'https://storage/doc123.jpg');
        expect(report.address, 'Calle 5 # 10-20');
        expect(report.deviceId, 'device-abc');
      });
      verifyNever(() => storageService.delete(any()));
    });

    test('escribe status "pendiente" y el deviceId resuelto en el mapa '
        'enviado a Firestore (US1 — FR-003)', () async {
      when(() => storageService.upload('doc123', draft.photo.bytes))
          .thenAnswer((_) async => 'https://storage/doc123.jpg');
      when(
        () => firestoreService.createReport(
          docId: 'doc123',
          reportData: any(named: 'reportData'),
        ),
      ).thenAnswer((_) async => '#IL-2026-000125');

      await repository.submitReport(draft);

      final captured =
          verify(
                () => firestoreService.createReport(
                  docId: 'doc123',
                  reportData: captureAny(named: 'reportData'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['status'], 'pendiente');
      expect(captured['deviceId'], 'device-abc');
    });

    test('si no se puede resolver el deviceId, retorna Left y no toca '
        'Storage ni Firestore', () async {
      when(() => deviceIdentifierRepository.getDeviceId())
          .thenAnswer((_) async => const Left(CacheFailure()));

      final result = await repository.submitReport(draft);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('esperaba Left'),
      );
      // El impl resuelve el deviceId antes de reservar el docId o tocar
      // Storage: si falla, no llega a ninguno de esos pasos.
      verifyNever(() => firestoreService.reserveDocId());
      verifyNever(
        () => firestoreService.createReport(
          docId: any(named: 'docId'),
          reportData: any(named: 'reportData'),
        ),
      );
    });

    test('si la transacción de Firestore falla, borra la foto ya subida '
        '(rollback) y retorna Left', () async {
      when(() => storageService.upload('doc123', draft.photo.bytes))
          .thenAnswer((_) async => 'https://storage/doc123.jpg');
      when(
        () => firestoreService.createReport(
          docId: 'doc123',
          reportData: any(named: 'reportData'),
        ),
      ).thenThrow(FirebaseException(plugin: 'cloud_firestore'));
      when(() => storageService.delete('doc123')).thenAnswer((_) async {});

      final result = await repository.submitReport(draft);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('esperaba Left'),
      );
      verify(() => storageService.delete('doc123')).called(1);
    });

    test(
      'si la subida de la foto falla, no intenta crear el documento',
      () async {
        when(() => storageService.upload('doc123', draft.photo.bytes))
            .thenThrow(FirebaseException(plugin: 'firebase_storage'));

        final result = await repository.submitReport(draft);

        expect(result.isLeft(), isTrue);
        verifyNever(
          () => firestoreService.createReport(
            docId: any(named: 'docId'),
            reportData: any(named: 'reportData'),
          ),
        );
      },
    );
  });
}
