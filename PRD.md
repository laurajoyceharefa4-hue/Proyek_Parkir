# PRD: ParkirPintar

Oct 31, 2026 · @aldikurniawan12301

**Pengembangan Sistem Prediksi Ketersediaan Parkir Jangka Pendek Menggunakan XGBoost Berbasis Flutter**

| Item | Isi |
| --- | --- |
| Nama aplikasi | ParkirPintar |
| Jenis dokumen | Product Requirements Document (PRD) |
| Tujuan proyek | Skripsi / Tugas Akhir |
| Platform | Mobile (Flutter, Android) |
| Versi dokumen | 1.2 (draft) |
| Tanggal | 31 Oktober 2026 |

## 1. Latar Belakang

Parkir adalah bagian penting sistem transportasi karena menyediakan ruang bagi kendaraan selama pengendara beraktivitas di suatu lokasi. Ketidakseimbangan antara jumlah ruang parkir dan jumlah kendaraan dapat menimbulkan kemacetan, terutama di area beraktivitas tinggi seperti rumah sakit, pusat perbelanjaan, dan kampus.

Saat ini pengendara umumnya tidak tahu kondisi parkir sebelum tiba di lokasi. Mereka berkeliling mencari ruang kosong, yang membuang waktu dan bahan bakar serta memperparah kemacetan. Pengelola juga sulit mengatur kapasitas karena tidak ada gambaran kebutuhan parkir beberapa menit ke depan.

Kebutuhan parkir dipengaruhi pola waktu: jam, hari kerja atau akhir pekan. Informasi parkir yang statis tidak cukup, sehingga diperlukan prediksi berbasis data historis dan pola waktu. Penelitian sebelumnya menunjukkan model machine learning berbasis pohon keputusan mampu menangkap pola temporal pada data parkir.

ParkirPintar menggabungkan empat hal dalam satu aplikasi mobile Android:

1. **Status dan prediksi** ketersediaan parkir jangka pendek (10, 20, dan 30 menit ke depan, atau pada tanggal dan jam pilihan sendiri) memakai model XGBoost yang sudah dilatih.
2. **Rekomendasi jam** sepi dan jam ramai dari rata-rata historis, serta tren harian dan mingguan.
3. **Rekap parkir** untuk admin: jumlah kendaraan masuk per jenis, lama parkir, jam dan hari tersibuk, dengan export Excel.
4. **Akurasi prediksi** dalam bahasa biasa, dibandingkan dengan pembanding dasar.

Proyek memakai dua dataset: dataset ketersediaan parkir (untuk model dan tren) dan dataset kendaraan (jenis, jam masuk, jam keluar; untuk rekap dan export). Model sudah selesai dilatih, sehingga fokus pengembangan ada pada integrasi, evaluasi, dan aplikasi. Publik dapat memakai fitur utama tanpa login; hanya admin yang perlu login.

## 2. Tujuan

### 2.1 Tujuan Produk

- Membantu pengendara mengetahui perkiraan ketersediaan parkir sebelum dan saat menuju lokasi, tanpa perlu login.
- Menampilkan hasil prediksi lengkap: perkiraan kendaraan, slot tersedia, status (kosong, hampir penuh, penuh), dan label "perkiraan".
- Membantu pengendara memilih waktu datang lewat rekomendasi jam sepi dan jam ramai.
- Membantu admin melihat rekap parkir, akurasi prediksi, dan mengatur parameter parkir.

### 2.2 Tujuan Skripsi

- Mengevaluasi model XGBoost untuk prediksi parkir jangka pendek (MAE, RMSE, R²) per horizon 10, 20, dan 30 menit, serta per tipe hari (hari kerja dan akhir pekan).
- Membandingkan XGBoost dengan dua pembanding dasar: persistensi (nilai saat ini dipakai sebagai prediksi) dan rata-rata historis per jam dan hari.
- Mengimplementasikan model dalam sistem client-server yang dapat dipakai di perangkat mobile.

### 2.3 Indikator Keberhasilan

| Indikator | Target |
| --- | --- |
| Tiga model XGBoost (10, 20, 30 menit) dapat dimuat dan dievaluasi | Laporan evaluasi tersedia (MAE, RMSE, R² per horizon dan tipe hari) |
| Model lebih baik dari pembanding dasar | Error lebih rendah daripada persistensi dan rata-rata historis per jam |
| Alur publik berjalan end-to-end | Pilih horizon atau waktu, prediksi tampil, riwayat tersimpan di HP |
| Alur admin berjalan end-to-end | Login, rekap, export Excel, ubah pengaturan parkir |
| Aplikasi dipakai di 2 HP berbeda | Publik dan admin melihat data dan konfigurasi yang sama |
| Respons prediksi cepat | Di bawah 3 detik pada jaringan lokal |

> Target nilai MAE, RMSE, dan R² ditetapkan setelah hasil evaluasi akhir tersedia.

## 3. Ruang Lingkup

