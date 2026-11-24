import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parkirpintar/core/app_constants.dart';
import 'package:parkirpintar/services/server_address_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Menggunakan alamat bawaan jika belum disimpan', () async {
    SharedPreferences.setMockInitialValues({});

    final preferences = await SharedPreferences.getInstance();

    final service = ServerAddressService(preferences);

    expect(service.address, AppConstants.alamatServerAwal);
  });

  test('Alamat yang disimpan menjadi alamat aktif', () async {
    SharedPreferences.setMockInitialValues({});

    final preferences = await SharedPreferences.getInstance();

    final service = ServerAddressService(preferences);

    await service.save('http://10.142.225.69:8001/');

    expect(service.address, 'http://10.142.225.69:8001');
  });

  test('Alamat tersimpan bertahan setelah service dibuat ulang', () async {
    SharedPreferences.setMockInitialValues({});

    final preferences = await SharedPreferences.getInstance();

    final first = ServerAddressService(preferences);

    await first.save('http://192.168.1.20:8001');

    final second = ServerAddressService(preferences);

    expect(second.address, 'http://192.168.1.20:8001');
  });

  test('Menolak alamat dengan path dan parameter', () {
    expect(
      ServerAddressService.validateAddress('http://192.168.1.20:8001/docs'),
      isNotNull,
    );

    expect(
      ServerAddressService.validateAddress(
        'http://192.168.1.20:8001?token=abc',
      ),
      isNotNull,
    );
  });

  test('Menolak alamat tanpa port', () {
    expect(
      ServerAddressService.validateAddress('http://192.168.1.20'),
      isNotNull,
    );
  });

  test('Menerima alamat FastAPI lokal yang valid', () {
    expect(
      ServerAddressService.validateAddress('http://10.142.225.69:8001'),
      isNull,
    );

    expect(
      ServerAddressService.validateAddress('http://127.0.0.1:8001'),
      isNull,
    );
  });

  test('Gagal menyimpan alamat yang tidak valid', () async {
    SharedPreferences.setMockInitialValues({});

    final preferences = await SharedPreferences.getInstance();

    final service = ServerAddressService(preferences);

    await expectLater(service.save('alamat-tidak-valid'), throwsArgumentError);
  });
}
