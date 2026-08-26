import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiapp/config/routes.dart';
import 'package:limpiapp/config/service_locator.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:limpiapp/domain/repositories/location_repository.dart';
import 'package:limpiapp/domain/repositories/photo_repository.dart';
import 'package:limpiapp/domain/repositories/report_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

class _MockPhotoRepository extends Mock implements PhotoRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerLazySingleton<ReportRepository>(
      () => _MockReportRepository(),
    );
    getIt.registerLazySingleton<PhotoRepository>(() => _MockPhotoRepository());
    final locationRepository = _MockLocationRepository();
    when(() => locationRepository.getCurrentLocation())
        .thenAnswer((_) async => const Left(PermissionFailure()));
    getIt.registerLazySingleton<LocationRepository>(() => locationRepository);
  });

  Future<void> pumpAppAt(WidgetTester tester, {String location = '/'}) async {
    final GoRouter router = buildAppRouter();
    router.go(location);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
  }

  group('HomeScreen (US1 — FR-001 a FR-005)', () {
    testWidgets('muestra el branding, el mensaje y los 3 botones en orden', (
      tester,
    ) async {
      await pumpAppAt(tester);

      expect(find.text('Ibagué Limpia'), findsOneWidget);
      expect(
        find.text(
          'Reporta, haz seguimiento y juntos mantengamos nuestra '
          'ciudad limpia.',
        ),
        findsOneWidget,
      );

      final buttonOrder = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where(
            (text) => const [
              'Hacer un reporte',
              'Mis reportes',
              'Mapa de reportes',
            ].contains(text),
          )
          .toList();
      expect(buttonOrder, [
        'Hacer un reporte',
        'Mis reportes',
        'Mapa de reportes',
      ]);
    });

    testWidgets('"Hacer un reporte" navega al flujo de crear reporte', (
      tester,
    ) async {
      await pumpAppAt(tester);

      await tester.tap(find.text('Hacer un reporte'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo reporte'), findsOneWidget);
    });

    testWidgets('"Mis reportes" navega a la lista de reportes', (tester) async {
      await pumpAppAt(tester);

      await tester.tap(find.text('Mis reportes'));
      await tester.pumpAndSettle();

      expect(find.text('Próximamente: Mis Reportes'), findsOneWidget);
    });

    testWidgets('"Mapa de reportes" navega al mapa', (tester) async {
      await pumpAppAt(tester);

      await tester.tap(find.text('Mapa de reportes'));
      await tester.pumpAndSettle();

      expect(find.text('Próximamente: Mapa de Reportes'), findsOneWidget);
    });
  });
}
