import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiapp/config/service_locator.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:limpiapp/domain/models/new_report_draft.dart';
import 'package:limpiapp/domain/models/photo.dart';
import 'package:limpiapp/domain/models/report.dart';
import 'package:limpiapp/domain/models/report_location.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/domain/repositories/location_repository.dart';
import 'package:limpiapp/domain/repositories/photo_repository.dart';
import 'package:limpiapp/domain/repositories/report_repository.dart';
import 'package:limpiapp/ui/reports/widgets/new_report_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

class _MockPhotoRepository extends Mock implements PhotoRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late _MockReportRepository reportRepository;
  late _MockPhotoRepository photoRepository;
  late _MockLocationRepository locationRepository;

  // PNG 1x1 transparente válido: `PhotoPickerCard` renderiza `photo.bytes`
  // con `Image.memory`, que fallaría al decodificar bytes arbitrarios.
  final validPngBytes = Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);
  late Photo photo;
  const autoLocation = ReportLocation(automaticAddress: 'Calle 5 # 10-20');

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

  Future<void> pumpScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/reportar',
      routes: [
        GoRoute(
          path: '/reportar',
          builder: (context, state) => const NewReportScreen(),
          routes: [
            GoRoute(
              path: 'confirmacion',
              builder: (context, state) => Scaffold(
                body: Text(
                  'CONFIRMACION ${(state.extra! as Report).reportNumber}',
                ),
              ),
            ),
          ],
        ),
      ],
    );

    // Viewport tipo teléfono: el formulario completo no cabe en el tamaño
    // por defecto de flutter_test (800x600) y los taps fallarían por
    // hit-test fuera de pantalla en vez de por scroll.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addValidPhoto(WidgetTester tester) async {
    when(() => photoRepository.pickFromCamera())
        .thenAnswer((_) async => Right(photo));
    await tester.ensureVisible(find.text('Tomar foto'));
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
  }

  Future<void> selectCategory(WidgetTester tester) async {
    final dropdown = find.byType(DropdownButtonFormField<WasteCategory>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basura acumulada').last);
    await tester.pumpAndSettle();
  }

  setUp(() async {
    reportRepository = _MockReportRepository();
    photoRepository = _MockPhotoRepository();
    locationRepository = _MockLocationRepository();
    photo = Photo(bytes: validPngBytes, sizeBytes: validPngBytes.length);

    await getIt.reset();
    getIt.registerLazySingleton<ReportRepository>(() => reportRepository);
    getIt.registerLazySingleton<PhotoRepository>(() => photoRepository);
    getIt.registerLazySingleton<LocationRepository>(() => locationRepository);

    when(() => locationRepository.getCurrentLocation())
        .thenAnswer((_) async => const Right(autoLocation));
  });

  testWidgets(
    'completar foto + categoría + ubicación habilita "Enviar reporte"; al '
    'enviar, bloquea toques y el botón atrás mientras dura (FR-016)',
    (tester) async {
      await pumpScreen(tester);
      await addValidPhoto(tester);
      await selectCategory(tester);

      final submitButton = find.widgetWithText(FilledButton, 'Enviar reporte');
      expect(tester.widget<FilledButton>(submitButton).onPressed, isNotNull);

      when(() => reportRepository.submitReport(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Right(
          Report(
            reportNumber: '#IL-2026-000125',
            category: WasteCategory.basuraAcumulada,
            description: '',
            address: 'Calle 5 # 10-20',
            photoUrl: 'https://storage/doc123.jpg',
            createdAt: DateTime(2026),
          ),
        );
      });

      await tester.tap(submitButton);
      await tester.pump();

      // Mientras se envía: overlay bloqueante visible y PopScope no permite
      // salir con el botón atrás.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);

      await tester.pumpAndSettle();

      expect(find.text('CONFIRMACION #IL-2026-000125'), findsOneWidget);
    },
  );

  testWidgets('sin ubicación automática, "Dirección manual" es obligatoria y '
      'bloquea el envío hasta llenarla (US2)', (tester) async {
    when(() => locationRepository.getCurrentLocation())
        .thenAnswer((_) async => const Left(PermissionFailure()));

    await pumpScreen(tester);
    await addValidPhoto(tester);
    await selectCategory(tester);

    expect(find.text('Dirección manual (obligatoria)'), findsOneWidget);
    var submitButton = find.widgetWithText(FilledButton, 'Enviar reporte');
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'Calle 9 # 3-45');
    await tester.pumpAndSettle();

    submitButton = find.widgetWithText(FilledButton, 'Enviar reporte');
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNotNull);
  });

  testWidgets(
    'permiso de cámara/galería denegado muestra la alerta obligatoria '
    '(FR-005)',
    (tester) async {
      when(() => photoRepository.pickFromCamera())
          .thenAnswer((_) async => const Left(PermissionFailure()));

      await pumpScreen(tester);
      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();

      expect(find.text('Foto obligatoria'), findsOneWidget);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(find.text('Foto obligatoria'), findsNothing);
    },
  );

  testWidgets(
    'foto que sigue pesando >2 MB tras comprimirse muestra el texto rojo '
    'y no habilita el envío (FR-006)',
    (tester) async {
      final tooLargePhoto = Photo(
        bytes: validPngBytes,
        sizeBytes: Photo.maxPhotoBytes + 1,
      );
      when(() => photoRepository.pickFromCamera())
          .thenAnswer((_) async => Right(tooLargePhoto));

      await pumpScreen(tester);
      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();

      expect(
        find.text('La imagen es muy grande. Toma o elige otra foto.'),
        findsOneWidget,
      );

      final submitButton = find.widgetWithText(FilledButton, 'Enviar reporte');
      expect(tester.widget<FilledButton>(submitButton).onPressed, isNull);
    },
  );

  testWidgets(
    'fallo de envío (ej. sin conexión) muestra un mensaje, no navega, y '
    'conserva los datos ingresados (FR-017, SC-004)',
    (tester) async {
      await pumpScreen(tester);
      await addValidPhoto(tester);
      await selectCategory(tester);

      when(() => reportRepository.submitReport(any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      await tester.tap(find.widgetWithText(FilledButton, 'Enviar reporte'));
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo enviar el reporte. Intenta de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Nuevo reporte'), findsOneWidget);
      // Los datos siguen ahí: la foto sigue mostrada y el botón vuelve a
      // habilitarse (canSubmit no cambió).
      final submitButton = find.widgetWithText(FilledButton, 'Enviar reporte');
      expect(tester.widget<FilledButton>(submitButton).onPressed, isNotNull);
    },
  );
}
