import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import '../app_constants.dart';

/// Shared page layout for screens that draw edge-to-edge on Android.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.body,
    this.hasBottomNav = false,
    this.backgroundColor,
    this.decoration,
    this.lightSystemIcons = false,
  });

  final Widget body;
  final bool hasBottomNav;
  final Color? backgroundColor;
  final Decoration? decoration;
  final bool lightSystemIcons;

  static EdgeInsets overlayPadding(BuildContext context) {
    final media = MediaQuery.of(context);
    return EdgeInsets.only(
      bottom: media.viewInsets.bottom + media.viewPadding.bottom,
    );
  }

  static double contentBottomPadding(BuildContext context) =>
      AppBottomNavMetrics.totalHeight(context);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding + media.viewPadding.left,
        AppSpacing.screenPadding + media.viewPadding.top,
        AppSpacing.screenPadding + media.viewPadding.right,
        hasBottomNav ? 0 : media.viewPadding.bottom + AppSpacing.screenPadding,
      ),
      child: body,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        systemNavigationBarColor: AppColors.transparent,
        systemNavigationBarDividerColor: AppColors.transparent,
        statusBarIconBrightness: lightSystemIcons
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarIconBrightness: lightSystemIcons
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor ?? AppColors.background,
        body: decoration == null
            ? content
            : DecoratedBox(
                decoration: decoration!,
                child: SizedBox.expand(child: content),
              ),
      ),
    );
  }
}

class AppBottomNavMetrics {
  AppBottomNavMetrics._();

  static const double pillHeight = 80;
  static const double screenMargin = 0;
  static const double featuredLift = 24;
  static const double contentGap = AppSpacing.l;

  static double totalHeight(BuildContext context) =>
      pillHeight + MediaQuery.viewPaddingOf(context).bottom;

  static double contentBottomPadding(BuildContext context) =>
      featuredLift + contentGap;
}
