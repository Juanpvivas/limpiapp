import 'package:flutter/material.dart';

/// Estado vacío de "Mis Reportes" (FR-009). Distingue el mensaje general
/// ("aún no tienes reportes") del mensaje específico de una pestaña de
/// filtro sin resultados ("no tienes reportes en este estado") — este
/// último se usa desde la Historia 2 (T035) pasando [filtered] en `true`.
class ReportListEmptyState extends StatelessWidget {
  const ReportListEmptyState({this.filtered = false, super.key});

  /// `true` cuando hay reportes en otros estados pero ninguno en la pestaña
  /// seleccionada; `false` cuando el dispositivo no tiene ningún reporte.
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final message = filtered
        ? 'No tienes reportes en este estado.'
        : 'Aún no has enviado ningún reporte.\n'
              'Cuando reportes un punto sucio, aparecerá aquí.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered ? Icons.filter_alt_off_outlined : Icons.inbox_outlined,
              size: 64,
              color: Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
