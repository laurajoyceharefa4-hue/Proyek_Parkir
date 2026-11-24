import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  Future<void> write({required String key, required String value});

  Future<String?> read({required String key});

  Future<void> delete({required String key});
}

class FlutterSecureStorageAdapter implements SecureStorage {
  const FlutterSecureStorageAdapter(this.storage);

  final FlutterSecureStorage storage;

  @override
  Future<void> write({required String key, required String value}) =>
      storage.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) => storage.read(key: key);

  @override
  Future<void> delete({required String key}) => storage.delete(key: key);
}

class SessionService {
  const SessionService(this.storage);

  static const String _tokenKey = 'admin_token';
  final SecureStorage storage;

  Future<void> saveToken(String token) =>
      storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => storage.read(key: _tokenKey);

  Future<void> clear() => storage.delete(key: _tokenKey);
}
