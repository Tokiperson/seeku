import 'dart:convert';

import '../../../core/rules/schedule_rules.dart';
import '../../import/domain/import_models.dart';
import '../../schedule/domain/schedule_models.dart';

class ScheduleAiJsonParser {
  const ScheduleAiJsonParser();

  ImportParseResult parse({
    required String content,
    required Semester semester,
    required Iterable<CourseEntry> existingEntries,
    required String source,
  }) {
    final warnings = <String>[];
    final decoded = _decodeObject(content);
    final rawWarnings = decoded['warnings'];
    if (rawWarnings is List) {
      warnings.addAll(
        rawWarnings
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty),
      );
    }

    final rawCourses = decoded['courses'];
    if (rawCourses is! List) {
      throw const FormatException('AI 返回 JSON 中缺少 courses 数组');
    }

    const validator = ImportValidator();
    const conflictDetector = ConflictDetector();
    final items = <ImportPreviewItem>[];
    for (var index = 0; index < rawCourses.length; index++) {
      final rawCourse = rawCourses[index];
      if (rawCourse is! Map) {
        warnings.add('第 ${index + 1} 条课程不是 JSON Object，已忽略');
        continue;
      }
      final courseWarnings = <String>[];
      final draft = _draftFromMap(
        rawCourse.cast<Object?, Object?>(),
        semester: semester,
        source: source,
        index: index,
        warnings: courseWarnings,
      );
      warnings.addAll(courseWarnings);
      final validation = validator.validate(draft);
      final conflicts = validation.isValid
          ? conflictDetector.detect(
              existingEntries: existingEntries,
              draft: draft,
            )
          : <ScheduleConflict>[];
      items.add(
        ImportPreviewItem(
          draft: draft,
          validation: validation,
          conflicts: conflicts,
          selected: validation.isValid && conflicts.isEmpty,
        ),
      );
    }

    if (items.isEmpty) {
      warnings.add('AI 未返回可预览课程');
    }
    return ImportParseResult(items: items, warnings: warnings);
  }

  Map<String, Object?> _decodeObject(String content) {
    final trimmed = _stripMarkdownFence(content.trim());
    final decoded = jsonDecode(trimmed);
    if (decoded is! Map) {
      throw const FormatException('AI 返回内容不是 JSON Object');
    }
    return decoded.cast<String, Object?>();
  }

  String _stripMarkdownFence(String value) {
    if (!value.startsWith('```')) {
      return value;
    }
    final firstLineEnd = value.indexOf('\n');
    if (firstLineEnd < 0) {
      return value;
    }
    var body = value.substring(firstLineEnd + 1).trim();
    if (body.endsWith('```')) {
      body = body.substring(0, body.length - 3).trim();
    }
    return body;
  }

  CourseDraft _draftFromMap(
    Map<Object?, Object?> map, {
    required Semester semester,
    required String source,
    required int index,
    required List<String> warnings,
  }) {
    final classroom = _nullableText(map['classroom']);
    final weekExpression = _text(map['weekExpression']);
    final parsedWeeks = _parseWeeks(
      weekExpression,
      index: index,
      warnings: warnings,
    );
    return CourseDraft(
      semesterId: semester.id,
      name: _text(map['name']),
      code: _nullableText(map['code']),
      category: _nullableText(map['category']),
      teacher: _nullableText(map['teacher']),
      note: _nullableText(map['note']),
      classroom: classroom,
      campus: CampusInference.fromClassroom(classroom),
      weekday: _intValue(map['weekday']),
      startSection: _intValue(map['startSection']),
      endSection: _intValue(map['endSection']),
      weekExpression: weekExpression,
      parsedWeeks: parsedWeeks,
      source: source,
    );
  }

  List<int> _parseWeeks(
    String expression, {
    required int index,
    required List<String> warnings,
  }) {
    if (expression.trim().isEmpty) {
      return const [];
    }
    try {
      final weeks = WeekExpressionParser.parse(expression);
      if (weeks.isEmpty) {
        warnings.add('第 ${index + 1} 条课程周次无法解析：$expression');
      }
      return weeks;
    } on FormatException catch (error) {
      warnings.add('第 ${index + 1} 条课程周次无法解析：${error.message}');
      return const [];
    }
  }

  int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  String _text(Object? value) => value?.toString().trim() ?? '';

  String? _nullableText(Object? value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }
}
