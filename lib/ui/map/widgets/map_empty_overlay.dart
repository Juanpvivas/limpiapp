import 'package:flutter/material.dart';

/// Mensaje sobre el mapa cuando no hay marcadores que mostrar.
///
/// - `filtered == false`: el dispositivo no tiene reportes mapeables (FR-023),
///   mismo tono que el estado vacío de "Mis Reportes".
/// - `filtered == true`: hay reportes pero el filtro activo no deja ninguno
///   (FR-024) — no es un error, el mapa sigue visible detrás.
class MapEmptyOverlay extends StatelessWidget {
  const MapEmptyOverlay({required this.filtered, super.key});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface
                .withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filtered ? Icons.filter_alt_off_outlined : Icons.inbox_outlined,
                size: 48,
                color: Colors.black38,
              ),
              const SizedBox(height: 12),
              Text(
                filtered
                    ? 'No tienes reportes en este estado.'
                    : 'Aún no has enviado ningún reporte.\n'
                          'Cuando reportes un punto sucio, aparecerá aquí en el mapa.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
