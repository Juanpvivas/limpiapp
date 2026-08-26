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

  NavigationBar navigationBar(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar));

  group('AppBottomNavBar (US2 — FR-006/FR-007, US3 — FR-008)', () {
    testWidgets('muestra 3 accesos: Inicio, Reportar y Mapa', (tester) async {
      await pumpAppAt(tester);

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Reportar'), findsOneWidget);
      expect(find.text('Mapa'), findsOneWidget);
    });

    testWidgets(
      'desde "Mis reportes", tocar "Mapa" navega directo al mapa sin pasar '
      'por Inicio',
      (tester) async {
        await pumpAppAt(tester, location: misReportesPath);
        expect(find.text('Próximamente: Mis Reportes'), findsOneWidget);

        await tester.tap(find.text('Mapa'));
        await tester.pumpAndSettle();

        expect(find.text('Próximamente: Mapa de Reportes'), findsOneWidget);
        expect(find.text('Ibagué Limpia'), findsNothing);
      },
    );

    testWidgets('tocar "Reportar" navega directo a crear reporte', (
      tester,
    ) async {
      await pumpAppAt(tester);

      await tester.tap(find.text('Reportar'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo reporte'), findsOneWidget);
    });

    testWidgets('tocar "Inicio" vuelve a la pantalla de inicio', (
      tester,
    ) async {
      await pumpAppAt(tester, location: '/mapa');

      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      expect(find.text('Ibagué Limpia'), findsOneWidget);
    });

    testWidgets(
      'el ítem resaltado coincide con la sección activa (currentIndex)',
      (tester) async {
        await pumpAppAt(tester);
        expect(navigationBar(tester).selectedIndex, AppTab.home.index);

        await tester.tap(find.text('Mapa'));
        await tester.pumpAndSettle();
        expect(navigationBar(tester).selectedIndex, AppTab.mapa.index);

        await tester.tap(find.text('Reportar'));
        await tester.pumpAndSettle();
        expect(navigationBar(tester).selectedIndex, AppTab.reportar.index);
      },
    );

    testWidgets('re-tocar una sección ya activa no duplica la navegación', (
      tester,
    ) async {
      await pumpAppAt(tester, location: '/mapa');
      expect(navigationBar(tester).selectedIndex, AppTab.mapa.index);

      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();

      expect(navigationBar(tester).selectedIndex, AppTab.mapa.index);
      expect(find.text('Próximamente: Mapa de Reportes'), findsOneWidget);
    });
  });
}
