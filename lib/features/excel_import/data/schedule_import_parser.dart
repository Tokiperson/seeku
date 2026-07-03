import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';

import '../../../core/rules/schedule_rules.dart';
import '../../import/domain/import_models.dart';
import '../../schedule/domain/schedule_models.dart';

class CquScheduleImportParser extends ScheduleImportParser {
  const CquScheduleImportParser();

  @override
  Future<ImportParseResult> parse({
    required String path,
    required Semester semester,
    required Iterable<CourseEntry> existingEntries,
  }) async {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.xlsx')) {
      return _parseRows(
        rows: _readXlsxRows(path),
        semester: semester,
        existingEntries: existingEntries,
      );
    }
    if (lowerPath.endsWith('.csv')) {
      return _parseRows(
        rows: await _readCsvRows(path),
        semester: semester,
        existingEntries: existingEntries,
      );
    }
    if (lowerPath.endsWith('.xls')) {
      throw const FormatException('暂不支持旧版 .xls，请另存为 .xlsx 或 .csv 后导入');
    }
    throw const FormatException('仅支持 .xlsx、.csv 或 .xls 文件');
  }

  List<List<String>> _readXlsxRows(String path) {
    final workbook = Excel.decodeBytes(File(path).readAsBytesSync());
    if (workbook.tables.isEmpty) {
      throw const FormatException('Excel 文件中没有可读取的工作表');
    }
    final sheetName = workbook.tables.keys.first;
    final sheet = workbook.tables[sheetName];
    if (sheet == null) {
      throw const FormatException('无法读取 Excel 第一个工作表');
    }
    return sheet.rows
        .map((row) => row.map(_cellText).toList(growable: false))
        .toList(growable: false);
  }

  Future<List<List<String>>> _readCsvRows(String path) async {
    final text = await File(path).readAsString(encoding: utf8);
    return const CsvMatrixReader().read(text);
  }

  ImportParseResult _parseRows({
    required List<List<String>> rows,
    required Semester semester,
    required Iterable<CourseEntry> existingEntries,
  }) {
    final warnings = <String>[];
    final items = <ImportPreviewItem>[];
    const validator = ImportValidator();
    const conflicts = ConflictDetector();
    final weekdayColumns = _detectWeekdayColumns(rows);

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      for (final column in weekdayColumns.entries) {
        final columnIndex = column.key;
        if (columnIndex >= row.length) {
          continue;
        }
        final cellText = row[columnIndex].trim();
        if (cellText.isEmpty || !cellText.contains('周')) {
          continue;
        }
        if (_isHeaderLine(cellText)) {
          continue;
        }
        for (final line in _courseLines(cellText)) {
          if (_isHeaderLine(line)) {
            continue;
          }
          final draft = _parseCourseLine(
            line: line,
            semesterId: semester.id,
            weekday: column.value,
          );
          if (draft == null) {
            warnings.add(_warning(rowIndex, columnIndex, line));
            continue;
          }
          final validation = validator.validate(draft);
          final detectedConflicts = validation.isValid
              ? conflicts.detect(existingEntries: existingEntries, draft: draft)
              : <ScheduleConflict>[];
          items.add(
            ImportPreviewItem(
              draft: draft,
              validation: validation,
              conflicts: detectedConflicts,
              selected: validation.isValid && detectedConflicts.isEmpty,
            ),
          );
        }
      }
    }

    if (items.isEmpty) {
      warnings.add('没有从文件中解析出可导入课程');
    }
    return ImportParseResult(items: items, warnings: warnings);
  }

  Map<int, int> _detectWeekdayColumns(List<List<String>> rows) {
    final detected = <int, int>{};
    for (final row in rows.take(12)) {
      for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
        final weekday = _weekdayFromText(row[columnIndex]);
        if (weekday != null) {
          detected[columnIndex] = weekday;
        }
      }
      if (detected.length >= 5) {
        return detected;
      }
    }
    return {for (var weekday = 1; weekday <= 7; weekday++) weekday: weekday};
  }

  int? _weekdayFromText(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    const patterns = <int, List<String>>{
      1: ['周一', '星期一', 'Monday'],
      2: ['周二', '星期二', 'Tuesday'],
      3: ['周三', '星期三', 'Wednesday'],
      4: ['周四', '星期四', 'Thursday'],
      5: ['周五', '星期五', 'Friday'],
      6: ['周六', '星期六', 'Saturday'],
      7: ['周日', '星期日', '星期天', 'Sunday'],
    };
    for (final entry in patterns.entries) {
      if (entry.value.any(compact.contains)) {
        return entry.key;
      }
    }
    return null;
  }

  bool _isHeaderLine(String value) {
    final compact = value.trim().replaceAll(RegExp(r'\s+'), '');
    if (compact.isEmpty) {
      return true;
    }
    if (_weekdayFromText(compact) != null && compact.length <= 8) {
      return true;
    }
    return compact == '节次' || compact == '课程' || compact == '时间';
  }

  Iterable<String> _courseLines(String cellText) {
    return cellText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
  }

  CourseDraft? _parseCourseLine({
    required String line,
    required int semesterId,
    required int weekday,
  }) {
    final normalized = line
        .replaceAll('【', '[')
        .replaceAll('】', ']')
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .trim();
    final match = RegExp(
      r'^(.+?)\s*(\[[^\]]*周\])\s*(\[[^\]]+\])\s*(.*)$',
    ).firstMatch(normalized);
    if (match == null) {
      return null;
    }

    final name = match.group(1)!.trim();
    final weekExpression = match.group(2)!.trim();
    final sectionExpression = match.group(3)!.trim();
    final classroom = match.group(4)!.trim();
    try {
      final sections = SectionExpressionParser.parse(sectionExpression);
      final weeks = WeekExpressionParser.parse(weekExpression);
      return CourseDraft(
        semesterId: semesterId,
        name: name,
        classroom: classroom.isEmpty ? null : classroom,
        weekday: weekday,
        startSection: sections.start,
        endSection: sections.end,
        weekExpression: weekExpression,
        parsedWeeks: weeks,
        source: ImportSourceType.excel.name,
      );
    } on FormatException {
      return null;
    }
  }

  String _warning(int rowIndex, int columnIndex, String line) {
    final category = _looksLikeWholeWeek(line) ? '整周/实践/集中周课程暂未自动入库' : '未解析';
    return '第 ${rowIndex + 1} 行第 ${columnIndex + 1} 列$category：$line';
  }

  bool _looksLikeWholeWeek(String line) {
    return line.contains('整周') ||
        line.contains('实践') ||
        line.contains('集中') ||
        line.contains('实习') ||
        !line.contains('节');
  }

  String _cellText(Data? cell) {
    final value = cell?.value;
    return switch (value) {
      null => '',
      TextCellValue(:final value) => value.toString(),
      FormulaCellValue(:final formula) => formula,
      IntCellValue(:final value) => value.toString(),
      DoubleCellValue(:final value) => value.toString(),
      BoolCellValue(:final value) => value ? 'true' : 'false',
      DateCellValue() => value.toString(),
      TimeCellValue() => value.toString(),
      DateTimeCellValue() => value.toString(),
    };
  }
}

class CsvMatrixReader {
  const CsvMatrixReader();

  List<List<String>> read(String text) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentCell = StringBuffer();
    var quoted = false;

    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      final next = index + 1 < text.length ? text[index + 1] : null;
      if (char == '"') {
        if (quoted && next == '"') {
          currentCell.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
        continue;
      }
      if (!quoted && char == ',') {
        currentRow.add(currentCell.toString());
        currentCell.clear();
        continue;
      }
      if (!quoted && (char == '\n' || char == '\r')) {
        if (char == '\r' && next == '\n') {
          index++;
        }
        currentRow.add(currentCell.toString());
        rows.add(List<String>.from(currentRow));
        currentRow.clear();
        currentCell.clear();
        continue;
      }
      currentCell.write(char);
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      rows.add(List<String>.from(currentRow));
    }
    return rows;
  }
}
