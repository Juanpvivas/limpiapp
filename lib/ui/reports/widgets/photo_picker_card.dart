import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/new_report_provider.dart';

/// Recuadro de foto + botones de captura + error de "imagen muy grande"
/// (FR-002, FR-004, FR-006).
class PhotoPickerCard extends ConsumerWidget {
  const PhotoPickerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(newReportProvider.select((s) => s.photo));
    final notifier = ref.read(newReportProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Toma una foto',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: photo == null
                ? const Center(
                    child: Icon(Icons.add_a_photo_outlined, size: 48),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      photo.bytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: notifier.pickPhotoFromCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Tomar foto'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: notifier.pickPhotoFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Elegir de galería'),
              ),
            ),
          ],
        ),
        if (photo != null && photo.exceedsMaxSize)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'La imagen es muy grande. Toma o elige otra foto.',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
      ],
    );
  }
}
