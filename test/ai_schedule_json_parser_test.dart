import 'package:flutter_test/flutter_test.dart';
import 'package:seeku/features/ai/data/schedule_ai_json_parser.dart';
import 'package:seeku/features/import/domain/import_models.dart';
import 'package:seeku/features/schedule/domain/schedule_models.dart';

void main() {
  const parser = ScheduleAiJsonParser();
  final semester = Semester(
    id: 1,
    name: '2025-2026 第二学期',
    academicYear: '2025-2026',
    termIndex: 2,
    startsOn: DateTime(2026, 2, 23),
    isCurrent: true,
  );

  test('parses AI schedule JSON into preview items', () {
    final result = parser.parse(
      content: '''
      {
        "courses": [
          {
            "name": "数据库系统",
            "code": "CSE1001",
            "teacher": "张老师",
            "category": "专业课",
            "classroom": "a5201",
            "weekday": 3,
            "startSection": 5,
            "endSection": 6,
            "weekExpression": "[1-16周]",
            "note": ""
          }
        ],
        "warnings": ["整周实践需手动录入"]
      }
      ''',
      semester: semester,
      existingEntries: const [],
      source: ImportSourceType.aiPdf.name,
    );

    expect(result.items, hasLength(1));
    final draft = result.items.single.draft;
    expect(draft.name, '数据库系统');
    expect(draft.classroom, 'a5201');
    expect(draft.campus, 'A');
    expect(draft.parsedWeeks, List<int>.generate(16, (index) => index + 1));
    expect(result.items.single.selected, isTrue);
    expect(result.warnings.single, '整周实践需手动录入');
  });

  test('keeps invalid AI courses in preview as unselectable items', () {
    final result = parser.parse(
      content: '''
      ```json
      {
        "courses": [
          {
            "name": "",
            "classroom": "虎溪 D123",
            "weekday": "0",
            "startSection": "0",
            "endSection": "0",
            "weekExpression": "待确认"
          }
        ],
        "warnings": []
      }
      ```
      ''',
      semester: semester,
      existingEntries: const [],
      source: ImportSourceType.aiImage.name,
    );

    expect(result.items, hasLength(1));
    final item = result.items.single;
    expect(item.draft.campus, isNull);
    expect(item.canImport, isFalse);
    expect(item.selected, isFalse);
    expect(item.validation.errors, contains('课程名不能为空'));
    expect(item.validation.errors, contains('星期必须在 1 到 7 之间'));
    expect(item.validation.errors, contains('节次范围不合法'));
    expect(item.validation.errors, contains('周次不能为空'));
    expect(result.warnings.single, contains('周次无法解析'));
  });

  test('detects conflicts for valid AI courses', () {
    final existing = CourseEntry(
      course: const Course(
        id: 1,
        semesterId: 1,
        name: '高等数学',
        source: 'manual',
      ),
      occurrence: const CourseOccurrence(
        id: 1,
        courseId: 1,
        weekday: 2,
        startSection: 1,
        endSection: 2,
        weekExpression: '[1-16周]',
        parsedWeeks: [1, 2, 3],
      ),
    );

    final result = parser.parse(
      content: '''
      {
        "courses": [
          {
            "name": "线性代数",
            "classroom": "D1201",
            "weekday": 2,
            "startSection": 2,
            "endSection": 3,
            "weekExpression": "[2周]"
          }
        ],
        "warnings": []
      }
      ''',
      semester: semester,
      existingEntries: [existing],
      source: ImportSourceType.aiPdf.name,
    );

    expect(result.items.single.hasConflicts, isTrue);
    expect(result.items.single.selected, isFalse);
  });
}
