
class Rekap {
  const Rekap({
    required this.jamTeramai,
    required this.jamTersepi,
    required this.hariTeramai,
    required this.hariTersepi,
    required this.rataTerisi,
    this.totalMasuk,
    this.perJenis,
    this.rataLamaParkirMenit,
    this.jumlahSampel = 0,
    this.kapasitas = 0,
    this.rataTersedia = 0,
    this.rataPersenTerisi = 0,
    this.tanggalDari,
    this.tanggalSampai,
    this.rataTerisiPerJam = const [],
    this.cakupanHarian = const [],
    this.kualitasData,
    this.catatan,
  });

  factory Rekap.fromJson(Map<String, dynamic> json) {
    return Rekap(
      totalMasuk: (json['total_masuk'] as num?)?.toInt(),
      perJenis: json['per_jenis'] is Map<String, dynamic>
          ? PerJenis.fromJson(
              json['per_jenis'] as Map<String, dynamic>,
            )
          : null,
      rataLamaParkirMenit:
          (json['rata_lama_parkir_menit'] as num?)?.toInt(),
      jamTeramai: (json['jam_teramai'] as num).toInt(),
      jamTersepi: (json['jam_tersepi'] as num).toInt(),
      hariTeramai: json['hari_teramai'] as String?,
      hariTersepi: json['hari_tersepi'] as String?,
      rataTerisi: (json['rata_terisi'] as num).toDouble(),
      rataTersedia:
          (json['rata_tersedia'] as num?)?.toDouble() ?? 0,
      rataPersenTerisi:
          (json['rata_persen_terisi'] as num?)?.toDouble() ?? 0,
      jumlahSampel:
          (json['jumlah_sampel'] as num?)?.toInt() ?? 0,
      kapasitas: (json['kapasitas'] as num?)?.toInt() ?? 0,
      tanggalDari: json['tanggal_dari'] as String?,
      tanggalSampai: json['tanggal_sampai'] as String?,
      catatan: json['catatan'] as String?,
      rataTerisiPerJam:
          (json['rata_terisi_per_jam'] as List<dynamic>? ?? [])
              .map(
                (item) => RekapJam.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
      cakupanHarian:
          (json['cakupan_harian'] as List<dynamic>? ?? [])
              .map(
                (item) => CakupanHarian.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
      kualitasData: json['kualitas_data'] is Map<String, dynamic>
          ? KualitasData.fromJson(
              json['kualitas_data'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final int? totalMasuk;
  final PerJenis? perJenis;
  final int? rataLamaParkirMenit;

  final int jamTeramai;
  final int jamTersepi;
  final String? hariTeramai;
  final String? hariTersepi;

  final double rataTerisi;
  final double rataTersedia;
  final double rataPersenTerisi;

  final int jumlahSampel;
  final int kapasitas;

  final String? tanggalDari;
  final String? tanggalSampai;
  final String? catatan;

  final List<RekapJam> rataTerisiPerJam;
  final List<CakupanHarian> cakupanHarian;
  final KualitasData? kualitasData;

  Map<String, dynamic> toJson() => {
    'total_masuk': totalMasuk,
    'per_jenis': perJenis?.toJson(),
    'rata_lama_parkir_menit': rataLamaParkirMenit,
    'jam_teramai': jamTeramai,
    'jam_tersepi': jamTersepi,
    'hari_teramai': hariTeramai,
    'hari_tersepi': hariTersepi,
    'rata_terisi': rataTerisi,
    'rata_tersedia': rataTersedia,
    'rata_persen_terisi': rataPersenTerisi,
    'jumlah_sampel': jumlahSampel,
    'kapasitas': kapasitas,
    'tanggal_dari': tanggalDari,
    'tanggal_sampai': tanggalSampai,
    'rata_terisi_per_jam':
        rataTerisiPerJam.map((item) => item.toJson()).toList(),
    'cakupan_harian':
        cakupanHarian.map((item) => item.toJson()).toList(),
    'kualitas_data': kualitasData?.toJson(),
    'catatan': catatan,
  };
}

class RekapJam {
  const RekapJam({
    required this.jam,
    required this.rataTerisi,
    required this.jumlahSampel,
  });

  factory RekapJam.fromJson(Map<String, dynamic> json) {
    return RekapJam(
      jam: (json['jam'] as num).toInt(),
      rataTerisi: (json['rata_terisi'] as num).toDouble(),
      jumlahSampel: (json['jumlah_sampel'] as num).toInt(),
    );
  }

  final int jam;
  final double rataTerisi;
  final int jumlahSampel;

  Map<String, dynamic> toJson() => {
    'jam': jam,
    'rata_terisi': rataTerisi,
    'jumlah_sampel': jumlahSampel,
  };
}

class CakupanHarian {
  const CakupanHarian({
    required this.tanggal,
    required this.hari,
    required this.jumlahSampel,
    required this.hariPenuh,
  });

  factory CakupanHarian.fromJson(Map<String, dynamic> json) {
    return CakupanHarian(
      tanggal: json['tanggal'] as String,
      hari: json['hari'] as String,
      jumlahSampel: (json['jumlah_sampel'] as num).toInt(),
      hariPenuh: json['hari_penuh'] as bool,
    );
  }

  final String tanggal;
  final String hari;
  final int jumlahSampel;
  final bool hariPenuh;

  Map<String, dynamic> toJson() => {
    'tanggal': tanggal,
    'hari': hari,
    'jumlah_sampel': jumlahSampel,
    'hari_penuh': hariPenuh,
  };
}

class KualitasData {
  const KualitasData({
    required this.barisKonsisten,
    required this.barisTidakKonsisten,
    required this.persentaseTidakKonsisten,
    required this.totalSelisihSlot,
    required this.rataSelisihSlot,
  });

  factory KualitasData.fromJson(Map<String, dynamic> json) {
    return KualitasData(
      barisKonsisten:
          (json['baris_konsisten'] as num).toInt(),
      barisTidakKonsisten:
          (json['baris_tidak_konsisten'] as num).toInt(),
      persentaseTidakKonsisten:
          (json['persentase_tidak_konsisten'] as num).toDouble(),
      totalSelisihSlot:
          (json['total_selisih_slot'] as num).toDouble(),
      rataSelisihSlot:
          (json['rata_selisih_slot'] as num).toDouble(),
    );
  }

  final int barisKonsisten;
  final int barisTidakKonsisten;
  final double persentaseTidakKonsisten;
  final double totalSelisihSlot;
  final double rataSelisihSlot;

  Map<String, dynamic> toJson() => {
    'baris_konsisten': barisKonsisten,
    'baris_tidak_konsisten': barisTidakKonsisten,
    'persentase_tidak_konsisten': persentaseTidakKonsisten,
    'total_selisih_slot': totalSelisihSlot,
    'rata_selisih_slot': rataSelisihSlot,
  };
}

class PerJenis {
  const PerJenis({
    required this.motor,
    required this.mobil,
    required this.lainnya,
  });

  factory PerJenis.fromJson(Map<String, dynamic> json) {
    return PerJenis(
      motor: (json['motor'] as num).toInt(),
      mobil: (json['mobil'] as num).toInt(),
      lainnya: (json['lainnya'] as num).toInt(),
    );
  }

  final int motor;
  final int mobil;
  final int lainnya;

  Map<String, dynamic> toJson() => {
    'motor': motor,
    'mobil': mobil,
    'lainnya': lainnya,
  };
}
