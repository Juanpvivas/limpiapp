import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/connectivity_status.dart';
import '../offline_copy.dart';
import '../providers/connectivity_provider.dart';

/// Aviso global de "sin conexión" (FR-001..FR-004). Se coloca en el `builder:`
/// de `MaterialApp.router`, apilado **encima** del contenido ruteado (Column),
/// así que ocupa su propio espacio y nunca intercepta gestos del contenido
/// (FR-003). Mientras `connectivityStatusProvider` esté en carga o sin dato se
/// trata como `online` → no se muestra (evita parpadeo en el arranque).
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline =
        ref.watch(connectivityStatusProvider).value ==
        ConnectivityStatus.offline;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: isOffline ? const _Bar() : const SizedBox(width: double.infinity),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF37474F),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.wifi_off, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                kOfflineBannerText,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