### 3.1 Dalam Lingkup

- Status parkir saat ini, prediksi 10, 20, 30 menit, dan prediksi pada tanggal dan jam pilihan sendiri.
- Rekomendasi jam sepi dan jam ramai, serta tren harian dan mingguan.
- Riwayat prediksi per HP (publik) dan riwayat semua HP (admin).
- Login admin, rekap parkir, akurasi prediksi, dan export Excel.
- Pengaturan parkir (jumlah slot, batas status) dan kelola admin.
- Pengaturan alamat server (admin).
- Demo web Streamlit untuk mencoba model XGBoost.

### 3.2 Di Luar Lingkup (Pengembangan Lanjutan)

- Pembaruan data real-time dari sensor atau kamera parkir.
- Pelatihan ulang model otomatis dari dalam aplikasi.
- Model lain (Random Forest, LSTM) dan pemilihan atau perbandingan model di aplikasi.
- Dukungan banyak lokasi parkir.
- Reservasi dan pembayaran parkir.
- Navigasi menuju slot tertentu.
- Deployment ke server online / hosting.
- Aplikasi iOS dan web.

## 4. Pengguna dan Hak Akses

Satu aplikasi dipasang di dua HP dengan dua peran: publik (tanpa login) dan admin (login). Data dan konfigurasi dipakai bersama lewat satu server.

### 4.1 Publik (tanpa login)

- Melihat status parkir saat ini (slot kosong dan status).
- Prediksi 10, 20, dan 30 menit ke depan.
- Prediksi pada tanggal dan jam pilihan sendiri.
- Melihat rekomendasi jam sepi dan jam ramai.
- Melihat tren harian dan mingguan.
- Melihat riwayat prediksi dari HP sendiri (dikenali lewat `device_id`).

### 4.2 Admin (login)

Semua hak publik, ditambah:

- Login dan logout admin.
- Rekap parkir: total kendaraan masuk, per jenis, rata-rata lama parkir, jam dan hari tersibuk dan tersepi, rata-rata terisi, grafik, pilihan periode.
- Akurasi prediksi per horizon dan per tipe hari.
- Export Excel dari layar Rekap.
- Pengaturan parkir: jumlah slot dan batas status.
- Kelola admin: tambah, ganti password, nonaktifkan.
- Melihat riwayat prediksi dari semua HP.
- Pengaturan alamat server (tersembunyi dari publik, alamat awal terisi otomatis).

### 4.3 Alasan Pembagian

Publik hanya membutuhkan informasi prediksi sehingga tidak perlu akun. Admin memegang data rekap, pengaturan parkir, dan akurasi, sehingga hasil yang tampil ke semua pengguna konsisten.

## 5. Gambaran Alur Utama

**Alur publik**

1. Buka aplikasi; Beranda menampilkan status dan slot kosong.
2. Pilih horizon (10, 20, 30 menit) dan, bila mau, tanggal dan jam target.
3. Server menyiapkan 16 fitur, menjalankan XGBoost, lalu menghitung slot tersedia dan status.
4. Hasil tampil berlabel "perkiraan" dan tersimpan di riwayat HP itu.
5. Rekomendasi jam dan tren dihitung dari data historis.

**Alur admin**

1. Login dari layar Profil; ganti password awal dan tambah admin lain bila perlu.
2. Buka Rekap & Akurasi; export Excel dari layar yang sama.
3. Ubah jumlah slot dan batas status; berlaku untuk semua pengguna.
4. Lihat riwayat prediksi dari semua HP.

## 6. Kebutuhan Fungsional

### 6.1 Status Parkir (Publik)

| ID | Kebutuhan |
| --- | --- |
| F-STAT-01 | Beranda menampilkan slot kosong dan status parkir saat ini. |
| F-STAT-02 | Status dihitung dari ambang: kosong di bawah 60%, hampir penuh 60 sampai 90%, penuh 90% ke atas (dapat diubah admin). |
| F-STAT-03 | Data "sekarang" diambil dari dataset 1 bulan yang sudah dipakai melatih. |

### 6.2 Prediksi (Publik)

| ID | Kebutuhan |
| --- | --- |
| F-PRED-01 | Pengguna dapat memilih horizon prediksi: 10, 20, atau 30 menit. |
| F-PRED-02 | Pengguna dapat memilih tanggal dan jam target sendiri (opsional). |
| F-PRED-03 | Sistem membentuk 16 fitur (kondisi saat ini, lag, rata-rata bergulir, perubahan 10 menit, jam dan hari siklik, akhir pekan) lalu mengirimnya ke model XGBoost horizon yang sesuai. |
| F-PRED-04 | Hasil menampilkan perkiraan jumlah kendaraan (terisi) dan slot tersedia. |
| F-PRED-05 | Hasil menampilkan status parkir berdasarkan ambang. |
| F-PRED-06 | Hasil berlabel "perkiraan" dan menampilkan MAE historis sebagai acuan. |
| F-PRED-07 | Setiap prediksi tersimpan sebagai riwayat (horizon, waktu target, hasil, `device_id`, waktu). |
| F-PRED-08 | Publik melihat riwayat dari HP sendiri; admin melihat riwayat semua HP. |

