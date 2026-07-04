import '../../import/domain/import_models.dart';
import '../../schedule/domain/schedule_models.dart';
import '../domain/ai_models.dart';

abstract class ScheduleAiParser {
  const ScheduleAiParser();

  Future<ImportParseResult> parseSchedule({
    required AiScheduleParseRequest request,
    required Semester semester,
    required Iterable<CourseEntry> existingEntries,
  });
}
