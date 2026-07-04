enum AiPurpose { scheduleImport }

enum AiScheduleSourceType { pdf, image }

class AiProviderConfig {
  const AiProviderConfig({
    required this.providerName,
    required this.baseUrl,
    required this.model,
  });

  final String providerName;
  final String baseUrl;
  final String model;
}

class AiScheduleParseRequest {
  const AiScheduleParseRequest({required this.path, required this.sourceType});

  final String path;
  final AiScheduleSourceType sourceType;
}
