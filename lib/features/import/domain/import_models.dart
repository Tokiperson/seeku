import '../../schedule/domain/schedule_models.dart';

enum ImportSourceType { excel, teachingWeb, manual }

enum ImportBatchStatus { waitingForSample, previewReady, imported, failed }

class ImportSource {
  const ImportSource({
    required this.type,
    required this.displayName,
    required this.originalPath,
    required this.contentType,
  });

  final ImportSourceType type;
  final String displayName;
  final String originalPath;
  final String contentType;
}

class RawImportSnapshot {
  const RawImportSnapshot({
    required this.originalPath,
    this.snapshotPath,
    required this.contentType,
    required this.savedCopy,
  });

  final String originalPath;
  final String? snapshotPath;
  final String contentType;
  final bool savedCopy;
}

class ImportBatch {
  const ImportBatch({
    required this.id,
    required this.sourceType,
    required this.importedAt,
    this.rawSnapshotPath,
    required this.status,
  });

  final int id;
  final String sourceType;
  final DateTime importedAt;
  final String? rawSnapshotPath;
  final String status;

  ImportBatch copyWith({String? status}) {
    return ImportBatch(
      id: id,
      sourceType: sourceType,
      importedAt: importedAt,
      rawSnapshotPath: rawSnapshotPath,
      status: status ?? this.status,
    );
  }
}

class CourseDraft {
  const CourseDraft({
    required this.semesterId,
    required this.name,
    this.code,
    this.category,
    this.teacher,
    this.note,
    this.classroom,
    this.campus,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.weekExpression,
    required this.parsedWeeks,
    required this.source,
  });

  final int semesterId;
  final String name;
  final String? code;
  final String? category;
  final String? teacher;
  final String? note;
  final String? classroom;
  final String? campus;
  final int weekday;
  final int startSection;
  final int endSection;
  final String weekExpression;
  final List<int> parsedWeeks;
  final String source;
}

class ImportValidationResult {
  const ImportValidationResult({required this.errors});

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

class ImportValidator {
  const ImportValidator();

  ImportValidationResult validate(CourseDraft draft) {
    final errors = <String>[];
    if (draft.name.trim().isEmpty) {
      errors.add('课程名不能为空');
    }
    if (draft.semesterId <= 0) {
      errors.add('课程必须绑定到学期');
    }
    if (draft.weekday < 1 || draft.weekday > 7) {
      errors.add('星期必须在 1 到 7 之间');
    }
    if (draft.startSection <= 0 || draft.endSection < draft.startSection) {
      errors.add('节次范围不合法');
    }
    if (draft.endSection > 13) {
      errors.add('节次不能超过第 13 节');
    }
    if (draft.parsedWeeks.isEmpty) {
      errors.add('周次不能为空');
    }
    return ImportValidationResult(errors: errors);
  }
}

class ScheduleConflict {
  const ScheduleConflict({required this.existingEntry, required this.draft});

  final CourseEntry existingEntry;
  final CourseDraft draft;
}

class ImportPreviewItem {
  const ImportPreviewItem({
    required this.draft,
    required this.validation,
    required this.conflicts,
    required this.selected,
  });

  final CourseDraft draft;
  final ImportValidationResult validation;
  final List<ScheduleConflict> conflicts;
  final bool selected;

  bool get canImport => validation.isValid;
  bool get hasConflicts => conflicts.isNotEmpty;

  ImportPreviewItem copyWith({bool? selected}) {
    return ImportPreviewItem(
      draft: draft,
      validation: validation,
      conflicts: conflicts,
      selected: selected ?? this.selected,
    );
  }
}

class ImportParseResult {
  const ImportParseResult({required this.items, required this.warnings});

  final List<ImportPreviewItem> items;
  final List<String> warnings;
}

class ImportPreviewSession {
  const ImportPreviewSession({required this.batch, required this.result});

  final ImportBatch batch;
  final ImportParseResult result;
}

abstract class ScheduleImportParser {
  const ScheduleImportParser();

  Future<ImportParseResult> parse({
    required String path,
    required Semester semester,
    required Iterable<CourseEntry> existingEntries,
  });
}

class ConflictDetector {
  const ConflictDetector();

  List<ScheduleConflict> detect({
    required Iterable<CourseEntry> existingEntries,
    required CourseDraft draft,
  }) {
    final conflicts = <ScheduleConflict>[];
    for (final entry in existingEntries) {
      if (entry.course.semesterId != draft.semesterId) {
        continue;
      }
      if (entry.occurrence.weekday != draft.weekday) {
        continue;
      }
      final weeksOverlap = entry.occurrence.parsedWeeks.any(
        draft.parsedWeeks.contains,
      );
      if (!weeksOverlap) {
        continue;
      }
      final sectionsOverlap =
          draft.startSection <= entry.occurrence.endSection &&
          draft.endSection >= entry.occurrence.startSection;
      if (sectionsOverlap) {
        conflicts.add(ScheduleConflict(existingEntry: entry, draft: draft));
      }
    }
    return conflicts;
  }
}
