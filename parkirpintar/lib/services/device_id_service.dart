import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  const DeviceIdService(this.preferences);

  static const String _key = 'device_id';
  final SharedPreferences preferences;

  Future<String> getDeviceId() async {
    final existing = preferences.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final id = List.generate(
      8,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    await preferences.setString(_key, id);
    return id;
  }
}
