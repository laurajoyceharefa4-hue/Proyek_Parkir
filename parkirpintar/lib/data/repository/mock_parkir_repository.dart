
import '../../core/app_constants.dart';
import '../../core/status_level.dart';
import '../mock/mock_data.dart';
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

class MockParkirRepository implements ParkirRepository {
  MockParkirRepository()
      : _konfigurasi = Konfigurasi.fromJson(MockData.konfigurasi),
        _riwayat = MockData.riwayat.map(Prediksi.fromJson).toList(),
        _admins = MockData.admins.map(Admin.fromJson).toList();

  Konfigurasi _konfigurasi;
  final List<Prediksi> _riwayat;
  final List<Admin> _admins;

  final Map<String, String> _passwords = {
    'admin': 'admin123',
  };

  Admin? _adminAktif;

  int _nextRiwayatId = 31;
  int _nextAdminId = 4;

  bool simulasiOffline = false;
  bool simulasiSesiHabis = false;

  Future<void> _periksaSesi() async {
    if (simulasiSesiHabis) {
      throw const ParkirException(
        'Sesi berakhir, silakan masuk lagi',
        JenisGalat.sesiHabis,
      );
    }
  }

  Future<void> _jeda() {
    return Future<void>.delayed(
      const Duration(milliseconds: 350),
    );
  }

  Future<void> _periksaKoneksi() async {
    await _jeda();

    if (simulasiOffline) {
      throw const ParkirException(
        'Tidak bisa terhubung ke server.',
        JenisGalat.koneksi,
      );
    }
  }

  // ======================================
  // STATUS PARKIR
  // ======================================

  @override
  Future<StatusParkir> getStatus() async {
    await _periksaKoneksi();

    const terisi = 96;

    return StatusParkir(
      waktu: DateTime.now(),
      kapasitas: _konfigurasi.kapasitas,
      terisi: terisi,
      slotTersedia: (
        _konfigurasi.kapasitas - terisi
      ).clamp(0, _konfigurasi.kapasitas),
      status: StatusLevel.hitung(
        terisi: terisi,
        kapasitas: _konfigurasi.kapasitas,
        ambangHampirPenuh:
            _konfigurasi.ambangHampirPenuh,
        ambangPenuh: _konfigurasi.ambangPenuh,
      ),
    );
  }

  // ======================================
  // PREDIKSI SIMULASI
  // ======================================

  @override
  Future<Prediksi> prediksi(
    PrediksiRequest request,
  ) async {
    await _periksaKoneksi();

    if (!AppConstants.horizons.contains(
      request.horizonMenit,
    )) {
      throw const ParkirException(
        'Horizon prediksi tidak valid.',
        JenisGalat.validasi,
      );
    }

    final waktuTarget = request.waktuTarget ??
        DateTime.now().add(
          Duration(minutes: request.horizonMenit),
        );

    final perkiraan = _perkiraanUntukJam(
      waktuTarget.hour,
    );

    final mae = switch (request.horizonMenit) {
      10 => 2.34,
      20 => 3.10,
      _ => 3.54,
    };

    final kapasitas = _konfigurasi.kapasitas;
    final slotTersedia = kapasitas - perkiraan;

    final hasil = Prediksi(
      riwayatId: _nextRiwayatId++,
      model: 'xgboost',
      horizonMenit: request.horizonMenit,
      waktuTarget: waktuTarget,
      perkiraanKendaraan: perkiraan,
      kapasitas: kapasitas,
      slotTersedia: slotTersedia,
      status: StatusLevel.hitung(
        terisi: perkiraan,
        kapasitas: kapasitas,
        ambangHampirPenuh:
            _konfigurasi.ambangHampirPenuh,
        ambangPenuh: _konfigurasi.ambangPenuh,
      ),
      maeHistoris: mae,
      keterangan: 'Perkiraan',
      waktu: DateTime.now(),
      deviceId: request.deviceId,
    );

    _riwayat.add(hasil);
    return hasil;
  }

  int _perkiraanUntukJam(int jam) {
    const pola = [
      18, 16, 14, 14, 18, 28,
      48, 78, 102, 115, 124, 132,
      136, 130, 120, 110, 98, 86,
      72, 60, 48, 36, 28, 22,
    ];

    return pola[jam].clamp(
      0,
      _konfigurasi.kapasitas,
    );
  }

  // ======================================
  // RIWAYAT
  // ======================================

  @override
  Future<List<Prediksi>> getRiwayat({
    required String deviceId,
    bool semuaHp = false,
  }) async {
    await _periksaKoneksi();

    final hasil = semuaHp
        ? List<Prediksi>.from(_riwayat)
        : _riwayat
            .where(
              (item) => item.deviceId == deviceId,
            )
            .toList();

    hasil.sort(
      (a, b) => b.waktu.compareTo(a.waktu),
    );

    return List<Prediksi>.unmodifiable(hasil);
  }

  @override
  Future<Prediksi> getRiwayatDetail(
    int id,
  ) async {
    await _periksaKoneksi();

    return _riwayat.firstWhere(
      (item) => item.riwayatId == id,
      orElse: () => throw const ParkirException(
        'Riwayat tidak ditemukan.',
        JenisGalat.validasi,
      ),
    );
  }

  // ======================================
  // TREN DAN REKOMENDASI
  // ======================================

  @override
  Future<Tren> getTren() async {
    await _periksaKoneksi();
    return Tren.fromJson(MockData.tren);
  }

  @override
  Future<Rekomendasi> getRekomendasi() async {
    await _periksaKoneksi();
    return Rekomendasi.fromJson(
      MockData.rekomendasi,
    );
  }

  // ======================================
  // REKAP SIMULASI
  // ======================================

