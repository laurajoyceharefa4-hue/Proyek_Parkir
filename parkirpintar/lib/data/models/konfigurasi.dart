class Konfigurasi {
  const Konfigurasi({
    required this.kapasitas,
    required this.ambangHampirPenuh,
    required this.ambangPenuh,
  });

  factory Konfigurasi.fromJson(Map<String, dynamic> json) {
    return Konfigurasi(
      kapasitas: (json['kapasitas'] as num).toInt(),
      // Asumsi kontrak: ambang disimpan sebagai persen bulat.
      ambangHampirPenuh: (json['ambang_hampir_penuh'] as num).toInt(),
      ambangPenuh: (json['ambang_penuh'] as num).toInt(),
    );
  }

  final int kapasitas;
  final int ambangHampirPenuh;
  final int ambangPenuh;

  Konfigurasi copyWith({
    int? kapasitas,
    int? ambangHampirPenuh,
    int? ambangPenuh,
  }) {
    return Konfigurasi(
      kapasitas: kapasitas ?? this.kapasitas,
      ambangHampirPenuh: ambangHampirPenuh ?? this.ambangHampirPenuh,
      ambangPenuh: ambangPenuh ?? this.ambangPenuh,
    );
  }

  Map<String, dynamic> toJson() => {
    'kapasitas': kapasitas,
    'ambang_hampir_penuh': ambangHampirPenuh,
    'ambang_penuh': ambangPenuh,
  };
}
