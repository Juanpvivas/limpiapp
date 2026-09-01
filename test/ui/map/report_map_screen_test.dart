import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiapp/config/routes.dart';
import 'package:limpiapp/config/service_locator.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:limpiapp/domain/models/report.dart';
import 'package:limpiapp/domain/models/report_status.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/domain/repositories/device_identifier_repository.dart';
import 'package:limpiapp/domain/repositories/report_list_repository.dart';
import 'package:limpiapp/ui/map/providers/selected_map_report_provider.dart';
import 'package:limpiapp/domain/models/connectivity_status.dart';
import 'package:limpiapp/ui/core/offline_copy.dart';
import 'package:limpiapp/ui/core/providers/connectivity_provider.dart';
import 'package:limpiapp/ui/core/ui/data_error_state.dart';
import 'package:limpiapp/ui/map/widgets/map_empty_overlay.dart';
import 'package:limpiapp/ui/map/widgets/map_legend.dart';
import 'package:limpiapp/ui/map/widgets/map_marker_cluster_layer.dart';
import 'package:limpiapp/ui/map/widgets/report_map_screen.dart';
import 'package:limpiapp/ui/map/widgets/report_summary_card.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportListRepository extends Mock implements ReportListRepository {}

class _MockDeviceIdentifierRepository extends Mock
    implements DeviceIdentifierRepository {}

/// PNG transparente de 1×1 — evita cualquier request de red en los tests
/// (research.md §7).
final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  '+P+/HgAFhAJ/wlseKgAAAABJRU5ErkJggg==',
);

class _FakeTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_pixel);
}

Report _report(
  String id, {
  ReportStatus status = ReportStatus.pendiente,
  bool withCoords = true,
}) => Report(
  id: id,
  reportNumber: '#IL-2026-00000$id',
  category: WasteCategory.escombros,
  description: '',
  address: 'Calle $id',
  photoUrl: '',
  createdAt: DateTime(2026, 1, int.parse(id)),
  status: status,
  deviceId: 'd1',
  // Coordenadas distintas por id para ejercitar el encuadre real.
  latitude: withCoords ? 4.40 + int.parse(id) * 0.02 : null,
  longitude: withCoords ? -75.25 + int.parse(id) * 0.02 : null,
);

