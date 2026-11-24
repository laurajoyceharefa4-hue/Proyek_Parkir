import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/waktu_swiss.dart';
import '../../core/widgets/hero_card.dart';
import '../../core/widgets/round_back_button.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/status_track.dart';

import '../../data/models/konfigurasi.dart';
import '../../data/models/prediksi.dart';
import '../../services/app_services.dart';

class HasilPrediksiScreen extends StatefulWidget {
  const HasilPrediksiScreen({super.key, this.prediksi, this.horizon});

  final Prediksi? prediksi;
  final int? horizon;

  @override
  State<HasilPrediksiScreen> createState() => _HasilPrediksiScreenState();
}

class _HasilPrediksiScreenState extends State<HasilPrediksiScreen> {
  Prediksi? _result;
  Konfigurasi? _config;

  bool _loadingConfig = false;
  bool _configFailed = false;

  @override
  void initState() {
    super.initState();

    // Prediksi sudah dibuat pada FormPrediksiScreen.
    // Jangan memanggil endpoint prediksi lagi.
    _result = widget.prediksi;

    if (_result != null) {
      _loadConfig();
    }
  }

  @override
  void didUpdateWidget(covariant HasilPrediksiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.prediksi != oldWidget.prediksi) {
      _result = widget.prediksi;
      _config = null;
      _configFailed = false;

      if (_result != null) {
        _loadConfig();
      }
    }
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loadingConfig = true;
      _configFailed = false;
    });

    try {
      final config = await AppServices.repository.getKonfigurasi();

      if (!mounted) return;

      setState(() {
        _config = config;
        _loadingConfig = false;
      });
    } catch (_) {
      if (!mounted) return;

      // Hasil prediksi tetap ditampilkan
      // walaupun konfigurasi gagal dimuat.
      setState(() {
        _config = null;
        _configFailed = true;
        _loadingConfig = false;
      });
    }
  }

  void _prediksiLagi() {
    final horizon = _result?.horizonMenit ?? widget.horizon ?? 10;

    context.go('/prediksi?horizon=$horizon');
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    if (result == null) {
      return _emptyResult(context);
    }

    final percent = result.kapasitas <= 0
        ? 0.0
        : result.perkiraanKendaraan / result.kapasitas * 100;

    final waktuTarget = WaktuSwiss.tanggalJam(result.waktuTarget);

    final waktuSimpan = DateFormat('dd/MM/yyyy, HH.mm')
        .format(result.waktu.toLocal());

    return ScreenScaffold(
      hasBottomNav: true,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: AppSpacing.xxl,
          bottom: ScreenScaffold.contentBottomPadding(context),
        ),
        children: [
          _header(context),

          const SizedBox(height: AppSpacing.m),

          _historicalNotice(),

          const SizedBox(height: AppSpacing.l),

          Text(
            'Target: $waktuTarget',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppColors.brand, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: AppSpacing.s),

          Text(
            '${result.horizonMenit} menit setelah '
            'waktu pengamatan historis.',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: AppSpacing.cardGap),

          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prediksi slot parkir tersedia',
                  style: TextStyle(color: AppColors.softWhite, fontSize: 14),
                ),

                const SizedBox(height: AppSpacing.m),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: result.slotTersedia.toDouble(),
                      ),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Text(
                          value.round().toString(),
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 54,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: AppSpacing.s),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s),
                        child: Text(
                          'dari ${result.kapasitas} slot',
                          style: const TextStyle(
                            color: AppColors.softWhite,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.l),

                StatusChip(status: result.status, onBrand: true),

                const Divider(
                  height: AppSpacing.xxl,
                  color: AppColors.translucentWhite,
                ),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Perkiraan slot terisi',
                        style: TextStyle(color: AppColors.softWhite),
                      ),
                    ),
                    Text(
                      '${result.perkiraanKendaraan} slot',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.cardGap),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posisi Keterisian',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: AppSpacing.m),

                  Text(
                    '${result.perkiraanKendaraan} '
                    'dari ${result.kapasitas} slot '
                    'diprediksi terisi '
                    '(${percent.toStringAsFixed(1).replaceAll('.', ',')}%).',
                  ),

                  const SizedBox(height: AppSpacing.m),

                  if (_loadingConfig)
                    const LinearProgressIndicator()
                  else if (_config != null)
                    StatusTrack(
                      percent: percent,
                      ambangHampirPenuh: _config!.ambangHampirPenuh,
                      ambangPenuh: _config!.ambangPenuh,
                    )
                  else
                    LinearProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      minHeight: 10,
                      color: AppColors.brand,
                      backgroundColor: AppColors.brandSoft,
                    ),

                  if (_configFailed) ...[
                    const SizedBox(height: AppSpacing.m),
                    const Text(
                      'Pengaturan ambang belum '
                      'dapat dimuat. Status prediksi '
                      'tetap menggunakan hasil '
                      'yang dikirim FastAPI.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.cardGap),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rincian Prediksi XGBoost',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: AppSpacing.m),

                  _detail('Model', result.model.toUpperCase()),

                  _detail('Horizon', '${result.horizonMenit} menit'),

                  _detail('Kapasitas', '${result.kapasitas} slot'),

                  _detail('Slot tersedia', '${result.slotTersedia} slot'),

                  _detail('Slot terisi', '${result.perkiraanKendaraan} slot'),

                  _detail(
                    'MAE data testing',
                    '${result.maeHistoris.toStringAsFixed(4).replaceAll('.', ',')} slot',
                  ),

                  _detail('ID riwayat', '${result.riwayatId}'),

                  _detail('Disimpan (waktu perangkat)', waktuSimpan),

                  const Divider(height: AppSpacing.xxl),

                  const Text(
                    'MAE merupakan rata-rata '
                    'galat model pada data testing, '
                    'bukan selisih prediksi dan '
                    'aktual untuk satu pengamatan.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.cardGap),

          Card(
            color: AppColors.brandSoft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.brand),
                      SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          'Perkiraan, bukan jaminan',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.m),

                  Text(
                    result.keterangan,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),

                  const SizedBox(height: AppSpacing.m),

                  const Text(
                    'Prediksi ini menggunakan '
                    'pengamatan historis lokasi '
                    'Oberes Mätteli, Frauenfeld. '
                    'Bukan informasi ketersediaan '
                    'parkir secara real-time.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.l),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _prediksiLagi,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Prediksi Lagi'),
            ),
          ),

          const SizedBox(height: AppSpacing.s),

          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push('/riwayat');
              },
              icon: const Icon(Icons.history_rounded),
              label: const Text('Lihat Riwayat'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const RoundBackButton(),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineLarge,
              children: const [
                TextSpan(text: 'Hasil '),
                TextSpan(
                  text: 'Prediksi',
                  style: TextStyle(color: AppColors.brand),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _historicalNotice() {
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
              'DEMO HISTORIS · DATA 2024\n'
              'Waktu target menggunakan '
              'zona waktu Swiss (CET/CEST).',
              style: TextStyle(color: AppColors.brandDark, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyResult(BuildContext context) {
    return ScreenScaffold(
      hasBottomNav: true,
      body: ListView(
        padding: EdgeInsets.only(
          top: AppSpacing.xxl,
          bottom: ScreenScaffold.contentBottomPadding(context),
        ),
        children: [
          _header(context),

          const SizedBox(height: AppSpacing.xl),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 42,
                    color: AppColors.brand,
                  ),
                  SizedBox(height: AppSpacing.m),
                  Text(
                    'Belum ada hasil prediksi.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.s),
                  Text(
                    'Pilih tanggal, jam pengamatan, '
                    'dan horizon melalui form '
                    'prediksi terlebih dahulu.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.l),

          FilledButton.icon(
            onPressed: _prediksiLagi,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Kembali ke Form Prediksi'),
          ),
        ],
      ),
    );
  }
}
