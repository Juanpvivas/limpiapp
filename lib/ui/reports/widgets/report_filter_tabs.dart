import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/report_filter.dart';
import '../providers/report_filter_provider.dart';

/// Fila de 4 pestañas de filtro (FR-005). `ConsumerWidget`: lee
/// `reportFilterProvider` y despacha `select(...)` al tocar una pestaña.
class ReportFilterTabs extends ConsumerWidget {
  const ReportFilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportFilterProvider);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: ReportFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ReportFilter.values[index];
          return ChoiceChip(
            label: Text(filter.label),
            selected: filter == selected,
            onSelected: (_) =>
                ref.read(reportFilterProvider.notifier).select(filter),
          );
        },
      ),
    );
  }
}
