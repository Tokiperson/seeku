import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seeku/app/theme.dart';
import 'package:seeku/core/database/seeku_database.dart';
import 'package:seeku/core/providers/app_providers.dart';
import 'package:seeku/features/import/domain/import_models.dart';
import 'package:seeku/features/openlib/data/cqu_openlib_resource_provider.dart';
import 'package:seeku/features/openlib/domain/openlib_models.dart';
import 'package:seeku/features/schedule/presentation/course_detail_page.dart';

void main() {
  test('database stores Openlib cache rows', () async {
    final database = SeekuDatabase.memory();
    addTearDown(database.close);

    await database.upsertOpenlibResourceCache(
      queryKey: '电路原理',
      cachedAt: DateTime(2026, 7, 8),
      payload: '[]',
    );
    final cache = await database.getOpenlibResourceCache('电路原理');

    expect(cache, isNotNull);
    expect(cache!.payload, '[]');
  });
  test(
    'CQU Openlib provider matches course pages and reuses fresh cache',
    () async {
      final database = SeekuDatabase.memory();
      addTearDown(database.close);
      var fetchCount = 0;
      final provider = CquOpenlibResourceProvider(
        database: database,
        now: () => DateTime(2026, 7, 8),
        fetchText: (uri) async {
          fetchCount++;
          return _searchIndexFixture;
        },
      );

      final first = await provider.search(
        const ResourceSearchQuery(courseName: '电路原理'),
      );
      expect(first, isNotEmpty);

      final cacheAfterFirst = await database.getOpenlibResourceCache('电路原理');
      expect(cacheAfterFirst, isNotNull);
      final second = await provider.search(
        const ResourceSearchQuery(courseName: '电路原理'),
      );

      expect(fetchCount, 1);
      expect(first, isNotEmpty);
      expect(first.first.title, '电路原理');
      expect(
        Uri.decodeFull(first.first.url.toString()),
        'https://cqu-openlib.cn/course/电路原理/',
      );
      expect(second.first.title, first.first.title);
    },
  );

  test(
    'CQU Openlib provider falls back to stale cache on refresh failure',
    () async {
      final database = SeekuDatabase.memory();
      addTearDown(database.close);
      final warmProvider = CquOpenlibResourceProvider(
        database: database,
        cacheMaxAge: const Duration(days: 1),
        now: () => DateTime(2026, 7, 8),
        fetchText: (uri) async => _searchIndexFixture,
      );
      await warmProvider.search(const ResourceSearchQuery(courseName: '电路原理'));

      final offlineProvider = CquOpenlibResourceProvider(
        database: database,
        cacheMaxAge: const Duration(days: 1),
        now: () => DateTime(2026, 7, 10),
        fetchText: (uri) async => throw const FormatException('offline'),
      );

      final resources = await offlineProvider.search(
        const ResourceSearchQuery(courseName: '电路原理'),
      );

      expect(resources, isNotEmpty);
      expect(resources.first.title, '电路原理');
    },
  );

  testWidgets('Course detail shows best Openlib resource link', (tester) async {
    final database = SeekuDatabase.memory();
    addTearDown(database.close);
    await database.seedDefaults();
    final semester = await database.getCurrentSemester();
    final courseId = await database.insertCourseWithOccurrence(
      CourseDraft(
        semesterId: semester!.id,
        name: '电路原理',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        weekExpression: '[1-16周]',
        parsedWeeks: List<int>.generate(16, (index) => index + 1),
        source: 'test',
      ),
    );

    _FakeOpenlibResourceProvider.searchCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          openlibResourceProvider.overrideWithValue(
            const _FakeOpenlibResourceProvider(),
          ),
        ],
        child: MaterialApp(
          theme: buildSeekUTheme(),
          home: CourseDetailPage(courseId: courseId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('相关资源链接'), findsOneWidget);
    expect(find.text('https://cqu-openlib.cn/course/电路原理/'), findsOneWidget);
    expect(find.textContaining('资源来自 CQU-Openlib 检索'), findsOneWidget);
    expect(_FakeOpenlibResourceProvider.searchCount, 1);
  });
}

final _searchIndexFixture = jsonEncode({
  'docs': [
    {'location': 'course/电力系统分析/', 'title': '电力系统分析', 'text': '暂无数据，欢迎贡献'},
    {
      'location': 'course/电路原理/',
      'title': '电路原理',
      'text': '攻略 资源 教材上册 教材习题解答 实验教材 期末试卷 课件',
    },
    {'location': 'life/校园网/', 'title': '校园网', 'text': '生活技巧'},
  ],
});

class _FakeOpenlibResourceProvider extends OpenlibResourceProvider {
  const _FakeOpenlibResourceProvider();

  static int searchCount = 0;

  @override
  Future<List<LearningResource>> search(ResourceSearchQuery query) async {
    searchCount++;
    return [
      LearningResource(
        id: 'course-circuit',
        title: '电路原理',
        url: Uri.parse('https://cqu-openlib.cn/course/电路原理/'),
        summary: '攻略 资源 教材 试卷',
        matchScore: 1,
      ),
    ];
  }
}
