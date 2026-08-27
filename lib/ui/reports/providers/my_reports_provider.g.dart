// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_reports_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stream de todos los reportes de este dispositivo (FR-004), ordenados del
/// más reciente al más antiguo (el orden lo garantiza `ReportQueryService`).
///
/// Resuelve el `deviceId` vía `DeviceIdentifierRepository` y delega en
/// `ReportListRepository.watchReports`. Cualquier `Left` (de cualquiera de
/// los 2 Repository) se traduce a una excepción para que Riverpod lo
/// represente como `AsyncError` (research.md §6). El filtro por pestaña
/// (FR-005) se aplica en la pantalla sobre esta lista, no aquí.

@ProviderFor(myReports)
final myReportsProvider = MyReportsProvider._();

/// Stream de todos los reportes de este dispositivo (FR-004), ordenados del
/// más reciente al más antiguo (el orden lo garantiza `ReportQueryService`).
///
/// Resuelve el `deviceId` vía `DeviceIdentifierRepository` y delega en
/// `ReportListRepository.watchReports`. Cualquier `Left` (de cualquiera de
/// los 2 Repository) se traduce a una excepción para que Riverpod lo
/// represente como `AsyncError` (research.md §6). El filtro por pestaña
/// (FR-005) se aplica en la pantalla sobre esta lista, no aquí.

final class MyReportsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Report>>,
          List<Report>,
          Stream<List<Report>>
        >
    with $FutureModifier<List<Report>>, $StreamProvider<List<Report>> {
  /// Stream de todos los reportes de este dispositivo (FR-004), ordenados del
  /// más reciente al más antiguo (el orden lo garantiza `ReportQueryService`).
  ///
  /// Resuelve el `deviceId` vía `DeviceIdentifierRepository` y delega en
  /// `ReportListRepository.watchReports`. Cualquier `Left` (de cualquiera de
  /// los 2 Repository) se traduce a una excepción para que Riverpod lo
  /// represente como `AsyncError` (research.md §6). El filtro por pestaña
  /// (FR-005) se aplica en la pantalla sobre esta lista, no aquí.
  MyReportsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myReportsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myReportsHash();

  @$internal
  @override
  $StreamProviderElement<List<Report>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Report>> create(Ref ref) {
    return myReports(ref);
  }
}

String _$myReportsHash() => r'a27c3b279e2604faeee58ae1bad3e693f188884f';
