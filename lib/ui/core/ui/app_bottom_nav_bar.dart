import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';

/// Barra de navegación inferior persistente (FR-006, FR-007). No lee ningún
/// provider ni Notifier — todo su estado (rama activa) viene de
/// [StatefulNavigationShell], así que es un `StatelessWidget` (Principio III
/// de la constitución, ver `docs/ARCHITECTURE.md` Regla 9).
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      // FR-008: NavigationBar distingue visualmente el ítem seleccionado a
      // partir de currentIndex (SC-004).
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) =>
          navigationShell.goBranch(index, initialLocation: true),
      destinations: [
        for (final tab in AppTab.values)
          NavigationDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.selectedIcon),
            label: tab.label,
          ),
      ],
    );
  }
}
