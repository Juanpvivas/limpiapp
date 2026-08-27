import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/models/report.dart';
import '../ui/core/ui/app_bottom_nav_bar.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/map/widgets/report_map_screen.dart';
import '../ui/reports/widgets/confirmation_screen.dart';
import '../ui/reports/widgets/new_report_screen.dart';
import '../ui/reports/widgets/report_detail_screen.dart';
import '../ui/reports/widgets/report_list_screen.dart';

/// Una de las 3 ramas de la barra de navegación inferior. No es un domain
/// model (ver `specs/001-navegacion-principal/data-model.md`): es un detalle
/// de ruteo/UI, por eso vive en `config/` y no en `domain/models/`.
enum AppTab {
  home(
    path: '/',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Inicio',
  ),
  reportar(
    path: '/reportar',
    icon: Icons.camera_alt_outlined,
    selectedIcon: Icons.camera_alt,
    label: 'Reportar',
  ),
  mapa(
    path: '/mapa',
    icon: Icons.map_outlined,
    selectedIcon: Icons.map,
    label: 'Mapa',
  );

  const AppTab({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Ruta anidada dentro de la rama [AppTab.home] (no es una rama propia de la
/// barra inferior, ver FR-004/FR-006 en `spec.md`).
const String misReportesPath = '/mis-reportes';

/// Construye una instancia nueva del router. Se usa una función (en vez de
/// un único `GoRouter` global reutilizado) para que los widget tests puedan
/// crear una instancia aislada por test sin arrastrar estado de navegación
/// de un test a otro.
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: AppTab.home.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: AppBottomNavBar(
              navigationShell: navigationShell,
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppTab.home.path,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'mis-reportes',
                    builder: (context, state) => const ReportListScreen(),
                    routes: [
                      // "Detalle del reporte" (003) — anidada bajo
                      // /mis-reportes: a diferencia de "Confirmación"
                      // (issue #28), aquí SÍ corresponde mostrar la barra de
                      // navegación inferior, por eso queda dentro del shell.
                      // El `reportId` es el ID del documento de Firestore
                      // (research.md §5).
                      GoRoute(
                        path: ':reportId',
                        builder: (context, state) => ReportDetailScreen(
                          reportId: state.pathParameters['reportId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppTab.reportar.path,
                builder: (context, state) => const NewReportScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppTab.mapa.path,
                builder: (context, state) => const ReportMapScreen(),
              ),
            ],
          ),
        ],
      ),
      // Ruta top-level, hermana del shell (no anidada en ninguna rama): así
      // renderiza sin la barra de navegación inferior, igual que el mock
      // (issue #28 — `StatefulShellRoute.indexedStack` envuelve en su propio
      // `Scaffold` con bottom nav a cualquier ruta anidada dentro de una
      // rama, aunque esa ruta sea "de paso" como esta).
      // FR-025: solo alcanzable con un Report recibido como `extra` de un
      // envío exitoso; si no, redirige a Inicio.
      GoRoute(
        path: '${AppTab.reportar.path}/confirmacion',
        redirect: (context, state) =>
            state.extra is Report ? null : AppTab.home.path,
        builder: (context, state) =>
            ConfirmationScreen(report: state.extra! as Report),
      ),
    ],
  );
}

/// Instancia usada por la app real (`app.dart`). Los tests deben llamar a
/// [buildAppRouter] directamente en vez de reusar esta instancia global.
final GoRouter appRouter = buildAppRouter();
