import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/widgets/round_back_button.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../data/repository/parkir_exception.dart';
import '../../services/app_services.dart';

class LoginAdminScreen extends StatefulWidget {
  const LoginAdminScreen({super.key, this.expired = false});

  final bool expired;

  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends State<LoginAdminScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;

  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  String _messageFor(ParkirException error) {
    switch (error.jenis) {
      case JenisGalat.koneksi:
        return 'Tidak dapat menghubungi FastAPI. '
            'Periksa alamat server dan jaringan.';

      case JenisGalat.sesiHabis:
        return 'Sesi tidak valid. Silakan login kembali.';

      case JenisGalat.validasi:
        return error.pesan;

      case JenisGalat.server:
        return 'Backend mengalami kendala: ${error.pesan}';

      case JenisGalat.lainnya:
        return error.pesan;
    }
  }

  Future<void> _login() async {
    if (_loading) return;

    final username = _username.text.trim();
    final password = _password.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Isi username dan password terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await AppServices.repository.login(username, password);

      await AppServices.session.saveToken(result.accessToken);

      AppServices.adminName = result.admin.nama;

      if (!mounted) return;

      context.go('/profil');
    } on ParkirException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _messageFor(error);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
            'Tidak dapat menyelesaikan login. '
            'Periksa koneksi dan penyimpanan sesi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      lightSystemIcons: true,
      backgroundColor: AppColors.splashBackground,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.brandDark,
            AppColors.loginMid,
            AppColors.splashBackground,
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.l),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: RoundBackButton(
              fallbackLocation: '/profil',
              backgroundColor: AppColors.translucentWhite,
              foregroundColor: AppColors.surface,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          const Center(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.brand,
              child: Icon(
                Icons.local_parking_rounded,
                size: 42,
                color: AppColors.surface,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.surface,
              ),
              children: [
                TextSpan(text: 'Masuk sebagai '),
                TextSpan(
                  text: 'Admin',
                  style: TextStyle(color: AppColors.brandBright),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          const Text(
            'Khusus pengelola Parkir Pintar.',
            style: TextStyle(color: AppColors.mutedWhite),
          ),

          const SizedBox(height: AppSpacing.xl),

          _input(
            controller: _username,
            hint: 'Username',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: AppSpacing.l),

          _input(
            controller: _password,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: !_showPassword,
            textInputAction: TextInputAction.done,
            suffix: IconButton(
              tooltip: _showPassword
                  ? 'Sembunyikan password'
                  : 'Lihat password',
              onPressed: _loading
                  ? null
                  : () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
            onSubmitted: (_) => _login(),
          ),

          if (widget.expired) ...[
            const SizedBox(height: AppSpacing.l),
            _message(
              'Sesi admin berakhir. '
              'Silakan login lagi.',
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: AppSpacing.l),
            _message(_error!),
          ],

          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _loading ? null : _login,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: const StadiumBorder(),
              ),
              child: _loading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : const Text('Masuk'),
            ),
          ),

          const SizedBox(height: AppSpacing.l),

          SizedBox(
            height: 48,
            child: TextButton.icon(
              onPressed: _loading
                  ? null
                  : () {
                      context.push('/pengaturan-server');
                    },
              icon: const Icon(
                Icons.settings_ethernet_rounded,
                color: AppColors.surface,
              ),
              label: const Text(
                'Pengaturan Server',
                style: TextStyle(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.m),

          const Text(
            'Jika koneksi gagal atau IP laptop '
            'berubah, periksa Pengaturan Server.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedWhite, fontSize: 12),
          ),

          const SizedBox(height: AppSpacing.l),

          const Text(
            'Pengguna umum tidak perlu login.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedWhite),
          ),
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputAction? textInputAction,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: !_loading,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autocorrect: false,
      enableSuggestions: !obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.brand),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.l,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _message(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.statusPenuh.withAlpha(90),
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.surface),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.surface),
            ),
          ),
        ],
      ),
    );
  }
}
