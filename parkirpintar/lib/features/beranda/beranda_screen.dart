import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/waktu_swiss.dart';
import '../../core/widgets/connection_banner.dart';
import '../../core/widgets/hero_card.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../core/widgets/skeleton_box.dart';
import '../../core/widgets/status_chip.dart';

import '../../data/models/rekomendasi.dart';
import '../../data/models/status_parkir.dart';
import '../../data/models/tren.dart';
import '../../data/repository/parkir_exception.dart';

import '../../services/app_services.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  StatusParkir? _status;
  Rekomendasi? _rekomendasi;
  Tren? _tren;

  String? _error;
  bool _loading = true;
  bool _admin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = AppServices.initialized
          ? await AppServices.session.readToken()
          : null;

      final values = await Future.wait<Object>([
        AppServices.repository.getStatus(),
        AppServices.repository.getRekomendasi(),
        AppServices.repository.getTren(),
      ]);

      if (!mounted) return;

      setState(() {
        _admin = token != null && token.isNotEmpty;
        _status = values[0] as StatusParkir;
        _rekomendasi = values[1] as Rekomendasi;
        _tren = values[2] as Tren;
        _loading = false;
      });
    } on ParkirException catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.jenis == JenisGalat.koneksi ? 'koneksi' : error.pesan;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Data historis tidak dapat dimuat.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      hasBottomNav: true,
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                top: AppSpacing.xxl,
                bottom: ScreenScaffold.contentBottomPadding(context),
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_error == 'koneksi') ...[
                    ConnectionBanner(onRetry: _load, isAdmin: _admin),
                    const SizedBox(height: AppSpacing.cardGap),
                  ],

                  const _GreetingHeader(),

                  const SizedBox(height: AppSpacing.xl),

                  const _PageTitle(),

                  const SizedBox(height: AppSpacing.s),

                  const Text(
                    'Lokasi: Oberes Mätteli, Frauenfeld, Swiss',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: AppSpacing.s),

                  const _HistoricalNotice(),

                  const SizedBox(height: AppSpacing.l),

                  if (_loading) ..._loadingContent() else ..._content(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _loadingContent() => [
    const SkeletonBox(height: 280),
    const SizedBox(height: AppSpacing.cardGap),
    Row(
      children: List.generate(
        3,
        (_) => const Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: AppSpacing.s),
            child: SkeletonBox(height: 130),
          ),
        ),
      ),
    ),
    const SizedBox(height: AppSpacing.cardGap),
    const SkeletonBox(height: 190),
    const SizedBox(height: AppSpacing.cardGap),
    const SkeletonBox(height: 220),
  ];

  List<Widget> _content() => [
    if (_status != null) _HeroStatus(status: _status!),

    const SizedBox(height: AppSpacing.cardGap),

    const _PredictionShortcuts(),

    const SizedBox(height: AppSpacing.cardGap),

    if (_rekomendasi != null) _RecommendationCard(data: _rekomendasi!),

    const SizedBox(height: AppSpacing.cardGap),

    if (_tren != null) _TrendCard(data: _tren!),

    if (_error != null && _error != 'koneksi') ...[
      Text(_error!, style: const TextStyle(color: AppColors.brandDark)),
      TextButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Coba Lagi'),
      ),
    ],
  ];
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    final greeting = hour < 11
        ? 'Selamat pagi'
        : hour < 15
        ? 'Selamat siang'
        : hour < 18
        ? 'Selamat sore'
        : 'Selamat malam';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.brandSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: AppColors.brand),
        ),

        const SizedBox(width: AppSpacing.m),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.bodySmall),
              Text(
                AppServices.adminName ?? 'Pengguna Parkir',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.headlineLarge,
        children: const [
          TextSpan(text: 'Status '),
          TextSpan(
            text: 'Parkir',
            style: TextStyle(color: AppColors.brand),
          ),
        ],
      ),
    );
  }
}

