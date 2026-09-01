// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_map_report_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `Report.id` del marcador cuya tarjeta resumen está abierta, o `null` si no
/// hay ninguna (FR-017/FR-018 — como máximo una tarjeta a la vez).
///
/// Auto-dispose: la selección no debe sobrevivir a salir del tab "Mapa".

@ProviderFor(SelectedMapReport)
final selectedMapReportProvider = SelectedMapReportProvider._();

/// `Report.id` del marcador cuya tarjeta resumen está abierta, o `null` si no
/// hay ninguna (FR-017/FR-018 — como máximo una tarjeta a la vez).
///
/// Auto-dispose: la selección no debe sobrevivir a salir del tab "Mapa".
final class SelectedMapReportProvider
    extends $NotifierProvider<SelectedMapReport, String?> {
  /// `Report.id` del marcador cuya tarjeta resumen está abierta, o `null` si no
  /// hay ninguna (FR-017/FR-018 — como máximo una tarjeta a la vez).
  ///
  /// Auto-dispose: la selección no debe sobrevivir a salir del tab "Mapa".
  SelectedMapReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedMapReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedMapReportHash();

  @$internal
  @override
  SelectedMapReport create() => SelectedMapReport();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedMapReportHash() => r'7adae88cadc7dc86fe2dad59e10f9cbeb3e3c011';

/// `Report.id` del marcador cuya tarjeta resumen está abierta, o `null` si no
/// hay ninguna (FR-017/FR-018 — como máximo una tarjeta a la vez).
///
/// Auto-dispose: la selección no debe sobrevivir a salir del tab "Mapa".

abstract class _$SelectedMapReport extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
