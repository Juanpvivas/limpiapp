import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:limpiapp/config/service_locator.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:limpiapp/domain/models/new_report_draft.dart';
import 'package:limpiapp/domain/models/photo.dart';
import 'package:limpiapp/domain/models/report.dart';
import 'package:limpiapp/domain/models/report_status.dart';
import 'package:limpiapp/domain/models/report_location.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/domain/repositories/location_repository.dart';
import 'package:limpiapp/domain/repositories/photo_repository.dart';
import 'package:limpiapp/domain/repositories/report_repository.dart';
import 'package:limpiapp/ui/reports/providers/new_report_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

class _MockPhotoRepository extends Mock implements PhotoRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late _MockReportRepository reportRepository;
  late _MockPhotoRepository photoRepository;
  late _MockLocationRepository locationRepository;
  late ProviderContainer container;

  final photo = Photo(bytes: Uint8List.fromList([1, 2, 3]), sizeBytes: 3);
  const autoLocation = ReportLocation(automaticAddress: 'Calle 5 # 10-20');
  final report = Report(
    id: 'doc123',
    reportNumber: '#IL-2026-000125',
    category: WasteCategory.basuraAcumulada,
    description: '',
    address: 'Calle 5 # 10-20',
    photoUrl: 'https://storage/doc123.jpg',
    createdAt: DateTime(2026),
    status: ReportStatus.pendiente,
    deviceId: 'device-abc',
  );

  setUpAll(() {
    registerFallbackValue(
      NewReportDraft(
        photo: Photo(bytes: Uint8List.fromList([0]), sizeBytes: 1),
        category: WasteCategory.otros,
        description: '',
        location: const ReportLocation(automaticAddress: 'fallback'),
      ),
    );
  });

  setUp(() async {
    reportRepository = _MockReportRepository();
    photoRepository = _MockPhotoRepository();
    locationRepository = _MockLocationRepository();

    await getIt.reset();
    getIt.registerLazySingleton<ReportRepository>(() => reportRepository);
    getIt.registerLazySingleton<PhotoRepository>(() => photoRepository);
    getIt.registerLazySingleton<LocationRepository>(() => locationRepository);

    when(() => locationRepository.getCurrentLocation())
        .thenAnswer((_) async => const Right(autoLocation));

    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  // `newReportProvider` es autoDispose: sin un listener activo, Riverpod
  // podría destruirlo antes de que termine el Future de
  // `_loadAutomaticLocation()`/`submit()`, tirando el resto del test. Se
  // llama al inicio de cada test (no en `setUp`) para que dispare `build()`
  // ya con los stubs de ese test (ej. ubicación fallida) en vigor.
  void keepAlive() => container.listen(newReportProvider, (_, _) {});

  test('estado inicial: isLoadingLocation en true hasta que resuelve la '
      'ubicación automática', () async {
    keepAlive();
    final initial = container.read(newReportProvider);
    expect(initial.photo, isNull);
    expect(initial.category, isNull);
    expect(initial.isLoadingLocation, isTrue);

    await Future<void>.delayed(Duration.zero);

    final afterLoad = container.read(newReportProvider);
    expect(afterLoad.isLoadingLocation, isFalse);
    expect(afterLoad.autoLocation, autoLocation);
  });

  test('canSubmit se habilita con foto válida + categoría + ubicación '
      'automática', () async {
    keepAlive();
    final notifier = container.read(newReportProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(newReportProvider).canSubmit, isFalse);

    when(() => photoRepository.pickFromCamera())
        .thenAnswer((_) async => Right(photo));
    await notifier.pickPhotoFromCamera();
    notifier.setCategory(WasteCategory.basuraAcumulada);

    expect(container.read(newReportProvider).canSubmit, isTrue);
  });

  test('submit() exitoso retorna el Report al caller sin guardarlo en el '
      'state, y navega (el widget decide con ese valor)', () async {
    keepAlive();
    final notifier = container.read(newReportProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    when(() => photoRepository.pickFromCamera())
        .thenAnswer((_) async => Right(photo));
    await notifier.pickPhotoFromCamera();
    notifier.setCategory(WasteCategory.basuraAcumulada);

    when(() => reportRepository.submitReport(any()))
        .thenAnswer((_) async => Right(report));

    final result = await notifier.submit();

    expect(result, report);
    expect(container.read(newReportProvider).isSubmitting, isFalse);
    expect(container.read(newReportProvider).submitError, isNull);
  });

  test('ubicación automática falla: canSubmit permanece false hasta llenar '
      'dirección manual, luego se habilita (US2)', () async {
    when(() => locationRepository.getCurrentLocation())
        .thenAnswer((_) async => const Left(PermissionFailure()));
    keepAlive();

    final notifier = container.read(newReportProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    when(() => photoRepository.pickFromCamera())
        .thenAnswer((_) async => Right(photo));
    await notifier.pickPhotoFromCamera();
    notifier.setCategory(WasteCategory.basuraAcumulada);

    expect(container.read(newReportProvider).canSubmit, isFalse);

    notifier.setManualAddress('Calle 9 # 3-45');

    expect(container.read(newReportProvider).canSubmit, isTrue);
  });

  test('submit() falla: isSubmitting vuelve a false, submitError se setea, '
      'y el resto del state permanece intacto (US3/SC-004)', () async {
    keepAlive();
    final notifier = container.read(newReportProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    when(() => photoRepository.pickFromCamera())
        .thenAnswer((_) async => Right(photo));
    await notifier.pickPhotoFromCamera();
    notifier.setCategory(WasteCategory.basuraAcumulada);
    notifier.setDescription('Huele muy mal');

    when(() => reportRepository.submitReport(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await notifier.submit();

    expect(result, isNull);
    final state = container.read(newReportProvider);
    expect(state.isSubmitting, isFalse);
    expect(state.submitError, isNotNull);
    expect(state.photo, photo);
    expect(state.category, WasteCategory.basuraAcumulada);
    expect(state.description, 'Huele muy mal');
  });

  test('permiso de foto denegado activa showPermissionDeniedAlert, y '
      'dismissPermissionAlert() lo resetea (US3)', () async {
    keepAlive();
    final notifier = container.read(newReportProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    when(() => photoRepository.pickFromCamera())
        .thenAnswer((_) async => const Left(PermissionFailure()));

    await notifier.pickPhotoFromCamera();
    expect(container.read(newReportProvider).showPermissionDeniedAlert, isTrue);

    notifier.dismissPermissionAlert();
    expect(
      container.read(newReportProvider).showPermissionDeniedAlert,
      isFalse,
    );
  });
}
