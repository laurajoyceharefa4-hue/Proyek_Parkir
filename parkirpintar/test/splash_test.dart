import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parkirpintar/core/app_router.dart';
import 'package:parkirpintar/data/repository/mock_parkir_repository.dart';
import 'package:parkirpintar/features/beranda/beranda_screen.dart';
import 'package:parkirpintar/services/app_services.dart';

void main() {
  setUp(() {
    // Test tidak membutuhkan FastAPI asli.
    // Namun repository harus tersedia sebelum
    // SplashScreen membuka Beranda.
    AppServices.repository = MockParkirRepository();

    // Melewati pembacaan layanan lokal
    // yang tidak diperlukan dalam widget test.
    AppServices.initialized = false;
    AppServices.adminName = null;
  });

  testWidgets('Splash berpindah ke Beranda', (tester) async {
    final router = createAppRouter();

    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // Splash menampilkan animasi sekitar
    // satu detik sebelum navigasi.
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(BerandaScreen), findsOneWidget);

    // Beranda menggunakan repository mock
    // khusus dalam pengujian ini.
    expect(AppServices.repository, isA<MockParkirRepository>());
  });
}
