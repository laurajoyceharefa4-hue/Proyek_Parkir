String formatRataRataMeleset(double? value) => value == null
    ? 'Belum tersedia'
    : 'sekitar ${value.toStringAsFixed(1).replaceAll('.', ',')} slot';

String formatMelesetTerbesar(double? value) => value == null
    ? 'Belum tersedia'
    // Pendekatan dari RMSE karena kontrak evaluasi tidak memuat galat maksimum.
    : 'sekitar ${value.toStringAsFixed(1).replaceAll('.', ',')} slot';

String formatKecocokan(double? value) => value == null
    ? 'Belum tersedia'
    : '${(value * 100).round().clamp(0, 100)}%';
