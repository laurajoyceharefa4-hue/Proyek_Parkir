import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/waktu_swiss.dart';
import '../../core/widgets/connection_banner.dart';
import '../../core/widgets/hero_card.dart';
import '../../core/widgets/list_card.dart';
import '../../core/widgets/round_back_button.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../core/widgets/skeleton_box.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/status_track.dart';

import '../../data/models/konfigurasi.dart';
import '../../data/models/prediksi.dart';
import '../../data/repository/parkir_exception.dart';
import '../../services/app_services.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<Prediksi> _items = const [];

  int? _filter;

  bool _loading = true;
  String? _error;

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
      final items = List<Prediksi>.of(
        await AppServices.repository.getRiwayat(
          deviceId: AppServices.deviceId ?? 'a1b2c3d4',
          semuaHp: false,
        ),
      );

      items.sort((a, b) => b.waktu.compareTo(a.waktu));

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
      });
    } on ParkirException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.jenis == JenisGalat.koneksi ? 'koneksi' : error.pesan;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Riwayat gagal dimuat.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null
        ? _items
        : _items.where((item) => item.horizonMenit == _filter).toList();

    return ScreenScaffold(
      hasBottomNav: true,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: AppSpacing.xxl,
            bottom: ScreenScaffold.contentBottomPadding(context),
          ),
          children: [
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineLarge,
                children: const [
                  TextSpan(text: 'Riwayat '),
                  TextSpan(
                    text: 'Prediksi',
                    style: TextStyle(color: AppColors.brand),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.s),

            Text(
              'Riwayat prediksi historis '
              'dari perangkat ini.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: AppSpacing.s),

            const Text(
              'Tanggal prediksi menggunakan waktu Swiss. '
              'Data historis bukan kondisi parkir saat ini.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),

            const SizedBox(height: AppSpacing.l),

            Row(
              children: [
                for (var index = 0; index < 4; index++) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.s),

                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ChoiceChip(
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                index == 0
                                    ? 'Semua'
                                    : '${AppConstants.horizons[index - 1]} menit',
                              ),
                            ),
                            selected:
                                _filter ==
                                (index == 0
                                    ? null
                                    : AppConstants.horizons[index - 1]),
                            onSelected: (_) {
                              setState(() {
                                _filter = index == 0
                                    ? null
                                    : AppConstants.horizons[index - 1];
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.l),

            if (_error == 'koneksi') ConnectionBanner(onRetry: _load),

            if (_error != null && _error != 'koneksi')
              Text(_error!, style: const TextStyle(color: AppColors.brandDark)),

            if (_loading)
              ...List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.cardGap),
                  child: SkeletonBox(height: 118, animate: false),
                ),
              )
            else if (_error == null && filtered.isEmpty)
              _EmptyHistory(
                filter: _filter,
                onReset: () {
                  setState(() {
                    _filter = null;
                  });
                },
              )
            else if (_error == null) ...[
              Text(
                '${filtered.length} prediksi',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: AppSpacing.s),

              for (final item in filtered)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
                  child: ListCard(
                    title: WaktuSwiss.tanggalJam(item.waktuTarget),
                    subtitle: 'Horizon ${item.horizonMenit} menit',
                    detail:
                        '${item.slotTersedia} slot tersedia '
                        'dari ${item.kapasitas} slot',
                    status: item.status,
                    onTap: () {
                      context.push('/riwayat/${item.riwayatId}', extra: item);
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.filter, required this.onReset});

  final int? filter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final filtered = filter != null;

    return SizedBox(
      height: 320,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: AppColors.brandSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 52,
                color: AppColors.brand,
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            Text(
              filtered
                  ? 'Belum ada prediksi $filter menit'
                  : 'Belum ada prediksi',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.s),

            Text(
              filtered
                  ? 'Coba tampilkan semua horizon.'
                  : 'Hasil prediksi historis '
                        'akan tersimpan di sini.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: AppSpacing.l),

            FilledButton.icon(
              onPressed: filtered ? onReset : () => context.push('/prediksi'),
              icon: Icon(
                filtered ? Icons.filter_alt_off_rounded : Icons.add_rounded,
              ),
              label: Text(filtered ? 'Lihat Semua' : 'Buat Prediksi'),
            ),
          ],
        ),
      ),
    );
  }
}

class RiwayatDetailScreen extends StatefulWidget {
  const RiwayatDetailScreen({super.key, required this.id, this.prediksi});

  final int id;
  final Prediksi? prediksi;

  @override
  State<RiwayatDetailScreen> createState() => _RiwayatDetailScreenState();
}

class _RiwayatDetailScreenState extends State<RiwayatDetailScreen> {
  Prediksi? _item;
  Konfigurasi? _config;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _item = widget.prediksi;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prediksi =
          _item ?? await AppServices.repository.getRiwayatDetail(widget.id);