  @override
  Future<Rekap> getRekap({
    required DateTime dari,
    required DateTime sampai,
  }) async {
    await _periksaKoneksi();
    await _periksaSesi();

    final hari = sampai
        .difference(dari)
        .inDays
        .abs()
        .clamp(1, 365);

    final faktor = hari / 31;

    final sumber = Rekap.fromJson(
      MockData.rekap,
    );

    int skala(int nilai) {
      return (nilai * faktor).round();
    }

    // Model Rekap terbaru mengizinkan null.
    // Periksa nilai sebelum perhitungan.
    final totalMasuk = sumber.totalMasuk;
    final jenis = sumber.perJenis;

    return Rekap(
      totalMasuk: totalMasuk == null
          ? null
          : skala(totalMasuk),

      perJenis: jenis == null
          ? null
          : PerJenis(
              motor: skala(jenis.motor),
              mobil: skala(jenis.mobil),
              lainnya: skala(jenis.lainnya),
            ),

      rataLamaParkirMenit:
          sumber.rataLamaParkirMenit,

      jamTeramai: sumber.jamTeramai,
      jamTersepi: sumber.jamTersepi,

      hariTeramai: sumber.hariTeramai,
      hariTersepi: sumber.hariTersepi,

      rataTerisi: sumber.rataTerisi,
    );
  }

  // ======================================
  // EVALUASI
  // ======================================

  @override
  Future<Evaluasi> getEvaluasi() async {
    await _periksaKoneksi();
    await _periksaSesi();

    return Evaluasi.fromJson(
      MockData.evaluasi,
    );
  }

  // ======================================
  // KONFIGURASI
  // ======================================

  @override
  Future<Konfigurasi> getKonfigurasi() async {
    await _periksaKoneksi();
    await _periksaSesi();

    return _konfigurasi;
  }

  @override
  Future<Konfigurasi> updateKonfigurasi(
    Konfigurasi konfigurasi,
  ) async {
    await _periksaKoneksi();
    await _periksaSesi();

    if (konfigurasi.kapasitas <= 0 ||
        konfigurasi.ambangHampirPenuh < 0 ||
        konfigurasi.ambangPenuh > 100 ||
        konfigurasi.ambangHampirPenuh >=
            konfigurasi.ambangPenuh) {
      throw const ParkirException(
        'Konfigurasi tidak valid.',
        JenisGalat.validasi,
      );
    }

    _konfigurasi = konfigurasi;

    return _konfigurasi;
  }

  // ======================================
  // LOGIN ADMIN SIMULASI
  // ======================================

  @override
  Future<LoginResult> login(
    String username,
    String password,
  ) async {
    await _periksaKoneksi();

    final admin = _admins.firstWhere(
      (item) => item.username == username,
      orElse: () => throw const ParkirException(
        'Username atau password salah',
        JenisGalat.validasi,
      ),
    );

    if (!admin.aktif ||
        _passwords[username] != password) {
      throw const ParkirException(
        'Username atau password salah',
        JenisGalat.validasi,
      );
    }

    _adminAktif = admin;

    return LoginResult(
      accessToken: 'mock-jwt-token',
      tokenType: 'bearer',
      admin: admin,
    );
  }

  // ======================================
  // PROFIL ADMIN
  // ======================================

  @override
  Future<Admin> me() async {
    await _jeda();

    return _adminAktif ??
        (throw const ParkirException(
          'Sesi berakhir, silakan masuk lagi',
          JenisGalat.sesiHabis,
        ));
  }

  // ======================================
  // DAFTAR ADMIN
  // ======================================

  @override
  Future<List<Admin>> getDaftarAdmin() async {
    await _periksaKoneksi();
    await _periksaSesi();

    return List<Admin>.unmodifiable(_admins);
  }

  // ======================================
  // TAMBAH ADMIN
  // ======================================

  @override
  Future<Admin> tambahAdmin({
    required String nama,
    required String username,
    required String password,
  }) async {
    await _periksaKoneksi();
    await _periksaSesi();

    if (_admins.any(
      (item) => item.username == username,
    )) {
      throw const ParkirException(
        'Username sudah dipakai',
        JenisGalat.validasi,
      );
    }

    final admin = Admin(
      id: _nextAdminId++,
      nama: nama,
      username: username,
      aktif: true,
    );

    _admins.add(admin);
    _passwords[username] = password;

    return admin;
  }

  // ======================================
  // GANTI PASSWORD ADMIN
  // ======================================

  @override
  Future<Admin> gantiPassword({
    required int id,
    required String passwordBaru,
  }) async {
    await _periksaKoneksi();
    await _periksaSesi();

    final index = _admins.indexWhere(
      (item) => item.id == id,
    );

    if (index < 0) {
      throw const ParkirException(
        'Admin tidak ditemukan.',
        JenisGalat.validasi,
      );
    }

    final admin = _admins[index];

    if (admin.username != null) {
      _passwords[admin.username!] = passwordBaru;
    }

    return admin;
  }

  // ======================================
  // AKTIFKAN / NONAKTIFKAN ADMIN
  // ======================================

  @override
  Future<Admin> setAdminAktif({
    required int id,
    required bool aktif,
  }) async {
    await _periksaKoneksi();
    await _periksaSesi();

    final index = _admins.indexWhere(
      (item) => item.id == id,
    );

    if (index < 0) {
      throw const ParkirException(
        'Admin tidak ditemukan.',
        JenisGalat.validasi,
      );
    }

    final admin = Admin(
      id: _admins[index].id,
      nama: _admins[index].nama,
      username: _admins[index].username,
      aktif: aktif,
    );

    _admins[index] = admin;

    if (_adminAktif?.id == id && !aktif) {
      _adminAktif = null;
    }

    return admin;
  }
}
