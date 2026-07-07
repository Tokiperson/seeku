import 'dart:io' show Platform, exit;

import 'package:flutter/services.dart';

Future<void> exitSeekUApplication() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    exit(0);
  }
  await SystemNavigator.pop();
}
