import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiapp/data/repositories/report_list_repository_impl.dart';
import 'package:limpiapp/data/services/firebase/report_query_service.dart';
import 'package:limpiapp/domain/models/failure.dart';
import 'package:limpiapp/domain/models/report_status.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportQueryService extends Mock implements ReportQueryService {}

Map<String, dynamic> _doc({
  String reportNumber = '#IL-2026-000001',
  String status = 'pendiente',
  String deviceId = 'device-1',
  DateTime? createdAt,
  DateTime? inProgressAt,
  DateTime? resolvedAt,
}) {
  return {
    'reportNumber': reportNumber,
    'wasteCategory': WasteCategory.escombros.name,
    'description': 'Escombros en la vía',
    'address': 'Calle 5 # 10-20',
    'photoUrl': 'https://storage/1.jpg',
    'status': status,
    'deviceId': deviceId,
    'createdAt': Timestamp.fromDate(createdAt ?? DateTime(2026, 1, 2)),
    'inProgressAt': inProgressAt == null
        ? null
        : Timestamp.fromDate(inProgressAt),
    'resolvedAt': resolvedAt == null ? null : Timestamp.fromDate(resolvedAt),
  };
}

void main() {
  late _MockReportQueryService queryService;
  late ReportListRepositoryImpl repository;

  setUp(() {
    queryService = _MockReportQueryService();
    repository = ReportListRepositoryImpl(queryService);
  });

  group('watchReports', () {
    test('mapea el stream feliz a una lista de Report y reenvía el deviceId '
        'exacto al Service (FR-004/SC-002)', () async {
      when(() => queryService.watchReportsByDevice('device-1')).thenAnswer(
        (_) => Stream.value([
          (id: 'a', data: _doc(reportNumber: '#IL-2026-000002')),
          (id: 'b', data: _doc(status: 'solucionado')),
        ]),
      );

      final result = await repository.watchReports('device-1').first;

      expect(result.isRight(), isTrue);
      result.match((_) => fail('esperaba Right'), (reports) {
        expect(reports, hasLength(2));
        expect(reports.first.id, 'a');
        expect(reports.first.reportNumber, '#IL-2026-000002');
        expect(reports[1].status, ReportStatus.solucionado);
      });
      verify(() => queryService.watchReportsByDevice('device-1')).called(1);
    });

    test('un error del stream subyacente se emite como Left(Failure), no como '
        'error de stream sin capturar', () async {
      when(() => queryService.watchReportsByDevice(any())).thenAnswer(
        (_) => Stream<List<FirestoreRecord>>.error(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
      );

      final result = await repository.watchReports('device-1').first;

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('esperaba Left'),
      );
    });

    test('un error de red se mapea a NetworkFailure', () async {
      when(() => queryService.watchReportsByDevice(any())).thenAnswer(
        (_) => Stream<List<FirestoreRecord>>.error(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
      );

      final result = await repository.watchReports('device-1').first;

      result.match(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('esperaba Left'),
      );
    });
  });

  group('watchReportById', () {
    test('emite Right(Report) cuando el documento existe', () async {
      when(() => queryService.watchReportById('r1'))
          .thenAnswer((_) => Stream.value((id: 'r1', data: _doc())));

      final result = await repository.watchReportById('r1').first;

      result.match((_) => fail('esperaba Right'), (report) {
        expect(report, isNotNull);
        expect(report!.id, 'r1');
      });
    });

    test('emite Right(null) cuando el documento no existe', () async {
      when(() => queryService.watchReportById('missing'))
          .thenAnswer((_) => Stream.value(null));

      final result = await repository.watchReportById('missing').first;

      result.match(
        (_) => fail('esperaba Right'),
        (report) => expect(report, isNull),
      );
    });
  });
}
