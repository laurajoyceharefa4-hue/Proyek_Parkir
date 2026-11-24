import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/widgets/parkir_logo.dart';
import '../../services/app_services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1000)),
      _readLocalServices(),
    ]);
    if (mounted) context.go('/beranda');
  }

  Future<void> _readLocalServices() async {
    if (!AppServices.initialized) return;
    await Future.wait([
      AppServices.session.readToken(),
      Future<String>.value(AppServices.serverAddress.address),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context);
    return PopScope<void>(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          systemNavigationBarColor: AppColors.transparent,
          systemNavigationBarDividerColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: AppColors.brandDark,
          body: SizedBox.expand(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.brandDark, AppColors.splashBlack],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  inset.left,
                  inset.top,
                  inset.right,
                  inset.bottom,
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    const ParkirLogo(size: 112),
                    const Spacer(),
                    Semantics(
                      label: 'Memuat aplikasi',
                      child: SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            value: 0.6,
                            backgroundColor: AppColors.translucentWhite,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.brandBright,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
