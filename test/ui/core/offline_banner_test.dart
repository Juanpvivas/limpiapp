import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiapp/domain/models/connectivity_status.dart';
import 'package:limpiapp/ui/core/offline_copy.dart';
import 'package:limpiapp/ui/core/providers/connectivity_provider.dart';
import 'package:limpiapp/ui/core/ui/offline_banner.dart';

void main() {
  testWidgets('el builder de MaterialApp.router apila la franja sobre la ruta '
      'activa', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('pantalla ruteada'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWith(
            (ref) => Stream.value(ConnectivityStatus.offline),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => Column(
            children: [
              const OfflineBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(kOfflineBannerText), findsOneWidget);
    expect(find.text('pantalla ruteada'), findsOneWidget);
  });

  testWidgets('aparece con offline, desaparece con online, y no intercepta '
      'gestos del contenido', (tester) async {
    final controller = StreamController<ConnectivityStatus>.broadcast();
    addTearDown(controller.close);
    var taps = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWith((ref) => controller.stream),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const OfflineBanner(),
                Expanded(
                  child: GestureDetector(
                    onTap: () => taps++,
                    child: const ColoredBox(
                      color: Color(0xFFEEEEEE),
                      child: SizedBox.expand(child: Text('contenido')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Sin dato aún → se trata como online → sin franja.
    await tester.pump();
    expect(find.text(kOfflineBannerText), findsNothing);

    controller.add(ConnectivityStatus.offline);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250)); // AnimatedSize
    expect(find.text(kOfflineBannerText), findsOneWidget);

    // Con la franja visible, un tap sobre el contenido detrás sigue llegando.
    await tester.tap(find.text('contenido'));
    expect(taps, 1);

    controller.add(ConnectivityStatus.online);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text(kOfflineBannerText), findsNothing);
  });
}
