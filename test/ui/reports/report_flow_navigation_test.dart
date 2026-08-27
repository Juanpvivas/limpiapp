import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiapp/config/routes.dart';
import 'package:limpiapp/config/service_locator.dart';
import 'package:limpiapp/domain/models/new_report_draft.dart';
import 'package:limpiapp/domain/models/photo.dart';
import 'package:limpiapp/domain/models/report.dart';
import 'package:limpiapp/domain/models/report_location.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/domain/repositories/location_repository.dart';
import 'package:limpiapp/domain/repositories/photo_repository.dart';
import 'package:limpiapp/domain/repositories/report_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

class _MockPhotoRepository extends Mock implements PhotoRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

/// Regresión de las issues #27 y #28, usando `buildAppRouter()` (el árbol de
/// rutas real de la app, con `StatefulShellRoute.indexedStack`) en vez de un
/// router aislado — ambos bugs solo se manifiestan con esa estructura real.
void main() {
  late _MockReportRepository reportRepository;
  late _MockPhotoRepository photoRepository;
  late _MockLocationRepository locationRepository;

  // PNG 1x1 transparente válido (ver new_report_screen_test.dart).
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
  final report = Report(
    reportNumber: '#IL-2026-000125',
    category: WasteCategory.basuraAcumulada,
    description: '',
    address: 'Calle 5 # 10-20',
    photoUrl: 'https://storage/doc123.jpg',
    createdAt: DateTime(2026),
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
    photo = Photo(bytes: validPngBytes, sizeBytes: validPngBytes.length);

    await getIt.reset();
    getIt.registerLazySingleton<ReportRepository>(() => reportRepository);
    getIt.registerLazySingleton<PhotoRepository>(() => photoRepository);
    getIt.registerLazySingleton<LocationRepository>(() => locationRepository);

    when(() => locationRepository.getCurrentLocation())
        .thenAnswer((_) async => const Right(autoLocation));
    when(() => photoRepository.pickFromCamera())
        .thenAnswer((_) async => Right(photo));
    when(() => reportRepository.submitReport(any()))
        .thenAnswer((_) async => Right(report));
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GoRouter router = buildAppRouter();
    router.go(AppTab.reportar.path);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Tomar foto'));
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();

    final dropdown = find.byType(DropdownButtonFormField<WasteCategory>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basura acumulada').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Enviar reporte'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'issue #28: "Confirmación" no muestra la barra de navegación inferior',
    (tester) async {
      await pumpApp(tester);
      await fillAndSubmit(tester);

      expect(find.text('#IL-2026-000125'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets('issue #27: al volver a "Reportar" tras un envío exitoso, el '
      'formulario aparece vacío (no conserva la foto/categoría anteriores)', (
    tester,
  ) async {
    await pumpApp(tester);
    await fillAndSubmit(tester);

    // Vuelve a Inicio y luego a Reportar, simulando que el usuario abre
    // un reporte nuevo después de haber enviado uno.
    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reportar'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo reporte'), findsOneWidget);
    // Recuadro de foto vacío otra vez (ícono placeholder, no la imagen).
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    // El dropdown vuelve a mostrar el hint, no "Basura acumulada".
    expect(find.text('Selecciona una categoría'), findsOneWidget);
    expect(find.text('Basura acumulada'), findsNothing);
  });
}
