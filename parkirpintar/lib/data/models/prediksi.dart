
import '../../core/status_level.dart';

class Prediksi {
  const Prediksi({
    required this.riwayatId,
    required this.model,
    required this.horizonMenit,
    required this.waktuTarget,
    required this.perkiraanKendaraan,
    required this.kapasitas,
    required this.slotTersedia,
    required this.status,
    required this.maeHistoris,
    required this.keterangan,
    required this.waktu,
    this.deviceId,
  });

  factory Prediksi.fromJson(Map<String, dynamic> json) {
    return Prediksi(
      riwayatId: (json['riwayat_id'] as num).toInt(),
      model: json['model'] as String,
      horizonMenit: (json['horizon_menit'] as num).toInt(),
      waktuTarget: DateTime.parse(
        json['waktu_target'] as String,
      ),
      perkiraanKendaraan:
          (json['perkiraan_kendaraan'] as num).toInt(),
      kapasitas: (json['kapasitas'] as num).toInt(),
      slotTersedia: (json['slot_tersedia'] as num).toInt(),
      status: StatusLevel.fromKode(
        json['status'] as String,
      ),
      maeHistoris: (json['mae_historis'] as num).toDouble(),
      keterangan: json['keterangan'] as String,
      waktu: DateTime.parse(json['waktu'] as String),
      deviceId: json['device_id'] as String?,
    );
  }

  final int riwayatId;
  final String model;
  final int horizonMenit;
  final DateTime waktuTarget;
  final int perkiraanKendaraan;
  final int kapasitas;
  final int slotTersedia;
  final StatusLevel status;
  final double maeHistoris;
  final String keterangan;
  final DateTime waktu;
  final String? deviceId;

  Map<String, dynamic> toJson() => {
    'riwayat_id': riwayatId,
    'model': model,
    'horizon_menit': horizonMenit,
    'waktu_target': waktuTarget.toIso8601String(),
    'perkiraan_kendaraan': perkiraanKendaraan,
    'kapasitas': kapasitas,
    'slot_tersedia': slotTersedia,
    'status': status.kode,
    'mae_historis': maeHistoris,
    'keterangan': keterangan,
    'waktu': waktu.toIso8601String(),
    if (deviceId != null) 'device_id': deviceId,
  };
}

class PrediksiRequest {
  const PrediksiRequest({
    required this.horizonMenit,
    required this.deviceId,
    this.waktuTarget,
    this.nomorBaris,
  });

  final int horizonMenit;
  final DateTime? waktuTarget;
  final String deviceId;
  final int? nomorBaris;

  Map<String, dynamic> toJson() => {
    'horizon_menit': horizonMenit,
    'device_id': deviceId,
    if (nomorBaris != null) 'nomor_baris': nomorBaris,
    if (waktuTarget != null)
      'waktu_target': waktuTarget!.toIso8601String(),
  };
}
