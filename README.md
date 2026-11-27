# ParkirPintar

ParkirPintar adalah aplikasi Flutter dengan backend FastAPI untuk memprediksi jumlah slot parkir yang tersedia pada 10, 20, dan 30 menit berikutnya menggunakan model XGBoost.

Aplikasi menggunakan data historis lokasi Oberes Mätteli, Frauenfeld, Swiss. Prediksi dijalankan dari titik pengamatan pada dataset, sehingga waktu yang ditampilkan mengikuti data historis, bukan kondisi parkir saat ini. Backend berjalan di laptop dan diakses aplikasi melalui jaringan lokal.

## Fitur

- Status ketersediaan parkir, prediksi tiga horizon, dan riwayat prediksi per perangkat.
- Tren keterisian serta rekomendasi waktu berdasarkan data historis.
- Evaluasi model per horizon menggunakan MAE, RMSE, dan R².
- Login admin, rekap dengan filter tanggal, dan ekspor CSV.
- Pengaturan ambang status parkir dan alamat server.
- Pengelolaan akun admin oleh superadmin: tambah akun, ubah password, dan nonaktifkan akun.

Keluaran model adalah **jumlah slot tersedia**. Perkiraan slot terisi dihitung dari kapasitas dikurangi prediksi slot tersedia. Kapasitas pada dataset saat ini adalah 185 slot; konfigurasi backend memvalidasi kapasitas terhadap dataset.

## Struktur dan kebutuhan

| Lokasi | Isi |
| --- | --- |
| `backend/` | FastAPI, integrasi model, autentikasi, dan rekap |
| `backend/data/` | CSV historis serta database SQLite yang dibuat saat aplikasi berjalan |
| `backend/models/` | Tiga model XGBoost dan metadata |
| `parkirpintar/` | Proyek Flutter, aset, dan pengujian |
| `PRD.md`, `DESIGN.md` | Dokumen kebutuhan dan rancangan |

Siapkan Git, Python dengan pip dan venv, serta Flutter dan Android SDK. Versi Dart harus memenuhi `^3.13.3` sebagaimana tercantum dalam `parkirpintar/pubspec.yaml`. Dependensi backend mengikuti `backend/requirements.txt`.

Panduan perintah berikut menggunakan PowerShell Windows. Jika proyek sudah tersedia di laptop, gunakan folder tersebut. Untuk salinan baru:

```powershell
git clone https://github.com/laurajoyceharefa4-hue/Proyek_Parkir.git parkir
cd parkir
```

## Menjalankan backend

Dari folder utama proyek, buat lingkungan Python dan pasang dependensi:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Pastikan berkas berikut tersedia dengan nama yang sesuai:

| Folder | Berkas |
| --- | --- |
| `data/` | `Frauenfeld_Test.csv`, `Frauenfeld_Regression_10_20_30.csv`, `Frauenfeld_TimeSeries_10Min.csv` |
| `models/` | `XGBoost_target_10m.json`, `XGBoost_target_20m.json`, `XGBoost_target_30m.json` |
| `models/` | `Frauenfeld_Preprocessing_Metadata.json`, `XGBoost_Config.json` |

Untuk instalasi pertama, tetapkan akun superadmin pada terminal yang sama sebelum menjalankan server:

```powershell
$env:PARKIR_ADMIN_USER = "adminparkir"
$env:PARKIR_ADMIN_NAME = "Pengelola Parkir"
$passwordParkir = Read-Host "Password superadmin, minimal 12 karakter" -AsSecureString
$env:PARKIR_ADMIN_PASSWORD = [System.Net.NetworkCredential]::new("", $passwordParkir).Password
```

Username contoh `adminparkir` dapat diganti. Username harus dimulai dengan huruf, sepanjang 3–30 karakter, dan hanya memakai huruf kecil, angka, titik, garis bawah, atau tanda hubung. Tentukan password sendiri dan jangan simpan password di repositori.

Akun awal hanya dibuat ketika tabel admin masih kosong. Pengaturan environment ini tidak mengganti password akun yang sudah ada. Database `admin_demo.sqlite3` dan `riwayat_demo.sqlite3` disimpan di `backend/data/` dan tidak disertakan dalam Git.

Jalankan server:

```powershell
.\.venv\Scripts\python.exe -m uvicorn final_api:app --host 0.0.0.0 --port 8001
```

Biarkan terminal tetap berjalan. Dari browser laptop, buka:

