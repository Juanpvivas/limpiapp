// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pestaña de filtro seleccionada en "Mis reportes". `Notifier` simple
/// (estado efímero de UI, no de negocio): arranca en `ReportFilter.todos`
/// (FR-006) y solo cambia al tocar otra pestaña.

@ProviderFor(ReportFilterNotifier)
final reportFilterProvider = ReportFilterNotifierProvider._();

/// Pestaña de filtro seleccionada en "Mis reportes". `Notifier` simple
/// (estado efímero de UI, no de negocio): arranca en `ReportFilter.todos`
/// (FR-006) y solo cambia al tocar otra pestaña.
final class ReportFilterNotifierProvider
    extends $NotifierProvider<ReportFilterNotifier, ReportFilter> {
  /// Pestaña de filtro seleccionada en "Mis reportes". `Notifier` simple
  /// (estado efímero de UI, no de negocio): arranca en `ReportFilter.todos`
  /// (FR-006) y solo cambia al tocar otra pestaña.
  ReportFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportFilterNotifierHash();

  @$internal
  @override
  ReportFilterNotifier create() => ReportFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportFilter>(value),
    );
  }
}

String _$reportFilterNotifierHash() =>
    r'62ce6d4cede5cc1d0b46bdd419e77827415f792e';

/// Pestaña de filtro seleccionada en "Mis reportes". `Notifier` simple
/// (estado efímero de UI, no de negocio): arranca en `ReportFilter.todos`
/// (FR-006) y solo cambia al tocar otra pestaña.

abstract class _$ReportFilterNotifier extends $Notifier<ReportFilter> {
  ReportFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReportFilter, ReportFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReportFilter, ReportFilter>,
              ReportFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
