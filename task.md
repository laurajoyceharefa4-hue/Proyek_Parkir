# Daftar Tugas ParkirPintar (PRD v1.2)

Fase 1 (pelatihan model) sudah selesai. Frontend dikerjakan dengan data mock yang bentuknya persis seperti kontrak API di PRD bagian 9. Tugas frontend yang harus menunggu backend dipindah ke bagian backend.

---

## Frontend (Flutter, Android)

### Dasar
- [x] 1. Buat proyek Flutter dan struktur folder `core`, `data`, `services`, `features`.
- [x] 2. Buat tema, warna, dan konstanta, termasuk warna status (kosong, hampir penuh, penuh).
- [x] 3. Buat model data dan data mock yang bentuknya persis seperti respons PRD bagian 9.
- [x] 4. Buat repository (antarmuka data) yang sementara memakai mock.
- [x] 5. Buat `device_id` sekali saat pertama dibuka, lalu simpan di HP.

### Layar semua pengguna
- [x] 6. Splash dan Beranda (status dan slot kosong).
- [x] 7. Form Prediksi (horizon 10/20/30 menit, tanggal dan jam opsional).
- [x] 8. Hasil Prediksi (label "perkiraan", MAE, slot, status).
- [x] 9. Riwayat Prediksi (daftar dan detail).
- [x] 10. Tren (grafik harian dan mingguan).
- [x] 11. Rekomendasi Jam (3 tersepi, 3 teramai).
- [x] 12. Profil.

### Layar admin
- [ ] 13. Login Admin (token disimpan dari mock).
- [ ] 14. Rekap & Akurasi (grafik, pilihan periode, tombol Export Excel sebagai tampilan saja).
- [ ] 15. Terjemahan akurasi ke bahasa biasa ("rata-rata meleset", "meleset terbesar", "kecocokan dengan data asli").
- [ ] 16. Pengaturan Parkir (jumlah slot dan batas status, dengan mock).
- [ ] 17. Kelola Admin (tambah, ganti password, nonaktifkan, dengan mock).
- [ ] 18. Pengaturan Server (simpan alamat di HP, hanya terlihat setelah login admin).

---

## Backend (FastAPI + PostgreSQL)

### Dasar
- [ ] 1. Setup `.venv`, `requirements.txt`, dan `config.py` (path model, API key, kapasitas awal, ambang).
- [ ] 2. Koneksi PostgreSQL (SQLAlchemy) dan enam tabel di `models_db.py`.
- [ ] 3. Startup otomatis: muat 3 model XGBoost, buat admin awal, isi `data_parkir` dan `kendaraan_parkir` dari CSV, impor `hasil_evaluasi`.

### Inti prediksi
- [ ] 4. `predictor.py`: bentuk 16 fitur berurutan, jalankan model per horizon, hitung slot tersedia dan status.
- [ ] 5. Logika prediksi waktu bebas (titik acuan = waktu target dikurangi horizon).
- [ ] 6. `rekomendasi.py` (rata-rata historis per jam).

### Keamanan dan endpoint
- [ ] 7. `auth.py`: login admin, JWT, pengecekan API key.
- [ ] 8. Endpoint publik: `/status`, `/prediksi`, `/prediksi/riwayat` (dan detail), `/tren`, `/rekomendasi`, `/konfigurasi` (GET).
- [ ] 9. Endpoint admin: `/auth/login`, `/auth/me`, `/rekap`, `/evaluasi`, `/konfigurasi` (PUT), `/admin`, `/export/kendaraan`.
- [ ] 10. `export.py`: Excel dengan openpyxl, filter tanggal dan jenis.

### Pelengkap
- [ ] 11. Demo Streamlit (`web_demo/app.py`).
- [ ] 12. Folder `backup/` dan dokumentasi backup manual.

### Dipindah dari frontend (menunggu backend jadi)
- [ ] 13. Ganti mock dengan pemanggil API asli (header `X-API-Key`, `Bearer` untuk admin).
- [ ] 14. Penanganan error dan koneksi putus.
- [ ] 15. Unduh dan simpan file Excel dari `/export/kendaraan`.
- [ ] 16. Uji alur lengkap di dua HP dan cek respons di bawah 3 detik.

---

## Pengecekan data (sebelum atau bersamaan)

- [ ] Cek `train_model.py`: `target_10m/20m/30m` harus dibentuk dari jumlah terisi, bukan tersedia.
- [ ] Cek periode dataset kendaraan sama dengan dataset 1 bulan.
- [ ] Hitung pembanding persistensi dan rata-rata historis.
- [ ] Hitung RMSE dan R² per horizon dan per tipe hari (hari kerja, akhir pekan).
- [ ] Tetapkan jumlah layar yang benar (13 atau 14) dan setujui cara prediksi waktu bebas.

---

## Fase 4: Pengujian dan skripsi

- [ ] Pengujian fungsional per fitur dan per peran.
- [ ] Pengujian integrasi di dua HP.
- [ ] Pengujian pengguna (kuesioner SUS, jika memungkinkan).
- [ ] Penyusunan laporan skripsi.
