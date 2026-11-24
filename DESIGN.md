# Design ParkirPintar (UI/UX)

Panduan desain untuk aplikasi Flutter (Android) ParkirPintar, mengacu pada PRD v1.2. Referensi visual: dua gambar contoh aplikasi bertema merah (kesehatan dan layanan transportasi). Yang diambil hanya **gaya** (warna, bentuk, tata letak, komponen), bukan logo, ilustrasi, foto, atau nama dari referensi.

> Nilai warna dan ukuran di bawah adalah perkiraan dari gambar. Sesuaikan saat implementasi.

---

## 1. Karakter Visual

Dari referensi:

- Warna utama merah tua dan merah terang di atas latar putih kemerahan (pink sangat muda).
- Kartu besar dengan sudut sangat membulat dan bayangan lembut.
- Satu kartu "hero" berwarna merah penuh sebagai fokus utama layar.
- Chip dan tombol berbentuk pil (kapsul).
- Bilah navigasi bawah mengambang, berbentuk pil, dengan item aktif berupa lingkaran merah.
- Judul besar tebal dengan satu kata diberi warna merah.
- Ikon garis sederhana di dalam kotak atau lingkaran berlatar lembut.
- Banyak ruang kosong; satu hal penting per kartu.

Untuk ParkirPintar:

- Rasa: bersih, tenang, mudah dibaca sekilas. Status parkir harus terbaca dalam satu detik.
- Bahasa Indonesia, kalimat pendek.
- Aplikasi dipakai di jaringan lokal tanpa internet, jadi **semua aset (font, ikon, ilustrasi) disimpan lokal** di `assets/`. Jangan memakai gambar atau font dari internet.

---

## 2. Warna

### 2.1 Palet Merek

| Token | Kegunaan | Perkiraan |
| --- | --- | --- |
| `brandDark` | Latar splash, bilah navigasi bawah, teks judul gelap | `#4A0A0F` |
| `brand` | Kartu hero, tombol utama, chip aktif | `#C4161C` |
| `brandBright` | Aksen, ikon aktif, kata yang disorot di judul | `#E0252B` |
| `brandSoft` | Latar ikon, chip tidak aktif | `#FCE4E6` |
| `background` | Latar layar | `#FDF3F4` |
| `surface` | Kartu putih | `#FFFFFF` |
| `textPrimary` | Teks utama | `#1E1416` |
| `textSecondary` | Teks pendukung | `#7A6A6D` |
| `outline` | Garis tipis dan pemisah | `#F0DADD` |

### 2.2 Warna Status Parkir

Merah dipakai sebagai warna merek, sehingga **status "penuh" tidak boleh hanya mengandalkan merah**. Setiap status memakai warna, ikon, dan teks sekaligus.

| Status | Syarat (terisi) | Warna | Ikon | Teks |
| --- | --- | --- | --- | --- |
| Kosong | di bawah 60% | Hijau `#2E9E5B` | centang | "Masih Lega" |
| Hampir penuh | 60 sampai 90% | Kuning tua `#E8A317` | peringatan | "Hampir Penuh" |
| Penuh | 90% ke atas | Merah gelap `#9E0F14` | silang | "Penuh" |

Catatan: ambang dapat diubah admin; label tetap mengikuti tiga status di atas. Status selalu ditampilkan sebagai chip dengan ikon, bukan hanya warna latar.

---

## 3. Tipografi

- Keluarga huruf: sans-serif geometris yang bersih (usulan: **Plus Jakarta Sans** atau **Poppins**), disimpan di `assets/fonts/`.
- Judul layar: 28 sp, tebal (w700). Satu kata kunci diberi warna `brand` (contoh: "Prediksi **Parkir**").
- Judul kartu: 16 sp, w600.
- Angka besar (slot kosong, perkiraan kendaraan): 40 sampai 48 sp, w700.
- Isi: 14 sp, w400. Keterangan kecil: 12 sp, `textSecondary`.
- Minimum ukuran teks 12 sp.

---

## 4. Bentuk, Jarak, dan Elevasi

| Elemen | Nilai |
| --- | --- |
| Radius kartu | 24 |
| Radius kartu kecil dan input | 16 |
| Radius chip dan tombol | pil (999) |
| Padding layar | 20 |
| Jarak antar kartu | 16 |
| Padding dalam kartu | 16 sampai 20 |
| Bayangan kartu | lembut, blur 24, opasitas rendah, warna kemerahan |
| Bilah navigasi | mengambang, margin 16 dari tepi, radius pil |

