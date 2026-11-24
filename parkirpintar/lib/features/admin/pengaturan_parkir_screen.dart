
import 'package:flutter/material.dart';

import '../../core/admin_helpers.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/status_level.dart';
import '../../core/widgets/admin_screen_scaffold.dart';
import '../../core/widgets/status_chip.dart';

import '../../data/models/konfigurasi.dart';
import '../../data/repository/parkir_exception.dart';
import '../../services/app_services.dart';

class PengaturanParkirScreen extends StatefulWidget {
  const PengaturanParkirScreen({super.key});

  @override
  State<PengaturanParkirScreen> createState() =>
      _PengaturanParkirScreenState();
}

class _PengaturanParkirScreenState
    extends State<PengaturanParkirScreen> {
  Konfigurasi? _original;

  int _kapasitas = 185;
  int _almost = 60;
  int _full = 90;

  bool _loading = true;
  bool _saving = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _valid =>
      _almost >= 1 &&
      _almost < _full &&
      _full <= 100;

  bool get _changed =>
      _original != null &&
      (_almost != _original!.ambangHampirPenuh ||
          _full != _original!.ambangPenuh);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final config =
          await AppServices.repository.getKonfigurasi();

      if (!mounted) return;

      setState(() {
        _original = config;
        _kapasitas = config.kapasitas;
        _almost = config.ambangHampirPenuh;
        _full = config.ambangPenuh;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      if (await handleAdminError(context, error)) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error is ParkirException
            ? error.pesan
            : 'Pengaturan tidak dapat dimuat.';
      });
    }
  }

  Future<void> _save() async {
    if (!_valid || !_changed || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result =
          await AppServices.repository.updateKonfigurasi(
        Konfigurasi(
          kapasitas: _kapasitas,
          ambangHampirPenuh: _almost,
          ambangPenuh: _full,
        ),
      );

      if (!mounted) return;

      setState(() {
        _original = result;
        _kapasitas = result.kapasitas;
        _almost = result.ambangHampirPenuh;
        _full = result.ambangPenuh;
        _saving = false;
      });

      showAdminMessage(
        context,
        'Pengaturan berhasil disimpan ke FastAPI.',
      );
    } catch (error) {
      if (!mounted) return;

      if (await handleAdminError(context, error)) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = error is ParkirException
            ? error.pesan
            : 'Gagal menyimpan pengaturan.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScreenScaffold(
      title: 'Pengaturan ',
      accent: 'Parkir',
      subtitle:
          'Kelola ambang keterisian untuk data historis.',
      children: [
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_original != null)
          ..._content(),

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.m),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.statusPenuh,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _content() {
    return [
      Card(
        color: AppColors.brand,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kapasitas parkir historis',
                style: TextStyle(
                  color: AppColors.softWhite,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$_kapasitas slot',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.surface,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              const Text(
                'Kapasitas dikunci karena mengikuti '
                'dataset Frauenfeld yang digunakan '
                'untuk pengujian XGBoost.',
                style: TextStyle(
                  color: AppColors.softWhite,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: AppSpacing.cardGap),

      _thresholdCard(
        title: 'Batas hampir penuh',
        description:
            'Mulai dari persentase ini, status '
            'berubah menjadi Hampir Penuh.',
        value: _almost,
        minimum: 1,
        maximum: 99,
        onChanged: (value) {
          setState(() => _almost = value);
        },
      ),

      const SizedBox(height: AppSpacing.cardGap),

      _thresholdCard(
        title: 'Batas penuh',
        description:
            'Mulai dari persentase ini, status '
            'berubah menjadi Penuh.',
        value: _full,
        minimum: 2,
        maximum: 100,
        onChanged: (value) {
          setState(() => _full = value);
        },
      ),

      const SizedBox(height: AppSpacing.cardGap),

      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pratinjau status',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: AppSpacing.m),

              _preview(
                '${(_almost - 1).clamp(0, 100)}% terisi',
                (_almost - 1).clamp(0, 100),
              ),

              const SizedBox(height: AppSpacing.s),

              _preview(
                '$_almost% terisi',
                _almost,
              ),

              const SizedBox(height: AppSpacing.s),

              _preview(
                '$_full% terisi',
                _full,
              ),
            ],
          ),
        ),
      ),

      if (!_valid) ...[
        const SizedBox(height: AppSpacing.m),
        const Text(
          'Ambang hampir penuh harus lebih '
          'kecil dari ambang penuh.',
          style: TextStyle(
            color: AppColors.statusPenuh,
          ),
        ),
      ],

      const SizedBox(height: AppSpacing.l),

      SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: _valid && _changed && !_saving
              ? _save
              : null,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: Text(
            _saving ? 'Menyimpan...' : 'Simpan Pengaturan',
          ),
        ),
      ),

      const SizedBox(height: AppSpacing.m),

      const Text(
        'Perubahan status berlaku pada respons '
        'API mobile. Nilai prediksi XGBoost '
        'tidak ikut berubah.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    ];
  }

  Widget _thresholdCard({
    required String title,
    required String description,
    required int value,
    required int minimum,
    required int maximum,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$value%',
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.s),

            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: AppSpacing.m),

            Slider(
              min: minimum.toDouble(),
              max: maximum.toDouble(),
              divisions: maximum - minimum,
              value: value
                  .clamp(minimum, maximum)
                  .toDouble(),
              label: '$value%',
              onChanged: _saving
                  ? null
                  : (next) => onChanged(next.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(String label, int persen) {
    final status = StatusLevel.hitung(
      terisi: persen,
      kapasitas: 100,
      ambangHampirPenuh: _almost,
      ambangPenuh: _full,
    );

    return Row(
      children: [
        Expanded(child: Text(label)),
        StatusChip(status: status),
      ],
    );
  }
}
