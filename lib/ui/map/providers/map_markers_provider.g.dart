// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_markers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reportes que se dibujan como marcadores en el mapa: los del propio
/// dispositivo (reutiliza `myReportsProvider` de "Mis Reportes", sin tocar la
/// capa Data), tras aplicar el filtro por estado del mapa (FR-014) y descartar
/// los que no tienen coordenadas válidas (FR-004).
///
/// Devuelve un `AsyncValue` (vía `whenData`) para propagar tal cual los
/// estados de carga y error de `myReportsProvider` (FR-022/FR-025).

@ProviderFor(mapMarkers)
final mapMarkersProvider = MapMarkersProvider._();

/// Reportes que se dibujan como marcadores en el mapa: los del propio
/// dispositivo (reutiliza `myReportsProvider` de "Mis Reportes", sin tocar la
/// capa Data), tras aplicar el filtro por estado del mapa (FR-014) y descartar
/// los que no tienen coordenadas válidas (FR-004).
///
/// Devuelve un `AsyncValue` (vía `whenData`) para propagar tal cual los
/// estados de carga y error de `myReportsProvider` (FR-022/FR-025).

final class MapMarkersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Report>>,
          AsyncValue<List<Report>>,
          AsyncValue<List<Report>>
        >
    with $Provider<AsyncValue<List<Report>>> {
  /// Reportes que se dibujan como marcadores en el mapa: los del propio
  /// dispositivo (reutiliza `myReportsProvider` de "Mis Reportes", sin tocar la
  /// capa Data), tras aplicar el filtro por estado del mapa (FR-014) y descartar
  /// los que no tienen coordenadas válidas (FR-004).
  ///
  /// Devuelve un `AsyncValue` (vía `whenData`) para propagar tal cual los
  /// estados de carga y error de `myReportsProvider` (FR-022/FR-025).
  MapMarkersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapMarkersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapMarkersHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Report>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Report>> create(Ref ref) {
    return mapMarkers(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Report>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Report>>>(value),
    );
  }
}

String _$mapMarkersHash() => r'7e68ff2d7938393e1e636ff6b3e99893235d15ae';
