import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seeku/app/theme.dart';
import 'package:seeku/core/database/seeku_database.dart';
import 'package:seeku/core/providers/app_providers.dart';
import 'package:seeku/features/schedule/presentation/desktop_schedule_home_page.dart';

void main() {
  testWidgets(
    'Desktop schedule entry shows right time axis and day switching',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final database = SeekuDatabase.memory();
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            theme: buildSeekUTheme(),
            home: const DesktopScheduleHomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (find.text('稍后').evaluate().isNotEmpty) {
        await tester.tap(find.text('稍后'));
        await tester.pumpAndSettle();
      }

      expect(find.text('SeekU 课表'), findsOneWidget);
      expect(find.text('周视图'), findsOneWidget);
      expect(find.textContaining('22:40-23:25'), findsOneWidget);

      await tester.tap(find.text('日视图'));
      await tester.pumpAndSettle();
      expect(find.text('日视图'), findsOneWidget);
    },
  );
}