**Contoh hasil prediksi (ilustrasi):**

```
Input:
- Waktu   : Senin, 10:00
- Horizon : 30 menit

Hasil:
Perkiraan kendaraan : 118 dari 150 slot
Slot tersedia       : 32
Status parkir       : Hampir penuh
Model               : XGBoost (MAE validasi: 3,54 slot)
Catatan             : Perkiraan, bukan jaminan
```

Model hanya memprediksi jumlah terisi. Field lain dihitung:

| Field | Sumber |
| --- | --- |
| Perkiraan jumlah kendaraan (terisi) | Model XGBoost |
| Slot tersedia | Dihitung: kapasitas dikurangi perkiraan |
| Status parkir | Dihitung dari ambang yang diatur admin |
| MAE historis | Hasil evaluasi model (tabel evaluasi) |

### 6.3 Rekomendasi Jam dan Tren (Publik)

| ID | Kebutuhan |
| --- | --- |
| F-REK-01 | Aplikasi menampilkan 3 jam tersepi dan 3 jam teramai. |
| F-REK-02 | Rekomendasi dihitung dari rata-rata historis per jam (bukan dari model). |
| F-TREN-01 | Pengguna dapat melihat grafik tren parkir harian dan mingguan. |

### 6.4 Autentikasi Admin

| ID | Kebutuhan |
| --- | --- |
| F-AUTH-01 | Admin login dengan username dan password dari layar Profil. |
| F-AUTH-02 | Sistem mengeluarkan token JWT setelah login berhasil. |
| F-AUTH-03 | Fitur admin dibatasi oleh token; fitur publik tidak memerlukan login. |
| F-AUTH-04 | Admin dapat logout. |
| F-AUTH-05 | Setiap request ke API disertai API key sebagai lapisan tambahan. |
| F-AUTH-06 | Akun admin awal dibuat otomatis saat server pertama menyala; admin menggantinya dari aplikasi. |

### 6.5 Rekap, Akurasi, dan Export (Admin)

| ID | Kebutuhan |
| --- | --- |
| F-REKAP-01 | Rekap menampilkan total kendaraan masuk dan rincian per jenis (motor, mobil, lainnya). |
| F-REKAP-02 | Rekap menampilkan rata-rata lama parkir, jam dan hari paling ramai dan sepi, serta rata-rata terisi. |
| F-REKAP-03 | Rekap menampilkan grafik dengan pilihan periode. |
| F-EVAL-01 | Akurasi ditampilkan dalam bahasa biasa: rata-rata meleset, meleset terbesar, dan kecocokan dengan data asli. |
| F-EVAL-02 | Akurasi ditampilkan per horizon (10, 20, 30 menit) dan per tipe hari (hari kerja, akhir pekan). |
| F-EXP-01 | Admin dapat export Excel dengan kolom no, jenis, jam masuk, jam keluar, durasi. |
| F-EXP-02 | Export dapat difilter berdasarkan tanggal dan jenis; tombol berada di layar Rekap. |

### 6.6 Konfigurasi dan Kelola Admin

| ID | Kebutuhan |
| --- | --- |
| F-CFG-01 | Admin dapat mengatur jumlah slot parkir (awal dari `capacity_now` dataset) dan batas status. |
| F-CFG-02 | Admin dapat mengubah alamat server dari aplikasi; alamat awal terisi otomatis. |
| F-ADM-01 | Admin dapat menambah admin, mengganti password, dan menonaktifkan admin. |

> **Catatan:** mengganti dataset atau menambah fitur memerlukan pelatihan ulang model. Pelatihan dilakukan di luar aplikasi.

### 6.7 Backup

| ID | Kebutuhan |
| --- | --- |
| F-BKP-01 | Backup database dilakukan manual di sisi server (folder `backup/`) dan didokumentasikan. |

## 7. Daftar Layar

Aplikasi memiliki 13 layar yang diperinci: 8 untuk semua pengguna dan 5 khusus admin. Export Excel bukan layar terpisah, melainkan tombol di layar Rekap & Akurasi (rangkuman awal menyebut 14, lihat bagian 17).

