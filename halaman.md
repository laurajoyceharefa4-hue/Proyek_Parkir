# Daftar Halaman ParkirPintar (Checklist)

Total **13 halaman** (PRD v1.2 bagian 7): 8 untuk semua pengguna dan 5 khusus admin. Export Excel adalah tombol di halaman Rekap & Akurasi, bukan halaman sendiri. Detail tampilan ada di `design.md`.

Progres: desain 13 dari 13 layar selesai (semua item desain dicentang). Implementasi kode tersedia untuk halaman 1–13; penyelesaian audit visual dan keterpakaian penuh masih tertunda karena font Plus Jakarta Sans lokal belum tersedia.


## Referensi Desain Stitch (via MCP)

Desain visual tiap halaman ada di Google Stitch. Agent mengambil gambar dan kode layar lewat MCP Stitch memakai ID di bawah. Jadikan layar Stitch sebagai acuan tampilan, dan `design.md` sebagai acuan token (warna, tipografi, radius).

- Project: **ParkirPintar Mobile UI**
- Project ID: `7187888947005802512`
- Ukuran semua layar: mobile 390 x 844 px

| No | Halaman | Nama layar di Stitch | Screen ID |
| --- | --- | --- | --- |
| 1 | Splash | Layar Splash Mobile - ParkirPintar | `f09c2def27bd4d1486ee2aa1db62650a` |
| 2 | Beranda | Beranda Mobile - ParkirPintar | `c02e3152f94b4fedb56157e2a1d9ecef` |
| 3 | Form Prediksi | Form Prediksi - ParkirPintar | `cfd8c11cd51e4c1cada1c5f071c2b850` |
| 4 | Hasil Prediksi | Hasil Prediksi Mobile - ParkirPintar | `405722969a664b529a041ea14af23340` |
| 5 | Riwayat Prediksi | Riwayat Prediksi - ParkirPintar (Mobile) | `f9f7cbf1310e48eca1b52c9c2ecb591a` |
| 6 | Tren Parkir | Tren Parkir Mobile - ParkirPintar | `e3120260440f4f969332a39201dbc194` |
| 7 | Rekomendasi Jam | Rekomendasi Jam Lengkap - ParkirPintar | `9e8033cb4b7744cfa625ff597c871a4b` |
| 8 | Profil | Profil - ParkirPintar (Mobile) | `1179fd1caed24b359de150eed4128973` |
| 9 | Login Admin | Login Admin Mobile - ParkirPintar | `2bd2118dd1e24875a9115e6510f2188d` |
| 10 | Rekap & Akurasi | Rekap & Akurasi Admin - ParkirPintar (Mobile) | `e473b3c40a214dcdb5f193cc3cf868c0` |
| 11 | Pengaturan Parkir | Pengaturan Parkir - ParkirPintar (Mobile) | `35e8a46aef4740d29466adfd6e1f5a17` |
| 12 | Kelola Admin | Kelola Admin & Konfirmasi - ParkirPintar (Mobile) | `2d37406094954ba99b6f937b10bb1a65` |
| 13 | Pengaturan Server | Pengaturan Server - ParkirPintar (Mobile) | `eb52204313e344eba926002fa4fca7ac` |

Cara agent memakainya:
1. Sebelum membuat halaman, ambil gambar dan kode layar dari MCP Stitch (project ID dan screen ID di atas).
2. Unduh URL hasil (gambar atau kode) dengan `curl -L`.
3. Ikuti tata letak, ikon, dan teks dari layar Stitch. Terjemahkan ke widget Flutter memakai token di `design.md` (`core/app_colors.dart`, `core/app_theme.dart`).
4. Komponen yang berulang (bilah navigasi bawah, chip status, kartu hero) dibuat **satu kali** di `core/widgets/`, bukan disalin per halaman.
5. Data tetap dari mock sesuai kontrak API PRD bagian 9. Angka di desain hanya contoh.

Catatan: kode HTML dari Stitch hanya acuan visual, bukan untuk disalin langsung ke Flutter. Aplikasi berjalan tanpa internet, jadi semua font dan ikon harus dibundel lokal di `assets/`.


## Halaman untuk Semua Pengguna

### 1. Splash
Stitch: `f09c2def27bd4d1486ee2aa1db62650a`
- [x] Logo di tengah, tanpa tombol dan tanpa slogan (masuk otomatis)
- [x] Indikator loading kecil
- [x] Cek sesi dan alamat server
- [x] Pindah otomatis ke Beranda
- [x] Pesan koneksi di Beranda jika server tidak terjangkau
- [x] Desain selesai di Stitch
- [ ] Implementasi Flutter selesai

### 2. Beranda
Stitch: `c02e3152f94b4fedb56157e2a1d9ecef`
- [x] Header sapaan
- [x] Kartu hero: slot kosong, status, progres terisi
- [x] Tiga pintasan prediksi 10, 20, 30 menit
- [x] Kartu info jam tersepi dan teramai
- [x] Grafik mini tren hari ini
- [x] Bilah navigasi bawah
- [x] Desain selesai di Stitch
- [ ] Implementasi Flutter selesai

