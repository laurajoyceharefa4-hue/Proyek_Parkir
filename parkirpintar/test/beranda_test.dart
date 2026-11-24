import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parkirpintar/data/repository/mock_parkir_repository.dart';
import 'package:parkirpintar/features/beranda/beranda_screen.dart';
import 'package:parkirpintar/services/app_services.dart';

void main() {
  late MockParkirRepository repository;

  setUp(() {
    repository = MockParkirRepository();
    AppServices.repository = repository;
    AppServices.initialized = false;
    AppServices.adminName = null;
  });

  testWidgets('Beranda menampilkan status dengan label historis', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BerandaScreen()));

    await tester.pump(const Duration(milliseconds: 650));

    expect(find.text('Status Pengamatan Historis'), findsOneWidget);

    expect(find.text('96 dari 150 terisi'), findsOneWidget);

    expect(find.text('Hampir Penuh'), findsOneWidget);

    expect(find.textContaining('DEMO HISTORIS'), findsOneWidget);

    expect(find.text('Status Parkir Sekarang'), findsNothing);
  });

  testWidgets('Beranda menampilkan pesan koneksi gagal', (tester) async {
    repository.simulasiOffline = true;

    await tester.pumpWidget(const MaterialApp(home: BerandaScreen()));

    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.textContaining('Tidak bisa terhubung ke server'),
      findsOneWidget,
    );

    expect(find.text('Coba Lagi'), findsOneWidget);
  });
}
