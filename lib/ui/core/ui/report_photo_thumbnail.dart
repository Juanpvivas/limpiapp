import 'package:flutter/material.dart';

/// Miniatura cuadrada de la foto de un reporte. Extraída de
/// `report_list_item.dart` (feature 003) para reutilizarla en la tarjeta
/// resumen del mapa (feature 004). `StatelessWidget`: solo recibe la `url`.
class ReportPhotoThumbnail extends StatelessWidget {
  const ReportPhotoThumbnail({required this.url, this.size = 64, super.key});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? const ColoredBox(
                color: Color(0xFFEEEEEE),
                child: Icon(Icons.image_not_supported_outlined, size: 24),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const ColoredBox(
                        color: Color(0xFFEEEEEE),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                errorBuilder: (context, error, stack) => const ColoredBox(
                  color: Color(0xFFEEEEEE),
                  child: Icon(Icons.broken_image_outlined, size: 24),
                ),
              ),
      ),
    );
  }
}
