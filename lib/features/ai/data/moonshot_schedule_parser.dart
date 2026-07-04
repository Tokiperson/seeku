import '../../import/domain/import_models.dart';
import '../../schedule/domain/schedule_models.dart';
import '../domain/ai_models.dart';
import 'moonshot_api_client.dart';
import 'schedule_ai_json_parser.dart';
import 'schedule_ai_parser.dart';

class MoonshotScheduleParser extends ScheduleAiParser {
  const MoonshotScheduleParser({
    MoonshotApiClient? client,
    ScheduleAiJsonParser jsonParser = const ScheduleAiJsonParser(),
  }) : _client = client,
       _jsonParser = jsonParser;

  final MoonshotApiClient? _client;
  final ScheduleAiJsonParser _jsonParser;

  @override
  Future<ImportParseResult> parseSchedule({
    required AiScheduleParseRequest request,
    required Semester semester,
    required Iterable<CourseEntry> existingEntries,
  }) async {
    final client = _client ?? MoonshotApiClient();
    final content = switch (request.sourceType) {
      AiScheduleSourceType.pdf => await client.parseSchedulePdf(request.path),
      AiScheduleSourceType.image => await client.parseScheduleImage(
        request.path,
      ),
    };
    return _jsonParser.parse(
      content: content,
      semester: semester,
      existingEntries: existingEntries,
      source: switch (request.sourceType) {
        AiScheduleSourceType.pdf => ImportSourceType.aiPdf.name,
        AiScheduleSourceType.image => ImportSourceType.aiImage.name,
      },
    );
  }
}
