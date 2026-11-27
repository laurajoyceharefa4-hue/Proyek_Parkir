# ParkirPintar — Aplikasi Flutter

Aplikasi Flutter untuk mengakses prediksi ketersediaan slot parkir 10, 20, dan 30 menit dari backend FastAPI.

Panduan instalasi backend, pembuatan akun superadmin, konfigurasi jaringan, pengujian, dan build APK tersedia pada [README utama proyek](../README.md).

Dari folder ini, setelah backend berjalan dan alamat IP laptop diketahui:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8001
```

Ganti `192.168.1.10` dengan IP laptop yang menjalankan backend. Alamat juga dapat diperbarui melalui Pengaturan Server di aplikasi.

Aplikasi menggunakan data historis; nilai yang ditampilkan bukan pembacaan sensor parkir real-time.