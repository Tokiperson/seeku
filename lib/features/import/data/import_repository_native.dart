import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/seeku_database.dart';
import '../../excel_import/data/schedule_import_parser.dart';
import '../../schedule/domain/schedule_models.dart';
import '../domain/import_models.dart';

class ImportRepository {
  const ImportRepository(
    this._database, {
    ScheduleImportParser parser = const CquScheduleImportParser(),
  }) : _parser = parser;

  final SeekuDatabase _database;
  final ScheduleImportParser _parser;

  Future<ImportBatch> createExcelBatch({
    required String path,
    required bool saveSnapshot,
  }) async {
    await _database.ensureInitialized();
    final importedAt = DateTime.now();
    final file = File(path);
    final snapshotPath = saveSnapshot ? await _copySnapshot(file) : null;
    final batchId = await _database.insertImportBatch(
      sourceType: ImportSourceType.excel.name,
      importedAt: importedAt,
      rawSnapshotPath: snapshotPath,
      status: ImportBatchStatus.waitingForSample.name,
    );
    return ImportBatch(
      id: batchId,
      sourceType: ImportSourceType.excel.name,
      importedAt: importedAt,
      rawSnapshotPath: snapshotPath,
      status: ImportBatchStatus.waitingForSample.name,
    );
  }

  Future<ImportPreviewSession> createExcelPreview({
    required String path,
    required bool saveSnapshot,
    required Semester semester,
    required Iterable<CourseEntry> existingEntries,
  }) async {
    final batch = await createExcelBatch(
      path: path,
      saveSnapshot: saveSnapshot,
    );
    try {
      final result = await _parser.parse(
        path: path,
        semester: semester,
        existingEntries: existingEntries,
      );
      await _database.updateImportBatchStatus(
        batch.id,
        ImportBatchStatus.previewReady.name,
      );
      return ImportPreviewSession(
        batch: batch.copyWith(status: ImportBatchStatus.previewReady.name),
        result: result,
      );
    } on Object {
      await _database.updateImportBatchStatus(
        batch.id,
        ImportBatchStatus.failed.name,
      );
      rethrow;
    }
  }

  Future<int> confirmImport({
    required int batchId,
    required Iterable<ImportPreviewItem> items,
  }) async {
    await _database.ensureInitialized();
    var importedCount = 0;
    for (final item in items) {
      if (!item.selected || !item.canImport) {
        continue;
      }
      await _database.insertCourseWithOccurrence(item.draft);
      importedCount++;
    }
    await _database.updateImportBatchStatus(
      batchId,
      ImportBatchStatus.imported.name,
    );
    return importedCount;
  }

  Future<List<ImportBatch>> getImportBatches() => _database.getImportBatches();

  Future<String> _copySnapshot(File file) async {
    final supportDir = await getApplicationSupportDirectory();
    final snapshotDir = Directory(p.join(supportDir.path, 'import_snapshots'));
    if (!snapshotDir.existsSync()) {
      snapshotDir.createSync(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$timestamp-${p.basename(file.path)}';
    final target = File(p.join(snapshotDir.path, fileName));
    await file.copy(target.path);
    return target.path;
  }
}
