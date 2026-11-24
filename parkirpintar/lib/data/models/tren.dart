class Tren {
  const Tren({required this.harian, required this.mingguan});

  factory Tren.fromJson(Map<String, dynamic> json) {
    return Tren(
      harian: (json['harian'] as List<dynamic>)
          .map((item) => TitikTren.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      mingguan: (json['mingguan'] as List<dynamic>)
          .map((item) => TitikTren.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final List<TitikTren> harian;
  final List<TitikTren> mingguan;

  Map<String, dynamic> toJson() => {
    'harian': harian.map((item) => item.toJson()).toList(),
    'mingguan': mingguan.map((item) => item.toJson()).toList(),
  };
}

class TitikTren {
  const TitikTren({required this.label, required this.rataTerisi});

  factory TitikTren.fromJson(Map<String, dynamic> json) {
    return TitikTren(
      label: json['label'] as String,
      rataTerisi: (json['rata_terisi'] as num).toDouble(),
    );
  }

  final String label;
  final double rataTerisi;

  Map<String, dynamic> toJson() => {'label': label, 'rata_terisi': rataTerisi};
}
