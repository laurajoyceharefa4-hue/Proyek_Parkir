import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/widgets/round_back_button.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../core/widgets/status_chip.dart';

import '../../data/models/prediksi.dart';
import '../../data/models/status_parkir.dart';
import '../../data/repository/api_parkir_repository.dart';
import '../../data/repository/parkir_exception.dart';

import '../../services/app_services.dart';

class FormPrediksiScreen extends StatefulWidget {
  const FormPrediksiScreen({super.key, this.initialHorizon = 10});

  final int initialHorizon;

  @override
  State<FormPrediksiScreen> createState() => _FormPrediksiScreenState();
}

class _FormPrediksiScreenState extends State<FormPrediksiScreen> {
  late int _horizon;

  List<String> _tanggal = [];
  List<WaktuHistoris> _pilihanWaktu = [];

  String? _tanggalDipilih;
  int? _nomorBaris;

  StatusParkir? _status;

  bool _loadingTanggal = true;
  bool _loadingWaktu = false;
  bool _loadingStatus = false;
  bool _predicting = false;

  String? _error;

  ApiParkirRepository get _api => AppServices.apiRepository;

  @override
  void initState() {
    super.initState();

    _horizon = _validHorizon(widget.initialHorizon);

    _loadTanggal();
  }

  @override
  void didUpdateWidget(covariant FormPrediksiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialHorizon != oldWidget.initialHorizon) {
      _horizon = _validHorizon(widget.initialHorizon);
    }
  }

  int _validHorizon(int value) {
    return AppConstants.horizons.contains(value) ? value : 10;
  }

  Future<void> _loadTanggal() async {
    setState(() {
      _loadingTanggal = true;
      _error = null;
    });

    try {
      final dates = await _api.getTanggalTersedia();

      if (!mounted) return;

      if (dates.isEmpty) {
        setState(() {
          _tanggal = [];
          _tanggalDipilih = null;
          _nomorBaris = null;
          _status = null;
          _loadingTanggal = false;
          _error = 'Tidak ada tanggal historis yang tersedia.';
        });

        return;
      }

      setState(() {
        _tanggal = dates;
        _loadingTanggal = false;
      });

      await _loadWaktu(dates.last);
    } on ParkirException catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingTanggal = false;
        _error = error.pesan;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingTanggal = false;
        _error = 'Gagal mengambil tanggal dari FastAPI.';
      });
    }
  }

  Future<void> _loadWaktu(String tanggal) async {
    setState(() {
      _tanggalDipilih = tanggal;
      _nomorBaris = null;
      _pilihanWaktu = [];
      _status = null;
      _loadingWaktu = true;
      _loadingStatus = false;
      _error = null;
    });

    try {
      final times = await _api.getWaktuTersedia(tanggal);

      if (!mounted || _tanggalDipilih != tanggal) {
        return;
      }

      setState(() {
        _pilihanWaktu = times;
        _loadingWaktu = false;
      });

      if (times.isNotEmpty) {
        await _pilihBaris(times.last.nomorBaris);
      } else {
        setState(() {
          _error = 'Tidak ada jam pengamatan pada tanggal tersebut.';
        });
      }
    } on ParkirException catch (error) {
      if (!mounted || _tanggalDipilih != tanggal) {
        return;
      }

      setState(() {
        _loadingWaktu = false;
        _error = error.pesan;
      });
    } catch (_) {
      if (!mounted || _tanggalDipilih != tanggal) {
        return;
      }

      setState(() {
        _loadingWaktu = false;
        _error = 'Gagal mengambil pilihan waktu historis.';
      });
    }
  }

  Future<void> _pilihBaris(int index) async {
    setState(() {
      _nomorBaris = index;
      _status = null;
      _loadingStatus = true;
      _error = null;
    });

    try {
      final status = await _api.getStatusAt(index);

      if (!mounted || _nomorBaris != index) {
        return;
      }

      setState(() {
        _status = status;
        _loadingStatus = false;
      });
    } on ParkirException catch (error) {
      if (!mounted || _nomorBaris != index) {
        return;
      }

      setState(() {
        _loadingStatus = false;
        _error = error.pesan;
      });
    } catch (_) {
      if (!mounted || _nomorBaris != index) {
        return;
      }

      setState(() {
        _loadingStatus = false;
        _error = 'Kondisi parkir tidak dapat dimuat.';
      });
    }
  }

  Future<void> _submit() async {
    if (_predicting) return;

    final index = _nomorBaris;

    if (index == null) {
      setState(() {
        _error = 'Pilih tanggal dan jam pengamatan dahulu.';
      });

      return;
    }

    setState(() {
      _predicting = true;
      _error = null;
    });

    try {
      final hasil = await AppServices.repository.prediksi(
        PrediksiRequest(
          horizonMenit: _horizon,
          deviceId: AppServices.deviceId ?? 'demo-device',
          nomorBaris: index,
        ),
      );

      if (!mounted) return;

      // Halaman hasil menerima objek yang
      // sudah diprediksi, sehingga tidak
      // mengirim prediksi kedua ke server.
      context.push('/prediksi/hasil', extra: hasil);
    } on ParkirException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.pesan;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Prediksi gagal diproses. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _predicting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTime = _pilihanWaktu.where(
      (item) => item.nomorBaris == _nomorBaris,
    );

    final waktu = selectedTime.isEmpty ? null : selectedTime.first;

    return ScreenScaffold(
      hasBottomNav: true,
      body: RefreshIndicator(
        onRefresh: _loadTanggal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: AppSpacing.xxl,
            bottom: ScreenScaffold.contentBottomPadding(context),
          ),
          children: [
            Row(
              children: [
                const RoundBackButton(),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    'Prediksi Parkir',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.l),

            Card(
              color: AppColors.brandSoft,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.l),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.brand),
                    SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        'MODE DEMO HISTORIS\n'
                        'Prediksi menggunakan dataset '
                        'Frauenfeld tahun 2024, bukan '
                        'kondisi parkir sekarang. '
                        'Jam pengamatan menggunakan '
                        'zona waktu Swiss.',
                      ),
                    ),
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
                      'Tanggal pengamatan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: AppSpacing.m),

                    if (_loadingTanggal)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey('tanggal_${_tanggalDipilih ?? ''}'),
                        initialValue: _tanggalDipilih,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                        items: _tanggal.map((tanggal) {
                          return DropdownMenuItem(
                            value: tanggal,
                            child: Text(tanggal),
                          );
                        }).toList(),
                        onChanged: _predicting
                            ? null
                            : (tanggal) {
                                if (tanggal != null) {
                                  _loadWaktu(tanggal);
                                }
                              },
                      ),

                    const SizedBox(height: AppSpacing.l),

                    Text(
                      'Jam pengamatan (Swiss)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: AppSpacing.m),

                    if (_loadingWaktu)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<int>(
                        key: ValueKey('baris_${_nomorBaris ?? -1}'),
                        initialValue: _nomorBaris,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time_rounded),
                        ),
                        items: _pilihanWaktu.map((item) {
                          return DropdownMenuItem<int>(
                            value: item.nomorBaris,
                            child: Text('${item.jam} — Swiss'),
                          );
                        }).toList(),
                        onChanged: _predicting
                            ? null
                            : (index) {
                                if (index != null) {
                                  _pilihBaris(index);
                                }
                              },
                      ),

                    if (waktu != null) ...[
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'Pengamatan: '
                        '${waktu.waktuPengamatan}',
                        style: Theme.of(context).textTheme.bodySmall,
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
                      'Horizon prediksi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: AppSpacing.m),

                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: [
                        for (final minutes in AppConstants.horizons)
                          ChoiceChip(
                            label: Text('$minutes menit'),
                            selected: _horizon == minutes,
                            onSelected: _predicting
                                ? null
                                : (_) {
                                    setState(() {
                                      _horizon = minutes;
                                    });
                                  },
                          ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s),

                    Text(
                      'Model XGBoost memperkirakan '
                      'slot kosong $_horizon menit '
                      'setelah waktu pengamatan.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.cardGap),

            if (_loadingStatus)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.l),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_status != null)
              _KondisiHistorisCard(status: _status!),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.m),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.statusPenuh),
              ),
              TextButton.icon(
                onPressed: _loadTanggal,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Muat Ulang'),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed:
                    _predicting ||
                        _loadingTanggal ||
                        _loadingWaktu ||
                        _loadingStatus ||
                        _status == null ||
                        _nomorBaris == null
                    ? null
                    : _submit,
                icon: _predicting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _predicting ? 'Memproses XGBoost...' : 'Lihat Prediksi',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KondisiHistorisCard extends StatelessWidget {
  const _KondisiHistorisCard({required this.status});

  final StatusParkir status;

  @override
  Widget build(BuildContext context) {
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
                    'Kondisi pada pengamatan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusChip(status: status.status),
              ],
            ),

            const SizedBox(height: AppSpacing.m),

            Text(
              '${status.slotTersedia} slot kosong '
              'dari ${status.kapasitas} slot',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.s),

            Text(
              '${status.terisi} slot terisi',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: AppSpacing.m),

            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: (status.persenTerisi / 100).clamp(0.0, 1.0),
                color: status.status.warna,
                backgroundColor: AppColors.brandSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
