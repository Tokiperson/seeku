import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seeku/app/app.dart';
import 'package:seeku/core/database/seeku_database.dart';
import 'package:seeku/core/providers/app_providers.dart';

void main() {
  testWidgets('SeekU app smoke flow opens schedule, form, and settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final database = SeekuDatabase.memory();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const SeekUApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SeekU 课表'), findsOneWidget);
    expect(find.text('周视图'), findsOneWidget);

    await tester.tap(find.text('日视图'));
    await tester.pumpAndSettle();
    expect(find.textContaining('本日'), findsWidgets);

    await tester.tap(find.byTooltip('新增课程'));
    await tester.pumpAndSettle();
    expect(find.text('新增课程'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    expect(find.text('重庆大学默认节次表'), findsOneWidget);
    expect(find.text('保存导入原始文件'), findsOneWidget);
  });
}
