
class AppConstants {
  AppConstants._();

  static const String namaAplikasi = 'ParkirPintar';
  static const String versi = '1.0.0';

  static const List<int> horizons = [10, 20, 30];

  static const int ambangAwalHampirPenuh = 60;
  static const int ambangAwalPenuh = 90;
  static const int kapasitasAwal = 150;

  static const Duration batasRespons = Duration(seconds: 20);

  // Android Emulator menggunakan 10.0.2.2.
  // Untuk HP fisik, tentukan IP laptop saat flutter run.
  static const String alamatServerAwal = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8001',
  );

  static const String defaultServerUrl = alamatServerAwal;

  static const String apiKeyPlaceholder = 'GANTI_DENGAN_API_KEY';
  static const String fontFamily = 'PlusJakartaSans';
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double screenPadding = 20;
  static const double cardGap = 16;
}

class AppRadius {
  AppRadius._();

  static const double card = 24;
  static const double cardSmall = 16;
  static const double pill = 999;
}
