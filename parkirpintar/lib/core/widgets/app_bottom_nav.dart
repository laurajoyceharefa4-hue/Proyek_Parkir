import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app_colors.dart';
import '../app_constants.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  static const _items = [
    (label: 'Beranda', path: '/beranda', icon: Icons.home_rounded),
    (label: 'Tren', path: '/tren', icon: Icons.show_chart_rounded),
    (label: 'Prediksi', path: '/prediksi', icon: Icons.calendar_month_rounded),
    (label: 'Riwayat', path: '/riwayat', icon: Icons.history_rounded),
    (label: 'Profil', path: '/profil', icon: Icons.person_rounded),
  ];

  static const double _contentHeight = 64;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        systemNavigationBarColor: AppColors.transparent,
        systemNavigationBarDividerColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: SizedBox(
        width: double.infinity,
        height: _contentHeight + bottom,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.brandDark,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.card),
                    topRight: Radius.circular(AppRadius.card),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottom),
                  child: SizedBox(
                    height: _contentHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s,
                      ),
                      child: Row(
                        children: [
                          for (var index = 0; index < _items.length; index++)
                            Expanded(
                              child: index == 2
                                  ? const SizedBox()
                                  : _NavItem(
                                      item: _items[index],
                                      selected: path == _items[index].path,
                                      onTap: () =>
                                          context.go(_items[index].path),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -20,
              height: 60,
              child: Center(
                child: _NavItem(
                  item: _items[2],
                  selected: path.startsWith('/prediksi'),
                  featured: true,
                  onTap: () => context.go(_items[2].path),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
    this.featured = false,
  });

  final ({String label, String path, IconData icon}) item;
  final bool selected;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final diameter = featured ? 60.0 : 56.0;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.surface,
      fontWeight: FontWeight.w700,
      fontSize: featured ? 9 : 10,
      height: 1,
    );
    return Semantics(
      button: true,
      label: item.label,
      selected: selected,
      child: Center(
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: featured || selected
                    ? AppColors.brand
                    : AppColors.transparent,
                shape: BoxShape.circle,
                border: featured
                    ? Border.all(color: AppColors.surface, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: featured ? 21 : 19,
                    color: AppColors.surface,
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(item.label, style: labelStyle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
