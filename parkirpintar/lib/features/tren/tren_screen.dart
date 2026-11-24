import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/widgets/connection_banner.dart';
import '../../core/widgets/skeleton_box.dart';
import '../../core/widgets/info_tip_card.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../core/widgets/stat_tile.dart';
import '../../data/models/tren.dart';
import '../../data/repository/parkir_exception.dart';
import '../../services/app_services.dart';

class TrenScreen extends StatefulWidget {
  const TrenScreen({super.key});
  @override
  State<TrenScreen> createState() => _TrenScreenState();
}

class _TrenScreenState extends State<TrenScreen> {
  Tren? _data;
  bool _weekly = false;
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _offline = false;
    });
    try {
      final data = await AppServices.repository.getTren();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } on ParkirException catch (error) {
      if (mounted) {
        setState(() {
          _offline = error.jenis == JenisGalat.koneksi;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = _weekly
        ? (_data?.mingguan ?? const <TitikTren>[])
        : (_data?.harian ?? const <TitikTren>[]);
    final max = values.isEmpty
        ? 100.0
        : values.map((e) => e.rataTerisi).reduce((a, b) => a > b ? a : b) + 10;
    return ScreenScaffold(
      hasBottomNav: true,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.only(
            top: AppSpacing.xxl,
            bottom: ScreenScaffold.contentBottomPadding(context),
          ),
          children: [
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineLarge,
                children: const [
                  TextSpan(text: 'Tren '),
                  TextSpan(
                    text: 'Parkir',
                    style: TextStyle(color: AppColors.brand),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Pola keterisian parkir dari data historis.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        height: 40,
                        width: double.infinity,
                        child: ChoiceChip(
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Harian'),
                          ),
                          selected: !_weekly,
                          onSelected: (_) => setState(() => _weekly = false),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        height: 40,
                        width: double.infinity,
                        child: ChoiceChip(
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Mingguan'),
                          ),
                          selected: _weekly,
                          onSelected: (_) => setState(() => _weekly = true),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.cardGap),
            if (_offline) ConnectionBanner(onRetry: _load),
            if (_loading)
              const SkeletonBox(height: 360, animate: false)
            else if (values.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Center(child: Text('Belum ada data tren.')),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _weekly
                            ? 'Rata-rata per hari'
                            : 'Rata-rata Terisi per Jam',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.l),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final chartHeight = constraints.maxHeight.isFinite
                              ? constraints.maxHeight.clamp(240.0, 360.0)
                              : (MediaQuery.sizeOf(context).height * .32).clamp(
                                  240.0,
                                  360.0,
                                );
                          return SizedBox(
                            height: chartHeight,
                            child: Semantics(
                              label:
                                  'Grafik tren parkir, rata-rata ${_summary(values)}',
                              child: LineChart(
                                LineChartData(
                                  minX: 0,
                                  maxX: (values.length - 1).toDouble(),
                                  minY: 0,
                                  maxY: max,
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) =>
                                        const FlLine(
                                          color: AppColors.outline,
                                          strokeWidth: 1,
                                          dashArray: [4, 4],
                                        ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 32,
                                        interval: max / 3,
                                        getTitlesWidget: (value, meta) => Text(
                                          value.round().toString(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: _weekly ? 1 : 4,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.round();
                                          return index >= 0 &&
                                                  index < values.length
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: AppSpacing.s,
                                                      ),
                                                  child: Text(
                                                    values[index].label,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox();
                                        },
                                      ),
                                    ),
                                  ),
                                  lineTouchData: LineTouchData(
                                    enabled: true,
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipColor: (_) =>
                                          AppColors.brandDark,
                                      getTooltipItems: (spots) => spots
                                          .map(
                                            (spot) => LineTooltipItem(
                                              '${values[spot.x.round()].label} · ${spot.y.round()} kendaraan',
                                              const TextStyle(
                                                color: AppColors.surface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        for (var i = 0; i < values.length; i++)
                                          FlSpot(
                                            i.toDouble(),
                                            values[i].rataTerisi,
                                          ),
                                      ],
                                      isCurved: true,
                                      color: AppColors.brand,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: AppColors.brandSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.l),
                      Text(
                        'Paling ramai ${_weekly ? 'hari' : 'pukul'} ${_peak(values).label}${_weekly ? '' : '.00'}.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.trending_up_rounded,
                      value: _formatPoint(_peak(values)),
                      label: _weekly ? 'Hari teramai' : 'Puncak',
                      detail: '${_peak(values).rataTerisi.round()} terisi',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: StatTile(
                      icon: Icons.trending_down_rounded,
                      value: _formatPoint(_lowest(values)),
                      label: _weekly ? 'Hari tersepi' : 'Tersepi',
                      detail: '${_lowest(values).rataTerisi.round()} terisi',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: StatTile(
                      icon: Icons.analytics_outlined,
                      value: _formatNumber(_average(values)),
                      label: 'Rata-rata',
                      detail: 'slot terisi',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.cardGap),
              InfoTipCard(
                message:
                    'Jam tersepi: ${_lowest(values).label}${_weekly ? '' : '.00'}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  TitikTren _peak(List<TitikTren> values) =>
      values.reduce((a, b) => a.rataTerisi >= b.rataTerisi ? a : b);
  TitikTren _lowest(List<TitikTren> values) =>
      values.reduce((a, b) => a.rataTerisi <= b.rataTerisi ? a : b);

  double _average(List<TitikTren> values) =>
      values.map((item) => item.rataTerisi).reduce((a, b) => a + b) /
      values.length;

  String _formatPoint(TitikTren point) => _weekly
      ? point.label
      : '${point.label}.00 · ${point.rataTerisi.toStringAsFixed(0)}';

  String _formatNumber(double value) {
    final decimals = value == value.roundToDouble() ? 0 : 1;
    return value.toStringAsFixed(decimals).replaceAll('.', ',');
  }

  String _summary(List<TitikTren> values) =>
      values.isEmpty ? 'belum tersedia' : 'puncak ${_peak(values).label}';
}
