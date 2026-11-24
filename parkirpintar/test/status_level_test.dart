import 'package:flutter_test/flutter_test.dart';
import 'package:parkirpintar/core/status_level.dart';

void main() {
  test('calculates parking status across thresholds', () {
    expect(
      StatusLevel.hitung(
        terisi: 50,
        kapasitas: 150,
        ambangHampirPenuh: 60,
        ambangPenuh: 90,
      ),
      StatusLevel.kosong,
    );
    expect(
      StatusLevel.hitung(
        terisi: 96,
        kapasitas: 150,
        ambangHampirPenuh: 60,
        ambangPenuh: 90,
      ),
      StatusLevel.hampirPenuh,
    );
    expect(
      StatusLevel.hitung(
        terisi: 140,
        kapasitas: 150,
        ambangHampirPenuh: 60,
        ambangPenuh: 90,
      ),
      StatusLevel.penuh,
    );
    expect(
      StatusLevel.hitung(
        terisi: 90,
        kapasitas: 150,
        ambangHampirPenuh: 60,
        ambangPenuh: 90,
      ),
      StatusLevel.hampirPenuh,
    );
    expect(
      StatusLevel.hitung(
        terisi: 135,
        kapasitas: 150,
        ambangHampirPenuh: 60,
        ambangPenuh: 90,
      ),
      StatusLevel.penuh,
    );
    expect(
      StatusLevel.hitung(
        terisi: 1,
        kapasitas: 0,
        ambangHampirPenuh: 60,
        ambangPenuh: 90,
      ),
      StatusLevel.kosong,
    );
  });
}
