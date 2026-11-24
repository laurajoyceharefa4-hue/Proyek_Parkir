
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/admin.dart';
import '../models/evaluasi.dart';
import '../models/konfigurasi.dart';
import '../models/prediksi.dart';
import '../models/rekomendasi.dart';
import '../models/rekap.dart';
import '../models/status_parkir.dart';
import '../models/tren.dart';
import 'parkir_exception.dart';
import 'parkir_repository.dart';

class WaktuHistoris {
  const WaktuHistoris({
    required this.nomorBaris,
    required this.jam,
    required this.waktuPengamatan,
  });

  factory WaktuHistoris.fromJson(Map<String, dynamic> json) {
    return WaktuHistoris(
      nomorBaris: (json['nomor_baris'] as num).toInt(),
      jam: json['jam'] as String,
      waktuPengamatan: json['waktu_pengamatan'] as String,
    );
  }

  final int nomorBaris;
  final String jam;
  final String waktuPengamatan;
}

class PeriodeRekap {
  const PeriodeRekap({
    required this.tanggalAwal,
    required this.tanggalAkhir,
    required this.jumlahSampel,
  });

  factory PeriodeRekap.fromJson(Map<String, dynamic> json) {
    return PeriodeRekap(
      tanggalAwal: DateTime.parse(json['tanggal_awal'] as String),
      tanggalAkhir: DateTime.parse(json['tanggal_akhir'] as String),
      jumlahSampel: (json['jumlah_sampel'] as num).toInt(),
    );
  }

  final DateTime tanggalAwal;
  final DateTime tanggalAkhir;
  final int jumlahSampel;
}

class ApiParkirRepository implements ParkirRepository {
  ApiParkirRepository({
    required this.addressProvider,
    required this.deviceIdProvider,
    required this.tokenProvider,
  });

  final String Function() addressProvider;
  final String Function() deviceIdProvider;
  final Future<String?> Function() tokenProvider;

  static const Duration _timeout = Duration(seconds: 20);

  Uri _url(String path) {
    final base = addressProvider()
        .trim()
        .replaceAll(RegExp(r'/+$'), '');

    final uri = Uri.tryParse('$base$path');

    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const ParkirException(
        'Alamat server tidak valid.',
        JenisGalat.validasi,
      );
    }

