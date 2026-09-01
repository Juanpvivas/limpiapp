// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_report_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Estado del filtro por estado del "Mapa de Reportes" (FR-012/FR-013).
///
/// Reutiliza el enum [ReportFilter] de "Mis Reportes" pero es una instancia de
/// estado **independiente** de `reportFilterProvider` (FR-015): cambiar el
/// filtro del mapa no toca el de la lista y viceversa.
///
/// `keepAlive` para que la selección sobreviva al cambio de tab y al
/// ida-y-vuelta al "Detalle del reporte" (FR-028) — la rama "Mapa" permanece
/// montada en el `IndexedStack` del shell, pero el provider igual se marca
/// `keepAlive` para no depender de ese detalle de montaje.

@ProviderFor(MapReportFilter)
final mapReportFilterProvider = MapReportFilterProvider._();

/// Estado del filtro por estado del "Mapa de Reportes" (FR-012/FR-013).
///
/// Reutiliza el enum [ReportFilter] de "Mis Reportes" pero es una instancia de
/// estado **independiente** de `reportFilterProvider` (FR-015): cambiar el
/// filtro del mapa no toca el de la lista y viceversa.
///
/// `keepAlive` para que la selección sobreviva al cambio de tab y al
/// ida-y-vuelta al "Detalle del reporte" (FR-028) — la rama "Mapa" permanece
/// montada en el `IndexedStack` del shell, pero el provider igual se marca
/// `keepAlive` para no depender de ese detalle de montaje.
final class MapReportFilterProvider
    extends $NotifierProvider<MapReportFilter, ReportFilter> {
  /// Estado del filtro por estado del "Mapa de Reportes" (FR-012/FR-013).
  ///
  /// Reutiliza el enum [ReportFilter] de "Mis Reportes" pero es una instancia de
  /// estado **independiente** de `reportFilterProvider` (FR-015): cambiar el
  /// filtro del mapa no toca el de la lista y viceversa.
  ///
  /// `keepAlive` para que la selección sobreviva al cambio de tab y al
  /// ida-y-vuelta al "Detalle del reporte" (FR-028) — la rama "Mapa" permanece
  /// montada en el `IndexedStack` del shell, pero el provider igual se marca
  /// `keepAlive` para no depender de ese detalle de montaje.
  MapReportFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapReportFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapReportFilterHash();

  @$internal
  @override
  MapReportFilter create() => MapReportFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportFilter>(value),
    );
  }
}

String _$mapReportFilterHash() => r'd94b2cae21ae8fc8870916bef27012d3f4400bfe';

/// Estado del filtro por estado del "Mapa de Reportes" (FR-012/FR-013).
///
/// Reutiliza el enum [ReportFilter] de "Mis Reportes" pero es una instancia de
/// estado **independiente** de `reportFilterProvider` (FR-015): cambiar el
/// filtro del mapa no toca el de la lista y viceversa.
///
/// `keepAlive` para que la selección sobreviva al cambio de tab y al
/// ida-y-vuelta al "Detalle del reporte" (FR-028) — la rama "Mapa" permanece
/// montada en el `IndexedStack` del shell, pero el provider igual se marca
/// `keepAlive` para no depender de ese detalle de montaje.

abstract class _$MapReportFilter extends $Notifier<ReportFilter> {
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
