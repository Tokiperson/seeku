import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class SeekUApp extends ConsumerWidget {
  const SeekUApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'SeekU',
      debugShowCheckedModeBanner: false,
      theme: buildSeekUTheme(),
      routerConfig: router,
    );
  }
}