      Konfigurasi? konfigurasi;

      try {
        konfigurasi = await AppServices.repository.getKonfigurasi();
      } catch (_) {
        // Detail tetap dapat dilihat jika
        // konfigurasi tidak bisa dimuat.
      }

      if (!mounted) return;

      setState(() {
        _item = prediksi;
        _config = konfigurasi;
        _loading = false;
      });
    } on ParkirException catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.pesan;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Detail riwayat tidak tersedia.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      hasBottomNav: true,
      body: _item == null
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error ?? 'Riwayat tidak tersedia.'),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: AppSpacing.xxl,
                bottom: ScreenScaffold.contentBottomPadding(context),
              ),
              children: _detailContent(context, _item!),
            ),
    );
  }

  List<Widget> _detailContent(BuildContext context, Prediksi prediksi) {
    final waktuTarget = WaktuSwiss.tanggalJam(prediksi.waktuTarget);

    final waktuSimpan = prediksi.waktu.toLocal();

    final dibuatPada =
        '${waktuSimpan.day.toString().padLeft(2, '0')}/'
        '${waktuSimpan.month.toString().padLeft(2, '0')}/'
        '${waktuSimpan.year} '
        '${waktuSimpan.hour.toString().padLeft(2, '0')}.'
        '${waktuSimpan.minute.toString().padLeft(2, '0')}';

    final percent = prediksi.kapasitas <= 0
        ? 0.0
        : prediksi.perkiraanKendaraan / prediksi.kapasitas * 100;

    return [
      Row(
        children: [
          const RoundBackButton(),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              'Detail Riwayat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),

      const SizedBox(height: AppSpacing.l),

      HeroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Waktu target prediksi',
              style: TextStyle(color: AppColors.softWhite),
            ),

            const SizedBox(height: AppSpacing.s),

            Text(
              waktuTarget,
              style: const TextStyle(
                color: AppColors.surface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            Text(
              '${prediksi.slotTersedia}',
              style: const TextStyle(
                color: AppColors.surface,
                fontSize: 48,
                fontWeight: FontWeight.w800,
              ),
            ),

            const Text(
              'slot diprediksi tersedia',
              style: TextStyle(color: AppColors.softWhite),
            ),

            const SizedBox(height: AppSpacing.m),

            StatusChip(status: prediksi.status, onBrand: true),

            if (_config != null) ...[
              const SizedBox(height: AppSpacing.l),
              StatusTrack(
                percent: percent,
                ambangHampirPenuh: _config!.ambangHampirPenuh,
                ambangPenuh: _config!.ambangPenuh,
              ),
            ],
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
                'Rincian Prediksi',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: AppSpacing.m),

              _detailRow(
                Icons.schedule_rounded,
                'Horizon',
                '${prediksi.horizonMenit} menit',
              ),

              _detailRow(
                Icons.local_parking_rounded,
                'Slot tersedia',
                '${prediksi.slotTersedia} slot',
              ),

              _detailRow(
                Icons.directions_car_rounded,
                'Perkiraan slot terisi',
                '${prediksi.perkiraanKendaraan} slot',
              ),

              _detailRow(
                Icons.storage_rounded,
                'Kapasitas',
                '${prediksi.kapasitas} slot',
              ),

              _detailRow(Icons.insights_rounded, 'Model', 'XGBoost'),

              _detailRow(
                Icons.speed_rounded,
                'MAE pengujian model',
                '${prediksi.maeHistoris.toStringAsFixed(4).replaceAll('.', ',')} slot',
              ),

              _detailRow(
                Icons.event_available_rounded,
                'Disimpan pada (waktu perangkat)',
                dibuatPada,
              ),

              if (prediksi.deviceId != null)
                _detailRow(
                  Icons.phone_android_rounded,
                  'Perangkat',
                  prediksi.deviceId!,
                ),
            ],
          ),
        ),
      ),

      const SizedBox(height: AppSpacing.cardGap),

      const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.l),
          child: Text(
            'DEMO HISTORIS: waktu target '
            'berasal dari dataset Frauenfeld 2024. '
            'Hasil ini bukan informasi parkir '
            'real-time. MAE adalah rata-rata '
            'galat pada data testing, bukan '
            'galat untuk satu prediksi ini.',
          ),
        ),
      ),

      const SizedBox(height: AppSpacing.cardGap),

      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            context.push('/prediksi?horizon=${prediksi.horizonMenit}');
          },
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Prediksi Lagi'),
        ),
      ),
    ];
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            ),
            child: Icon(icon, color: AppColors.brand),
          ),

          const SizedBox(width: AppSpacing.m),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
