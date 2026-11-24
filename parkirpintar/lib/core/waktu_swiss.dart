class WaktuSwiss {
  WaktuSwiss._();

  // Swiss memakai CET (UTC+1) saat musim dingin
  // dan CEST (UTC+2) saat daylight saving time.
  static DateTime keWaktuSwiss(DateTime waktu) {
    final utc = waktu.toUtc();
    final mulaiDst = _mingguTerakhir(utc.year, 3);
    final akhirDst = _mingguTerakhir(utc.year, 10);

    final dalamDst = !utc.isBefore(mulaiDst) && utc.isBefore(akhirDst);

    return utc.add(Duration(hours: dalamDst ? 2 : 1));
  }

  // Pergantian DST Swiss terjadi pada
  // Minggu terakhir Maret/Oktober pukul
  // 01.00 UTC.
  static DateTime _mingguTerakhir(int tahun, int bulan) {
    var tanggal = DateTime.utc(tahun, bulan + 1, 0, 1);

    while (tanggal.weekday != DateTime.sunday) {
      tanggal = tanggal.subtract(const Duration(days: 1));
    }

    return tanggal;
  }

  static String zona(DateTime waktu) {
    final utc = waktu.toUtc();

    final mulaiDst = _mingguTerakhir(utc.year, 3);

    final akhirDst = _mingguTerakhir(utc.year, 10);

    final dalamDst = !utc.isBefore(mulaiDst) && utc.isBefore(akhirDst);

    return dalamDst ? 'CEST' : 'CET';
  }

  static String jam(DateTime waktu) {
    final swiss = keWaktuSwiss(waktu);

    final jam = swiss.hour.toString().padLeft(2, '0');
    final menit = swiss.minute.toString().padLeft(2, '0');

    return '$jam.$menit';
  }

  static String tanggal(DateTime waktu) {
    final swiss = keWaktuSwiss(waktu);

    final hari = swiss.day.toString().padLeft(2, '0');
    final bulan = swiss.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${swiss.year}';
  }

  static String tanggalJam(DateTime waktu) {
    return '${tanggal(waktu)}, '
        '${jam(waktu)} ${zona(waktu)}';
  }
}
