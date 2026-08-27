import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiapp/domain/models/report.dart';
import 'package:limpiapp/domain/models/report_status.dart';
import 'package:limpiapp/domain/models/waste_category.dart';
import 'package:limpiapp/ui/reports/widgets/report_status_timeline.dart';

Report _report({
  required ReportStatus status,
  DateTime? inProgressAt,
  DateTime? resolvedAt,
}) => Report(
  id: 'r1',
  reportNumber: '#IL-2026-000001',
  category: WasteCategory.otros,
  description: '',
  address: 'Calle 1',
  photoUrl: '',
  createdAt: DateTime(2026, 1, 10, 8),
  status: status,
  deviceId: 'd1',
  inProgressAt: inProgressAt,
  resolvedAt: resolvedAt,
);

Future<void> _pump(WidgetTester tester, Report report) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: ReportStatusTimeline(report: report)),
  ),
);

void main() {
  testWidgets('pendiente: solo "Reporte recibido" tiene fecha; los otros 2 '
      'pasos muestran "Pendiente"', (tester) async {
    await _pump(tester, _report(status: ReportStatus.pendiente));

    expect(find.text('Reporte recibido'), findsOneWidget);
    expect(find.text('10/01/2026 · 08:00'), findsOneWidget);
    expect(find.text('En proceso'), findsOneWidget);
    expect(find.text('Solucionado'), findsOneWidget);
    expect(find.text('Pendiente'), findsNWidgets(2));
  });

  testWidgets('en proceso: "Reporte recibido" y "En proceso" con fecha, '
      '"Solucionado" pendiente', (tester) async {
    await _pump(
      tester,
      _report(
        status: ReportStatus.enProceso,
        inProgressAt: DateTime(2026, 1, 12, 9, 30),
      ),
    );

    expect(find.text('10/01/2026 · 08:00'), findsOneWidget);
    expect(find.text('12/01/2026 · 09:30'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
  });

  testWidgets('solucionado: los 3 pasos muestran fecha, ninguno "Pendiente"', (
    tester,
  ) async {
    await _pump(
      tester,
      _report(
        status: ReportStatus.solucionado,
        inProgressAt: DateTime(2026, 1, 12, 9, 30),
        resolvedAt: DateTime(2026, 1, 15, 16),
      ),
    );

    expect(find.text('10/01/2026 · 08:00'), findsOneWidget);
    expect(find.text('12/01/2026 · 09:30'), findsOneWidget);
    expect(find.text('15/01/2026 · 16:00'), findsOneWidget);
    expect(find.text('Pendiente'), findsNothing);
  });
}
