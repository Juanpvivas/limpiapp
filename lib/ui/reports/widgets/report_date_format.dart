/// Formateo de fecha/hora de envío para "Mis Reportes" (FR-008, FR-013,
/// FR-014). Sin `intl` (fuera del stack aprobado): formato fijo
/// `dd/MM/yyyy · HH:mm` en la hora local del dispositivo.
String formatReportDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final d = _pad2(local.day);
  final m = _pad2(local.month);
  final y = local.year.toString();
  final hh = _pad2(local.hour);
  final mm = _pad2(local.minute);
  return '$d/$m/$y · $hh:$mm';
}

String _pad2(int value) => value.toString().padLeft(2, '0');