| No | Layar | Peran | Keterangan |
| --- | --- | --- | --- |
| 1 | Splash | Semua | Logo dan pengecekan sesi |
| 2 | Beranda | Semua | Status parkir saat ini, slot kosong, dan menu |
| 3 | Form Prediksi | Semua | Pilih horizon dan, opsional, tanggal dan jam target |
| 4 | Hasil Prediksi | Semua | Perkiraan kendaraan, slot, status, MAE, label "perkiraan" |
| 5 | Riwayat Prediksi | Semua (admin: semua HP) | Daftar dan detail |
| 6 | Tren Parkir | Semua | Grafik harian dan mingguan |
| 7 | Rekomendasi Jam | Semua | 3 jam tersepi dan 3 jam teramai |
| 8 | Profil | Semua | Info, pintu masuk login admin, logout |
| 9 | Login Admin | Admin | Username dan password |
| 10 | Rekap & Akurasi | Admin | Rekap kendaraan, akurasi, grafik, periode, tombol Export Excel (filter tanggal dan jenis) |
| 11 | Pengaturan Parkir | Admin | Jumlah slot dan batas status |
| 12 | Kelola Admin | Admin | Tambah, ganti password, nonaktifkan |
| 13 | Pengaturan Server | Admin | Alamat server (IP dan port), tersembunyi dari publik |

> Layar adalah usulan awal dan dapat disesuaikan. Demo Streamlit berupa halaman web terpisah dari daftar ini: pilih horizon, lihat prediksi XGBoost, serta grafik evaluasi.

## 8. Arsitektur

### 8.1 Gambaran

Sistem berbasis client-server dengan REST API dan satu server FastAPI di laptop. Server memuat tiga model XGBoost sekali saat menyala, membuat akun admin awal, dan mengisi database dari dua dataset bila tabel masih kosong. Dua HP terhubung lewat Wi-Fi atau hotspot yang sama. Demo web Streamlit memuat model yang sama langsung dari folder `models/`, tanpa melalui API.

&#91;embedded content: arsitektur · 2 HP, 1 server, 1 database, 3 model\]

Publik dan admin memakai satu server yang sama, sehingga pengaturan parkir dari admin langsung terlihat di HP publik.

### 8.2 Teknologi

| Komponen | Teknologi |
| --- | --- |
| Aplikasi mobile | Flutter (Dart), Android |
| Server API | FastAPI (Python) |
| Database | PostgreSQL |
| Akses database | SQLAlchemy |
| Machine learning | XGBoost (3 model: 10, 20, 30 menit) |
| Penyimpanan model | `.json` (XGBoost) |
| Export Excel | openpyxl |
| Autentikasi | JWT (admin), ditambah API key |
| Demo web | Streamlit (Python), memuat model langsung dari folder `models/` |

### 8.3 Struktur Folder

```
C:\parkir
│
├── parkirpintar/                    -> Flutter (Android)
│   ├── lib/
│   │   ├── core/                    -> tema, warna, konstanta, alamat server
│   │   ├── data/                    -> model data, repository, data mock
│   │   ├── services/                -> pemanggil API
│   │   └── features/
│   │       ├── beranda/
│   │       ├── prediksi/            -> form, hasil, riwayat
│   │       ├── rekomendasi/
│   │       ├── tren/
│   │       ├── auth/                -> login admin, profil
│   │       └── admin/               -> rekap & akurasi, pengaturan parkir,
│   │                                   kelola admin, pengaturan server
│   ├── assets/
│   └── pubspec.yaml
│
└── parkirpintar_backend/            -> FastAPI + model + database
    ├── .venv/
    ├── app/
    │   ├── main.py                  -> endpoint, startup (muat model, buat admin awal,
    │   │                               isi data dari dataset jika tabel kosong)
    │   ├── config.py
    │   ├── schemas.py
    │   ├── database.py
    │   ├── models_db.py
    │   ├── auth.py
    │   ├── predictor.py             -> 3 model XGBoost, 16 fitur
    │   ├── rekomendasi.py
    │   └── export.py                -> Excel (openpyxl)
    ├── models/
    │   └── xgb_target_10m/20m/30m.json
    ├── dataset/
    │   ├── dataset_parkir.csv
    │   └── dataset_kendaraan.csv
    ├── training/
    │   └── train_model.py
    ├── web_demo/
    │   └── app.py                   -> demo Streamlit
    ├── backup/
    └── requirements.txt
```

| Folder | Tugas |
| --- | --- |
| `parkirpintar` | Tampilan publik dan admin |
| `parkirpintar_backend` | Endpoint, login admin, riwayat, memuat model, rekap, export, dataset, skrip pelatihan, demo Streamlit, backup |

Folder `scripts/` tidak dipakai: pembuatan admin awal dan impor data berjalan otomatis saat server menyala. Path ke file model dikonfigurasi di `config.py` (satu tempat).

### 8.4 Mode Jaringan

- **Tahap skripsi:** jaringan lokal (LAN) tanpa internet. Server di laptop, HP terhubung lewat Wi-Fi atau hotspot yang sama, misalnya `http://192.168.1.10:8000`.
- **Pengembangan lanjutan:** online dengan memindahkan server ke hosting.
- Alamat server dapat diubah di aplikasi (layar Pengaturan Server, khusus admin); alamat awal terisi otomatis.
- **Syarat saat dipakai:** laptop menyala dan satu jaringan dengan HP.

## 9. Kontrak API (Draft)

