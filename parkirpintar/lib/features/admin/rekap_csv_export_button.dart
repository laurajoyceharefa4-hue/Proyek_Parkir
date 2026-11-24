import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;

import '../../core/admin_helpers.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../data/repository/parkir_exception.dart';
import '../../services/app_services.dart';

class RekapCsvExportButton extends StatefulWidget {
  const RekapCsvExportButton({super.key, required this.range});

  final DateTimeRange range;

  @override
  State<RekapCsvExportButton> createState() => _RekapCsvExportButtonState();
}

class _RekapCsvExportButtonState extends State<RekapCsvExportButton> {
  bool _exporting = false;

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _errorFromResponse(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];

        if (detail is String && detail.isNotEmpty) {
          return detail;
        }

        if (detail != null) {
          return detail.toString();
        }
      }
    } catch (_) {
      // Respons mungkin bukan JSON.
    }

    return 'HTTP ${response.statusCode}';
  }

  Future<void> _exportCsv() async {
    if (_exporting) return;

    setState(() {
      _exporting = true;
    });

    try {
      if (!AppServices.initialized) {
        throw const ParkirException(
          'Layanan aplikasi belum siap.',
          JenisGalat.server,
        );
      }

      final token = await AppServices.session.readToken();

      if (token == null || token.isEmpty) {
        throw const ParkirException(
          'Sesi admin tidak tersedia. Silakan login kembali.',
          JenisGalat.sesiHabis,
        );
      }

      final dari = _formatDate(widget.range.start);
      final sampai = _formatDate(widget.range.end);

      final baseAddress = AppServices.serverAddress.address.trim().replaceFirst(
        RegExp(r'/+$'),
        '',
      );

      final baseUri = Uri.tryParse(baseAddress);

      if (baseUri == null ||
          !baseUri.hasAuthority ||
          (baseUri.scheme != 'http' && baseUri.scheme != 'https')) {
        throw const ParkirException(
          'Alamat server tidak valid.',
          JenisGalat.validasi,
        );
      }

      final url = Uri.parse('$baseAddress/api/admin/rekap/export.csv')
          .replace(queryParameters: {'dari': dari, 'sampai': sampai});

      // CSV harus diminta langsung dari backend,
      // bukan dibuat ulang dari angka di Flutter.
      final response = await http
          .get(
            url,
            headers: {'Authorization': 'Bearer $token', 'Accept': 'text/csv'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        throw const ParkirException(
          'Sesi admin telah berakhir.',
          JenisGalat.sesiHabis,
        );
      }

      if (response.statusCode != 200) {
        final detail = _errorFromResponse(response);

        throw ParkirException(
          'Gagal mengambil CSV: $detail',
          response.statusCode == 403 ||
                  response.statusCode == 404 ||
                  response.statusCode == 422
              ? JenisGalat.validasi
              : JenisGalat.server,
        );
      }

      if (response.bodyBytes.isEmpty) {
        throw const ParkirException(
          'CSV dari server kosong.',
          JenisGalat.server,
        );
      }

      final contentType = response.headers['content-type'] ?? '';

      if (contentType.contains('application/json') ||
          contentType.contains('text/html')) {
        throw const ParkirException(
          'Server tidak mengembalikan file CSV.',
          JenisGalat.server,
        );
      }

      final filename = 'rekap_parkir_${dari}_$sampai.csv';

      if (!mounted) return;

      // Android membuka dialog penyimpanan.
      // User bisa memilih folder Download.
      final savedLocation = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          data: response.bodyBytes,
          fileName: filename,
          mimeTypesFilter: const ['text/csv'],
        ),
      );

      if (!mounted) return;

      if (savedLocation == null) {
        showAdminMessage(context, 'Penyimpanan CSV dibatalkan.');
        return;
      }

      showAdminMessage(context, 'CSV berhasil disimpan: $filename');
    } on ParkirException catch (error) {
      if (!mounted) return;

      if (await handleAdminError(context, error)) {
        return;
      }

      if (!mounted) return;

      showAdminMessage(context, error.pesan);
    } on TimeoutException {
      if (!mounted) return;

      showAdminMessage(
        context,
        'Permintaan CSV terlalu lama. Periksa koneksi FastAPI.',
      );
    } on http.ClientException catch (error) {
      if (!mounted) return;

      showAdminMessage(context, 'Koneksi ke server gagal: ${error.message}');
    } catch (error) {
      if (!mounted) return;

      showAdminMessage(context, 'Gagal menyimpan CSV: $error');
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dari = _formatDate(widget.range.start);
    final sampai = _formatDate(widget.range.end);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ekspor Data Historis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Periode: $dari sampai $sampai',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            const Text(
              'File CSV diambil langsung dari FastAPI '
              'dan berisi data pengamatan parkir '
              'sesuai periode yang dipilih.',
            ),
            const SizedBox(height: AppSpacing.l),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _exporting ? null : _exportCsv,
                icon: _exporting
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _exporting ? 'Menyiapkan CSV...' : 'Unduh CSV Rekap',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'Setelah dialog Android terbuka, '
              'pilih folder Download, lalu tekan Simpan.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
