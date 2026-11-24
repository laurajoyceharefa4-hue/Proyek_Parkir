import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:parkirpintar/features/auth/login_admin_screen.dart';
import 'package:parkirpintar/services/app_services.dart';
import 'package:parkirpintar/services/session_service.dart';

void main() {
  testWidgets('protected admin route redirects without a token', (
    tester,
  ) async {
    AppServices.initialized = false;
    AppServices.session = const SessionService(_EmptyStorage());
    final router = GoRouter(
      initialLocation: '/admin/rekap',
      redirect: (context, state) async {
        if (state.uri.path.startsWith('/admin/') &&
            (!AppServices.initialized ||
                await AppServices.session.readToken() == null)) {
          return '/login-admin';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login-admin',
          builder: (context, state) => const LoginAdminScreen(),
        ),
        GoRoute(
          path: '/admin/rekap',
          builder: (context, state) => const Scaffold(body: Text('RAHASIA')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    expect(find.text('RAHASIA'), findsNothing);
    expect(find.text('Username'), findsOneWidget);
  });
}

class _EmptyStorage implements SecureStorage {
  const _EmptyStorage();

  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> read({required String key}) async => null;

  @override
  Future<void> write({required String key, required String value}) async {}
}
