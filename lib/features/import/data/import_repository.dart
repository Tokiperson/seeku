import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/seeku_database.dart';
import '../domain/import_models.dart';

class ImportRepository {
  const ImportRepository(this._database);

  final SeekuDatabase _database;

  Future<ImportBatch> createExcelBatch({
    required File file,
    required bool saveSnapshot,
  }) async {
    await _database.ensureInitialized();
    final snapshotPath = saveSnapshot ? await _copySnapshot(file) : null;
    final batchId = await _database.insertImportBatch(
      sourceType: ImportSourceType.excel.name,
      importedAt: DateTime.now(),
      rawSnapshotPath: snapshotPath,
      status: ImportBatchStatus.waitingForSample.name,
    );
    return ImportBatch(
      id: batchId,
      sourceType: ImportSourceType.excel.name,
      importedAt: DateTime.now(),
      rawSnapshotPath: snapshotPath,
      status: ImportBatchStatus.waitingForSample.name,
    );
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
