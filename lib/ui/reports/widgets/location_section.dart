import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/new_report_provider.dart';

/// Dirección automática + campo de dirección manual, cuya obligatoriedad
/// depende de si la ubicación automática se obtuvo (FR-010 a FR-014).
class LocationSection extends ConsumerStatefulWidget {
  const LocationSection({super.key});

  @override
  ConsumerState<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends ConsumerState<LocationSection> {
  // Estado efímero puramente local (Principio III, excepción documentada
  // en plan.md): el texto en sí no es estado de negocio.
  final TextEditingController _manualAddressController =
      TextEditingController();

  @override
  void dispose() {
    _manualAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      newReportProvider.select((s) => s.isLoadingLocation),
    );
    final autoLocation = ref.watch(
      newReportProvider.select((s) => s.autoLocation),
    );
    final notifier = ref.read(newReportProvider.notifier);
    final hasAutomatic = autoLocation?.hasAutomaticLocation ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('4. Ubicación', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (isLoading)
          const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Expanded(child: Text('Obteniendo tu ubicación...')),
            ],
          )
        else if (hasAutomatic)
          Row(
            children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(autoLocation!.automaticAddress!)),
            ],
          )
        else
          const Text('No se pudo obtener tu ubicación automáticamente.'),
        const SizedBox(height: 12),
        TextField(
          controller: _manualAddressController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: hasAutomatic
                ? 'Dirección manual (opcional)'
                : 'Dirección manual (obligatoria)',
          ),
          onChanged: notifier.setManualAddress,
        ),
      ],
    );
  }
}
