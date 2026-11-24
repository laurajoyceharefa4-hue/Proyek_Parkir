class Evaluasi {
  const Evaluasi({required this.hasil});

  factory Evaluasi.fromJson(Map<String, dynamic> json) {
    return Evaluasi(
      hasil: (json['hasil'] as List<dynamic>)
          .map((item) => HasilEvaluasi.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final List<HasilEvaluasi> hasil;

  Map<String, dynamic> toJson() => {
    'hasil': hasil.map((item) => item.toJson()).toList(),
  };
}

class HasilEvaluasi {
  const HasilEvaluasi({
    required this.horizonMenit,
    required this.tipeHari,
    this.mae,
    this.rmse,
    this.r2,
  });

  factory HasilEvaluasi.fromJson(Map<String, dynamic> json) {
    return HasilEvaluasi(
      horizonMenit: (json['horizon_menit'] as num).toInt(),
      tipeHari: json['tipe_hari'] as String,
      mae: (json['mae'] as num?)?.toDouble(),
      rmse: (json['rmse'] as num?)?.toDouble(),
      r2: (json['r2'] as num?)?.toDouble(),
    );
  }

  final int horizonMenit;
  final String tipeHari;
  final double? mae;
  final double? rmse;
  final double? r2;

  Map<String, dynamic> toJson() => {
    'horizon_menit': horizonMenit,
    'tipe_hari': tipeHari,
    'mae': mae,
    'rmse': rmse,
    'r2': r2,
  };
}
