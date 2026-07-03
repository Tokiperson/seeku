import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'android_schedule_home_page.dart';
import 'desktop_schedule_home_page.dart';

class ScheduleHomePage extends StatelessWidget {
  const ScheduleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return const AndroidScheduleHomePage();
    }
    return const DesktopScheduleHomePage();
  }
}
