import 'package:flutter_test/flutter_test.dart';
import 'package:parkirpintar/core/akurasi_text.dart';

void main() {
  test('formats slot values with Indonesian decimal comma', () {
    expect(formatRataRataMeleset(3.54), 'sekitar 3,5 slot');
    expect(formatMelesetTerbesar(4.8), 'sekitar 4,8 slot');
  });

  test('rounds and clamps match percentage', () {
    expect(formatKecocokan(.945), '95%');
    expect(formatKecocokan(1.4), '100%');
    expect(formatKecocokan(-.2), '0%');
  });

  test('null values are unavailable, not zero', () {
    expect(formatRataRataMeleset(null), 'Belum tersedia');
    expect(formatMelesetTerbesar(null), 'Belum tersedia');
    expect(formatKecocokan(null), 'Belum tersedia');
  });
}
