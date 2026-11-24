import '../../core/status_level.dart';

class StatusParkir {
  const StatusParkir({
    required this.waktu,
    required this.kapasitas,
    required this.terisi,
    required this.slotTersedia,
    required this.status,
  });

  factory StatusParkir.fromJson(Map<String, dynamic> json) {
    return StatusParkir(
      waktu: DateTime.parse(json['waktu'] as String),
      kapasitas: (json['kapasitas'] as num).toInt(),
      terisi: (json['terisi'] as num).toInt(),
      slotTersedia: (json['slot_tersedia'] as num).toInt(),
      status: StatusLevel.fromKode(json['status'] as String),
    );
  }

  final DateTime waktu;
  final int kapasitas;
  final int terisi;
  final int slotTersedia;
  final StatusLevel status;

  double get persenTerisi => kapasitas <= 0 ? 0 : terisi / kapasitas * 100;

  Map<String, dynamic> toJson() => {
    'waktu': waktu.toIso8601String(),
    'kapasitas': kapasitas,
    'terisi': terisi,
    'slot_tersedia': slotTersedia,
    'status': status.kode,
  };
}
