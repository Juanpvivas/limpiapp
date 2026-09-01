import 'package:flutter/material.dart';

import '../offline_copy.dart';

/// Estado de error compartido para las pantallas de lectura ("Mis reportes",
/// "Mapa de reportes"): icono + mensaje + botón "Reintentar" (FR-025).
///
/// Unifica el antiguo `MapErrorState` (004) y el `_ErrorState` privado de
/// `report_list_screen.dart` (003). La pantalla decide el [message] según sea
/// falta de conexión o un error de servidor (FR-007) — el texto sale de
/// `offline_copy.dart` (FR-019).
class DataErrorState extends StatelessWidget {
  const DataErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text(kRetryLabel)),
          ],
        ),
      ),
    );
  }
}
