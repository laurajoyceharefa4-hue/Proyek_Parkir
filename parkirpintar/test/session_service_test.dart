import 'package:flutter_test/flutter_test.dart';
import 'package:parkirpintar/services/session_service.dart';

void main() {
  test('saves, reads, and clears admin token', () async {
    final storage = _FakeSecureStorage();
    final service = SessionService(storage);

    await service.saveToken('token-uji');
    expect(await service.readToken(), 'token-uji');
    await service.clear();
    expect(await service.readToken(), isNull);
  });
}

class _FakeSecureStorage implements SecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> delete({required String key}) async => values.remove(key);
}
