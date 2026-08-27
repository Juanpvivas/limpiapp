// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stream de un reporte por su `id` de documento, para "Detalle del
/// reporte". Se suscribe (no una carga única) para reflejar cambios de
/// estado en tiempo real sin recargar (Assumption de spec.md).
///
/// Emite `null` si el documento no existe (reporte no encontrado). Un `Left`
/// del Repository se traduce a `AsyncError` igual que en `myReports`.

@ProviderFor(reportDetail)
final reportDetailProvider = ReportDetailFamily._();

/// Stream de un reporte por su `id` de documento, para "Detalle del
/// reporte". Se suscribe (no una carga única) para reflejar cambios de
/// estado en tiempo real sin recargar (Assumption de spec.md).
///
/// Emite `null` si el documento no existe (reporte no encontrado). Un `Left`
/// del Repository se traduce a `AsyncError` igual que en `myReports`.

final class ReportDetailProvider
    extends $FunctionalProvider<AsyncValue<Report?>, Report?, Stream<Report?>>
    with $FutureModifier<Report?>, $StreamProvider<Report?> {
  /// Stream de un reporte por su `id` de documento, para "Detalle del
  /// reporte". Se suscribe (no una carga única) para reflejar cambios de
  /// estado en tiempo real sin recargar (Assumption de spec.md).
  ///
  /// Emite `null` si el documento no existe (reporte no encontrado). Un `Left`
  /// del Repository se traduce a `AsyncError` igual que en `myReports`.
  ReportDetailProvider._({
    required ReportDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'reportDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reportDetailHash();

  @override
  String toString() {
    return r'reportDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Report?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Report?> create(Ref ref) {
    final argument = this.argument as String;
    return reportDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReportDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reportDetailHash() => r'33c3f1d8c62cf8c163211553d6b5a8c0f28df0e7';

/// Stream de un reporte por su `id` de documento, para "Detalle del
/// reporte". Se suscribe (no una carga única) para reflejar cambios de
/// estado en tiempo real sin recargar (Assumption de spec.md).
///
/// Emite `null` si el documento no existe (reporte no encontrado). Un `Left`
/// del Repository se traduce a `AsyncError` igual que en `myReports`.

final class ReportDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Report?>, String> {
  ReportDetailFamily._()
    : super(
        retry: null,
        name: r'reportDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream de un reporte por su `id` de documento, para "Detalle del
  /// reporte". Se suscribe (no una carga única) para reflejar cambios de
  /// estado en tiempo real sin recargar (Assumption de spec.md).
  ///
  /// Emite `null` si el documento no existe (reporte no encontrado). Un `Left`
  /// del Repository se traduce a `AsyncError` igual que en `myReports`.

  ReportDetailProvider call(String reportId) =>
      ReportDetailProvider._(argument: reportId, from: this);

  @override
  String toString() => r'reportDetailProvider';
}