Kelipatan jarak: 4, 8, 12, 16, 20, 24.

---

## 5. Komponen

### 5.1 Header Sapaan
Avatar bulat kecil, teks kecil "Selamat pagi" dan di bawahnya nama atau "Pengguna Parkir". Di kanan: tombol lonceng bulat (opsional, bisa dipakai untuk info "perkiraan, bukan jaminan" atau dihilangkan bila tidak ada notifikasi).

### 5.2 Kartu Hero Status (merah penuh)
Kartu `brand` berisi:
- Judul kecil "Status Parkir Sekarang" dan jam.
- Angka besar jumlah slot kosong.
- Chip status (lihat 2.2).
- Bilah progres terisi (kapasitas terisi dibanding total).
- Tombol bulat putih berisi panah menuju Form Prediksi.

### 5.3 Chip Filter / Pilihan
Pil horizontal. Aktif: latar `brandDark`, teks putih. Tidak aktif: latar putih atau `brandSoft`, teks `textSecondary`. Dipakai untuk horizon (10, 20, 30 menit) dan periode rekap.

### 5.4 Kartu Daftar
Ikon di kotak lembut di kiri, judul dan keterangan di tengah, chip waktu di kanan, panah bulat di ujung. Dipakai untuk riwayat dan rekomendasi jam.

### 5.5 Kartu Input Bergaya "Dari / Ke"
Satu kartu putih berisi beberapa baris input dengan ikon titik merah di kiri dan garis pemisah. Dipakai di Form Prediksi: baris "Waktu target" (sekarang atau pilih tanggal dan jam) dan baris "Horizon", dengan tombol panah merah bulat di ujung kanan bawah sebagai aksi utama.

### 5.6 Garis Waktu / Slider Status
Garis putus-putus dengan penanda hati diganti **penanda mobil atau titik merah** di posisi persentase terisi. Dipakai di Hasil Prediksi untuk menunjukkan posisi antara kosong dan penuh, dengan tiga zona warna sesuai ambang.

### 5.7 Tombol
- **Utama:** pil, latar `brand`, teks putih, ikon panah di kanan.
- **Sekunder:** pil, garis `brand`, teks `brand`.
- **Aksi bulat:** lingkaran putih atau merah dengan ikon (panah, tambah, cari).
- Tinggi minimum 48.

### 5.8 Bilah Navigasi Bawah
Selebar layar dan menempel di bawah, latar `brandDark`, sudut atas membulat. Item aktif: lingkaran `brand` dengan ikon dan label putih. Item tidak aktif: ikon dan label abu muda.

Susunan (5 item, tombol tengah menonjol seperti referensi kedua):
1. Beranda
2. Tren
3. **Prediksi** (tombol tengah, lingkaran merah lebih besar)
4. Riwayat
5. Profil

Rekomendasi Jam diakses dari kartu di Beranda, bukan dari bilah navigasi. Menu admin muncul di layar Profil setelah login.

### 5.9 Kartu Promo / Info
Kartu merah dengan dekorasi bentuk lembut dan satu tombol putih. Dipakai untuk satu pesan di Beranda, misalnya "Jam tersepi hari ini: 07.00" dengan tombol "Lihat Rekomendasi".

### 5.10 Label "Perkiraan"
Setiap hasil prediksi memuat chip kecil "Perkiraan" dan teks "Bukan jaminan". Tidak boleh dihilangkan.

---

## 6. Layar per Layar

Setiap layar sesuai daftar di PRD bagian 7.

### 6.1 Splash (Semua)
- Latar gradasi `brandDark` ke hitam kemerahan.
- Logo ParkirPintar (huruf P di dalam bentuk lokasi atau tanda parkir) di atas.
- Ilustrasi sederhana bertema parkir (denah slot atau mobil dari atas) dengan garis berdenyut merah, menggantikan jantung pada referensi.
- Judul besar: "Cari Parkir, **Tanpa Putar-Putar**".
- Keterangan: "Lihat dan perkirakan slot parkir sebelum Anda tiba."
- Tombol pil "Mulai" dengan panah, ditambah tombol bulat putih di sebelahnya.
- Fungsi: cek sesi dan alamat server; bila server tidak terjangkau, lanjut ke Beranda dengan pesan koneksi.

