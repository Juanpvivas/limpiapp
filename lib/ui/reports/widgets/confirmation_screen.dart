import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../domain/models/report.dart';

/// Pantalla "Confirmación" (FR-019 a FR-023). No lee ningún provider —
/// recibe el `Report` ya resuelto por constructor (`extra` de navegación),
/// así que es `StatelessWidget`, no `ConsumerWidget` (Principio III). La
/// verificación de "sin Report → redirigir a Inicio" (FR-025) es
/// responsabilidad única del guard de ruta en `config/routes.dart`.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({required this.report, super.key});

  final Report report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 96),
              const SizedBox(height: 24),
              const Text(
                '¡Reporte enviado con éxito! Tu reporte ha sido registrado '
                'correctamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Text(
                report.reportNumber,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Text(
                'Te notificaremos cuando haya novedades sobre tu reporte.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go(misReportesPath),
                child: const Text('Ver mis reportes'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppTab.home.path),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
