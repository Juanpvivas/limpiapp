// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_report_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lógica de presentación de "Nuevo reporte": resuelve sus dependencias vía
/// `getIt<T>()` (Principio V) y nunca importa `lib/data/` (Principio IV.2).

@ProviderFor(NewReportNotifier)
final newReportProvider = NewReportNotifierProvider._();

/// Lógica de presentación de "Nuevo reporte": resuelve sus dependencias vía
/// `getIt<T>()` (Principio V) y nunca importa `lib/data/` (Principio IV.2).
final class NewReportNotifierProvider
    extends $NotifierProvider<NewReportNotifier, NewReportState> {
  /// Lógica de presentación de "Nuevo reporte": resuelve sus dependencias vía
  /// `getIt<T>()` (Principio V) y nunca importa `lib/data/` (Principio IV.2).
  NewReportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newReportNotifierHash();

  @$internal
  @override
  NewReportNotifier create() => NewReportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewReportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewReportState>(value),
    );
  }
}

String _$newReportNotifierHash() => r'4c10632314ef1d93ed5742bd9104a53281adb381';

/// Lógica de presentación de "Nuevo reporte": resuelve sus dependencias vía
/// `getIt<T>()` (Principio V) y nunca importa `lib/data/` (Principio IV.2).

abstract class _$NewReportNotifier extends $Notifier<NewReportState> {
  NewReportState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NewReportState, NewReportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NewReportState, NewReportState>,
              NewReportState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
