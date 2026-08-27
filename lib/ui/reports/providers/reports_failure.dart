import '../../../domain/models/failure.dart';

/// Traduce un [Failure] de Domain a una excepción para que Riverpod lo
/// represente como `AsyncError` de forma nativa (research.md §6). Es la
/// única capa donde `Either` se convierte a la idiomática de Riverpod;
/// Domain y Data siguen usando `Either` (Principio V).
class ReportsFailureException implements Exception {
  const ReportsFailureException(this.failure);

  final Failure failure;

  @override
  String toString() => failure.message;
}
