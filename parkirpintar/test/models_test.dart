import 'package:flutter_test/flutter_test.dart';

import 'package:parkirpintar/data/mock/mock_data.dart';
import 'package:parkirpintar/data/models/admin.dart';
import 'package:parkirpintar/data/models/evaluasi.dart';
import 'package:parkirpintar/data/models/konfigurasi.dart';
import 'package:parkirpintar/data/models/prediksi.dart';
import 'package:parkirpintar/data/models/rekomendasi.dart';
import 'package:parkirpintar/data/models/rekap.dart';
import 'package:parkirpintar/data/models/status_parkir.dart';
import 'package:parkirpintar/data/models/tren.dart';

void main() {
  test('parses and serializes API models', () {
    expect(StatusParkir.fromJson(MockData.status).slotTersedia, 54);

    expect(Prediksi.fromJson(MockData.prediksi).maeHistoris, 3.54);

    expect(Rekomendasi.fromJson(MockData.rekomendasi).tersepi.first.jam, 6);

    expect(Tren.fromJson(MockData.tren).harian, hasLength(24));

    // perJenis sekarang nullable.
    // MockData tetap harus menghasilkan 980 motor.
    expect(Rekap.fromJson(MockData.rekap).perJenis?.motor, 980);

    expect(Evaluasi.fromJson(MockData.evaluasi).hasil, hasLength(9));

    expect(Evaluasi.fromJson(MockData.evaluasi).hasil[5].mae, isNull);

    expect(Konfigurasi.fromJson(MockData.konfigurasi).ambangPenuh, 90);

    expect(Admin.fromJson(MockData.admins.first).nama, 'Admin');

    expect(LoginResult.fromJson(MockData.login).accessToken, 'mock-jwt-token');
  });

  test('omits optional waktu_target from prediction request', () {
    final json = const PrediksiRequest(
      horizonMenit: 10,
      deviceId: 'a1b2c3d4',
    ).toJson();

    expect(json.containsKey('waktu_target'), isFalse);

    expect(json['device_id'], 'a1b2c3d4');
  });

  test('rekap historis menerima data transaksi null', () {
    final response = <String, dynamic>{
      'mode': 'demo_historis',
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
      'rata_terisi_per_jam': <dynamic>[],
      'cakupan_harian': <dynamic>[],
      'kualitas_data': {
        'baris_konsisten': 590,
        'baris_tidak_konsisten': 13,
        'persentase_tidak_konsisten': 2.156,
        'total_selisih_slot': 169,
        'rata_selisih_slot': 0.28,
      },
    };

    final rekap = Rekap.fromJson(response);

    expect(rekap.jumlahSampel, 603);
    expect(rekap.kapasitas, 185);
    expect(rekap.rataTerisi, 104.37);

    // Data transaksi tidak tersedia dalam
    // dataset Frauenfeld.
    expect(rekap.totalMasuk, isNull);
    expect(rekap.perJenis, isNull);
    expect(rekap.rataLamaParkirMenit, isNull);

    expect(rekap.hariTeramai, 'Sabtu');
    expect(rekap.hariTersepi, 'Minggu');

    expect(rekap.kualitasData?.barisKonsisten, 590);

    expect(rekap.kualitasData?.barisTidakKonsisten, 13);
  });
}
