import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'widgets/screen_scaffold.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(color: AppColors.brandDark),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
