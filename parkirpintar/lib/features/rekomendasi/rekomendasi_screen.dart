import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/widgets/connection_banner.dart';
import '../../core/widgets/skeleton_box.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../core/widgets/round_back_button.dart';
import '../../data/models/konfigurasi.dart';
import '../../data/models/rekomendasi.dart';
import '../../data/repository/parkir_exception.dart';
import '../../services/app_services.dart';

class RekomendasiScreen extends StatefulWidget {
  const RekomendasiScreen({super.key});
  @override
  State<RekomendasiScreen> createState() => _RekomendasiScreenState();
}

class _RekomendasiScreenState extends State<RekomendasiScreen> {
  Rekomendasi? _data;
  Konfigurasi? _config;
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
      final values = await Future.wait<Object>([
        AppServices.repository.getRekomendasi(),
        AppServices.repository.getKonfigurasi(),
      ]);
      if (mounted) {
        setState(() {
          _data = values[0] as Rekomendasi;
          _config = values[1] as Konfigurasi;
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
  Widget build(BuildContext context) => ScreenScaffold(
    body: ListView(
      padding: const EdgeInsets.only(top: AppSpacing.l),
      children: [
        const Align(alignment: Alignment.centerLeft, child: RoundBackButton()),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineLarge,
            children: const [
              TextSpan(text: 'Waktu '),
              TextSpan(
                text: 'Terbaik',
                style: TextStyle(color: AppColors.brand),
              ),
              TextSpan(text: ' Parkir'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Pilih jam datang yang paling lega.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_offline) ConnectionBanner(onRetry: _load),
        if (_loading) ...[
          const SkeletonBox(height: 150, animate: false),
          const SizedBox(height: AppSpacing.cardGap),
          const SkeletonBox(height: 260, animate: false),
        ] else if (_data == null)
          const Center(child: Text('Rekomendasi belum tersedia.'))
        else if (_data != null && _config != null) ...[
          _Section(
            title: 'Jam tersepi',
            items: _data!.tersepi,
            capacity: _config!.kapasitas,
            color: AppColors.statusKosong,
          ),
          const SizedBox(height: AppSpacing.cardGap),
          _Section(
            title: 'Jam teramai',
            items: _data!.teramai,
            capacity: _config!.kapasitas,
            color: AppColors.statusPenuh,
          ),
          const SizedBox(height: AppSpacing.cardGap),
          const Text(
            'Berdasarkan rata-rata data historis',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.capacity,
    required this.color,
  });
  final String title;
  final List<JamRekomendasi> items;
  final int capacity;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                title == 'Jam tersepi'
                    ? Icons.check_circle_rounded
                    : Icons.warning_rounded,
                color: color,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const Divider(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${items[index].jam.toString().padLeft(2, '0')}.00',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Rata-rata ${items[index].rataTerisi.toStringAsFixed(0)} terisi',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${items[index].rataTerisi.toStringAsFixed(0)} / $capacity',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Semantics(
              label:
                  'Rata-rata ${items[index].rataTerisi.toStringAsFixed(0)} dari $capacity slot terisi',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: capacity == 0
                      ? 0
                      : (items[index].rataTerisi / capacity).clamp(0, 1),
                  color: color,
                  backgroundColor: AppColors.brandSoft,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
