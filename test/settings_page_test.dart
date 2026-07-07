import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seeku/app/build_info.dart';
import 'package:seeku/app/theme.dart';
import 'package:seeku/core/database/seeku_database.dart';
import 'package:seeku/core/providers/app_providers.dart';
import 'package:seeku/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('Settings page switches to about page with version text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final database = SeekuDatabase.memory();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: buildSeekUTheme(),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('课表设置'), findsWidgets);
    await tester.tap(find.text('关于软件').first);
    await tester.pumpAndSettle();

    expect(find.text(SeekUBuildInfo.displayVersion), findsOneWidget);
    expect(find.text('关于SeekU'), findsOneWidget);
    expect(find.text('用户协议'), findsOneWidget);

    await tester.tap(find.text('用户协议'));
    await tester.pumpAndSettle();
    expect(find.text('SeekU 用户协议'), findsWidgets);
    expect(find.textContaining('请您务必审慎阅读'), findsWidgets);
  });
}
