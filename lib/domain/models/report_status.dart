/// Estado de seguimiento de un reporte (FR-008, FR-011 a FR-014). Cada valor
/// lleva su `label` mostrable en la UI (mismo patrón que `WasteCategory`).
///
/// El `name` del enum (`pendiente`/`enProceso`/`solucionado`) es exactamente
/// el string persistido en el campo `status` del documento de Firestore (ver
/// `contracts/reports-schema.md`), no el `label` en español.
enum ReportStatus {
  pendiente('Pendiente'),
  enProceso('En proceso'),
  solucionado('Solucionado');

  const ReportStatus(this.label);

  /// Texto mostrado al usuario en la etiqueta de estado.
  final String label;
}
