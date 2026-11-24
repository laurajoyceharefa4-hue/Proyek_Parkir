
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repository/api_parkir_repository.dart';
import '../data/repository/parkir_repository.dart';

import 'device_id_service.dart';
import 'server_address_service.dart';
import 'session_service.dart';

class AppServices {
  AppServices._();

  static late ApiParkirRepository apiRepository;
  static late ParkirRepository repository;

  static String? deviceId;
  static String? adminName;

  static late SessionService session;
  static late ServerAddressService serverAddress;

  static bool initialized = false;

  static Future<void> initialize() async {
    final preferences =
        await SharedPreferences.getInstance();

    deviceId ??= await DeviceIdService(
      preferences,
    ).getDeviceId();

    session = SessionService(
      const FlutterSecureStorageAdapter(
        FlutterSecureStorage(),
      ),
    );

    serverAddress = ServerAddressService(
      preferences,
    );

    // Bersihkan token simulasi lama.
    final oldToken = await session.readToken();

    if (oldToken == 'mock-jwt-token') {
      await session.clear();
    }

    apiRepository = ApiParkirRepository(
      addressProvider: () => serverAddress.address,
      deviceIdProvider: () =>
          deviceId ?? 'demo-device',
      tokenProvider: () => session.readToken(),
    );

    // Semua halaman diarahkan ke backend FastAPI.
    repository = apiRepository;

    initialized = true;
  }
}
