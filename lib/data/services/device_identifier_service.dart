import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Genera y persiste el identificador anónimo de dispositivo (research.md
/// §2/§7). El identificador nunca se muestra ni sale de la app: solo sirve
/// como llave de filtro en Firestore, así que se genera con `dart:math`
/// (`Random.secure()`) sin necesitar el paquete `uuid`.
///
/// No recibe una instancia de `SharedPreferences` por constructor:
/// `getInstance()` es asíncrono (y el propio paquete cachea su instancia
/// interna), mientras que el resto del `service_locator` es síncrono
/// (research.md §7).
class DeviceIdentifierService {
  static const _prefsKey = 'anonymous_device_id';

  /// Retorna el identificador ya persistido, o genera uno nuevo, lo guarda y
  /// lo retorna la primera vez. Puede lanzar si el almacenamiento local no
  /// está disponible — el Repository lo captura y mapea a `CacheFailure`.
  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = _generateId();
    await prefs.setString(_prefsKey, generated);
    return generated;
  }

  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final micros = DateTime.now().microsecondsSinceEpoch;
    return '$micros-${base64Url.encode(bytes)}';
  }
}
