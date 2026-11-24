import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../features/beranda/beranda_screen.dart';
import '../features/beranda/splash_screen.dart';
import '../features/prediksi/form_prediksi_screen.dart';
import '../features/prediksi/hasil_prediksi_screen.dart';
import '../features/prediksi/riwayat_screen.dart';
import '../features/tren/tren_screen.dart';
import '../features/rekomendasi/rekomendasi_screen.dart';
import '../features/auth/profil_screen.dart';
import '../features/auth/login_admin_screen.dart';
import '../features/admin/rekap_akurasi_screen.dart';
import '../features/admin/pengaturan_parkir_screen.dart';
import '../features/admin/kelola_admin_screen.dart';
import '../features/admin/pengaturan_server_screen.dart';
import '../data/models/prediksi.dart';
import '../services/app_services.dart';
import 'widgets/app_bottom_nav.dart';
import 'navigation/back_handler.dart';

CustomTransitionPage<void> _slidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

      return SlideTransition(position: offset, child: child);
    },
  );
}

CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final path = state.uri.path;

      // Hasil prediksi hanya dapat dibuka
      // setelah proses prediksi dilakukan.
      if (path == '/prediksi/hasil' && state.extra is! Prediksi) {
        final horizon = int.tryParse(
          state.uri.queryParameters['horizon'] ?? '',
        );

        final selected = switch (horizon) {
          10 || 20 || 30 => horizon!,
          _ => 10,
        };

        return '/prediksi?horizon=$selected';
      }

      // Halaman login dan pengaturan server
      // dapat dibuka tanpa token admin.
      if (path == '/login-admin' || path == '/pengaturan-server') {
        return null;
      }

      if (path.startsWith('/admin/')) {
        final token = AppServices.initialized
            ? await AppServices.session.readToken()
            : null;

        if (token == null || token.isEmpty) {
          return '/login-admin';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) {
          return _fadePage(state: state, child: const SplashScreen());
        },
      ),

      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: Column(
              children: [
                Expanded(child: _ShellBackScope(child: child)),
                const AppBottomNav(),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/beranda',
            pageBuilder: (context, state) {
              return _fadePage(state: state, child: const BerandaScreen());
            },
          ),

          GoRoute(
            path: '/tren',
            pageBuilder: (context, state) {
              return _slidePage(state: state, child: const TrenScreen());
            },
          ),

          GoRoute(
            path: '/prediksi',
            pageBuilder: (context, state) {
              final horizon = int.tryParse(
                state.uri.queryParameters['horizon'] ?? '',
              );

              final selected = switch (horizon) {
                10 || 20 || 30 => horizon!,
                _ => 10,
              };

              return _slidePage(
                state: state,
                child: FormPrediksiScreen(initialHorizon: selected),
              );
            },
          ),

          GoRoute(
            path: '/prediksi/hasil',
            pageBuilder: (context, state) {
              return _slidePage(
                state: state,
                child: HasilPrediksiScreen(
                  prediksi: state.extra is Prediksi
                      ? state.extra! as Prediksi
                      : null,
                  horizon: int.tryParse(
                    state.uri.queryParameters['horizon'] ?? '',
                  ),
                ),
              );
            },
          ),

          GoRoute(
            path: '/riwayat',
            pageBuilder: (context, state) {
              return _slidePage(state: state, child: const RiwayatScreen());
            },
          ),

          GoRoute(
            path: '/riwayat/:id',
            pageBuilder: (context, state) {
              return _slidePage(
                state: state,
                child: RiwayatDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                  prediksi: state.extra is Prediksi
                      ? state.extra! as Prediksi
                      : null,
                ),
              );
            },
          ),

          GoRoute(
            path: '/profil',
            pageBuilder: (context, state) {
              return _slidePage(state: state, child: const ProfilScreen());
            },
          ),
        ],
      ),

      GoRoute(
        path: '/rekomendasi',
        pageBuilder: (context, state) {
          return _slidePage(state: state, child: const RekomendasiScreen());
        },
      ),

      GoRoute(
        path: '/login-admin',
        pageBuilder: (context, state) {
          return _slidePage(
            state: state,
            child: LoginAdminScreen(
              expired: state.uri.queryParameters['expired'] == '1',
            ),
          );
        },
      ),

      // Bisa diakses tanpa login, terutama
      // jika IP laptop berubah.
      GoRoute(
        path: '/pengaturan-server',
        pageBuilder: (context, state) {
          return _slidePage(
            state: state,
            child: const PengaturanServerScreen(),
          );
        },
      ),

      // Rute lama tetap dipertahankan
      // untuk menu pada Profil Admin.
      GoRoute(
        path: '/admin/pengaturan-server',
        pageBuilder: (context, state) {
          return _slidePage(
            state: state,
            child: const PengaturanServerScreen(),
          );
        },
      ),

      GoRoute(
        path: '/admin/rekap',
        pageBuilder: (context, state) {
          return _slidePage(state: state, child: const RekapAkurasiScreen());
        },
      ),

      GoRoute(
        path: '/admin/pengaturan-parkir',
        pageBuilder: (context, state) {
          return _slidePage(
            state: state,
            child: const PengaturanParkirScreen(),
          );
        },
      ),

      GoRoute(
        path: '/admin/kelola-admin',
        pageBuilder: (context, state) {
          return _slidePage(state: state, child: const KelolaAdminScreen());
        },
      ),
    ],
  );
}

class _ShellBackScope extends StatefulWidget {
  const _ShellBackScope({required this.child});

  final Widget child;

  @override
  State<_ShellBackScope> createState() => _ShellBackScopeState();
}

class _ShellBackScopeState extends State<_ShellBackScope> {
  DateTime? _lastBack;

  void _onBack() {
    final location = GoRouterState.of(context).uri.path;

    if (location != '/beranda') {
      handleBack(context);
      return;
    }

    final now = DateTime.now();

    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }

    _lastBack = now;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Tekan sekali lagi untuk keluar'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onBack();
        }
      },
      child: widget.child,
    );
  }
}