- [Health check](http://127.0.0.1:8001/health)
- [Kesiapan model dan dataset](http://127.0.0.1:8001/api/kesiapan)
- [Swagger UI](http://127.0.0.1:8001/docs)

Periksa hasil kesiapan sebelum mencoba prediksi. Data pengujian yang disertakan berisi 603 sampel dengan 16 fitur masukan dan tiga model untuk horizon 10, 20, serta 30 menit.

## Menjalankan Flutter dan membangun APK

Hubungkan laptop dan HP ke jaringan Wi-Fi atau hotspot yang sama. Cari IPv4 laptop pada adaptor yang aktif:

```powershell
ipconfig
```

Misalnya IP laptop adalah `192.168.1.10`, alamat backend menjadi `http://192.168.1.10:8001`. Ganti IP contoh dengan IP laptop yang sebenarnya. Coba buka `http://192.168.1.10:8001/health` dari browser HP terlebih dahulu.

Buka terminal baru dari folder utama proyek:

```powershell
cd parkirpintar
flutter pub get
flutter devices
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8001
```

Jika beberapa perangkat terdeteksi, pilih perangkat tujuan. Alamat server juga dapat diubah melalui menu **Pengaturan Server** pada aplikasi. Alamat yang telah disimpan di aplikasi diprioritaskan dibanding nilai `API_BASE_URL` saat build.

Gunakan IP laptop untuk HP fisik. Alamat bawaan `http://10.0.2.2:8001` ditujukan untuk Android Emulator. `0.0.0.0` adalah alamat bind server, bukan alamat tujuan yang diisikan pada aplikasi.

Untuk membuat APK release, jalankan dari folder `parkirpintar/`:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.10:8001
```

APK dihasilkan pada `parkirpintar/build/app/outputs/flutter-apk/app-release.apk`, relatif terhadap folder utama proyek. Salin APK ke HP untuk dipasang. Backend harus tetap aktif ketika aplikasi digunakan.

## API utama

Daftar lengkap parameter, respons, dan skema autentikasi tersedia pada Swagger UI ketika server berjalan.

| Metode | Endpoint | Fungsi |
| --- | --- | --- |
| GET | `/health`, `/api/kesiapan` | Memeriksa layanan, model, dan dataset |
| GET | `/api/mobile/status` | Status parkir dari data historis |
| POST | `/api/mobile/prediksi` | Prediksi ketersediaan slot |
| GET | `/api/mobile/riwayat` | Riwayat berdasarkan `device_id` |
| GET | `/api/mobile/evaluasi` | Evaluasi model per horizon |
| GET | `/api/mobile/konfigurasi` | Kapasitas dan ambang status |
| GET | `/api/mobile/tren`, `/api/mobile/rekomendasi` | Tren dan rekomendasi historis |
| POST | `/api/admin/login`, `/api/admin/logout` | Login dan logout admin |
| GET | `/api/admin/rekap`, `/api/admin/rekap/export.csv` | Rekap dan ekspor CSV dengan autentikasi |

Contoh body JSON untuk `POST /api/mobile/prediksi`:

```json
{
  "horizon_menit": 10,
  "nomor_baris": 0,
  "device_id": "perangkat-uji-01"
}
```

Nilai `horizon_menit` adalah 10, 20, atau 30. `nomor_baris` memilih titik pengamatan pada data testing. Token dari login dikirim sebagai `Authorization: Bearer <token>` untuk endpoint admin yang memerlukan autentikasi. Pengelolaan akun dan perubahan konfigurasi parkir memerlukan hak superadmin.

## Pengujian dan pemecahan masalah

Untuk menjalankan pengujian Flutter yang tersedia, dari folder `parkirpintar/`:

```powershell
flutter test
```

Catat hasil pengujian dari lingkungan yang digunakan. Perintah ini tidak menggantikan pengujian integrasi HP, pengukuran latensi jaringan, atau uji pengguna.

| Kendala | Pemeriksaan |
| --- | --- |
| HP gagal terhubung | Pastikan Uvicorn aktif, IP dan port benar, jaringan dapat saling mengakses, serta firewall mengizinkan koneksi backend pada jaringan privat yang digunakan. |
| Alamat lama masih digunakan | Perbarui alamat melalui Pengaturan Server karena alamat tersimpan diprioritaskan. |
| Model atau CSV tidak terbaca | Periksa nama dan lokasi berkas, termasuk kemungkinan tambahan nama seperti `(1)`. Buka `/api/kesiapan`. |
| Login pada instalasi baru gagal | Pastikan environment akun awal diisi sebelum server dijalankan dan password memenuhi minimal 12 karakter. |
| Port 8001 sudah digunakan | Periksa apakah backend sudah berjalan pada terminal lain sebelum menjalankan instance tambahan. |

## Batasan

- Data berasal dari satu lokasi dan periode pengamatan terbatas. Hasil belum menunjukkan kondisi parkir di Indonesia atau kemampuan generalisasi lintas lokasi.
- Evaluasi tersedia per horizon; evaluasi terpisah menurut tipe hari belum disajikan.
- Rekap berisi keterisian dan ketersediaan slot. Dataset tidak menyediakan jenis kendaraan atau lama parkir per kendaraan.
- Ekspor menggunakan CSV. Fitur backup database manual melalui aplikasi belum tersedia.
- Repositori berisi kode, data, dan model untuk menjalankan demo lokal. Backend belum dideploy sebagai layanan publik.

Repositori: [Proyek_Parkir](https://github.com/laurajoyceharefa4-hue/Proyek_Parkir).