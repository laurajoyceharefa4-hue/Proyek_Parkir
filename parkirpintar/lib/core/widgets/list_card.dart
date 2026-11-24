import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_constants.dart';
import '../status_level.dart';
import 'status_chip.dart';

class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.status,
    required this.onTap,
    this.leadingIcon = Icons.schedule_rounded,
    this.trailing = true,
  });

  final String title;
  final String subtitle;
  final String detail;
  final StatusLevel status;
  final VoidCallback onTap;
  final IconData leadingIcon;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle, $detail, ${status.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.l),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.outline),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                ),
                child: Icon(leadingIcon, color: AppColors.brand),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(status: status),
                  if (trailing) ...[
                    const SizedBox(height: AppSpacing.s),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.background,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