class _HistoricalNotice extends StatelessWidget {
  const _HistoricalNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history_rounded, color: AppColors.brand),

          SizedBox(width: AppSpacing.s),

          Expanded(
            child: Text(
              'DEMO HISTORIS · Data 2024\n'
              'Bukan informasi ketersediaan '
              'slot parkir saat ini.',
              style: TextStyle(color: AppColors.brandDark, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({required this.status});

  final StatusParkir status;

  @override
  Widget build(BuildContext context) {
    final progress = status.kapasitas <= 0
        ? 0.0
        : (status.terisi / status.kapasitas).clamp(0.0, 1.0);

    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Pengamatan Historis',
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: AppSpacing.s),

          Text(
            WaktuSwiss.tanggalJam(status.waktu),
            style: const TextStyle(
              color: AppColors.softWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppSpacing.l),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: status.slotTersedia.toDouble()),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Text(
                    value.round().toString(),
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 54,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  );
                },
              ),

              const SizedBox(width: AppSpacing.s),

              Expanded(
                child: Text(
                  'slot kosong dari '
                  '${status.kapasitas}',
                  style: const TextStyle(
                    color: AppColors.softWhite,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.m),

          StatusChip(status: status.status, onBrand: true),

          const SizedBox(height: AppSpacing.xl),

          Semantics(
            label:
                '${status.terisi} dari '
                '${status.kapasitas} slot terisi',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: progress,
                backgroundColor: AppColors.brandDark.withAlpha(80),
                valueColor: const AlwaysStoppedAnimation(AppColors.surface),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.s),

          Row(
            children: [
              Expanded(
                child: Text(
                  '${status.terisi} dari '
                  '${status.kapasitas} terisi',
                  style: const TextStyle(
                    color: AppColors.softWhite,
                    fontSize: 12,
                  ),
                ),
              ),

              Text(
                'Kapasitas ${status.kapasitas}',
                style: const TextStyle(
                  color: AppColors.mutedWhite,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.m),

          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Buka Prediksi Parkir',
              onPressed: () {
                context.push('/prediksi');
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.brand,
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionShortcuts extends StatelessWidget {
  const _PredictionShortcuts();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final horizon in AppConstants.horizons)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s),
              child: _ShortcutCard(horizon: horizon),
            ),
          ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.horizon});

  final int horizon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buka perkiraan prediksi $horizon menit',
      child: InkWell(
        onTap: () {
          context.push('/prediksi?horizon=$horizon');
        },
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            border: Border.all(color: AppColors.outline),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: AppColors.brand,
                ),
              ),

              const SizedBox(height: AppSpacing.s),

              Text(
                'Prediksi',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),

              Text(
                '$horizon menit',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.s),

              const Text(
                'XGBoost',
                style: TextStyle(
                  color: AppColors.brand,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.data});

  final Rekomendasi data;

  @override
  Widget build(BuildContext context) {
    final quiet = data.tersepi.isEmpty ? null : data.tersepi.first.jam;

    final busy = data.teramai.isEmpty ? null : data.teramai.first.jam;

    String clock(int? hour) {
      if (hour == null) {
        return 'Tidak tersedia';
      }

      return '${hour.toString().padLeft(2, '0')}.00';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.surface),
              SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  'Pola Parkir Historis',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.m),

          Text(
            quiet == null
                ? 'Jam tersepi belum tersedia'
                : 'Rata-rata jam tersepi: '
                      '${clock(quiet)} Swiss',
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppSpacing.s),

          Text(
            busy == null
                ? 'Jam teramai belum tersedia'
                : 'Rata-rata jam teramai: '
                      '${clock(busy)} Swiss',
            style: const TextStyle(color: AppColors.mutedWhite, fontSize: 13),
          ),

          const SizedBox(height: AppSpacing.l),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push('/rekomendasi');
              },
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
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.data});

  final Tren data;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var index = 0; index < data.harian.length; index++)
        FlSpot(index.toDouble(), data.harian[index].rataTerisi),
    ];

    final maxY = data.harian.isEmpty
        ? 100.0
        : data.harian
                  .map((item) => item.rataTerisi)
                  .reduce((a, b) => a > b ? a : b) +
              10;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tren Keterisian Historis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Text(
                'Rata-rata',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s),

          const Text(
            'Pola rata-rata per jam, '
            'bukan grafik kondisi real-time.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),

          const SizedBox(height: AppSpacing.l),

          if (spots.isEmpty)
            const SizedBox(
              height: 150,
              child: Center(child: Text('Data tren belum tersedia.')),
            )
          else
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (spots.length - 1).toDouble().clamp(1.0, 23.0),
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.brand,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.brandSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(height: AppSpacing.xxl),

          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.brand,
              ),
              SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  'Grafik berdasarkan '
                  'pengamatan historis Swiss.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
