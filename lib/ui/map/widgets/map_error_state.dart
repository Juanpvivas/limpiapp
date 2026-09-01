import 'package:flutter/material.dart';

/// Estado de error de la carga de reportes (no de las teselas del mapa):
/// mensaje + botón "Reintentar" (FR-025). Consistente con "Mis Reportes".
class MapErrorState extends StatelessWidget {
  const MapErrorState({required this.onRetry, super.key});

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
              'No se pudieron cargar tus reportes.\n'
              'Revisa tu conexión e intenta de nuevo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
