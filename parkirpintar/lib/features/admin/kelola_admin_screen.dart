import 'package:flutter/material.dart';

import '../../core/admin_helpers.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/widgets/admin_screen_scaffold.dart';
import '../../core/widgets/connection_banner.dart';
import '../../core/widgets/skeleton_box.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../data/models/admin.dart';
import '../../data/repository/parkir_exception.dart';
import '../../services/app_services.dart';

class KelolaAdminScreen extends StatefulWidget {
  const KelolaAdminScreen({super.key});

  @override
  State<KelolaAdminScreen> createState() => _KelolaAdminScreenState();
}

class _KelolaAdminScreenState extends State<KelolaAdminScreen> {
  List<Admin> _admins = [];
  int? _currentId;
  bool _loading = true;
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
      final values = await Future.wait<Object>([
        AppServices.repository.getDaftarAdmin(),
        AppServices.repository.me(),
      ]);
      if (!mounted) return;
      setState(() {
        _admins = values[0] as List<Admin>;
        _currentId = (values[1] as Admin).id;
        _loading = false;
      });
    } catch (error) {
      if (await handleAdminError(context, error) || !mounted) return;
      setState(() {
        _error = error is ParkirException && error.jenis == JenisGalat.koneksi
            ? 'koneksi'
            : 'Daftar admin belum bisa dimuat.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AdminScreenScaffold(
    title: 'Kelola ',
    accent: 'Admin',
    subtitle: 'Atur siapa yang bisa mengelola parkir.',
    trailing: IconButton.filled(
      tooltip: 'Tambah Admin',
      onPressed: _addDialog,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.surface,
        minimumSize: const Size(48, 48),
      ),
      icon: const Icon(Icons.add_rounded),
    ),
    children: [
      if (_error == 'koneksi') ConnectionBanner(onRetry: _load, isAdmin: true),
      if (_loading)
        const SkeletonBox(height: 280, animate: false)
      else if (_admins.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text('Belum ada admin.'),
          ),
        )
      else ...[
        Card(
          color: AppColors.brand,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total admin',
                  style: TextStyle(color: AppColors.softWhite),
                ),
                Text(
                  '${_admins.length} admin',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_admins.where((item) => item.aktif).length} aktif',
                  style: const TextStyle(color: AppColors.surface),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        Text('Daftar Admin', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.s),
        ..._admins.map(_adminCard),
      ],
      if (_error != null && _error != 'koneksi')
        TextButton(onPressed: _load, child: Text(_error!)),
    ],
  );

  Widget _adminCard(Admin admin) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.brandSoft,
                child: Icon(Icons.person_rounded, color: AppColors.brand),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.nama,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '@${admin.username ?? '-'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: admin.aktif,
                onChanged: (value) => _changeActive(admin, value),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(
                admin.aktif ? Icons.check_circle : Icons.cancel,
                color: admin.aktif
                    ? AppColors.statusKosong
                    : AppColors.statusPenuh,
                size: 18,
              ),
              label: Text(admin.aktif ? 'Aktif' : 'Nonaktif'),
            ),
          ),
          const Divider(),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _passwordDialog(admin),
                icon: const Icon(Icons.key_rounded),
                label: const Text('Ganti Password'),
              ),
              TextButton.icon(
                onPressed: admin.aktif
                    ? () => _changeActive(admin, false)
                    : () => _changeActive(admin, true),
                icon: Icon(
                  admin.aktif
                      ? Icons.block_rounded
                      : Icons.check_circle_rounded,
                ),
                label: Text(admin.aktif ? 'Nonaktifkan' : 'Aktifkan'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _changeActive(Admin admin, bool active) async {
    if (!active && admin.id == _currentId) {
      showAdminMessage(
        context,
        'Admin yang sedang digunakan tidak dapat dinonaktifkan.',
      );
      return;
    }
    if (!active && _admins.where((item) => item.aktif).length <= 1) {
      showAdminMessage(
        context,
        'Admin aktif terakhir tidak dapat dinonaktifkan.',
      );
      return;
    }
    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => Padding(
          padding: ScreenScaffold.overlayPadding(context),
          child: AlertDialog(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.statusPenuh,
            ),
            title: const Text('Nonaktifkan admin ini?'),
            content: Text(
              '${admin.nama} tidak bisa masuk lagi sampai diaktifkan kembali.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusPenuh,
                ),
                child: const Text('Nonaktifkan'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true) return;
    }
    try {
      await AppServices.repository.setAdminAktif(id: admin.id, aktif: active);
      await _load();
    } catch (error) {
      if (!mounted) return;
      final expired = await handleAdminError(context, error);
      if (!expired && mounted) {
        showAdminMessage(context, 'Perubahan belum tersimpan. Coba lagi.');
      }
    }
  }

  Future<void> _addDialog() async {
    final name = TextEditingController();
    final username = TextEditingController();
    final password = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Padding(
        padding: ScreenScaffold.overlayPadding(context),
        child: _AdminFormDialog(
          title: 'Tambah Admin',
          fields: [
            ('Nama', name),
            ('Username', username),
            ('Password', password),
          ],
        ),
      ),
    );
    if (!mounted) {
      name.dispose();
      username.dispose();
      password.dispose();
      return;
    }
    if (result != true) {
      name.dispose();
      username.dispose();
      password.dispose();
      return;
    }
    if ([
          name,
          username,
          password,
        ].any((controller) => controller.text.trim().isEmpty) ||
        password.text.length < 6) {
      showAdminMessage(
        context,
        'Lengkapi semua isian. Password minimal 6 karakter.',
      );
      name.dispose();
      username.dispose();
      password.dispose();
      return;
    }
    try {
      await AppServices.repository.tambahAdmin(
        nama: name.text.trim(),
        username: username.text.trim(),
        password: password.text,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      final expired = await handleAdminError(context, error);
      if (!expired && mounted) {
        showAdminMessage(
          context,
          error is ParkirException
              ? error.pesan
              : 'Admin belum bisa ditambahkan.',
        );
      }
    } finally {
      name.dispose();
      username.dispose();
      password.dispose();
    }
  }

  Future<void> _passwordDialog(Admin admin) async {
    final password = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Padding(
        padding: ScreenScaffold.overlayPadding(context),
        child: _AdminFormDialog(
          title: 'Ganti Password',
          fields: [('Password baru', password)],
        ),
      ),
    );
    if (!mounted) {
      password.dispose();
      return;
    }
    if (ok != true) {
      password.dispose();
      return;
    }
    if (password.text.length < 6) {
      showAdminMessage(context, 'Password minimal 6 karakter.');
      password.dispose();
      return;
    }
    try {
      await AppServices.repository.gantiPassword(
        id: admin.id,
        passwordBaru: password.text,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      final expired = await handleAdminError(context, error);
      if (!expired && mounted) {
        showAdminMessage(context, 'Password belum bisa diganti. Coba lagi.');
      }
    }
    password.dispose();
  }
}

class _AdminFormDialog extends StatelessWidget {
  const _AdminFormDialog({required this.title, required this.fields});
  final String title;
  final List<(String, TextEditingController)> fields;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final field in fields)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: TextField(
                controller: field.$2,
                obscureText: field.$1.toLowerCase().contains('password'),
                decoration: InputDecoration(labelText: field.$1),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Simpan'),
      ),
    ],
  );
}