Semua endpoint memerlukan header `X-API-Key`. Endpoint admin juga memerlukan `Authorization: Bearer <token_jwt>`. Endpoint publik yang menyimpan atau membaca riwayat memakai `device_id`.

```
X-API-Key: <api_key>
Authorization: Bearer <token_jwt>   (hanya endpoint admin)
```

Mock data di fase 2 harus berbentuk persis seperti respons di bawah, agar saat server jadi hanya sumber datanya yang diganti.

### 9.1 Daftar Endpoint

| Metode | Endpoint | Akses | Fungsi |
| --- | --- | --- | --- |
| POST | `/auth/login` | Admin | Login, mengembalikan token |
| GET | `/auth/me` | Admin | Info admin aktif |
| GET | `/status` | Publik | Status parkir saat ini (slot kosong, status) |
| POST | `/prediksi` | Publik | Jalankan prediksi (horizon, `waktu_target` opsional, `device_id`) |
| GET | `/prediksi/riwayat` | Publik / Admin | Publik: milik `device_id` sendiri; admin: semua |
| GET | `/prediksi/riwayat/{id}` | Publik / Admin | Detail riwayat |
| GET | `/tren` | Publik | Data tren harian dan mingguan |
| GET | `/rekomendasi` | Publik | 3 jam tersepi dan 3 jam teramai |
| GET | `/rekap` | Admin | Rekap kendaraan per periode |
| GET | `/evaluasi` | Admin | Akurasi prediksi per horizon dan tipe hari |
| GET / PUT | `/konfigurasi` | GET: Publik, PUT: Admin | Kapasitas dan ambang status |
| GET | `/export/kendaraan` | Admin | Unduh Excel (filter tanggal dan jenis) |
| GET / POST / PUT | `/admin` | Admin | Kelola admin |

### 9.2 Contoh: Login Admin

**Request** `POST /auth/login`

```json
{ "username": "admin", "password": "********" }
```

**Response**

```json
{
  "access_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "admin": { "id": 1, "nama": "Admin", "aktif": true }
}
```

### 9.3 Contoh: Status Saat Ini

**Request** `GET /status`

```json
{
  "waktu": "2026-10-31T10:00:00",
  "kapasitas": 150,
  "terisi": 96,
  "slot_tersedia": 54,
  "status": "hampir_penuh"
}
```

### 9.4 Contoh: Prediksi

**Request** `POST /prediksi`

```json
{
  "horizon_menit": 30,
  "waktu_target": "2026-11-02T10:30:00",
  "device_id": "a1b2c3d4"
}
```

`waktu_target` bersifat opsional; bila kosong, waktu target = waktu sekarang + horizon.

**Response**

```json
{
  "riwayat_id": 31,
  "model": "xgboost",
  "horizon_menit": 30,
  "waktu_target": "2026-11-02T10:30:00",
  "perkiraan_kendaraan": 118,
  "kapasitas": 150,
  "slot_tersedia": 32,
  "status": "hampir_penuh",
  "mae_historis": 3.54,
  "keterangan": "Perkiraan",
  "waktu": "2026-10-31T10:00:00"
}
```

### 9.5 Contoh: Rekomendasi Jam

**Request** `GET /rekomendasi`

```json
{
  "tersepi": [
    { "jam": 6, "rata_terisi": 12.4 },
    { "jam": 7, "rata_terisi": 20.1 },
    { "jam": 21, "rata_terisi": 25.8 }
  ],
  "teramai": [
    { "jam": 12, "rata_terisi": 131.0 },
    { "jam": 11, "rata_terisi": 126.5 },
    { "jam": 13, "rata_terisi": 124.2 }
  ]
}
```

### 9.6 Contoh: Rekap (Admin)

**Request** `GET /rekap?dari=2026-10-01&sampai=2026-10-31`

```json
{
  "total_masuk": 1520,
  "per_jenis": { "motor": 980, "mobil": 510, "lainnya": 30 },
  "rata_lama_parkir_menit": 94,
  "jam_teramai": 12,
  "jam_tersepi": 6,
  "hari_teramai": "Jumat",
  "hari_tersepi": "Minggu",
  "rata_terisi": 78.3
}
```

### 9.7 Contoh: Akurasi Prediksi (Admin)

**Request** `GET /evaluasi`

```json
{
  "hasil": [
    { "horizon_menit": 10, "tipe_hari": "semua", "mae": 2.34, "rmse": null, "r2": null },
    { "horizon_menit": 20, "tipe_hari": "semua", "mae": 3.10, "rmse": null, "r2": null },
    { "horizon_menit": 30, "tipe_hari": "semua", "mae": 3.54, "rmse": null, "r2": null },
    { "horizon_menit": 30, "tipe_hari": "hari_kerja", "mae": null, "rmse": null, "r2": null },
    { "horizon_menit": 30, "tipe_hari": "akhir_pekan", "mae": null, "rmse": null, "r2": null }
  ]
}
```

