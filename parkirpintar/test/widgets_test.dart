import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:parkirpintar/core/app_colors.dart';
import 'package:parkirpintar/core/status_level.dart';
import 'package:parkirpintar/core/widgets/app_bottom_nav.dart';
import 'package:parkirpintar/core/widgets/status_chip.dart';

void main() {
  testWidgets('StatusChip shows icon and label for each status', (
    tester,
  ) async {
    for (final status in StatusLevel.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StatusChip(status: status)),
        ),
      );
      expect(find.text(status.label), findsOneWidget);
      expect(find.byIcon(status.ikon), findsOneWidget);
    }
  });

  testWidgets('AppBottomNav navigates to selected item', (tester) async {
    final router = GoRouter(
      initialLocation: '/beranda',
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              Scaffold(body: child, bottomNavigationBar: const AppBottomNav()),
          routes: [
            GoRoute(
              path: '/beranda',
              builder: (context, state) => const Text('Beranda'),
            ),
            GoRoute(
              path: '/tren',
              builder: (context, state) => const Text('Tren'),
            ),
            GoRoute(
              path: '/prediksi',
              builder: (context, state) => const Text('Prediksi'),
            ),
            GoRoute(
              path: '/riwayat',
              builder: (context, state) => const Text('Riwayat'),
            ),
            GoRoute(
              path: '/profil',
              builder: (context, state) => const Text('Profil'),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Tren').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tren'), findsOneWidget);
  });

  testWidgets('StatusChip keeps accessible contrast colors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusChip(status: StatusLevel.kosong)),
      ),
    );
    final text = tester.widget<Text>(find.text('Masih Lega'));
    expect(text.style?.color, AppColors.statusKosong);
  });
}