    return uri;
  }

  Future<Map<String, String>> _headers({
    bool requiresAuth = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = await tokenProvider();

      if (token == null || token.isEmpty) {
        throw const ParkirException(
          'Sesi admin tidak tersedia. Silakan login.',
          JenisGalat.sesiHabis,
        );
      }

      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = _url(path);
      final headers = await _headers(
        requiresAuth: requiresAuth,
      );

      late final http.Response response;

      if (method == 'GET') {
        response = await http.get(
          uri,
          headers: headers,
        ).timeout(_timeout);
      } else if (method == 'POST') {
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        ).timeout(_timeout);
      } else if (method == 'PUT') {
        response = await http.put(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        ).timeout(_timeout);
      } else {
        throw const ParkirException(
          'Metode HTTP tidak didukung.',
          JenisGalat.validasi,
        );
      }

      dynamic decoded;

      try {
        decoded = response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body);
      } on FormatException {
        throw const ParkirException(
          'Respons server bukan JSON yang valid.',
          JenisGalat.server,
        );
      }

      if (response.statusCode >= 400) {
        String pesan = 'Server mengalami kesalahan.';

        if (decoded is Map<String, dynamic>) {
          final detail = decoded['detail'];

          if (detail is String) {
            pesan = detail;
          } else if (detail != null) {
            pesan = detail.toString();
          }
        }

        final jenis = switch (response.statusCode) {
          401 => requiresAuth
              ? JenisGalat.sesiHabis
              : JenisGalat.validasi,
          400 || 403 || 404 || 409 || 422 =>
            JenisGalat.validasi,
          _ => JenisGalat.server,
        };

        throw ParkirException(pesan, jenis);
      }

      return decoded;
    } on ParkirException {
      rethrow;
    } on TimeoutException {
      throw const ParkirException(
        'Server terlalu lama merespons.',
        JenisGalat.koneksi,
      );
    } on SocketException {
      throw const ParkirException(
        'Tidak dapat terhubung ke FastAPI. Periksa jaringan.',
        JenisGalat.koneksi,
      );
    } on http.ClientException {
      throw const ParkirException(
        'Permintaan HTTP gagal. Periksa alamat server.',
        JenisGalat.koneksi,
      );
    }
  }

  Map<String, dynamic> _object(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    throw const ParkirException(
      'Format objek API tidak sesuai.',
      JenisGalat.server,
    );
  }

  List<dynamic> _list(dynamic value) {
    if (value is List) return value;

    throw const ParkirException(
      'Format daftar API tidak sesuai.',
      JenisGalat.server,
    );
  }

  String _date(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ========================================
  // STATUS DAN DATA HISTORIS
  // ========================================

  @override
  Future<StatusParkir> getStatus() async {
    final data = await _request(
      'GET',
      '/api/mobile/status',
    );

    return StatusParkir.fromJson(_object(data));
  }

  Future<StatusParkir> getStatusAt(int nomorBaris) async {
    final data = await _request(
      'GET',
      '/api/mobile/status?nomor_baris=$nomorBaris',
    );

    return StatusParkir.fromJson(_object(data));
  }

  Future<List<String>> getTanggalTersedia() async {
    final data = _object(
      await _request('GET', '/api/tanggal-tersedia'),
    );

    return _list(data['tanggal'])
        .map((value) => value.toString())
        .toList();
  }

  Future<List<WaktuHistoris>> getWaktuTersedia(
    String tanggal,
  ) async {
    final query = Uri.encodeQueryComponent(tanggal);

    final data = _object(
      await _request(
        'GET',
        '/api/waktu-tersedia?tanggal=$query',
      ),
    );

    return _list(data['pilihan'])
        .map(
          (value) => WaktuHistoris.fromJson(
            _object(value),
          ),
        )
        .toList();
  }

  // ========================================
  // PREDIKSI XGBOOST
  // ========================================

  @override
  Future<Prediksi> prediksi(
    PrediksiRequest request,
  ) async {
    final data = await _request(
      'POST',
      '/api/mobile/prediksi',
      body: request.toJson(),
    );

    return Prediksi.fromJson(_object(data));
  }

  // ========================================
  // RIWAYAT
  // ========================================

  @override
  Future<List<Prediksi>> getRiwayat({
    required String deviceId,
    bool semuaHp = false,
  }) async {
    if (semuaHp) {
      throw const ParkirException(
        'Riwayat seluruh perangkat belum tersedia.',
        JenisGalat.server,
      );
    }

    final id = Uri.encodeQueryComponent(deviceId);

    final data = await _request(
      'GET',
      '/api/mobile/riwayat?device_id=$id',
    );

    return _list(data)
        .map(
          (item) => Prediksi.fromJson(
            _object(item),
          ),
        )
        .toList();
  }

  @override
  Future<Prediksi> getRiwayatDetail(int id) async {
    final deviceId = Uri.encodeQueryComponent(
      deviceIdProvider(),
    );

    final data = await _request(
      'GET',
      '/api/mobile/riwayat/$id?device_id=$deviceId',
    );

    return Prediksi.fromJson(_object(data));
  }

  // ========================================
  // TREN, REKOMENDASI DAN EVALUASI
  // ========================================

  @override
  Future<Tren> getTren() async {
    final data = await _request(
      'GET',
      '/api/mobile/tren',
    );

    return Tren.fromJson(_object(data));
  }

  @override
  Future<Rekomendasi> getRekomendasi() async {
    final data = await _request(
      'GET',
      '/api/mobile/rekomendasi',
    );

    return Rekomendasi.fromJson(_object(data));
  }

  @override
  Future<Evaluasi> getEvaluasi() async {
    final data = await _request(
      'GET',
      '/api/mobile/evaluasi',
    );

    return Evaluasi.fromJson(_object(data));
  }

  // ========================================
  // KONFIGURASI
  // ========================================

  @override
  Future<Konfigurasi> getKonfigurasi() async {
    final data = await _request(
      'GET',
      '/api/mobile/konfigurasi',
    );

    return Konfigurasi.fromJson(_object(data));
  }

  @override
  Future<Konfigurasi> updateKonfigurasi(
    Konfigurasi konfigurasi,
  ) async {
    final data = await _request(
      'PUT',
      '/api/admin/konfigurasi',
      requiresAuth: true,
      body: konfigurasi.toJson(),
    );

    return Konfigurasi.fromJson(_object(data));
  }

  // ========================================
  // REKAP HISTORIS
  // ========================================

  Future<PeriodeRekap> getPeriodeRekap() async {
    final data = await _request(
      'GET',
      '/api/admin/rekap/periode',
      requiresAuth: true,
    );

    return PeriodeRekap.fromJson(_object(data));
  }

  @override
  Future<Rekap> getRekap({
    required DateTime dari,
    required DateTime sampai,
  }) async {
    final start = _date(dari);
    final end = _date(sampai);

    final data = await _request(
      'GET',
      '/api/admin/rekap?dari=$start&sampai=$end',
      requiresAuth: true,
    );

    return Rekap.fromJson(_object(data));
  }

  // ========================================
  // LOGIN ADMIN
  // ========================================

  @override
  Future<LoginResult> login(
    String username,
    String password,
  ) async {
    final data = await _request(
      'POST',
      '/api/admin/login',
      body: {
        'username': username.trim(),
        'password': password,
      },
    );

    return LoginResult.fromJson(_object(data));
  }

  @override
  Future<Admin> me() async {
    final data = await _request(
      'GET',
      '/api/admin/me',
      requiresAuth: true,
    );

    return Admin.fromJson(_object(data));
  }

  @override
  Future<List<Admin>> getDaftarAdmin() async {
    final data = await _request(
      'GET',
      '/api/admin/admins',
      requiresAuth: true,
    );

    return _list(data)
        .map((item) => Admin.fromJson(_object(item)))
        .toList();
  }

  @override
  Future<Admin> tambahAdmin({
    required String nama,
    required String username,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      '/api/admin/admins',
      requiresAuth: true,
      body: {
        'nama': nama.trim(),
        'username': username.trim(),
        'password': password,
      },
    );

    return Admin.fromJson(_object(data));
  }

  @override
  Future<Admin> gantiPassword({
    required int id,
    required String passwordBaru,
  }) async {
    final data = await _request(
      'PUT',
      '/api/admin/admins/$id/password',
      requiresAuth: true,
      body: {
        'password_baru': passwordBaru,
      },
    );

    return Admin.fromJson(_object(data));
  }

  @override
  Future<Admin> setAdminAktif({
    required int id,
    required bool aktif,
  }) async {
    final data = await _request(
      'PUT',
      '/api/admin/admins/$id/aktif',
      requiresAuth: true,
      body: {
        'aktif': aktif,
      },
    );

    return Admin.fromJson(_object(data));
  }

  Future<void> logoutServer() async {
    await _request(
      'POST',
      '/api/admin/logout',
      requiresAuth: true,
    );
  }
}
