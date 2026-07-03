import '../../../core/database/seeku_database.dart';
import '../../schedule/domain/schedule_models.dart';
import '../domain/import_models.dart';

class ImportRepository {
  const ImportRepository(this._database);

  final SeekuDatabase _database;

  Future<ImportBatch> createExcelBatch({
    required String path,
    required bool saveSnapshot,
  }) {
    throw UnsupportedError('当前 Web 预览版仅支持课表 UI 预览，暂不支持文件导入');
  }

  Future<ImportPreviewSession> createExcelPreview({
    required String path,
    required bool saveSnapshot,
    required Semester semester,
    required Iterable<CourseEntry> existingEntries,
  }) {
    throw UnsupportedError('当前 Web 预览版仅支持 Windows/Android 导入');
  }

  Future<int> confirmImport({
    required int batchId,
    required Iterable<ImportPreviewItem> items,
  }) {
    throw UnsupportedError('当前 Web 预览版仅支持 Windows/Android 导入');
  }

  Future<List<ImportBatch>> getImportBatches() => _database.getImportBatches();
}