void main() {
  late _MockReportListRepository listRepository;
  late _MockDeviceIdentifierRepository deviceRepository;

  setUp(() async {
    listRepository = _MockReportListRepository();
    deviceRepository = _MockDeviceIdentifierRepository();
    await getIt.reset();
    getIt.registerLazySingleton<ReportListRepository>(() => listRepository);
    getIt.registerLazySingleton<DeviceIdentifierRepository>(
      () => deviceRepository,
    );
    when(() => deviceRepository.getDeviceId())
        .thenAnswer((_) async => const Right('d1'));
  });

  Future<ProviderContainer> pumpMap(
    WidgetTester tester, {
    ConnectivityStatus connectivity = ConnectivityStatus.online,
  }) async {
    // Sin reintentos automáticos: un provider en error, si no, deja un Timer
    // de backoff pendiente al desmontar el árbol (rompe el test).
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        connectivityStatusProvider.overrideWith(
          (ref) => Stream.value(connectivity),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/mapa',
      routes: [
        GoRoute(
          path: '/mapa',
          builder: (_, _) => ReportMapScreen(tileProvider: _FakeTileProvider()),
        ),
        GoRoute(
          path: '$misReportesPath/:reportId',
          builder: (_, state) => Scaffold(
            appBar: AppBar(
              title: Text('Detalle ${state.pathParameters['reportId']}'),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return container;
  }

  // ---------- User Story 1 ----------

  testWidgets('estado de carga: muestra el indicador de progreso', (
    tester,
  ) async {
    when(() => listRepository.watchReports('d1'))
        .thenAnswer((_) => const Stream.empty());
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        connectivityStatusProvider.overrideWith(
          (ref) => Stream.value(ConnectivityStatus.online),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => ReportMapScreen(tileProvider: _FakeTileProvider()),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error de servidor: DataErrorState con mensaje genérico', (
    tester,
  ) async {
    when(() => listRepository.watchReports('d1'))
        .thenAnswer((_) => Stream.value(const Left(ServerFailure())));

    await pumpMap(tester);

    expect(find.byType(DataErrorState), findsOneWidget);
    expect(find.text(kRetryLabel), findsOneWidget);
    expect(find.text(kGenericServerErrorText), findsOneWidget);
  });

  testWidgets('NetworkFailure → DataErrorState con mensaje de sin conexión '
      '(FR-007)', (tester) async {
    when(() => listRepository.watchReports('d1'))
        .thenAnswer((_) => Stream.value(const Left(NetworkFailure())));

    await pumpMap(tester);

    expect(find.text(kOfflineReadErrorText), findsOneWidget);
  });

  testWidgets('con connectivity offline el mensaje es el de sin conexión '
      'aunque el Failure sea de servidor (FR-007)', (tester) async {
    when(() => listRepository.watchReports('d1'))
        .thenAnswer((_) => Stream.value(const Left(ServerFailure())));

    await pumpMap(tester, connectivity: ConnectivityStatus.offline);

    expect(find.text(kOfflineReadErrorText), findsOneWidget);
  });

  testWidgets('sin reportes: mapa + overlay vacío general + leyenda', (
    tester,
  ) async {
    when(() => listRepository.watchReports('d1'))
        .thenAnswer((_) => Stream.value(const Right(<Report>[])));

    await pumpMap(tester);

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(MapLegend), findsOneWidget);
    final overlay = tester.widget<MapEmptyOverlay>(
      find.byType(MapEmptyOverlay),
    );
    expect(overlay.filtered, isFalse);
    expect(find.textContaining('Aún no has enviado'), findsOneWidget);
  });

  testWidgets('con reportes: la capa de marcadores recibe solo los mapeables, '
      'con su estado', (tester) async {
    when(() => listRepository.watchReports('d1')).thenAnswer(
      (_) => Stream.value(
        Right([
          _report('1', status: ReportStatus.pendiente),
          _report('2', status: ReportStatus.solucionado),
          _report('3', withCoords: false),
        ]),
      ),
    );

    await pumpMap(tester);

    final layer = tester.widget<MapMarkerClusterLayer>(
      find.byType(MapMarkerClusterLayer),
    );
    expect(layer.reports.map((r) => r.id), ['1', '2']);
    expect(layer.reports.map((r) => r.status), [
      ReportStatus.pendiente,
      ReportStatus.solucionado,
    ]);
    expect(find.byType(MapEmptyOverlay), findsNothing);
  });

  testWidgets('FR-021: una nueva emisión del stream cambia los marcadores', (
    tester,
  ) async {
    final stream = Stream<Either<Failure, List<Report>>>.fromIterable([
      Right([_report('1', status: ReportStatus.pendiente)]),
      Right([_report('1', status: ReportStatus.solucionado), _report('2')]),
    ]);
    when(() => listRepository.watchReports('d1')).thenAnswer((_) => stream);

    await pumpMap(tester);
    await tester.pump(const Duration(seconds: 1));

    final layer = tester.widget<MapMarkerClusterLayer>(
      find.byType(MapMarkerClusterLayer),
    );
    expect(layer.reports.map((r) => r.id), ['1', '2']);
    expect(layer.reports.first.status, ReportStatus.solucionado);
  });

  // ---------- User Story 2 ----------

  testWidgets('seleccionar un marcador muestra la tarjeta resumen; otra '
      'selección la reemplaza; cerrar la oculta (FR-017/FR-018/FR-019)', (
    tester,
  ) async {
    when(() => listRepository.watchReports('d1'))
        .thenAnswer((_) => Stream.value(Right([_report('1'), _report('2')])));

    final container = await pumpMap(tester);
    expect(find.byType(ReportSummaryCard), findsNothing);

    container.read(selectedMapReportProvider.notifier).select('1');
    await tester.pump();
    expect(find.byType(ReportSummaryCard), findsOneWidget);
    expect(find.text('#IL-2026-000001'), findsOneWidget);

    container.read(selectedMapReportProvider.notifier).select('2');
    await tester.pump();
    expect(find.byType(ReportSummaryCard), findsOneWidget);
    expect(find.text('#IL-2026-000002'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.byType(ReportSummaryCard), findsNothing);
  });

  testWidgets('tocar la tarjeta navega a /mis-reportes/:id (FR-020)', (
    tester,
  ) async {
    when(() => listRepository.watchReports('d1'))
        .thenAnswer((_) => Stream.value(Right([_report('1')])));

    final container = await pumpMap(tester);
    container.read(selectedMapReportProvider.notifier).select('1');
    await tester.pump();

    await tester.tap(find.byType(ReportSummaryCard));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Detalle 1'), findsOneWidget);
  });

  // ---------- User Story 3 ----------

  testWidgets('filtrar por estado reduce los marcadores; un estado sin '
      'reportes muestra el overlay "en este estado" (FR-014/FR-024)', (
    tester,
  ) async {
    when(() => listRepository.watchReports('d1')).thenAnswer(
      (_) => Stream.value(
        Right([
          _report('1', status: ReportStatus.pendiente),
          _report('2', status: ReportStatus.enProceso),
        ]),
      ),
    );

    await pumpMap(tester);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('En proceso').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    var layer = tester.widget<MapMarkerClusterLayer>(
      find.byType(MapMarkerClusterLayer),
    );
    expect(layer.reports.map((r) => r.id), ['2']);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solucionados').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    final overlay = tester.widget<MapEmptyOverlay>(
      find.byType(MapEmptyOverlay),
    );
    expect(overlay.filtered, isTrue);
    expect(
      find.textContaining('No tienes reportes en este estado'),
      findsOneWidget,
    );
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}
