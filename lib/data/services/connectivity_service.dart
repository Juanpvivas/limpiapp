import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/models/connectivity_status.dart';

/// Wrapper delgado sobre `connectivity_plus` + heurística del disparo híbrido
/// del aviso global de "sin conexión" (feature 005, research.md §3).
///
/// Combina dos señales:
/// - **(a)** interfaz de red del dispositivo, vía `Connectivity.onConnectivityChanged`
///   (pasiva, dirigida por eventos).
/// - **(b)** un contador de fallos consecutivos de **establecer conexión** con
///   el backend que le reportan los Repositories (`reportBackendUnreachable` /
///   `reportBackendReachable`). Cubre "hay WiFi pero sin internet real".
///
/// Regla: `online` ⟺ hay interfaz **y** `fallos < failureThreshold`.
///
/// Debounce asimétrico (FR-004): mostrar `offline` es casi inmediato; volver a
/// `online` exige [_onlineDebounce] de estabilidad, para no parpadear.
///
/// Un error del stream de `connectivity_plus` se trata como "sin interfaz"
/// (tiende a `offline`) — nunca se propaga (Principio V, carve-out v2.6.0).
class ConnectivityService {
  ConnectivityService(
    this._connectivity, {
    Duration onlineDebounce = const Duration(milliseconds: 1500),
    Duration offlineDebounce = const Duration(milliseconds: 300),
    int failureThreshold = 2,
    // ignore: prefer_initializing_formals
  }) : _onlineDebounce = onlineDebounce,
       // ignore: prefer_initializing_formals
       _offlineDebounce = offlineDebounce,
       // ignore: prefer_initializing_formals
       _failureThreshold = failureThreshold;

  final Connectivity _connectivity;
  final Duration _onlineDebounce;
  final Duration _offlineDebounce;
  final int _failureThreshold;

  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _debounce;
  bool _started = false;

  // Se parte de "online" para no parpadear en el arranque con conexión; el
  // primer evento real corrige en < 1 s.
  bool _hasInterface = true;
  int _consecutiveFailures = 0;
  ConnectivityStatus _current = ConnectivityStatus.online;

  /// Emite el estado actual al suscribirse y luego cada cambio (ya debounced).
  Stream<ConnectivityStatus> get statusStream async* {
    _ensureStarted();
    yield _current;
    yield* _controller.stream;
  }

  /// Lo llama un Repository cuando una operación falla por **no poder
  /// establecer conexión** (timeout / host inalcanzable).
  void reportBackendUnreachable() {
    _consecutiveFailures++;
    _recompute();
  }

  /// Lo llama un Repository tras una operación exitosa contra el backend.
  void reportBackendReachable() {
    if (_consecutiveFailures == 0) return;
    _consecutiveFailures = 0;
    _recompute();
  }

  void _ensureStarted() {
    if (_started) return;
    _started = true;
    _connectivity.checkConnectivity().then(_onResults).catchError((_) {
      _hasInterface = false;
      _recompute();
    });
    _sub = _connectivity.onConnectivityChanged.listen(
      _onResults,
      onError: (_) {
        _hasInterface = false;
        _recompute();
      },
    );
  }

  void _onResults(List<ConnectivityResult> results) {
    _hasInterface = results.any((r) => r != ConnectivityResult.none);
    _recompute();
  }

  ConnectivityStatus get _raw =>
      (_hasInterface && _consecutiveFailures < _failureThreshold)
      ? ConnectivityStatus.online
      : ConnectivityStatus.offline;

  void _recompute() {
    final target = _raw;
    if (target == _current) {
      // Volvimos a la posición estable antes de que venciera el debounce.
      _debounce?.cancel();
      _debounce = null;
      return;
    }
    if (_debounce != null) return; // ya hay un cambio a `target` pendiente
    final delay = target == ConnectivityStatus.offline
        ? _offlineDebounce
        : _onlineDebounce;
    _debounce = Timer(delay, () {
      _debounce = null;
      _current = target;
      if (!_controller.isClosed) _controller.add(target);
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _debounce?.cancel();
    await _controller.close();
  }
}
