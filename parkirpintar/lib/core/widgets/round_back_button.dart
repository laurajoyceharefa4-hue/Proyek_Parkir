import 'package:flutter/material.dart';

import '../navigation/back_handler.dart';

class RoundBackButton extends StatelessWidget {
  const RoundBackButton({
    super.key,
    this.fallbackLocation = '/beranda',
    this.backgroundColor,
    this.foregroundColor,
  });

  final String fallbackLocation;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: 'Kembali',
    onPressed: () => handleBack(context, fallbackLocation: fallbackLocation),
    style: IconButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.primary,
      backgroundColor: backgroundColor,
    ),
    icon: const Icon(Icons.arrow_back_rounded),
  );
}
