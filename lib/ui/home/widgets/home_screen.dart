import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';

/// Pantalla de inicio / shell de navegación (FR-001, FR-002). No lee ningún
/// provider ni Notifier, por lo que es `StatelessWidget` (Principio III de
/// la constitución).
///
/// TODO(assets): el fondo y el ícono de marca son placeholders (gradiente +
/// ícono de Material) hasta contar con los archivos reales de diseño — ver
/// T012 en specs/001-navegacion-principal/tasks.md.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF66BB6A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                const _Branding(),
                const SizedBox(height: 16),
                const Text(
                  'Reporta, haz seguimiento y juntos mantengamos nuestra '
                  'ciudad limpia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Spacer(flex: 3),
                FilledButton(
                  onPressed: () => context.go(AppTab.reportar.path),
                  child: const Text('Hacer un reporte'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go(misReportesPath),
                  style: _outlinedOnDarkStyle,
                  child: const Text('Mis reportes'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go(AppTab.mapa.path),
                  style: _outlinedOnDarkStyle,
                  child: const Text('Mapa de reportes'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final ButtonStyle _outlinedOnDarkStyle = OutlinedButton.styleFrom(
  foregroundColor: Colors.white,
  side: const BorderSide(color: Colors.white),
);

class _Branding extends StatelessWidget {
  const _Branding();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.eco, color: Colors.white, size: 64),
        SizedBox(height: 8),
        Text(
          'Ibagué Limpia',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
