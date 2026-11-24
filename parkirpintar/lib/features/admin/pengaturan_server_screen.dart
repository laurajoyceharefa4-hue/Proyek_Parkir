import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/admin_helpers.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/widgets/admin_screen_scaffold.dart';
import '../../services/app_services.dart';
import '../../services/server_address_service.dart';

class PengaturanServerScreen extends StatefulWidget {
  const PengaturanServerScreen({super.key});

  @override
  State<PengaturanServerScreen> createState() => _PengaturanServerScreenState();
}

class _PengaturanServerScreenState extends State<PengaturanServerScreen> {
  final TextEditingController _address = TextEditingController();

  static const Duration _timeout = Duration(seconds: 6);

  String _activeAddress = '';
  String? _testedAddress;
  String? _connectionMessage;
  String? _error;

  bool _testing = false;
  bool _saving = false;
  bool? _connected;

  @override
  void initState() {
    super.initState();

    _activeAddress = AppServices.initialized
        ? AppServices.serverAddress.address
        : AppConstants.alamatServerAwal;

    _address.text = _activeAddress;
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  String get _candidate {
    return ServerAddressService.normalize(_address.text);
  }

  String? get _validation {
    return ServerAddressService.validateAddress(_address.text);
  }

  bool get _hasChanged {
    return _candidate != _activeAddress;
  }

  void _onAddressChanged(String value) {
    setState(() {
      _connected = null;
      _testedAddress = null;
      _connectionMessage = null;
      _error = null;
    });
  }

  Future<void> _testConnection() async {
    if (_testing || _saving) return;

    final validation = _validation;

    if (validation != null) {
      setState(() {
        _connected = false;
        _error = validation;
        _connectionMessage = null;
      });
      return;
    }

    final candidate = _candidate;

    setState(() {
      _testing = true;
      _connected = null;
      _testedAddress = null;
      _connectionMessage = null;
      _error = null;
    });

    final client = http.Client();

    try {
      // 1. Pastikan FastAPI merespons.
      final health = await client
          .get(
            Uri.parse('$candidate/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      if (health.statusCode != 200) {
        throw StateError('/health mengembalikan HTTP ${health.statusCode}.');
      }

      final healthData = jsonDecode(utf8.decode(health.bodyBytes));

      if (healthData is! Map<String, dynamic>) {
        throw const FormatException('Respons /health bukan objek JSON.');
      }

      // 2. Pastikan API Parkir Pintar tersedia.
      final config = await client
          .get(
            Uri.parse('$candidate/api/mobile/konfigurasi'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      if (config.statusCode != 200) {
        throw StateError('Konfigurasi API gagal: HTTP ${config.statusCode}.');
      }

      final configData = jsonDecode(utf8.decode(config.bodyBytes));

      if (configData is! Map<String, dynamic> ||
          configData['kapasitas'] is! num ||
          configData['ambang_hampir_penuh'] is! num ||
          configData['ambang_penuh'] is! num) {
        throw const FormatException(
          'Respons konfigurasi Parkir Pintar tidak sesuai.',
        );
      }

      if (!mounted || _candidate != candidate) {
        return;
      }

      final kapasitas = (configData['kapasitas'] as num).toInt();

      setState(() {
        _connected = true;
        _testedAddress = candidate;
        _connectionMessage =
            'FastAPI Parkir Pintar terhubung. '
            'HTTP 200. Kapasitas: $kapasitas slot.';
      });
    } on TimeoutException {
      _connectionFailed(
        candidate,
        'Koneksi melebihi 6 detik. '
        'Periksa jaringan dan firewall laptop.',
      );
    } on FormatException catch (error) {
      _connectionFailed(
        candidate,
        'Respons API tidak sesuai: ${error.message}',
      );
    } on http.ClientException catch (error) {
      _connectionFailed(candidate, 'Permintaan HTTP gagal: ${error.message}');
    } catch (error) {
      _connectionFailed(candidate, 'Server tidak dapat diverifikasi: $error');
    } finally {
      client.close();

      if (mounted) {
        setState(() {
          _testing = false;
        });
      }
    }
  }

  void _connectionFailed(String candidate, String message) {
    if (!mounted || _candidate != candidate) {
      return;
    }

    setState(() {
      _connected = false;
      _testedAddress = null;
      _connectionMessage = null;
      _error = message;
    });
  }

  Future<void> _save() async {
    if (_saving || _testing) return;

    final validation = _validation;

    if (validation != null) {
      setState(() {
        _error = validation;
      });
      return;
    }

    if (!AppServices.initialized) {
      setState(() {
        _error = 'Layanan aplikasi belum siap.';
      });
      return;
    }

    final newAddress = _candidate;
    final changed = _hasChanged;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (changed) {
        // Token lama tidak boleh dikirim ke
        // alamat backend yang baru.
        await AppServices.session.clear();
        AppServices.adminName = null;
      }

      await AppServices.serverAddress.save(newAddress);

      if (!mounted) return;

      setState(() {
        _activeAddress = newAddress;
        _saving = false;
      });

      if (changed) {
        // Setelah mengganti backend, admin
        // perlu mengautentikasi ulang.
        context.go('/login-admin');
        return;
      }

      showAdminMessage(context, 'Alamat server sudah tersimpan.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = 'Gagal menyimpan alamat server: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final testSuccessful = _connected == true && _testedAddress == _candidate;

    return AdminScreenScaffold(
      title: 'Pengaturan ',
      accent: 'Server',
      subtitle: 'Hubungkan aplikasi ke FastAPI Parkir Pintar.',
      children: [
        Card(
          color: AppColors.brand,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alamat server aktif',
                  style: TextStyle(color: AppColors.softWhite),
                ),

                const SizedBox(height: AppSpacing.s),

                SelectableText(
                  _activeAddress,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: AppSpacing.m),

                if (_connected == true)
                  const Chip(
                    avatar: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.statusKosong,
                    ),
                    label: Text('Terhubung'),
                  )
                else if (_connected == false)
                  const Chip(
                    avatar: Icon(
                      Icons.cancel_rounded,
                      color: AppColors.statusPenuh,
                    ),
                    label: Text('Tidak terhubung'),
                  )
                else
                  const Text(
                    'Koneksi belum diperiksa.',
                    style: TextStyle(color: AppColors.softWhite, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.cardGap),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alamat FastAPI',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: AppSpacing.m),

                TextField(
                  controller: _address,
                  onChanged: _onAddressChanged,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enabled: !_saving && !_testing,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.dns_rounded),
                    hintText: 'http://192.168.1.10:8001',
                  ),
                ),

                const SizedBox(height: AppSpacing.m),

                const Text(
                  'Masukkan IP laptop dan port FastAPI. '
                  'Jangan tambahkan /docs atau /health.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.cardGap),

        Card(
          color: AppColors.brandSoft,
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.l),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.brand),

                SizedBox(width: AppSpacing.m),

                Expanded(
                  child: Text(
                    'Alamat server harus dapat '
                    'diakses dari perangkat yang '
                    'menjalankan aplikasi.\n\n'
                    'HTTP digunakan hanya untuk '
                    'demo pada jaringan lokal '
                    'tepercaya. Jangan mengirim '
                    'password admin melalui '
                    'jaringan publik tanpa HTTPS.',
                    style: TextStyle(color: AppColors.brandDark, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_connectionMessage != null) ...[
          const SizedBox(height: AppSpacing.m),
          Text(
            _connectionMessage!,
            style: const TextStyle(
              color: AppColors.statusKosong,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.m),
          Text(_error!, style: const TextStyle(color: AppColors.statusPenuh)),
        ],

        const SizedBox(height: AppSpacing.l),

        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _saving || _testing ? null : _testConnection,
            icon: _testing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering_rounded),
            label: Text(_testing ? 'Memeriksa Koneksi...' : 'Tes Koneksi'),
          ),
        ),

        const SizedBox(height: AppSpacing.s),

        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _saving || _testing ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan Alamat Server'),
          ),
        ),

        if (!testSuccessful) ...[
          const SizedBox(height: AppSpacing.m),
          const Text(
            'Alamat boleh disimpan tanpa tes '
            'koneksi, tetapi belum dapat '
            'dinyatakan terhubung.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],

        if (_hasChanged) ...[
          const SizedBox(height: AppSpacing.s),
          const Text(
            'Mengganti server akan '
            'menghapus sesi admin lokal '
            'dan meminta login ulang.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
