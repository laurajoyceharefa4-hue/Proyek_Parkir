import 'package:flutter_test/flutter_test.dart';

import 'package:parkirpintar/core/waktu_swiss.dart';

void main() {
  test('Waktu target historis mempertahankan jam Swiss', () {
    final waktu = DateTime.parse('2024-09-26T21:20:00+02:00');

    expect(WaktuSwiss.tanggalJam(waktu), '26/09/2024, 21.20 CEST');
  });

  test('Waktu Swiss memakai CET pada musim dingin', () {
    final waktu = DateTime.parse('2024-01-01T10:00:00+01:00');

    expect(WaktuSwiss.tanggalJam(waktu), '01/01/2024, 10.00 CET');
  });

  test('Peralihan daylight saving time benar', () {
    final sebelum = DateTime.parse('2024-03-31T00:59:00Z');

    final sesudah = DateTime.parse('2024-03-31T01:00:00Z');

    expect(WaktuSwiss.jam(sebelum), '01.59');

    expect(WaktuSwiss.zona(sebelum), 'CET');

    expect(WaktuSwiss.jam(sesudah), '03.00');

    expect(WaktuSwiss.zona(sesudah), 'CEST');
  });
}
