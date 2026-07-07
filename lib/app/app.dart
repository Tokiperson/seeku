import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import 'router.dart';
import 'theme.dart';
import 'user_agreement_gate.dart';

class SeekUApp extends ConsumerWidget {
  const SeekUApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    final settings = switch (settingsAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };
    return MaterialApp.router(
      title: 'SeekU',
      debugShowCheckedModeBanner: false,
      theme: buildSeekUTheme(
        primaryColor: Color(settings?.primaryColorValue ?? 0xFF005BAC),
        fontScale: settings?.fontScale ?? 1,
      ),
      routerConfig: router,
      builder: (context, child) =>
          UserAgreementGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
