import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_colors.dart';
import '../app_constants.dart';

class InfoTipCard extends StatelessWidget {
  const InfoTipCard({
    super.key,
    required this.message,
    this.title = 'Mau tahu waktu terbaik?',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: AppColors.brand,
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.surface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(message, style: const TextStyle(color: AppColors.softWhite)),
        const SizedBox(height: AppSpacing.l),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/rekomendasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.brand,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lihat Rekomendasi'),
                Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
