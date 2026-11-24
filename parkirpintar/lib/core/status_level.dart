import 'package:flutter/material.dart';

import 'app_colors.dart';

enum StatusLevel {
  kosong(
    kode: 'kosong',
    label: 'Masih Lega',
    warna: AppColors.statusKosong,
    ikon: Icons.check_circle_rounded,
  ),
  hampirPenuh(
    kode: 'hampir_penuh',
    label: 'Hampir Penuh',
    warna: AppColors.statusHampirPenuh,
    ikon: Icons.warning_rounded,
  ),
  penuh(
    kode: 'penuh',
    label: 'Penuh',
    warna: AppColors.statusPenuh,
    ikon: Icons.cancel_rounded,
  );

  const StatusLevel({
    required this.kode,
    required this.label,
    required this.warna,
    required this.ikon,
  });

  final String kode;
  final String label;
  final Color warna;
  final IconData ikon;

  static StatusLevel fromKode(String kode) {
    return StatusLevel.values.firstWhere(
      (status) => status.kode == kode,
      orElse: () => StatusLevel.kosong,
    );
  }

  static StatusLevel hitung({
    required int terisi,
    required int kapasitas,
    required int ambangHampirPenuh,
    required int ambangPenuh,
  }) {
    if (kapasitas <= 0) return StatusLevel.kosong;

    final persenTerisi = (terisi / kapasitas) * 100;
    if (persenTerisi < ambangHampirPenuh) return StatusLevel.kosong;
    if (persenTerisi < ambangPenuh) return StatusLevel.hampirPenuh;
    return StatusLevel.penuh;
  }
}
