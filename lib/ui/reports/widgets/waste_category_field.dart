import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/waste_category.dart';
import '../providers/new_report_provider.dart';

/// Selector de categoría con las 5 opciones fijas (FR-007, FR-008).
class WasteCategoryField extends ConsumerWidget {
  const WasteCategoryField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(newReportProvider.select((s) => s.category));
    final notifier = ref.read(newReportProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Qué tipo de residuo es?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<WasteCategory>(
          initialValue: selected,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          hint: const Text('Selecciona una categoría'),
          items: [
            for (final category in WasteCategory.values)
              DropdownMenuItem(value: category, child: Text(category.label)),
          ],
          onChanged: (value) {
            if (value != null) notifier.setCategory(value);
          },
        ),
      ],
    );
  }
}
