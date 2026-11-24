import 'package:flutter_test/flutter_test.dart';
import 'package:parkirpintar/services/device_id_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('creates and persists an eight-character device id', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = DeviceIdService(preferences);

    final first = await service.getDeviceId();
    final second = await service.getDeviceId();

    expect(first, hasLength(8));
    expect(first, matches(RegExp(r'^[0-9a-f]{8}$')));
    expect(second, first);
  });
}
