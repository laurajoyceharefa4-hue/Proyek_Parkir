import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_colors.dart';
import '../app_constants.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    super.key,
    required this.onRetry,
    this.isAdmin = false,
  });

  final VoidCallback onRetry;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Tidak bisa terhubung ke server',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.brandDark),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    'Tidak bisa terhubung ke server. Pastikan HP dan laptop satu Wi-Fi.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.brandDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              children: [
                TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
                if (isAdmin)
                  TextButton(
                    onPressed: () => context.push('/admin/pengaturan-server'),
                    child: const Text('Pengaturan Server'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
