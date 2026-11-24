class Rekomendasi {
  const Rekomendasi({required this.tersepi, required this.teramai});

  factory Rekomendasi.fromJson(Map<String, dynamic> json) {
    return Rekomendasi(
      tersepi: (json['tersepi'] as List<dynamic>)
          .map((item) => JamRekomendasi.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      teramai: (json['teramai'] as List<dynamic>)
          .map((item) => JamRekomendasi.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final List<JamRekomendasi> tersepi;
  final List<JamRekomendasi> teramai;

  Map<String, dynamic> toJson() => {
    'tersepi': tersepi.map((item) => item.toJson()).toList(),
    'teramai': teramai.map((item) => item.toJson()).toList(),
  };
}

class JamRekomendasi {
  const JamRekomendasi({required this.jam, required this.rataTerisi});

  factory JamRekomendasi.fromJson(Map<String, dynamic> json) {
    return JamRekomendasi(
      jam: (json['jam'] as num).toInt(),
      rataTerisi: (json['rata_terisi'] as num).toDouble(),
    );
  }

  final int jam;
  final double rataTerisi;

  Map<String, dynamic> toJson() => {'jam': jam, 'rata_terisi': rataTerisi};
}
