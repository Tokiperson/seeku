import 'package:flutter_test/flutter_test.dart';

import 'package:seeku/core/rules/schedule_rules.dart';
import 'package:seeku/features/import/domain/import_models.dart';
import 'package:seeku/features/schedule/domain/schedule_models.dart';

void main() {
  group('WeekExpressionParser', () {
    test('parses supported CQU week expressions', () {
      expect(
        WeekExpressionParser.parse('[1-16周]'),
        List<int>.generate(16, (index) => index + 1),
      );
      expect(WeekExpressionParser.parse('[1-4,6-9,11-12周]'), [
        1,
        2,
        3,
        4,
        6,
        7,
        8,
        9,
        11,
        12,
      ]);
      expect(WeekExpressionParser.parse('[2,4,6周]'), [2, 4, 6]);
      expect(WeekExpressionParser.parse('[10周]'), [10]);
      expect(WeekExpressionParser.parse('[17-19周]'), [17, 18, 19]);
    });
  });

  group('SectionExpressionParser', () {
    test('parses supported section expressions', () {
      expect(SectionExpressionParser.parse('[1-2节]').start, 1);
      expect(SectionExpressionParser.parse('[1-2节]').end, 2);
      expect(SectionExpressionParser.parse('[10-13节]').start, 10);
      expect(SectionExpressionParser.parse('[10-13节]').end, 13);
      expect(SectionExpressionParser.parse('[1-4节]').start, 1);
      expect(SectionExpressionParser.parse('[1-4节]').end, 4);
    });
  });

  test(
    'ConflictDetector finds same-semester overlapping weeks and sections',
    () {
      const entry = CourseEntry(
        course: Course(id: 1, semesterId: 1, name: '高等数学', source: 'manual'),
        occurrence: CourseOccurrence(
          id: 1,
          courseId: 1,
          weekday: 1,
          startSection: 1,
          endSection: 2,
          weekExpression: '[1-16周]',
          parsedWeeks: [1, 2, 3, 4],
        ),
      );
      const draft = CourseDraft(
        semesterId: 1,
        name: '大学物理',
        weekday: 1,
        startSection: 2,
        endSection: 4,
        weekExpression: '[2周]',
        parsedWeeks: [2],
        source: 'manual',
      );

      final conflicts = const ConflictDetector().detect(
        existingEntries: [entry],
        draft: draft,
      );

      expect(conflicts, hasLength(1));
      expect(conflicts.single.existingEntry.course.name, '高等数学');
    },
  );
}
