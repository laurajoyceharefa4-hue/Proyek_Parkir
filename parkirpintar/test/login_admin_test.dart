import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:parkirpintar/data/repository/mock_parkir_repository.dart';
import 'package:parkirpintar/features/auth/login_admin_screen.dart';
import 'package:parkirpintar/services/app_services.dart';
import 'package:parkirpintar/services/session_service.dart';

void main() {
  late _MemoryStorage storage;

  setUp(() {
    storage = _MemoryStorage();
    AppServices.repository = MockParkirRepository();
    AppServices.session = SessionService(storage);
    AppServices.initialized = true;
  });

  testWidgets('login salah menampilkan pesan yang jelas', (tester) async {
    await tester.pumpWidget(_app());
    await tester.enterText(find.byType(TextField).at(0), 'salah');
    await tester.enterText(find.byType(TextField).at(1), 'salah');
    await tester.tap(find.text('Masuk'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Username atau password salah'), findsOneWidget);
  });

  testWidgets('login berhasil menyimpan token dan membuka Profil', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), 'admin123');
    await tester.tap(find.text('Masuk'));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    expect(await AppServices.session.readToken(), 'mock-jwt-token');
    expect(find.text('Profil tujuan'), findsOneWidget);
  });
}

Widget _app() {
  final router = GoRouter(
    initialLocation: '/login-admin',
    routes: [
      GoRoute(
        path: '/login-admin',
        builder: (context, state) => const LoginAdminScreen(),
      ),
      GoRoute(
        path: '/profil',
        builder: (context, state) => const Scaffold(body: Text('Profil tujuan')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

class _MemoryStorage implements SecureStorage {
  String? token;

  @override
  Future<void> delete({required String key}) async => token = null;

  @override
  Future<String?> read({required String key}) async => token;

  @override
  Future<void> write({required String key, required String value}) async =>
      token = value;
}