### 6.2 Beranda (Semua)
Urutan dari atas:
1. Header sapaan.
2. Judul "Status **Parkir**".
3. Kartu hero status: slot kosong, status, progres terisi, tombol ke prediksi.
4. Baris tiga kartu kecil: **Prediksi 10 menit**, **Prediksi 20 menit**, **Prediksi 30 menit** (pintasan ke hasil).
5. Kartu info: jam tersepi dan jam teramai, tombol "Lihat Rekomendasi".
6. Ringkasan tren hari ini (grafik mini).
7. Bilah navigasi bawah.

### 6.3 Form Prediksi (Semua)
- Judul "Prediksi **Parkir**".
- Chip pilihan horizon: 10 menit, 20 menit, 30 menit.
- Kartu input bergaya "Dari / Ke": baris waktu target ("Sekarang" atau pilih tanggal dan jam), baris horizon terpilih.
- Teks bantu: "Makin jauh waktunya, makin kasar perkiraannya."
- Tombol utama "Lihat Prediksi" (pil merah, panah).
- Saat memproses: tombol berubah menjadi indikator putar; batas respons di bawah 3 detik.

### 6.4 Hasil Prediksi (Semua)
- Tombol kembali bulat di kiri atas.
- Kartu atas: judul "Hasil Prediksi", waktu target, chip "Perkiraan".
- Kartu hero: angka besar **perkiraan kendaraan** dari kapasitas (contoh "118 dari 150"), **slot tersedia**, dan chip status.
- Garis status (5.6) dengan penanda posisi terisi.
- Kartu keterangan: "Model XGBoost, rata-rata meleset sekitar 3,5 slot" (diambil dari MAE historis) dan teks "Perkiraan, bukan jaminan".
- Tombol "Prediksi Lagi" dan "Lihat Riwayat".

### 6.5 Riwayat Prediksi (Semua)
- Judul "Riwayat **Prediksi**".
- Chip filter: Semua, 10 menit, 20 menit, 30 menit.
- Daftar kartu (5.4): ikon status, waktu target, horizon, perkiraan kendaraan, chip status.
- Ketuk kartu untuk membuka detail.
- Admin: tambahan keterangan asal HP (`device_id` disingkat).
- Keadaan kosong: ilustrasi sederhana dan teks "Belum ada prediksi".

### 6.6 Tren Parkir (Semua)
- Judul "Tren **Parkir**".
- Chip pilihan: Harian, Mingguan.
- Kartu grafik garis atau batang dengan warna `brand`, sumbu jelas, sentuh titik untuk melihat nilai.
- Ringkasan di bawah grafik dalam kalimat, contoh "Paling ramai pukul 12.00".

### 6.7 Rekomendasi Jam (Semua)
- Judul "Waktu **Terbaik** Parkir".
- Dua bagian: "Jam tersepi" (3 kartu, ikon hijau) dan "Jam teramai" (3 kartu, ikon merah gelap).
- Tiap kartu: jam, rata-rata terisi, bilah kecil.
- Keterangan: "Berdasarkan rata-rata data historis".

### 6.8 Profil (Semua)
- Kartu info aplikasi dan versi.
- Tombol "Masuk sebagai Admin" (pintu masuk login admin). Setelah login, kartu berubah menjadi info admin dan muncul daftar menu admin (6.10 sampai 6.13) serta tombol Keluar.

### 6.9 Login Admin (Admin)
- Latar sama dengan Splash (gelap) agar terasa terpisah dari area publik.
- Dua input (username, password) berbentuk pil putih, tombol "Masuk".
- Pesan galat yang jelas: "Username atau password salah".

### 6.10 Rekap & Akurasi (Admin)
- Judul "Rekap & **Akurasi**".
- Chip periode (Hari ini, 7 hari, Bulan ini, Pilih tanggal).
- Baris kartu angka: total masuk, rata-rata lama parkir, rata-rata terisi.
- Kartu per jenis: Motor, Mobil, Lainnya (bilah atau donat).
- Kartu "Paling ramai dan paling sepi": jam dan hari.
- Grafik (batang atau garis).
- Kartu **Akurasi** dalam bahasa biasa: "Rata-rata meleset", "Meleset terbesar", "Kecocokan dengan data asli" per 10/20/30 menit, dengan pemisah Hari kerja dan Akhir pekan.
- Tombol "Export Excel" (pil merah) di bagian bawah atau kanan atas; membuka pilihan tanggal dan jenis lalu mengunduh.

