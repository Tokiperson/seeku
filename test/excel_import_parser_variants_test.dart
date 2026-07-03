import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:seeku/features/excel_import/data/schedule_import_parser.dart';
import 'package:seeku/features/schedule/domain/schedule_models.dart';

void main() {
  test(
    'CquScheduleImportParser detects weekday columns in shifted csv',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/seeku_shifted_schedule.csv',
      );
      await file.writeAsString(
        [
          '说明,节次,周一,周二,周三,周四,周五,周六,周日',
          '上午,1-2,,高等数学 [1-16周] [1-2节] D1201,,,,,',
          '上午,3-4,,"大学英语 [1-8周] [3-4节] D2201\n整周实践 [17-18周]",,,,,',
        ].join('\n'),
      );
      const parser = CquScheduleImportParser();
      final result = await parser.parse(
        path: file.path,
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

      expect(result.items, hasLength(2));
      expect(result.items.first.draft.weekday, 2);
      expect(result.items.first.draft.name, '高等数学');
      expect(result.warnings.single, contains('第 3 行第 4 列'));
      expect(result.warnings.single, contains('整周/实践/集中周课程暂未自动入库'));
    },
  );
}
