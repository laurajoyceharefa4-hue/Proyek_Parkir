import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_constants.dart';
import '../status_level.dart';

class StatusTrack extends StatelessWidget {
  const StatusTrack({
    super.key,
    required this.percent,
    required this.ambangHampirPenuh,
    required this.ambangPenuh,
  });

  final double percent;
  final int ambangHampirPenuh;
  final int ambangPenuh;

  @override
  Widget build(BuildContext context) {
    final safePercent = percent.clamp(0, 100).toDouble();
    final hampirPenuh = (ambangHampirPenuh / 100).clamp(0.0, 1.0);
    final penuh = (ambangPenuh / 100).clamp(hampirPenuh, 1.0);
    final greenStop = (hampirPenuh - 0.05).clamp(0.0, 1.0);
    final yellowStop = ((hampirPenuh + penuh) / 2).clamp(greenStop, 1.0);
    final redStop = (penuh + 0.05).clamp(yellowStop, 1.0);
    return Semantics(
      label: 'Posisi keterisian parkir ${safePercent.round()} persen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const markerSize = 32.0;
                final markerRange = (constraints.maxWidth - markerSize)
                    .clamp(0.0, double.infinity)
                    .toDouble();
                final markerLeft =
                    (constraints.maxWidth * safePercent / 100 - markerSize / 2)
                        .clamp(0.0, markerRange)
                        .toDouble();

                return Column(
                  children: [
                    SizedBox(
                      height: 42,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 30,
                            child: Container(
                              width: double.infinity,
                              height: 12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: const [
                                    AppColors.statusKosong,
                                    AppColors.statusHampirPenuh,
                                    AppColors.statusPenuh,
                                  ],
                                  stops: [greenStop, yellowStop, redStop],
                                ),
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            left: markerLeft,
                            top: 0,
                            width: markerSize,
                            height: 42,
                            child: Stack(
                              children: [
                                Container(
                                  width: markerSize,
                                  height: markerSize,
                                  decoration: BoxDecoration(
                                    color: AppColors.brand,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surface,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.directions_car_rounded,
                                    size: 17,
                                    color: AppColors.surface,
                                  ),
                                ),
                                Positioned(
                                  left: (markerSize - 2) / 2,
                                  top: markerSize - 1,
                                  width: 2,
                                  height: 10,
                                  child: const ColoredBox(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Row(
                      children: [
                        Expanded(
                          child: _label(
                            StatusLevel.kosong.label,
                            AppColors.statusKosong,
                            Alignment.centerLeft,
                          ),
                        ),
                        Expanded(
                          child: _label(
                            StatusLevel.hampirPenuh.label,
                            AppColors.statusHampirPenuh,
                            Alignment.center,
                          ),
                        ),
                        Expanded(
                          child: _label(
                            StatusLevel.penuh.label,
                            AppColors.statusPenuh,
                            Alignment.centerRight,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, Color color, Alignment alignment) => Align(
    alignment: alignment,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
