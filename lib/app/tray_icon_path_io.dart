import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _trayIconAsset = 'windows/runner/resources/app_icon.ico';

Future<String> resolveTrayIconPath() async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}seeku_tray.ico');
  final data = await rootBundle.load(_trayIconAsset);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
