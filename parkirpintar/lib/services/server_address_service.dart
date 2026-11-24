import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';

class ServerAddressService {
  const ServerAddressService(this.preferences);

  final SharedPreferences preferences;

  static const String _key = 'server_address';

  static const String _buildAddress = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  String get address {
    // Prioritas 1: alamat yang disimpan pengguna.
    final saved = preferences.getString(_key);

    if (saved != null && saved.trim().isNotEmpty) {
      return normalize(saved);
    }

    // Prioritas 2: alamat ketika flutter run/build.
    if (_buildAddress.trim().isNotEmpty) {
      return normalize(_buildAddress);
    }

    // Prioritas 3: alamat bawaan aplikasi.
    return AppConstants.alamatServerAwal;
  }

  static String normalize(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  static String? validateAddress(String value) {
    final address = value.trim();

    if (address.isEmpty) {
      return 'Alamat server tidak boleh kosong.';
    }

    final uri = Uri.tryParse(address);

    if (uri == null) {
      return 'Format alamat server tidak valid.';
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Alamat harus diawali http:// atau https://.';
    }

    if (!uri.hasAuthority || uri.host.isEmpty) {
      return 'Masukkan IP atau hostname server.';
    }

    if (!uri.hasPort || uri.port <= 0 || uri.port > 65535) {
      return 'Sertakan port server, misalnya :8001.';
    }

    if (uri.userInfo.isNotEmpty) {
      return 'Alamat server tidak boleh berisi username atau password.';
    }

    if (uri.path.isNotEmpty && uri.path != '/') {
      return 'Jangan tambahkan path setelah alamat server.';
    }

    if (uri.hasQuery || uri.hasFragment) {
      return 'Hapus parameter URL dan tanda # dari alamat.';
    }

    return null;
  }

  Future<void> save(String value) async {
    final validation = validateAddress(value);

    if (validation != null) {
      throw ArgumentError(validation);
    }

    final saved = await preferences.setString(_key, normalize(value));

    if (!saved) {
      throw StateError('Alamat server gagal disimpan.');
    }
  }
}
