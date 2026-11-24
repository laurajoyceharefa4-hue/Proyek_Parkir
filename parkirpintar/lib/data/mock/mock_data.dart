class MockData {
  MockData._();

  static final Map<String, dynamic> login = {
    'access_token': 'mock-jwt-token',
    'token_type': 'bearer',
    'admin': {'id': 1, 'nama': 'Admin', 'username': 'admin', 'aktif': true},
  };

  static final Map<String, dynamic> status = {
    'waktu': '2026-10-31T10:00:00',
    'kapasitas': 150,
    'terisi': 96,
    'slot_tersedia': 54,
    'status': 'hampir_penuh',
  };

  static final Map<String, dynamic> prediksi = {
    'riwayat_id': 31,
    'model': 'xgboost',
    'horizon_menit': 30,
    'waktu_target': '2026-11-02T10:30:00',
    'perkiraan_kendaraan': 118,
    'kapasitas': 150,
    'slot_tersedia': 32,
    'status': 'hampir_penuh',
    'mae_historis': 3.54,
    'keterangan': 'Perkiraan',
    'waktu': '2026-10-31T10:00:00',
  };

  static final Map<String, dynamic> rekomendasi = {
    'tersepi': [
      {'jam': 6, 'rata_terisi': 12.4},
      {'jam': 7, 'rata_terisi': 20.1},
      {'jam': 21, 'rata_terisi': 25.8},
    ],
    'teramai': [
      {'jam': 12, 'rata_terisi': 131.0},
      {'jam': 11, 'rata_terisi': 126.5},
      {'jam': 13, 'rata_terisi': 124.2},
    ],
  };

  static final Map<String, dynamic> rekap = {
    'total_masuk': 1520,
    'per_jenis': {'motor': 980, 'mobil': 510, 'lainnya': 30},
    'rata_lama_parkir_menit': 94,
    'jam_teramai': 12,
    'jam_tersepi': 6,
    'hari_teramai': 'Jumat',
    'hari_tersepi': 'Minggu',
    'rata_terisi': 78.3,
  };

  static final Map<String, dynamic> evaluasi = {
    'hasil': [
      {
        'horizon_menit': 10,
        'tipe_hari': 'semua',
        'mae': 2.34,
        'rmse': 3.10,
        'r2': 0.91,
      },
      {
        'horizon_menit': 20,
        'tipe_hari': 'semua',
        'mae': 3.10,
        'rmse': 4.25,
        'r2': 0.86,
      },
      {
        'horizon_menit': 30,
        'tipe_hari': 'semua',
        'mae': 3.54,
        'rmse': 4.80,
        'r2': 0.82,
      },
      // ILUSTRASI, ganti dari hasil evaluasi asli.
      {
        'horizon_menit': 10,
        'tipe_hari': 'hari_kerja',
        'mae': 2.12,
        'rmse': 2.90,
        'r2': 0.93,
      },
      {
        'horizon_menit': 20,
        'tipe_hari': 'hari_kerja',
        'mae': 2.88,
        'rmse': 3.90,
        'r2': 0.88,
      },
      {
        'horizon_menit': 30,
        'tipe_hari': 'hari_kerja',
        'mae': null,
        'rmse': null,
        'r2': null,
      },
      {
        'horizon_menit': 10,
        'tipe_hari': 'akhir_pekan',
        'mae': 2.71,
        'rmse': 3.45,
        'r2': 0.89,
      },
      {
        'horizon_menit': 20,
        'tipe_hari': 'akhir_pekan',
        'mae': 3.55,
        'rmse': 4.70,
        'r2': 0.81,
      },
      {
        'horizon_menit': 30,
        'tipe_hari': 'akhir_pekan',
        'mae': 4.02,
        'rmse': 5.20,
        'r2': 0.76,
      },
    ],
  };

  static final Map<String, dynamic> tren = {
    'harian': List.generate(24, (jam) {
      const nilai = [
        12.0,
        10.0,
        9.0,
        8.0,
        10.0,
        18.0,
        32.0,
        55.0,
        76.0,
        92.0,
        108.0,
        124.0,
        132.0,
        126.0,
        115.0,
        102.0,
        88.0,
        76.0,
        61.0,
        48.0,
        36.0,
        25.0,
        18.0,
        14.0,
      ];
      return {
        'label': jam.toString().padLeft(2, '0'),
        'rata_terisi': nilai[jam],
      };
    }),
    'mingguan': [
      {'label': 'Sen', 'rata_terisi': 72.0},
      {'label': 'Sel', 'rata_terisi': 75.5},
      {'label': 'Rab', 'rata_terisi': 78.0},
      {'label': 'Kam', 'rata_terisi': 81.5},
      {'label': 'Jum', 'rata_terisi': 92.0},
      {'label': 'Sab', 'rata_terisi': 66.0},
      {'label': 'Min', 'rata_terisi': 42.0},
    ],
  };

  static Map<String, dynamic> konfigurasi = {
    'kapasitas': 150,
    'ambang_hampir_penuh': 60,
    'ambang_penuh': 90,
  };

  static final List<Map<String, dynamic>> admins = [
    {'id': 1, 'nama': 'Admin', 'username': 'admin', 'aktif': true},
    {
      'id': 2,
      'nama': 'Petugas Pagi',
      'username': 'petugas.pagi',
      'aktif': true,
    },
    {
      'id': 3,
      'nama': 'Petugas Lama',
      'username': 'petugas.lama',
      'aktif': false,
    },
  ];

  static final List<Map<String, dynamic>> riwayat = [
    {
      'riwayat_id': 30,
      'model': 'xgboost',
      'horizon_menit': 10,
      'waktu_target': '2026-10-31T10:10:00',
      'perkiraan_kendaraan': 72,
      'kapasitas': 150,
      'slot_tersedia': 78,
      'status': 'kosong',
      'mae_historis': 2.34,
      'keterangan': 'Perkiraan',
      'waktu': '2026-10-31T10:00:00',
      'device_id': 'a1b2c3d4',
    },
    {
      'riwayat_id': 29,
      'model': 'xgboost',
      'horizon_menit': 20,
      'waktu_target': '2026-10-31T09:50:00',
      'perkiraan_kendaraan': 100,
      'kapasitas': 150,
      'slot_tersedia': 50,
      'status': 'hampir_penuh',
      'mae_historis': 3.10,
      'keterangan': 'Perkiraan',
      'waktu': '2026-10-31T09:30:00',
      'device_id': 'a1b2c3d4',
    },
    {
      'riwayat_id': 28,
      'model': 'xgboost',
      'horizon_menit': 30,
      'waktu_target': '2026-10-30T13:00:00',
      'perkiraan_kendaraan': 140,
      'kapasitas': 150,
      'slot_tersedia': 10,
      'status': 'penuh',
      'mae_historis': 3.54,
      'keterangan': 'Perkiraan',
      'waktu': '2026-10-30T12:30:00',
      'device_id': 'z9y8x7w6',
    },
    {
      'riwayat_id': 27,
      'model': 'xgboost',
      'horizon_menit': 10,
      'waktu_target': '2026-10-30T08:10:00',
      'perkiraan_kendaraan': 60,
      'kapasitas': 150,
      'slot_tersedia': 90,
      'status': 'kosong',
      'mae_historis': 2.34,
      'keterangan': 'Perkiraan',
      'waktu': '2026-10-30T08:00:00',
      'device_id': 'a1b2c3d4',
    },
    {
      'riwayat_id': 26,
      'model': 'xgboost',
      'horizon_menit': 20,
      'waktu_target': '2026-10-29T17:20:00',
      'perkiraan_kendaraan': 128,
      'kapasitas': 150,
      'slot_tersedia': 22,
      'status': 'hampir_penuh',
      'mae_historis': 3.10,
      'keterangan': 'Perkiraan',
      'waktu': '2026-10-29T17:00:00',
      'device_id': 'z9y8x7w6',
    },
  ];
}