> Semua nilai pada contoh hanya ilustrasi, kecuali MAE XGBoost (2,34 / 3,10 / 3,54) yang diambil dari hasil pelatihan. Nilai `null` diisi dari hasil evaluasi Anda. Aplikasi menerjemahkannya ke bahasa biasa (rata-rata meleset, meleset terbesar, kecocokan dengan data asli).

## 10. Model Data (Gambaran Awal)

Database PostgreSQL memiliki enam tabel.

| Tabel | Isi utama |
| --- | --- |
| `admin` | id, nama, username, password\_hash, aktif |
| `konfigurasi` | id, kapasitas, ambang\_hampir\_penuh, ambang\_penuh |
| `data_parkir` | id, waktu, jumlah\_terisi, kapasitas (untuk status, tren, dan fitur lag) |
| `kendaraan_parkir` | id, jenis (motor, mobil, lainnya), jam\_masuk, jam\_keluar, durasi (dihitung otomatis) |
| `riwayat_prediksi` | id, device\_id, horizon\_menit, waktu\_target, perkiraan\_kendaraan, status, waktu |
| `hasil_evaluasi` | id, horizon\_menit, tipe\_hari, mae, rmse, r2 |

- Tabel `data_parkir` dan `kendaraan_parkir` diisi otomatis dari `dataset_parkir.csv` dan `dataset_kendaraan.csv` saat server pertama menyala bila masih kosong.
- Hasil evaluasi diisi dari proses pelatihan yang sudah selesai (impor sekali), bukan dihitung ulang setiap aplikasi dibuka.
- Riwayat publik dikenali lewat `device_id`, bukan akun.

## 11. Rencana Model Machine Learning

### 11.1 Pendekatan

- **Algoritma:** XGBoost Regressor saja. Random Forest dan LSTM tidak dipakai.
- **Model:** tiga model terpisah, satu per horizon (`target_10m`, `target_20m`, `target_30m`).
- **Fitur:** 16 fitur (lihat 11.2).
- **Target:** jumlah terisi (occupied). Slot tersedia = kapasitas dikurangi perkiraan; status dihitung dari ambang.
- **Pembanding dasar:** persistensi (nilai saat ini dipakai sebagai prediksi) dan rata-rata historis per jam dan hari.

### 11.2 Dataset

**Dataset 1: ketersediaan parkir** (sudah tersedia, interval 10 menit, sekitar 1 bulan). Dipakai untuk melatih model, status "sekarang", dan tren.

| Kolom | Keterangan |
| --- | --- |
| `available_now`, `occupied_now`, `capacity_now` | Kondisi saat ini: tersedia, terisi, kapasitas |
| `lag_10m`, `lag_20m`, `lag_30m`, `lag_60m`, `lag_120m` | Nilai 10 sampai 120 menit sebelumnya |
| `rolling_mean_30m`, `rolling_mean_60m` | Rata-rata bergulir 30 dan 60 menit |
| `change_10m` | Perubahan 10 menit terakhir |
| `hour_sin`, `hour_cos` | Jam dalam bentuk siklik |
| `dow_sin`, `dow_cos` | Hari dalam seminggu dalam bentuk siklik |
| `is_weekend` | 1 akhir pekan, 0 hari kerja |
| `target_10m`, `target_20m`, `target_30m` | Label: nilai pada 10, 20, 30 menit ke depan |

**Dataset 2: kendaraan** (`dataset_kendaraan.csv`). Berisi jenis kendaraan (motor, mobil, lainnya), jam masuk, dan jam keluar; durasi dihitung otomatis. Dipakai untuk rekap dan export Excel, bukan untuk melatih model.

Hal yang dicatat untuk laporan: periode dan jumlah baris tiap dataset, penanganan data hilang dan pencilan, pola hari kerja dibanding akhir pekan, serta kesesuaian periode kedua dataset.

### 11.3 Pelatihan dan Evaluasi (Sudah Dilakukan)

- Pembagian data latih dan uji berdasarkan urutan waktu (bukan acak).
- Metrik: MAE, RMSE, R², per horizon dan per tipe hari.
- Model tersimpan di `parkirpintar_backend/models/`; hasil evaluasi diimpor ke tabel `hasil_evaluasi`.

**Hasil pelatihan XGBoost:**

| Horizon | Iterasi terbaik | MAE validasi |
| --- | --- | --- |
| 10 menit | 124 | 2,34 |
| 20 menit | 195 | 3,10 |
| 30 menit | 172 | 3,54 |

Error naik seiring horizon, sesuai harapan. **Parameter:** XGBRegressor (XGBoost 3.4.1), objective `reg:squarederror`, n\_estimators 600 dengan early stopping 40 putaran, learning\_rate 0,05, max\_depth 5, subsample 0,8, colsample\_bytree 0,8, tree\_method `hist`, random\_state 42.

