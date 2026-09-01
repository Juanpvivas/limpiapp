import 'package:flutter/material.dart';

import 'config/routes.dart';
import 'ui/core/ui/offline_banner.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ibagué Limpia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
      // Aviso global de "sin conexión" apilado sobre TODA ruta (shell y rutas
      // top-level como "Confirmación"), sin tocar routes.dart (feature 005).
      builder: (context, child) => Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}
