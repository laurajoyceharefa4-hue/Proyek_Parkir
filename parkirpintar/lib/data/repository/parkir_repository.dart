import '../models/admin.dart';
import '../models/evaluasi.dart';
import '../models/konfigurasi.dart';
import '../models/prediksi.dart';
import '../models/rekomendasi.dart';
import '../models/rekap.dart';
import '../models/status_parkir.dart';
import '../models/tren.dart';

abstract class ParkirRepository {
  Future<StatusParkir> getStatus();

  Future<Prediksi> prediksi(PrediksiRequest request);

  Future<List<Prediksi>> getRiwayat({
    required String deviceId,
    bool semuaHp = false,
  });

  Future<Prediksi> getRiwayatDetail(int id);

  Future<Tren> getTren();

  Future<Rekomendasi> getRekomendasi();

  Future<Rekap> getRekap({required DateTime dari, required DateTime sampai});

  Future<Evaluasi> getEvaluasi();

  Future<Konfigurasi> getKonfigurasi();

  Future<Konfigurasi> updateKonfigurasi(Konfigurasi konfigurasi);

  Future<LoginResult> login(String username, String password);

  Future<Admin> me();

  Future<List<Admin>> getDaftarAdmin();

  Future<Admin> tambahAdmin({
    required String nama,
    required String username,
    required String password,
  });

  Future<Admin> gantiPassword({required int id, required String passwordBaru});

  Future<Admin> setAdminAktif({required int id, required bool aktif});
}
