enum JenisGalat { koneksi, sesiHabis, validasi, server, lainnya }

class ParkirException implements Exception {
  const ParkirException(this.pesan, this.jenis);

  final String pesan;
  final JenisGalat jenis;

  @override
  String toString() => pesan;
}
