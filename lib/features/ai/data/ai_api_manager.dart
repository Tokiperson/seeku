import '../../import/domain/import_models.dart';
import '../../schedule/domain/schedule_models.dart';
import '../domain/ai_models.dart';
import 'moonshot_schedule_parser.dart';
import 'schedule_ai_parser.dart';

abstract class AiApiManager {
  const AiApiManager();

  Future<ImportParseResult> parseScheduleImport({
    required AiScheduleParseRequest request,
    required Semester semester,
    required Iterable<CourseEntry> existingEntries,
  });
}

class DefaultAiApiManager extends AiApiManager {
  const DefaultAiApiManager({
    ScheduleAiParser scheduleParser = const MoonshotScheduleParser(),
  }) : _scheduleParser = scheduleParser;

  final ScheduleAiParser _scheduleParser;

  @override
  Future<ImportParseResult> parseScheduleImport({
    required AiScheduleParseRequest request,
    required Semester semester,
    required Iterable<CourseEntry> existingEntries,
  }) {
    return _scheduleParser.parseSchedule(
      request: request,
      semester: semester,
      existingEntries: existingEntries,
    );
  }
}
