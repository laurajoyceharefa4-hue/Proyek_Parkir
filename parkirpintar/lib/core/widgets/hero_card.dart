import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_constants.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandBright, AppColors.statusPenuh],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -42,
              child: _Orb(diameter: 170, opacity: 0.08),
            ),
            Positioned(
              right: 48,
              bottom: -74,
              child: _Orb(diameter: 190, opacity: 0.07),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.diameter, required this.opacity});

  final double diameter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: opacity == 0.08
              ? AppColors.translucentSurfaceStrong
              : AppColors.translucentSurface,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
