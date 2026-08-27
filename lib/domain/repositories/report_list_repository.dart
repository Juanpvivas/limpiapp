import 'package:fpdart/fpdart.dart';

import '../models/failure.dart';
import '../models/report.dart';

/// Lectura en tiempo real de la colección `reports` para "Mis Reportes" y
/// "Detalle del reporte". Es estrictamente de solo lectura: no expone ningún
/// método de escritura (FR-015/SC-005 verificable a nivel de interfaz).
abstract class ReportListRepository {
  /// Todos los reportes del dispositivo (`deviceId`), ordenados por
  /// `createdAt` descendente. El filtro por pestaña (FR-005) se aplica en
  /// Presentation sobre esta misma lista (research.md §4), no aquí.
  ///
  /// Un `Left` solo ocurre por un error real de lectura de Firestore (sin
  /// conexión, permisos denegados). "No hay reportes" es `Right(<[]>)`.
  Stream<Either<Failure, List<Report>>> watchReports(String deviceId);

  /// Un reporte específico por su `id` de documento, para "Detalle del
  /// reporte". `Right(null)` si el documento no existe (borrado o ID
  /// inválido) — es un dato válido de "no encontrado", no un `Failure`.
  Stream<Either<Failure, Report?>> watchReportById(String reportId);
}