**Temuan penting:** `available_now` dan `occupied_now` menyumbang sekitar 97% gain pada ketiga horizon; tiap fitur lain di bawah 2,2%. Prediksi sangat bertumpu pada kondisi saat ini, sehingga pembanding persistensi wajib dicantumkan agar peningkatan XGBoost terlihat nyata.

### 11.4 Prediksi pada Waktu Pilihan

Usulan (belum disetujui secara khusus): fitur diambil dari data pada titik acuan, yaitu waktu target dikurangi horizon. Untuk tanggal di luar rentang dataset, dipakai hari dan jam yang setara dari dataset. Karena model sangat bergantung pada kondisi saat ini, akurasi turun untuk waktu yang jauh, sehingga hasil selalu berlabel "perkiraan".

### 11.5 Rekomendasi Jam

Dihitung dari rata-rata historis terisi per jam pada `data_parkir`, bukan dari model: 3 jam tersepi dan 3 jam teramai.

### 11.6 Catatan Integrasi

- Urutan dan jenis 16 fitur saat prediksi harus sama persis dengan saat pelatihan; daftar fitur disimpan bersama model.
- Target model adalah jumlah terisi; `capacity_now` dibaca dari data, dan kapasitas aktif untuk perhitungan slot berasal dari pengaturan admin (awal dari dataset).
- Model dimuat sekali saat server menyala.
- Tanpa data real-time, "sekarang" memakai dataset 1 bulan yang sudah dipakai melatih.

## 12. Kebutuhan Non-Fungsional

| Aspek | Kebutuhan |
| --- | --- |
| Keamanan | Password admin disimpan sebagai hash. JWT dengan masa berlaku untuk admin. API key tertanam di aplikasi sehingga tidak dianggap rahasia penuh; keamanan fitur admin bertumpu pada login JWT. |
| Performa | Respons prediksi di bawah 3 detik pada jaringan lokal. Tiga model dimuat sekali saat server menyala. |
| Integritas data | Riwayat prediksi tersimpan lengkap (horizon, waktu target, hasil, `device_id`, waktu). |
| Ketersediaan | Laptop server harus menyala dan satu jaringan dengan HP saat aplikasi dipakai. |
| Kegunaan | Antarmuka berbahasa Indonesia, sederhana, status parkir mudah dibaca sekilas, akurasi dijelaskan dalam bahasa biasa. |
| Kompatibilitas | Android (versi minimum ditentukan saat implementasi). |
| Konfigurasi | Alamat server dapat diubah dari aplikasi tanpa rebuild; alamat awal terisi otomatis. |
| Pemeliharaan | Dua folder: `parkirpintar` (Flutter) dan `parkirpintar_backend`; tanggung jawab dipisah per modul di dalam `app/`. |
| Backup | Backup database manual di server, disimpan di folder `backup/` dan didokumentasikan. |

## 13. Fase Pengerjaan

| Fase | Fokus | Hasil |
| --- | --- | --- |
| 1 | Pengumpulan data dan pelatihan model (selesai) | Dataset siap, tiga model XGBoost terlatih dan tersimpan |
| 2 | Frontend Flutter dengan data mock yang mengikuti kontrak API | Seluruh layar pada bagian 7 berjalan dengan data tiruan |
| 3 | `parkirpintar_backend` dan PostgreSQL, memuat model asli | Status, prediksi, riwayat, rekap, export, login admin berjalan; aplikasi disambungkan ke API |
| 4 | Pengujian dan penyusunan skripsi | Pengujian fungsional, evaluasi model, dokumentasi |

Karena model sudah selesai, fase 3 langsung memakai model asli tanpa tahap mock untuk prediksi.

**Persiapan sekali (sebelum dipakai)**

1. Instal PostgreSQL di laptop, lalu jalankan server.
2. Saat pertama menyala, server memuat model, membuat akun admin awal, dan mengisi data dari kedua dataset.
3. HP dan laptop satu jaringan; alamat server sudah terisi otomatis di aplikasi.

## 14. Pengujian

- **Pengujian model:** MAE, RMSE, R² per horizon dan tipe hari, dibandingkan dengan persistensi dan rata-rata historis per jam.
- **Pengujian fungsional:** black-box per fitur dan per peran (publik dan admin), termasuk export Excel dan pengaturan parkir.
- **Pengujian integrasi:** alur lengkap pada dua HP, dari prediksi publik, riwayat, sampai login admin, rekap, dan perubahan pengaturan yang terlihat di HP publik.
- **Pengujian pengguna:** uji coba dengan beberapa pengguna (misalnya kuesioner SUS), jika memungkinkan.

