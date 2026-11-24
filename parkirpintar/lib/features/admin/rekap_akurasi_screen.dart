import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/admin_helpers.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/widgets/admin_screen_scaffold.dart';

import '../../data/models/evaluasi.dart';
import '../../data/models/rekap.dart';
import '../../data/repository/api_parkir_repository.dart';
import '../../data/repository/parkir_exception.dart';

import '../../services/app_services.dart';
import 'rekap_csv_export_button.dart';

class RekapAkurasiScreen extends StatefulWidget {
  const RekapAkurasiScreen({super.key});

  @override
  State<RekapAkurasiScreen> createState() => _RekapAkurasiScreenState();
}

class _RekapAkurasiScreenState extends State<RekapAkurasiScreen> {
  PeriodeRekap? _periode;
  DateTimeRange? _range;

  Rekap? _rekap;
  Evaluasi? _evaluasi;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _date(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  String _number(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals).replaceAll('.', ',');
  }

  String _clock(int hour) {
    return '${hour.toString().padLeft(2, '0')}.00';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final periode =
          _periode ?? await AppServices.apiRepository.getPeriodeRekap();

      final range =
          _range ??
          DateTimeRange(start: periode.tanggalAwal, end: periode.tanggalAkhir);

      final results = await Future.wait<Object>([
        AppServices.repository.getRekap(dari: range.start, sampai: range.end),
        AppServices.repository.getEvaluasi(),
      ]);

      if (!mounted) return;

      setState(() {
        _periode = periode;
        _range = range;
        _rekap = results[0] as Rekap;
        _evaluasi = results[1] as Evaluasi;
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
            : 'Rekap historis tidak dapat dimuat.';
      });
    }
  }

  Future<void> _selectRange() async {
    final periode = _periode;
    if (periode == null) return;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: periode.tanggalAwal,
      lastDate: periode.tanggalAkhir,
      initialDateRange: _range,
      helpText: 'Pilih periode historis',
      saveText: 'Terapkan',
    );

    if (!mounted || picked == null) return;

    setState(() {
      _range = picked;
    });

    await _load();
  }

  void _resetRange() {
    final periode = _periode;
    if (periode == null) return;

    setState(() {
      _range = DateTimeRange(
        start: periode.tanggalAwal,
        end: periode.tanggalAkhir,
      );
    });

    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScreenScaffold(
      title: 'Rekap & ',
      accent: 'Evaluasi',
      subtitle: 'Statistik keterisian historis dan evaluasi XGBoost.',
      children: [
        _periodCard(),

        const SizedBox(height: AppSpacing.cardGap),

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          _errorCard()
        else if (_rekap != null) ...[
          _summaryCard(),

          const SizedBox(height: AppSpacing.cardGap),

          _statisticsCard(),

          const SizedBox(height: AppSpacing.cardGap),

          _busyCard(),

          const SizedBox(height: AppSpacing.cardGap),

          _hourlyCard(),

          const SizedBox(height: AppSpacing.cardGap),

          _dailyCoverageCard(),

          const SizedBox(height: AppSpacing.cardGap),

          _qualityCard(),

          const SizedBox(height: AppSpacing.cardGap),

          _evaluationCard(),

          const SizedBox(height: AppSpacing.cardGap),

          _sourceCard(),

          // FITUR BARU:
          // Ekspor CSV sesuai periode rekap.
          if (_range != null) ...[
            const SizedBox(height: AppSpacing.cardGap),
            RekapCsvExportButton(range: _range!),
          ],
        ],
      ],
    );
  }

  Widget _periodCard() {
    final range = _range;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Periode Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.s),

            Text(
              range == null
                  ? 'Memuat periode dataset...'
                  : '${_date(range.start)} – ${_date(range.end)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: AppSpacing.s),

            const Text(
              'Zona waktu: Europe/Zurich (Swiss)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),

            const SizedBox(height: AppSpacing.m),

            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                OutlinedButton.icon(
                  onPressed: _periode == null || _loading ? null : _selectRange,
                  icon: const Icon(Icons.date_range_rounded),
                  label: const Text('Pilih Tanggal'),
                ),
                TextButton.icon(
                  onPressed: _periode == null || _loading ? null : _resetRange,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Semua Data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final data = _rekap!;

    return Card(
      color: AppColors.brand,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rata-rata slot terisi',
              style: TextStyle(color: AppColors.softWhite),
            ),

            const SizedBox(height: AppSpacing.s),

            Text(
              '${_number(data.rataTerisi)} slot',
              style: const TextStyle(
                color: AppColors.surface,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: AppSpacing.s),

            Text(
              '${data.jumlahSampel} pengamatan historis '
              '• Kapasitas ${data.kapasitas} slot',
              style: const TextStyle(color: AppColors.softWhite),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statisticsCard() {
    final data = _rekap!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik Keterisian',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.m),

            _detail(
              'Rata-rata slot tersedia',
              '${_number(data.rataTersedia)} slot',
            ),

            _detail(
              'Rata-rata keterisian',
              '${_number(data.rataPersenTerisi)}%',
            ),

            _detail('Jumlah pengamatan', '${data.jumlahSampel} sampel'),

            const Divider(),

            const Text(
              'Statistik ini tidak menunjukkan jumlah '
              'transaksi kendaraan masuk atau keluar.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _busyCard() {
    final data = _rekap!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paling Ramai & Sepi',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.m),

            _detail('Jam teramai', '${_clock(data.jamTeramai)} Swiss'),

            _detail('Jam tersepi', '${_clock(data.jamTersepi)} Swiss'),

            _detail(
              'Hari teramai (hari lengkap)',
              data.hariTeramai ?? 'Tidak tersedia',
            ),

            _detail(
              'Hari tersepi (hari lengkap)',
              data.hariTersepi ?? 'Tidak tersedia',
            ),

            const SizedBox(height: AppSpacing.s),

            const Text(
              'Peringkat hari hanya menggunakan tanggal '
              'yang memiliki 144 pengamatan lengkap.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hourlyCard() {
    final data = _rekap!;
    final kapasitas = data.kapasitas <= 0 ? 1 : data.kapasitas;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rata-rata Terisi per Jam',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.s),

            const Text(
              'Berdasarkan jam pengamatan historis di Swiss.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),

            const SizedBox(height: AppSpacing.m),

            for (final jam in data.rataTerisiPerJam) ...[
              Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      _clock(jam.jam),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),

                  Expanded(
                    child: LinearProgressIndicator(
                      value: (jam.rataTerisi / kapasitas).clamp(0.0, 1.0),
                      minHeight: 9,
                      color: AppColors.brand,
                      backgroundColor: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.s),

                  SizedBox(
                    width: 48,
                    child: Text(
                      _number(jam.rataTerisi, decimals: 1),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.m),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dailyCoverageCard() {
    final data = _rekap!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cakupan Data Harian',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.m),

            for (final day in data.cakupanHarian) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${day.hari}, ${day.tanggal}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${day.jumlahSampel} dari 144 sampel',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Chip(
                    label: Text(day.hariPenuh ? 'Lengkap' : 'Parsial'),
                    backgroundColor: day.hariPenuh ? AppColors.brandSoft : null,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.s),
            ],
          ],
        ),
      ),
    );
  }

  Widget _qualityCard() {
    final quality = _rekap!.kualitasData;

    if (quality == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Kualitas Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.m),

            _detail('Baris konsisten', '${quality.barisKonsisten}'),

            _detail('Baris tidak konsisten', '${quality.barisTidakKonsisten}'),

            _detail(
              'Persentase tidak konsisten',
              '${_number(quality.persentaseTidakKonsisten, decimals: 3)}%',
            ),

            _detail(
              'Total selisih slot',
              _number(quality.totalSelisihSlot, decimals: 0),
            ),

            const SizedBox(height: AppSpacing.s),

            const Text(
              'Audit membandingkan kapasitas dengan '
              'jumlah slot terisi dan tersedia. '
              'Data testing tidak dikoreksi otomatis.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _evaluationCard() {
    final results = _evaluasi?.hasil ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evaluasi Model XGBoost',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.s),

            const Text(
              'Metrik dihitung pada dataset testing. '
              'MAE dan RMSE semakin kecil semakin baik; '
              'R² semakin mendekati 1 semakin baik.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),

            const SizedBox(height: AppSpacing.m),

            for (final horizon in AppConstants.horizons) ...[
              _evaluationRow(
                horizon,
                results
                    .where(
                      (item) =>
                          item.horizonMenit == horizon &&
                          item.tipeHari == 'semua',
                    )
                    .firstOrNull,
              ),

              const SizedBox(height: AppSpacing.m),
            ],
          ],
        ),
      ),
    );
  }

  Widget _evaluationRow(int horizon, HasilEvaluasi? result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$horizon menit',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.brand,
          ),
        ),

        const SizedBox(height: AppSpacing.s),

        if (result == null)
          const Text('Metrik belum tersedia.')
        else ...[
          _detail(
            'MAE',
            result.mae == null
                ? 'Tidak tersedia'
                : '${_number(result.mae!, decimals: 4)} slot',
          ),

          _detail(
            'RMSE',
            result.rmse == null
                ? 'Tidak tersedia'
                : '${_number(result.rmse!, decimals: 4)} slot',
          ),

          _detail(
            'R²',
            result.r2 == null
                ? 'Tidak tersedia'
                : _number(result.r2!, decimals: 4),
          ),
        ],
      ],
    );
  }

  Widget _sourceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sumber dan Batasan',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.m),

            const Text(
              'Sumber: Frauenfeld_Test.csv, '
              'lokasi Oberes Mätteli, Swiss.',
            ),

            const SizedBox(height: AppSpacing.s),

            Text(_rekap?.catatan ?? 'Rekap merupakan statistik historis.'),

            const SizedBox(height: AppSpacing.m),

            const Text(
              'Jumlah kendaraan masuk, jenis kendaraan, '
              'dan durasi parkir tidak tersedia dalam '
              'dataset ini. File CSV memuat data '
              'pengamatan dari periode yang dipilih.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),

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

  Widget _errorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            Text(
              _error ?? 'Terjadi kesalahan.',
              style: const TextStyle(color: AppColors.statusPenuh),
            ),

            const SizedBox(height: AppSpacing.m),

            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
