import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seeku/app/theme.dart';
import 'package:seeku/core/database/seeku_database.dart';
import 'package:seeku/core/providers/app_providers.dart';
import 'package:seeku/features/schedule/presentation/android_schedule_home_page.dart';

void main() {
  testWidgets(
    'Android schedule entry shows mobile navigation and left time axis',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final database = SeekuDatabase.memory();
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            theme: buildSeekUTheme(),
            home: const AndroidScheduleHomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('当前课程'), findsOneWidget);
      expect(find.text('课表'), findsOneWidget);
      expect(find.text('添加'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
      expect(find.textContaining('22:40-23:25'), findsOneWidget);
    },
  );
}
