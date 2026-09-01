import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:limpiapp/config/routes.dart';
import 'package:limpiapp/config/service_locator.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:limpiapp/domain/models/report.dart';
import 'package:limpiapp/domain/models/report_status.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/domain/repositories/device_identifier_repository.dart';
import 'package:limpiapp/domain/repositories/location_repository.dart';
import 'package:limpiapp/domain/repositories/photo_repository.dart';
import 'package:limpiapp/domain/repositories/report_list_repository.dart';
import 'package:limpiapp/domain/models/connectivity_status.dart';
import 'package:limpiapp/domain/repositories/connectivity_repository.dart';
import 'package:limpiapp/domain/repositories/report_repository.dart';
import 'package:limpiapp/ui/core/offline_copy.dart';
import 'package:limpiapp/ui/core/ui/data_error_state.dart';
import 'package:limpiapp/ui/reports/widgets/report_list_item.dart';
import 'package:limpiapp/ui/reports/widgets/report_status_chip.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

class _MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

class _MockPhotoRepository extends Mock implements PhotoRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

class _MockReportListRepository extends Mock implements ReportListRepository {}

class _MockDeviceIdentifierRepository extends Mock
    implements DeviceIdentifierRepository {}

Report _report(
  String id, {
  ReportStatus status = ReportStatus.pendiente,
  DateTime? createdAt,
}) => Report(
  id: id,
  reportNumber: '#IL-2026-00000$id',
  category: WasteCategory.escombros,
  description: '',
  address: 'Calle $id # 2-3',
  photoUrl: 'https://storage/$id.jpg',
  createdAt: createdAt ?? DateTime(2026, 1, int.parse(id), 9),
  status: status,
  deviceId: 'd1',
);

