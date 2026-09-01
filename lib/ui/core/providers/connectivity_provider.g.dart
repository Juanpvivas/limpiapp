// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Estado de conectividad para toda la app (feature "Manejo de estado sin
/// conexión"). Lo consumen el `OfflineBanner` (aviso global), las pantallas
/// de lectura (mensaje de error específico) y `NewReportNotifier` (chequeo
/// pre-envío y mensaje).
///
/// `keepAlive`: el estado de red interesa mientras la app viva; evita
/// re-suscribirse a `connectivity_plus`.
///
/// Los consumidores tratan `AsyncLoading`/sin dato como `online` — no mostrar
/// el aviso hasta tener certeza (evita un parpadeo en el arranque).

@ProviderFor(connectivityStatus)
final connectivityStatusProvider = ConnectivityStatusProvider._();

/// Estado de conectividad para toda la app (feature "Manejo de estado sin
/// conexión"). Lo consumen el `OfflineBanner` (aviso global), las pantallas
/// de lectura (mensaje de error específico) y `NewReportNotifier` (chequeo
/// pre-envío y mensaje).
///
/// `keepAlive`: el estado de red interesa mientras la app viva; evita
/// re-suscribirse a `connectivity_plus`.
///
/// Los consumidores tratan `AsyncLoading`/sin dato como `online` — no mostrar
/// el aviso hasta tener certeza (evita un parpadeo en el arranque).

final class ConnectivityStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<ConnectivityStatus>,
          ConnectivityStatus,
          Stream<ConnectivityStatus>
        >
    with
        $FutureModifier<ConnectivityStatus>,
        $StreamProvider<ConnectivityStatus> {
  /// Estado de conectividad para toda la app (feature "Manejo de estado sin
  /// conexión"). Lo consumen el `OfflineBanner` (aviso global), las pantallas
  /// de lectura (mensaje de error específico) y `NewReportNotifier` (chequeo
  /// pre-envío y mensaje).
  ///
  /// `keepAlive`: el estado de red interesa mientras la app viva; evita
  /// re-suscribirse a `connectivity_plus`.
  ///
  /// Los consumidores tratan `AsyncLoading`/sin dato como `online` — no mostrar
  /// el aviso hasta tener certeza (evita un parpadeo en el arranque).
  ConnectivityStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityStatusHash();

  @$internal
  @override
  $StreamProviderElement<ConnectivityStatus> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ConnectivityStatus> create(Ref ref) {
    return connectivityStatus(ref);
  }
}

String _$connectivityStatusHash() =>
    r'52fe5c31b52c11a2837c6600134c38c06012b732';
