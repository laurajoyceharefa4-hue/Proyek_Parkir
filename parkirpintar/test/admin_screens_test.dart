import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:parkirpintar/data/mock/mock_data.dart';
import 'package:parkirpintar/data/models/evaluasi.dart';
import 'package:parkirpintar/data/models/rekap.dart';
import 'package:parkirpintar/data/repository/api_parkir_repository.dart';
import 'package:parkirpintar/features/admin/rekap_akurasi_screen.dart';
import 'package:parkirpintar/services/app_services.dart';

void main() {
  late _FakeRekapRepository repository;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() {
    repository = _FakeRekapRepository();

    AppServices.initialized = false;
    AppServices.apiRepository = repository;
    AppServices.repository = repository;
  });

  testWidgets('Rekap menampilkan statistik historis dari API', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RekapAkurasiScreen()));

    await tester.pumpAndSettle();

    expect(find.text('Periode Data'), findsOneWidget);

    expect(find.textContaining('2024'), findsWidgets);

    expect(repository.rekapDipanggil, isTrue);

    expect(repository.periodeDari?.year, 2024);

    expect(repository.periodeSampai?.year, 2024);

    // Halaman rekap tidak boleh mengklaim
    // transaksi kendaraan yang tidak
    // tersedia dalam dataset.
    expect(find.text('Total kendaraan masuk'), findsNothing);

    // Periksa bahwa pemilihan tanggal
    // menggunakan periode historis.
    expect(find.text('Pilih Tanggal'), findsOneWidget);

    expect(find.text('Semua Data'), findsOneWidget);
  });

  testWidgets('Rekap menampilkan laporan audit kualitas data', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RekapAkurasiScreen()));

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Audit Kualitas Data'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Audit Kualitas Data'), findsOneWidget);

    expect(find.text('Baris tidak konsisten'), findsOneWidget);

    expect(find.text('13'), findsOneWidget);
  });
}

class _FakeRekapRepository extends ApiParkirRepository {
  _FakeRekapRepository()
    : super(
        addressProvider: () => 'http://127.0.0.1:8001',
        deviceIdProvider: () => 'test-device',
        tokenProvider: () async => 'test-token',
      );

  bool rekapDipanggil = false;
  DateTime? periodeDari;
  DateTime? periodeSampai;

  @override
  Future<PeriodeRekap> getPeriodeRekap() async {
    return PeriodeRekap.fromJson({
      'tanggal_awal': '2024-09-26',
      'tanggal_akhir': '2024-10-01',
      'jumlah_sampel': 603,
    });
  }

  @override
  Future<Rekap> getRekap({
    required DateTime dari,
    required DateTime sampai,
  }) async {
    rekapDipanggil = true;
    periodeDari = dari;
    periodeSampai = sampai;

    return Rekap.fromJson({
      'mode': 'demo_historis',
      'sumber': 'Frauenfeld_Test.csv',
      'lokasi': '1 | Oberes Mätteli',
      'tanggal_dari': '2024-09-26',
      'tanggal_sampai': '2024-10-01',
      'zona_waktu': 'Europe/Zurich',
      'jumlah_sampel': 603,
      'kapasitas': 185,
      'rata_terisi': 104.37,
      'rata_tersedia': 80.35,
      'rata_persen_terisi': 56.416,
      'jam_teramai': 14,
      'jam_tersepi': 4,
      'hari_teramai': 'Sabtu',
      'hari_tersepi': 'Minggu',
      'total_masuk': null,
      'per_jenis': null,
      'rata_lama_parkir_menit': null,
      'rata_terisi_per_jam': [
        {'jam': 4, 'rata_terisi': 41.208, 'jumlah_sampel': 24},
        {'jam': 14, 'rata_terisi': 176.875, 'jumlah_sampel': 24},
      ],
      'cakupan_harian': [
        {
          'tanggal': '2024-09-26',
          'hari': 'Kamis',
          'jumlah_sampel': 17,
          'hari_penuh': false,
        },
        {
          'tanggal': '2024-09-27',
          'hari': 'Jumat',
          'jumlah_sampel': 144,
          'hari_penuh': true,
        },
        {
          'tanggal': '2024-09-28',
          'hari': 'Sabtu',
          'jumlah_sampel': 144,
          'hari_penuh': true,
        },
        {
          'tanggal': '2024-09-29',
          'hari': 'Minggu',
          'jumlah_sampel': 144,
          'hari_penuh': true,
        },
        {
          'tanggal': '2024-09-30',
          'hari': 'Senin',
          'jumlah_sampel': 144,
          'hari_penuh': true,
        },
        {
          'tanggal': '2024-10-01',
          'hari': 'Selasa',
          'jumlah_sampel': 10,
          'hari_penuh': false,
        },
      ],
      'kualitas_data': {
        'baris_konsisten': 590,
        'baris_tidak_konsisten': 13,
        'persentase_tidak_konsisten': 2.156,
        'total_selisih_slot': 169,
        'rata_selisih_slot': 0.28,
      },
      'catatan':
          'Statistik berasal dari snapshot '
          'keterisian, bukan transaksi kendaraan.',
    });
  }

  @override
  Future<Evaluasi> getEvaluasi() async {
    return Evaluasi.fromJson(MockData.evaluasi);
  }
}
