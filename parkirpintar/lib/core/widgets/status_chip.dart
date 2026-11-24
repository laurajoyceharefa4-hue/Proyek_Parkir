import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_constants.dart';
import '../status_level.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.onBrand = false});

  final StatusLevel status;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final background = onBrand ? AppColors.surface : status.warna.withAlpha(28);
    final foreground = onBrand ? AppColors.textPrimary : status.warna;
    return Semantics(
      label: 'Status parkir: ${status.label}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.ikon, size: 16, color: foreground),
            const SizedBox(width: AppSpacing.s),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