## 15. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Data tanpa input real-time | Prediksi memakai data lama | Data historis sebagai simulasi; batasan dijelaskan di laporan |
| Akurasi turun untuk waktu target yang jauh | Prediksi meleset | Label "perkiraan", tampilkan MAE, batasi penjelasan di laporan |
| Dataset kedua (kendaraan) belum tentu sama periodenya dengan dataset 1 | Rekap dan tren tidak selaras | Periksa periode kedua dataset; sesuaikan atau jelaskan di laporan |
| Model sangat bertumpu pada kondisi saat ini (97% gain) | Keunggulan XGBoost tidak terlihat | Wajib bandingkan dengan persistensi dan rata-rata historis |
| Target model keliru (tersedia, bukan terisi) | Slot tersedia salah hitung | Cek `train_model.py`: target dibentuk dari jumlah terisi |
| Pola tidak biasa (hari libur, acara khusus) | Prediksi meleset | Tampilkan sebagai perkiraan; fitur kalender sebagai pengembangan lanjutan |
| Fitur saat prediksi berbeda dari saat pelatihan | Hasil salah | Simpan daftar fitur bersama model, urutan sama persis |
| Cakupan aplikasi terlalu besar | Skripsi tidak selesai | Pegang batas pada bagian 3 |
| Laptop mati atau jaringan terputus saat demo | Aplikasi tidak bisa dipakai | Hotspot cadangan, uji sebelum demo |
| Alamat IP laptop berubah | Aplikasi gagal terhubung | Layar Pengaturan Server, atau IP statis |
| Prediksi dianggap pasti | Salah paham pengguna | Selalu beri label "perkiraan" |
| Mock tidak sama dengan respons asli | Layar perlu dibongkar ulang | Kontrak API ditetapkan sejak awal |
| Riwayat publik hilang bila `device_id` berubah | Riwayat HP tidak muncul | Jelaskan sebagai batasan; `device_id` disimpan di HP |

## 16. Asumsi

- Dipakai pada satu lokasi parkir, dengan dua HP (publik dan admin).
- Server berjalan di laptop dalam jaringan yang sama dengan HP.
- Dua dataset dan tiga model XGBoost terlatih sudah tersedia.
- Data "sekarang" berasal dari dataset 1 bulan yang sudah dipakai melatih (bukan sensor real-time).
- Kapasitas awal dari `capacity_now` dataset; kapasitas dan ambang status dapat diubah admin.
- Ambang status: kosong di bawah 60%, hampir penuh 60 sampai 90%, penuh 90% ke atas.
- Jenis kendaraan: motor, mobil, lainnya.
- Proyek ini skripsi / tugas akhir dengan aplikasi Flutter untuk Android.

## 17. Hal yang Belum Diputuskan atau Perlu Dicek

| No | Hal | Catatan |
| --- | --- | --- |
| 1 | Target model | Buka `train_model.py`; pastikan `target_10m/20m/30m` dibentuk dari jumlah terisi, bukan tersedia. |
| 2 | Periode dataset kedua | Apakah sama dengan dataset 1 bulan? Bila beda, rekap dan tren tidak selaras. |
| 3 | Prediksi di waktu bebas | Usulan: fitur dari titik acuan (waktu target dikurangi horizon); di luar rentang dataset dipakai hari dan jam setara. Belum disetujui khusus. |
| 4 | Jumlah layar | Rangkuman menyebut 14 layar, tetapi hanya 13 yang diperinci (Export Excel berada di layar Rekap). Tetapkan angka yang benar. |
| 5 | Target nilai MAE, RMSE, R² | Ditetapkan setelah evaluasi akhir. |
| 6 | Nilai RMSE dan R² serta evaluasi hari kerja dan akhir pekan | Diisi dari hasil evaluasi akhir; contoh API masih `null`. |
| 7 | Nama aplikasi | Saat ini "ParkirPintar" (usulan). |

## 18. Glosarium

| Istilah | Arti |
| --- | --- |
| XGBoost | Algoritma gradient boosting berbasis pohon keputusan |
| MAE | Mean Absolute Error, rata-rata selisih absolut prediksi dan nilai asli (di aplikasi: "rata-rata meleset") |
| RMSE | Root Mean Squared Error, akar rata-rata kuadrat selisih; lebih peka pada kesalahan besar |
| R² | Koefisien determinasi, seberapa besar variasi data dijelaskan model (di aplikasi: "kecocokan dengan data asli") |
| Horizon | Seberapa jauh ke depan prediksi dibuat (10, 20, 30 menit) |
| Persistensi | Pembanding dasar: nilai saat ini dipakai sebagai prediksi |
| Rata-rata historis | Pembanding dasar: rata-rata nilai pada jam dan hari yang sama |
| Occupied / terisi | Jumlah kendaraan yang sedang parkir; target model |
| `device_id` | Pengenal HP untuk riwayat publik tanpa login |
| Rekap | Ringkasan data kendaraan masuk, jenis, lama parkir, jam dan hari tersibuk |
| JWT | JSON Web Token, token login admin |
| API key | Kunci tambahan untuk mengakses API |
| LAN | Local Area Network, jaringan lokal tanpa internet |
| openpyxl | Pustaka Python untuk membuat file Excel |
| Streamlit | Pustaka Python untuk membuat aplikasi web demo dengan cepat |
