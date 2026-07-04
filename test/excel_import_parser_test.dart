import 'package:flutter_test/flutter_test.dart';
import 'package:seeku/features/excel_import/data/schedule_import_parser.dart';
import 'package:seeku/features/schedule/domain/schedule_models.dart';

void main() {
  test(
    'CquScheduleImportParser parses the desensitized xlsx fixture',
    () async {
      const parser = CquScheduleImportParser();
      final result = await parser.parse(
        path: 'test/fixtures/import/cqu_schedule_basic.xlsx',
        semester: Semester(
          id: 1,
          name: '2025-2026 第二学期',
          academicYear: '2025-2026',
          termIndex: 2,
          startsOn: DateTime(2026, 2, 23),
          isCurrent: true,
        ),
        existingEntries: const [],
      );

      expect(result.items, hasLength(33));
      expect(result.warnings, isNotEmpty);

      final first = result.items.first.draft;
      expect(first.name, '计算机组成与结构');
      expect(first.weekday, 2);
      expect(first.startSection, 1);
      expect(first.endSection, 2);
      expect(first.parsedWeeks, [1, 2, 3, 4, 6, 7, 8, 9, 11, 12]);
      expect(first.classroom, 'D1344');
      expect(first.campus, 'D');

      final longSection = result.items
          .map((item) => item.draft)
          .firstWhere(
            (draft) => draft.name == '计算机网络' && draft.startSection == 10,
          );
      expect(longSection.endSection, 13);
    },
  );
}
