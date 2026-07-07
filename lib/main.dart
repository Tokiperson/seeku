import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/window_controls.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureSeekUDesktopWindow();
  runApp(const ProviderScope(child: SeekUApp()));
}
