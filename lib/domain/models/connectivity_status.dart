/// Estado de conectividad observable por la app (feature "Manejo de estado
/// sin conexión"). Concepto de dominio efímero — no se persiste.
///
/// - [online]: hay una interfaz de red activa **y** no hay una racha de
///   fallos consecutivos de establecer conexión con el backend.
/// - [offline]: no hay interfaz de red, **o** hubo ≥ N fallos consecutivos de
///   conexión sin ningún éxito intermedio (FR-005 a/b). "No se puede
///   determinar" también colapsa en [offline].
enum ConnectivityStatus { online, offline }