void main() {
  late _MockReportListRepository listRepository;
  late _MockDeviceIdentifierRepository deviceRepository;
  late _MockConnectivityRepository connectivityRepo;

  setUp(() async {
    listRepository = _MockReportListRepository();
    deviceRepository = _MockDeviceIdentifierRepository();
    connectivityRepo = _MockConnectivityRepository();
    when(connectivityRepo.watch)
        .thenAnswer((_) => Stream.value(ConnectivityStatus.online));

    await getIt.reset();
    getIt.registerLazySingleton<ReportRepository>(
      () => _MockReportRepository(),
    );
    getIt.registerLazySingleton<PhotoRepository>(() => _MockPhotoRepository());
    final locationRepository = _MockLocationRepository();
    when(() => locationRepository.getCurrentLocation())
        .thenAnswer((_) async => const Left(PermissionFailure()));
    getIt.registerLazySingleton<LocationRepository>(() => locationRepository);
    getIt.registerLazySingleton<ReportListRepository>(() => listRepository);
    getIt.registerLazySingleton<DeviceIdentifierRepository>(
      () => deviceRepository,
    );
    getIt.registerLazySingleton<ConnectivityRepository>(() => connectivityRepo);

    when(() => deviceRepository.getDeviceId())
        .thenAnswer((_) async => const Right('d1'));
    when(() => listRepository.watchReportById(any()))
        .thenAnswer((_) => Stream.value(Right(_report('1'))));
  });

  Future<void> pumpList(WidgetTester tester) async {
    final router = buildAppRouter();
    router.go(misReportesPath);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista los reportes con miniatura, chip de estado, número y '
      'dirección, el más reciente primero', (tester) async {
    when(() => listRepository.watchReports('d1')).thenAnswer(
      (_) => Stream.value(
        Right([
          _report('3', status: ReportStatus.solucionado),
          _report('2', status: ReportStatus.enProceso),
          _report('1'),
        ]),
      ),
    );

    await pumpList(tester);

    expect(find.byType(ReportListItem), findsNWidgets(3));
    expect(find.byType(ReportStatusChip), findsNWidgets(3));
    expect(find.text('#IL-2026-000003'), findsOneWidget);
    expect(find.text('Calle 1 # 2-3'), findsOneWidget);

    final items = tester
        .widgetList<ReportListItem>(find.byType(ReportListItem))
        .toList();
    expect(items.map((i) => i.report.id), ['3', '2', '1']);
  });

  testWidgets('sin reportes muestra el estado vacío general', (tester) async {
    when(() => listRepository.watchReports('d1'))
        .thenAnswer((_) => Stream.value(const Right(<Report>[])));

    await pumpList(tester);

    expect(find.textContaining('Aún no has enviado'), findsOneWidget);
    expect(find.byType(ReportListItem), findsNothing);
  });

  testWidgets('tocar un reporte navega a su detalle', (tester) async {
    when(() => listRepository.watchReports('d1'))
        .thenAnswer((_) => Stream.value(Right([_report('1')])));

    await pumpList(tester);
    await tester.tap(find.byType(ReportListItem).first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Detalle del reporte'), findsOneWidget);
  });

  group('US2 (005) — estado de error de lectura', () {
    testWidgets('error de servidor: DataErrorState con mensaje genérico', (
      tester,
    ) async {
      when(() => listRepository.watchReports('d1'))
          .thenAnswer((_) => Stream.value(const Left(ServerFailure())));

      await pumpList(tester);

      expect(find.byType(DataErrorState), findsOneWidget);
      expect(find.text(kGenericServerErrorText), findsOneWidget);
      expect(find.text(kRetryLabel), findsOneWidget);
    });

    testWidgets('NetworkFailure → mensaje de sin conexión (FR-007)', (
      tester,
    ) async {
      when(() => listRepository.watchReports('d1'))
          .thenAnswer((_) => Stream.value(const Left(NetworkFailure())));

      await pumpList(tester);

      expect(find.text(kOfflineReadErrorText), findsOneWidget);
    });

    testWidgets('connectivity offline → mensaje de sin conexión aunque el '
        'Failure sea de servidor (FR-007)', (tester) async {
      when(connectivityRepo.watch)
          .thenAnswer((_) => Stream.value(ConnectivityStatus.offline));
      when(() => listRepository.watchReports('d1'))
          .thenAnswer((_) => Stream.value(const Left(ServerFailure())));

      await pumpList(tester);

      expect(find.text(kOfflineReadErrorText), findsOneWidget);
    });

    testWidgets('FR-009: el estado de error NO se limpia solo al volver la '
        'conexión (solo con "Reintentar")', (tester) async {
      final conn = StreamController<ConnectivityStatus>.broadcast();
      addTearDown(conn.close);
      when(connectivityRepo.watch).thenAnswer((_) => conn.stream);
      when(() => listRepository.watchReports('d1'))
          .thenAnswer((_) => Stream.value(const Left(NetworkFailure())));

      await pumpList(tester);
      expect(find.byType(DataErrorState), findsOneWidget);

      conn.add(ConnectivityStatus.online);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DataErrorState), findsOneWidget);
    });
  });

  group('US2 — filtro por pestañas', () {
    testWidgets('tocar cada pestaña filtra la lista mostrada', (tester) async {
      when(() => listRepository.watchReports('d1')).thenAnswer(
        (_) => Stream.value(
          Right([
            _report('3', status: ReportStatus.solucionado),
            _report('2', status: ReportStatus.enProceso),
            _report('1'),
          ]),
        ),
      );

      await pumpList(tester);
      expect(find.byType(ReportListItem), findsNWidgets(3));

      await tester.tap(find.text('Pendientes'));
      await tester.pumpAndSettle();
      var items = tester
          .widgetList<ReportListItem>(find.byType(ReportListItem))
          .toList();
      expect(items.map((i) => i.report.id), ['1']);

      await tester.tap(find.text('En proceso'));
      await tester.pumpAndSettle();
      items = tester
          .widgetList<ReportListItem>(find.byType(ReportListItem))
          .toList();
      expect(items.map((i) => i.report.id), ['2']);

      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportListItem), findsNWidgets(3));
    });

    testWidgets('una pestaña sin reportes muestra el estado vacío específico, '
        'no el general', (tester) async {
      when(() => listRepository.watchReports('d1'))
          .thenAnswer((_) => Stream.value(Right([_report('1')])));

      await pumpList(tester);
      await tester.tap(find.text('Solucionados'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No tienes reportes en este estado'),
        findsOneWidget,
      );
      expect(find.textContaining('Aún no has enviado'), findsNothing);
      expect(find.byType(ReportListItem), findsNothing);
    });
  });
}
