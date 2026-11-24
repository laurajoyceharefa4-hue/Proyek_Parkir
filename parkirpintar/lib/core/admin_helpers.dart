import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repository/parkir_exception.dart';
import '../services/app_services.dart';

Future<void> handleAdminException(BuildContext context, Object error) async {
  if (error is ParkirException && error.jenis == JenisGalat.sesiHabis) {
    await AppServices.session.clear();
    AppServices.adminName = null;
    if (context.mounted) context.go('/login-admin');
  }
}

void showAdminMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> handleAdminError(BuildContext context, Object error) async {
  await handleAdminException(context, error);
  return error is ParkirException && error.jenis == JenisGalat.sesiHabis;
}
