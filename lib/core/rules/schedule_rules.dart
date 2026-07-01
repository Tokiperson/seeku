class SectionRange {
  const SectionRange({required this.start, required this.end});

  final int start;
  final int end;
}

class WeekExpressionParser {
  const WeekExpressionParser._();

  static List<int> parse(String expression) {
    final cleaned = expression
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('周', '')
        .replaceAll(' ', '')
        .trim();
    if (cleaned.isEmpty) {
      return const [];
    }

    final weeks = <int>{};
    for (final segment in cleaned.split(',')) {
      if (segment.isEmpty) {
        continue;
      }
      if (segment.contains('-')) {
        final bounds = segment.split('-');
        if (bounds.length != 2) {
          continue;
        }
        final start = int.tryParse(bounds[0]);
        final end = int.tryParse(bounds[1]);
        if (start == null || end == null || start > end) {
          continue;
        }
        weeks.addAll(
          List<int>.generate(end - start + 1, (index) => start + index),
        );
      } else {
        final week = int.tryParse(segment);
        if (week != null) {
          weeks.add(week);
        }
      }
    }

    return weeks.toList()..sort();
  }
}

class SectionExpressionParser {
  const SectionExpressionParser._();

  static SectionRange parse(String expression) {
    final cleaned = expression
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('节', '')
        .replaceAll(' ', '')
        .trim();
    if (cleaned.isEmpty) {
      throw const FormatException('节次表达式不能为空');
    }

    if (cleaned.contains('-')) {
      final bounds = cleaned.split('-');
      if (bounds.length != 2) {
        throw FormatException('无法解析节次表达式: $expression');
      }
      final start = int.parse(bounds[0]);
      final end = int.parse(bounds[1]);
      if (start <= 0 || end < start) {
        throw FormatException('节次范围不合法: $expression');
      }
      return SectionRange(start: start, end: end);
    }

    final section = int.parse(cleaned);
    return SectionRange(start: section, end: section);
  }
}

class TeachingWeekCalculator {
  const TeachingWeekCalculator._();

  static int currentWeek(DateTime semesterStart, DateTime now) {
    final normalizedStart = DateTime(
      semesterStart.year,
      semesterStart.month,
      semesterStart.day,
    );
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final days = normalizedNow.difference(normalizedStart).inDays;
    if (days < 0) {
      return 1;
    }
    return (days ~/ 7) + 1;
  }
}
