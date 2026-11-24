import 'package:flutter_test/flutter_test.dart';
import 'package:parkirpintar/core/status_level.dart';
import 'package:parkirpintar/data/models/konfigurasi.dart';
import 'package:parkirpintar/data/models/prediksi.dart';
import 'package:parkirpintar/data/repository/mock_parkir_repository.dart';
import 'package:parkirpintar/data/repository/parkir_exception.dart';

void main() {
  late MockParkirRepository repository;

  setUp(() {
    repository = MockParkirRepository();
  });

  test('prediction is added to device history', () async {
    final before = await repository.getRiwayat(deviceId: 'test-device');
    await repository.prediksi(
      const PrediksiRequest(horizonMenit: 10, deviceId: 'test-device'),
    );
    final after = await repository.getRiwayat(deviceId: 'test-device');
    expect(after.length, before.length + 1);
  });

  test('public history only returns the requested device', () async {
    final history = await repository.getRiwayat(deviceId: 'a1b2c3d4');
    expect(history, isNotEmpty);
    expect(history.every((item) => item.deviceId == 'a1b2c3d4'), isTrue);
  });

  test(
    'login rejects wrong credentials and accepts the initial admin',
    () async {
      expect(
        () => repository.login('admin', 'salah'),
        throwsA(isA<ParkirException>()),
      );
      final result = await repository.login('admin', 'admin123');
      expect(result.admin.nama, 'Admin');
    },
  );

  test('configuration changes affect calculated status', () async {
    final before = await repository.getStatus();
    await repository.updateKonfigurasi(
      const Konfigurasi(kapasitas: 150, ambangHampirPenuh: 70, ambangPenuh: 95),
    );
    final after = await repository.getStatus();
    expect(before.status, StatusLevel.hampirPenuh);
    expect(after.status, StatusLevel.kosong);
    await repository.updateKonfigurasi(
      const Konfigurasi(kapasitas: 150, ambangHampirPenuh: 50, ambangPenuh: 60),
    );
    expect((await repository.getStatus()).status, StatusLevel.penuh);
  });

  test('duplicate admin username is rejected', () async {
    expect(
      () => repository.tambahAdmin(
        nama: 'Duplikat',
        username: 'admin',
        password: 'rahasia',
      ),
      throwsA(isA<ParkirException>()),
    );
  });
}
