import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/new_report_provider.dart';
import 'location_section.dart';
import 'photo_picker_card.dart';
import 'waste_category_field.dart';

/// Formulario "Nuevo reporte" (FR-001 a FR-018). Lee `NewReportNotifier`
/// vía `ref.watch`, por lo que es `ConsumerWidget` (Principio III).
class NewReportScreen extends ConsumerWidget {
  const NewReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newReportProvider);
    final notifier = ref.read(newReportProvider.notifier);

    ref.listen(newReportProvider.select((s) => s.showPermissionDeniedAlert), (
      _,
      show,
    ) {
      if (show) _showPermissionDeniedDialog(context, notifier);
    });

    ref.listen(newReportProvider.select((s) => s.submitError), (_, error) {
      if (error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    });

    // FR-016: mientras se envía, ni el gesto/botón "atrás" del sistema ni
    // ningún toque en la pantalla deben sacar al usuario de aquí.
    return PopScope(
      canPop: !state.isSubmitting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Nuevo reporte')),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PhotoPickerCard(),
                    const SizedBox(height: 24),
                    const WasteCategoryField(),
                    const SizedBox(height: 24),
                    Text(
                      '3. Descripción (opcional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Contexto adicional (opcional)',
                      ),
                      onChanged: notifier.setDescription,
                    ),
                    const SizedBox(height: 24),
                    const LocationSection(),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: state.canSubmit && !state.isSubmitting
                          ? () => _handleSubmit(context, ref, notifier)
                          : null,
                      child: const Text('Enviar reporte'),
                    ),
                  ],
                ),
              ),
            ),
            if (state.isSubmitting) ...[
              const ModalBarrier(dismissible: false, color: Colors.black45),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    WidgetRef ref,
    NewReportNotifier notifier,
  ) async {
    final report = await notifier.submit();
    if (report != null && context.mounted) {
      // `StatefulShellRoute.indexedStack` mantiene esta pantalla montada
      // entre pestañas (feature 001), así que `newReportProvider` (autoDispose)
      // nunca perdería su listener por sí solo — se invalida explícitamente
      // para que el próximo "Nuevo reporte" arranque en blanco (issue #27).
      ref.invalidate(newReportProvider);
      context.push('/reportar/confirmacion', extra: report);
    }
  }

  void _showPermissionDeniedDialog(
    BuildContext context,
    NewReportNotifier notifier,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Foto obligatoria'),
        content: const Text(
          'Agregar una foto es obligatorio para poder enviar el reporte.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              notifier.dismissPermissionAlert();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
