import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_map_report_provider.g.dart';

/// `Report.id` del marcador cuya tarjeta resumen está abierta, o `null` si no
/// hay ninguna (FR-017/FR-018 — como máximo una tarjeta a la vez).
///
/// Auto-dispose: la selección no debe sobrevivir a salir del tab "Mapa".
@riverpod
class SelectedMapReport extends _$SelectedMapReport {
  @override
  String? build() => null;

  void select(String reportId) => state = reportId;

  void clear() => state = null;
}