### 3. Form Prediksi
Stitch: `cfd8c11cd51e4c1cada1c5f071c2b850`
- [x] Pilihan horizon 10, 20, 30 menit
- [x] Pilihan waktu target (sekarang atau tanggal dan jam sendiri)
- [x] Tombol "Lihat Prediksi" dan status memuat
- [x] Desain selesai di Stitch
- [ ] Implementasi Flutter selesai

### 4. Hasil Prediksi
Stitch: `405722969a664b529a041ea14af23340`
- [x] Perkiraan kendaraan dari kapasitas dan slot tersedia
- [x] Chip status (ikon dan teks)
- [x] Garis status posisi terisi
- [x] MAE historis dan label "Perkiraan, bukan jaminan"
- [x] Tombol "Prediksi Lagi" dan "Lihat Riwayat"
- [x] Desain selesai di Stitch
- [ ] Implementasi Flutter selesai

### 5. Riwayat Prediksi
Stitch: `f9f7cbf1310e48eca1b52c9c2ecb591a`
- [x] Daftar riwayat dari HP sendiri
- [x] Filter horizon
- [x] Detail riwayat
- [x] Tampilan kosong
- [x] Desain selesai di Stitch
- [ ] Implementasi Flutter selesai

### 6. Tren Parkir
Stitch: `e3120260440f4f969332a39201dbc194`
- [x] Pilihan Harian / Mingguan
- [x] Grafik
- [x] Ringkasan satu kalimat
- [x] Desain selesai di Stitch
- [x] Implementasi Flutter selesai

### 7. Rekomendasi Jam
Stitch: `9e8033cb4b7744cfa625ff597c871a4b`
- [x] 3 jam tersepi
- [x] 3 jam teramai
- [x] Keterangan "berdasarkan data historis"
- [x] Desain selesai di Stitch
- [x] Implementasi Flutter selesai

### 8. Profil
Stitch: `1179fd1caed24b359de150eed4128973`
- [x] Info aplikasi
- [x] Tombol "Masuk sebagai Admin"
- [x] Tampilan setelah login: info admin, menu admin, tombol Keluar (desain mengikuti `design.md` 6.8)
- [x] Desain selesai di Stitch
- [x] Implementasi Flutter selesai

---

## Halaman Khusus Admin

### 9. Login Admin
Stitch: `2bd2118dd1e24875a9115e6510f2188d`
- [x] Input username dan password
- [x] Pesan galat jika salah
- [x] Simpan token
- [x] Desain selesai di Stitch
- [x] Implementasi Flutter selesai

### 10. Rekap & Akurasi
Stitch: `e473b3c40a214dcdb5f193cc3cf868c0`
- [x] Pilihan periode
- [x] Total masuk, per jenis (motor, mobil, lainnya), rata-rata lama parkir
- [x] Jam dan hari paling ramai dan sepi, rata-rata terisi
- [x] Grafik
- [x] Akurasi bahasa biasa (rata-rata meleset, meleset terbesar, kecocokan)
- [x] Akurasi per 10/20/30 menit dan hari kerja vs akhir pekan
- [x] Tombol Export Excel (filter tanggal dan jenis)
- [x] Desain selesai di Stitch
- [x] Implementasi Flutter selesai

### 11. Pengaturan Parkir
Stitch: `35e8a46aef4740d29466adfd6e1f5a17`
- [x] Input jumlah slot
- [x] Pengatur batas hampir penuh dan penuh (dengan pratinjau chip)
- [x] Tombol Simpan
- [x] Desain selesai di Stitch
- [x] Implementasi Flutter selesai

### 12. Kelola Admin
Stitch: `2d37406094954ba99b6f937b10bb1a65` (sudah termasuk dialog konfirmasi nonaktifkan)
- [x] Daftar admin
- [x] Tambah admin
- [x] Ganti password
- [x] Nonaktifkan admin (dengan konfirmasi)
- [x] Desain selesai di Stitch
- [x] Implementasi Flutter selesai

### 13. Pengaturan Server
Stitch: `eb52204313e344eba926002fa4fca7ac`
- [x] Input alamat server (IP dan port), nilai awal terisi otomatis
- [x] Tombol Tes Koneksi
- [x] Tombol Simpan
- [x] Desain selesai di Stitch
- [x] Implementasi Flutter selesai

---

## Keadaan Khusus (berlaku di semua halaman)

Desain mengikuti `design.md` bagian 7.

- [x] Tampilan memuat (kerangka)
- [x] Tampilan tidak terhubung ke server
- [x] Tampilan data kosong
- [x] Tampilan galat prediksi
- [x] Sesi admin habis kembali ke Login Admin

Catatan audit: implementasi layar admin tersedia; audit visual akhir seluruh 13 layar dan validasi keterpakaian penuh menunggu file font Plus Jakarta Sans lokal.

---

## Setelah Backend Jadi

- [ ] Ganti mock dengan API asli
- [ ] Uji tiap halaman di HP Android
- [ ] Uji alur publik dan admin di dua HP

---

## Alur Perpindahan Halaman

```
Splash -> Beranda
Beranda -> Form Prediksi -> Hasil Prediksi -> Riwayat Prediksi
Beranda -> Rekomendasi Jam
Navigasi -> Tren Parkir, Riwayat Prediksi, Profil
Profil -> Login Admin -> menu admin
Menu admin -> Rekap & Akurasi, Pengaturan Parkir, Kelola Admin, Pengaturan Server
```
