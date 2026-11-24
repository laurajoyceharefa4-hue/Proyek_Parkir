import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:parkirpintar/data/models/konfigurasi.dart';
import 'package:parkirpintar/data/models/prediksi.dart';
import 'package:parkirpintar/data/models/status_parkir.dart';

import 'package:parkirpintar/data/repository/api_parkir_repository.dart';
import 'package:parkirpintar/data/repository/mock_parkir_repository.dart';

import 'package:parkirpintar/features/prediksi/form_prediksi_screen.dart';
import 'package:parkirpintar/features/prediksi/hasil_prediksi_screen.dart';
import 'package:parkirpintar/features/prediksi/riwayat_screen.dart';
import 'package:parkirpintar/features/rekomendasi/rekomendasi_screen.dart';
import 'package:parkirpintar/features/tren/tren_screen.dart';

import 'package:parkirpintar/services/app_services.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() {
    AppServices.initialized = false;
    AppServices.deviceId = 'a1b2c3d4';

    AppServices.repository = MockParkirRepository();
  });

  testWidgets('Form historis memilih horizon dan membuka satu hasil', (
    tester,
  ) async {
    final repository = _FakePrediksiRepository();

    AppServices.apiRepository = repository;
    AppServices.repository = repository;

    final router = GoRouter(
      initialLocation: '/prediksi',
      routes: [
        GoRoute(
          path: '/prediksi',
          builder: (context, state) {
            return const FormPrediksiScreen();
          },
        ),
        GoRoute(
          path: '/prediksi/hasil',
          builder: (context, state) {
            return HasilPrediksiScreen(
              prediksi: state.extra as Prediksi,
              horizon: 20,
            );
          },
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.pumpAndSettle();

    // =================================
    // 1. Pastikan data historis dimuat
    // =================================

    expect(find.text('Tanggal pengamatan'), findsOneWidget);

    expect(repository.statusDipanggil, isTrue);

    expect(repository.barisDipilih, 0);

    // =================================
    // 2. Pilih horizon 20 menit
    // =================================

    final teks20Menit = find.text('20 menit');

    expect(teks20Menit, findsOneWidget);

    // Posisikan tombol pada area layar
    // yang benar-benar bisa diketuk.
    //
    // alignment 0.3 berarti sekitar
    // 30% dari bagian atas area scroll.
    await Scrollable.ensureVisible(tester.element(teks20Menit), alignment: 0.3);

    await tester.pumpAndSettle();

    // Ketuk ChoiceChip, bukan sekadar
    // teks di dalamnya.
    final chip20Menit = find.ancestor(
      of: teks20Menit,
      matching: find.byType(ChoiceChip),
    );

    expect(chip20Menit, findsOneWidget);

    await tester.tap(chip20Menit);
    await tester.pumpAndSettle();

    // Pastikan pilihan benar-benar berubah
    // sebelum mengirim prediksi.
    expect(tester.widget<ChoiceChip>(chip20Menit).selected, isTrue);

    // =================================
    // 3. Tekan tombol prediksi
    // =================================

    final tombolPrediksi = find.text('Lihat Prediksi');

    expect(tombolPrediksi, findsOneWidget);

    await Scrollable.ensureVisible(
      tester.element(tombolPrediksi),
      alignment: 0.5,
    );

    await tester.pumpAndSettle();

    await tester.tap(tombolPrediksi);
    await tester.pumpAndSettle();

    // =================================
    // 4. Verifikasi permintaan backend
    // =================================

    expect(repository.jumlahPrediksi, 1);

    expect(repository.horizonTerakhir, 20);

    expect(repository.barisPrediksiTerakhir, 0);

    // =================================
    // 5. Verifikasi halaman hasil
    // =================================

    expect(find.byType(HasilPrediksiScreen), findsOneWidget);

    expect(find.text('115'), findsWidgets);
  });

  testWidgets('Riwayat filter 10 menit menampilkan hasil', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RiwayatScreen()));

    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('10 menit').first);

    await tester.pump();

    expect(find.textContaining('Horizon 10 menit'), findsWidgets);
  });

  testWidgets('Tren dan rekomendasi menampilkan data mock', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrenScreen()));

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Rata-rata Terisi per Jam'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: RekomendasiScreen()));

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Jam tersepi'), findsOneWidget);

    expect(find.text('Jam teramai'), findsOneWidget);
  });
}

// ==========================================
// REPOSITORY PALSU UNTUK WIDGET TEST
// ==========================================

class _FakePrediksiRepository extends ApiParkirRepository {
  _FakePrediksiRepository()
    : super(
        addressProvider: () => 'http://127.0.0.1:8001',
        deviceIdProvider: () => 'a1b2c3d4',
        tokenProvider: () async => null,
      );

  bool statusDipanggil = false;
  int? barisDipilih;

  int jumlahPrediksi = 0;
  int? horizonTerakhir;
  int? barisPrediksiTerakhir;

  @override
  Future<List<String>> getTanggalTersedia() async {
    return ['2024-09-26'];
  }

  @override
  Future<List<WaktuHistoris>> getWaktuTersedia(String tanggal) async {
    return [
      const WaktuHistoris(
        nomorBaris: 0,
        jam: '21:10',
        waktuPengamatan: '2024-09-26T21:10:00+02:00',
      ),
    ];
  }

  @override
  Future<StatusParkir> getStatusAt(int nomorBaris) async {
    statusDipanggil = true;
    barisDipilih = nomorBaris;

    return StatusParkir.fromJson({
      'waktu': '2024-09-26T21:10:00+02:00',
      'kapasitas': 185,
      'terisi': 75,
      'slot_tersedia': 110,
      'status': 'kosong',
    });
  }

  @override
  Future<Prediksi> prediksi(PrediksiRequest request) async {
    jumlahPrediksi++;

    horizonTerakhir = request.horizonMenit;
    barisPrediksiTerakhir = request.nomorBaris;

    final horizon = request.horizonMenit;

    final prediksiSlot = switch (horizon) {
      10 => 112,
      20 => 115,
      30 => 116,
      _ => 112,
    };

    final target = switch (horizon) {
      10 => '2024-09-26T21:20:00+02:00',
      20 => '2024-09-26T21:30:00+02:00',
      30 => '2024-09-26T21:40:00+02:00',
      _ => '2024-09-26T21:20:00+02:00',
    };

    final mae = switch (horizon) {
      10 => 2.522484,
      20 => 3.612115,
      30 => 4.323544,
      _ => 2.522484,
    };

    return Prediksi.fromJson({
      'riwayat_id': 4,
      'model': 'xgboost',
      'horizon_menit': horizon,
      'waktu_target': target,
      'perkiraan_kendaraan': 185 - prediksiSlot,
      'kapasitas': 185,
      'slot_tersedia': prediksiSlot,
      'status': 'kosong',
      'mae_historis': mae,
      'keterangan': 'DEMO HISTORIS (bukan real-time).',
      'waktu': '2026-11-07T04:58:30+00:00',
      'device_id': request.deviceId,
    });
  }

  @override
  Future<Konfigurasi> getKonfigurasi() async {
    return Konfigurasi.fromJson({
      'kapasitas': 185,
      'ambang_hampir_penuh': 50,
      'ambang_penuh': 85,
    });
  }
}