### 6.11 Pengaturan Parkir (Admin)
- Input jumlah slot (stepper dengan tombol tambah dan kurang bulat).
- Dua pengatur batas status (slider atau input persen): batas hampir penuh dan batas penuh. Pratinjau chip status mengikuti nilai.
- Tombol "Simpan". Keterangan: "Berlaku untuk semua pengguna".

### 6.12 Kelola Admin (Admin)
- Daftar admin sebagai kartu dengan saklar aktif/nonaktif.
- Tombol bulat tambah (+) di kanan atas.
- Aksi per admin: ganti password, nonaktifkan.
- Konfirmasi sebelum menonaktifkan.

### 6.13 Pengaturan Server (Admin)
- Input alamat server (IP dan port), nilai awal terisi otomatis.
- Tombol "Tes Koneksi" dengan hasil berupa chip hijau atau merah gelap.
- Tombol "Simpan".

---

## 7. Keadaan Khusus

| Keadaan | Tampilan |
| --- | --- |
| Memuat | Kerangka kartu (skeleton) abu-merah muda, bukan layar kosong |
| Tidak terhubung ke server | Kartu peringatan di atas layar: "Tidak bisa terhubung ke server. Pastikan HP dan laptop satu Wi-Fi." dengan tombol "Coba Lagi" dan "Pengaturan Server" (admin) |
| Data kosong | Ilustrasi sederhana dan satu kalimat penjelasan |
| Galat prediksi | Pesan singkat dan tombol coba lagi; tidak menampilkan kode teknis |
| Sesi admin habis | Kembali ke Login Admin dengan pesan "Sesi berakhir, silakan masuk lagi" |

---

## 8. Gerak dan Interaksi

- Transisi antar layar: geser halus, 250 ms.
- Angka besar menghitung naik singkat saat pertama tampil (maksimal 600 ms).
- Penanda di garis status bergerak ke posisinya saat hasil muncul.
- Tombol: efek tekan (skala 0,97).
- Hindari animasi panjang; layar harus terasa cepat.

---

## 9. Aksesibilitas dan Keterbacaan

- Kontras teks terhadap latar minimal 4,5:1; teks putih pada `brand` sudah memenuhi, periksa pada `brandBright`.
- Status tidak pernah hanya warna: selalu ikon dan teks.
- Area sentuh minimal 48 x 48.
- Mendukung ukuran teks sistem yang diperbesar tanpa memotong kartu.
- Label semantik pada ikon dan grafik (deskripsi singkat untuk pembaca layar).
- Nilai perkiraan selalu memuat kata "perkiraan".

---

## 10. Pemetaan ke Kode Flutter

| Bagian desain | Lokasi di `parkirpintar/lib/` |
| --- | --- |
| Warna, tipografi, radius, `ThemeData` | `core/` (misalnya `app_colors.dart`, `app_theme.dart`) |
| Konstanta ambang dan teks status | `core/` |
| Komponen bersama (kartu hero, chip, tombol, bilah nav, chip status, kerangka muat) | `core/widgets/` |
| Layar Beranda | `features/beranda/` |
| Form, Hasil, Riwayat | `features/prediksi/` |
| Rekomendasi Jam | `features/rekomendasi/` |
| Tren | `features/tren/` |
| Login Admin dan Profil | `features/auth/` |
| Rekap & Akurasi, Pengaturan Parkir, Kelola Admin, Pengaturan Server | `features/admin/` |
| Font dan ilustrasi | `assets/fonts/`, `assets/images/` (didaftarkan di `pubspec.yaml`) |

Usulan paket: `fl_chart` untuk grafik, `go_router` atau navigator bawaan untuk rute, `dio` atau `http` untuk API, `flutter_secure_storage` untuk token admin, `shared_preferences` untuk `device_id` dan alamat server.

---

## 11. Hal yang Perlu Diputuskan

| No | Hal | Catatan |
| --- | --- | --- |
| 1 | Logo dan ilustrasi ParkirPintar | Dibuat sendiri; jangan memakai aset dari referensi |
| 2 | Font final | Plus Jakarta Sans atau Poppins, harus dibundel lokal |
| 3 | Lonceng di header | Dipakai atau dihapus, karena PRD tidak memuat notifikasi |
| 4 | Susunan bilah navigasi | Usulan 5 item dengan Prediksi di tengah; bisa diubah |
| 5 | Mode gelap | Di luar lingkup saat ini |
