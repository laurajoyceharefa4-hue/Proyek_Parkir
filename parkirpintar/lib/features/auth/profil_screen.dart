import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/widgets/hero_card.dart';
import '../../core/widgets/screen_scaffold.dart';

import '../../data/models/admin.dart';
import '../../data/repository/parkir_exception.dart';
import '../../services/app_services.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Admin? _admin;

  bool _loading = true;
  bool _loggingOut = false;
  bool _hasStoredToken = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!AppServices.initialized) {
        if (!mounted) return;

        setState(() {
          _admin = null;
          _hasStoredToken = false;
          _loading = false;
        });

        return;
      }

      final token = await AppServices.session.readToken();

      if (!mounted) return;

      _hasStoredToken = token != null && token.isNotEmpty;

      if (!_hasStoredToken) {
        setState(() {
          _admin = null;
          _loading = false;
        });

        return;
      }

      // Verifikasi token ke backend.
      final admin = await AppServices.repository.me();

      if (!mounted) return;

      AppServices.adminName = admin.nama;

      setState(() {
        _admin = admin;
        _loading = false;
        _error = null;
      });
    } on ParkirException catch (error) {
      if (error.jenis == JenisGalat.sesiHabis) {
        await AppServices.session.clear();
        AppServices.adminName = null;

        if (!mounted) return;

        context.go('/login-admin?expired=1');
        return;
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.pesan;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Gagal memeriksa sesi admin. '
            'Periksa koneksi ke FastAPI.';
      });
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    bool serverSessionRevoked = false;

    // Backend mencoba mencabut token
    // dari database SQLite.
    try {
      await AppServices.apiRepository.logoutServer();
      serverSessionRevoked = true;
    } catch (_) {
      // Jika server offline atau sesi sudah
      // kedaluwarsa, sesi perangkat tetap
      // perlu dihapus. Jangan mengklaim
      // bahwa token berhasil dicabut server.
    }

    try {
      await AppServices.session.clear();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loggingOut = false;
      });

      _showMessage(
        'Gagal menghapus sesi pada perangkat. '
        'Silakan coba lagi.',
      );

      return;
    }

    AppServices.adminName = null;

    if (!mounted) return;

    setState(() {
      _admin = null;
      _hasStoredToken = false;
      _loading = false;
      _loggingOut = false;
      _error = null;
    });

    _showMessage(
      serverSessionRevoked
          ? 'Berhasil keluar dari akun admin.'
          : 'Sesi perangkat dihapus. '
                'Pencabutan sesi di server belum '
                'terkonfirmasi; token server '
                'mungkin masih berlaku hingga kedaluwarsa.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      hasBottomNav: true,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: AppSpacing.xxl,
            bottom: ScreenScaffold.contentBottomPadding(context),
          ),
          children: [
            Text(
              'Profil',
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(color: AppColors.brand),
            ),

            const SizedBox(height: AppSpacing.s),

            Text(
              'Info aplikasi dan akses pengelola.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: AppSpacing.xl),

            HeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: Icon(
                          Icons.local_parking_rounded,
                          color: AppColors.brand,
                        ),
                      ),

                      const SizedBox(width: AppSpacing.m),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.namaAplikasi,
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Versi ${AppConstants.versi}',
                              style: const TextStyle(
                                color: AppColors.softWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.l),

                  const Text(
                    'Prediksi ketersediaan slot '
                    'parkir 10, 20, dan 30 menit '
                    'menggunakan data historis.',
                    style: TextStyle(color: AppColors.surface, height: 1.5),
                  ),

                  const SizedBox(height: AppSpacing.l),

                  const Text(
                    'Demo historis, bukan '
                    'pemantauan parkir real-time.',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
                      'Tentang Aplikasi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const ListTile(
                      leading: Icon(
                        Icons.analytics_outlined,
                        color: AppColors.brand,
                      ),
                      title: Text('Model prediksi'),
                      trailing: Text('XGBoost'),
                    ),

                    const Divider(),

                    const ListTile(
                      leading: Icon(
                        Icons.storage_rounded,
                        color: AppColors.brand,
                      ),
                      title: Text('Sumber data'),
                      trailing: Text('Frauenfeld 2024'),
                    ),

                    const Divider(),

                    const ListTile(
                      leading: Icon(
                        Icons.history_rounded,
                        color: AppColors.brand,
                      ),
                      title: Text('Mode aplikasi'),
                      trailing: Text('Historis'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.cardGap),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _errorCard()
            else if (_admin == null)
              _loginCard()
            else
              ..._adminContent(),

            if (!_loading && _admin == null && _error == null) ...[
              const SizedBox(height: AppSpacing.cardGap),
              const _HowItWorksCard(),
            ],

            const SizedBox(height: AppSpacing.cardGap),

            const _ImportantNoteCard(),

            const SizedBox(height: AppSpacing.l),

            Center(
              child: Text(
                '${AppConstants.namaAplikasi} · '
                'Versi ${AppConstants.versi}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.statusPenuh),
                SizedBox(width: AppSpacing.s),
                Text(
                  'Gagal Memuat Profil',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.m),

            Text(_error!),

            const SizedBox(height: AppSpacing.m),

            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),

            if (_hasStoredToken) ...[
              const SizedBox(height: AppSpacing.s),

              TextButton.icon(
                onPressed: _loggingOut ? null : _logout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari akun'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _loginCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masuk sebagai Admin',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: AppSpacing.s),

            const Text(
              'Khusus pengelola parkir untuk '
              'rekap, pengaturan, dan kelola admin.',
            ),

            const SizedBox(height: AppSpacing.l),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  context.push('/login-admin');
                },
                icon: const Icon(Icons.admin_panel_settings_rounded),
                label: const Text('Masuk sebagai Admin'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _adminContent() {
    return [
      Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(_admin!.nama),
          subtitle: Text(_admin!.username ?? 'Admin'),
        ),
      ),

      const SizedBox(height: AppSpacing.s),

      for (final entry in const [
        ('Rekap & Akurasi', '/admin/rekap'),
        ('Pengaturan Parkir', '/admin/pengaturan-parkir'),
        ('Kelola Admin', '/admin/kelola-admin'),
        ('Pengaturan Server', '/admin/pengaturan-server'),
      ])
        Card(
          child: ListTile(
            title: Text(entry.$1),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              context.push(entry.$2);
            },
          ),
        ),

      const SizedBox(height: AppSpacing.s),

      OutlinedButton.icon(
        onPressed: _loggingOut ? null : _logout,
        icon: _loggingOut
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(_loggingOut ? 'Keluar...' : 'Keluar'),
      ),
    ];
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.brandSoft,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cara Kerja', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: AppSpacing.m),

            const _HowItWorksStep(
              number: '1',
              title: 'Pilih pengamatan historis',
              detail:
                  'Pilih tanggal dan jam pada '
                  'dataset Frauenfeld tahun 2024.',
            ),

            const _HowItWorksStep(
              number: '2',
              title: 'Tentukan horizon',
              detail:
                  'Pilih 10, 20, atau 30 menit '
                  'untuk menjalankan model XGBoost.',
            ),

            const _HowItWorksStep(
              number: '3',
              title: 'Lihat hasil dan riwayat',
              detail:
                  'Periksa prediksi slot kosong '
                  'dan hasil yang tersimpan.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.detail,
  });

  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.brandSoft,
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.m),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportantNoteCard extends StatelessWidget {
  const _ImportantNoteCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.brand),

            const SizedBox(width: AppSpacing.m),

            Expanded(
              child: Text(
                'Prediksi menggunakan pengamatan '
                'historis tahun 2024, bukan kondisi '
                'parkir real-time. Hasil AI adalah '
                'estimasi dan bukan jaminan '
                'ketersediaan slot.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
