import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void handleBack(
  BuildContext context, {
  String fallbackLocation = '/beranda',
  VoidCallback? onHome,
}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  final location = GoRouterState.of(context).uri.path;
  if (location == '/beranda') {
    onHome?.call();
  } else {
    context.go(fallbackLocation);
  }
}
