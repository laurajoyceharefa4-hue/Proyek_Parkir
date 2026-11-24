import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_constants.dart';
import 'screen_scaffold.dart';
import 'round_back_button.dart';

class AdminScreenScaffold extends StatelessWidget {
  const AdminScreenScaffold({
    super.key,
    required this.title,
    required this.accent,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  final String title;
  final String accent;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ScreenScaffold(
    body: ListView(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.viewPaddingOf(context).bottom + AppSpacing.screenPadding,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const RoundBackButton(fallbackLocation: '/profil'),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineLarge,
            children: [
              TextSpan(text: title),
              TextSpan(
                text: accent,
                style: TextStyle(color: AppColors.brand),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.l),
        ...children,
      ],
    ),
  );
}
