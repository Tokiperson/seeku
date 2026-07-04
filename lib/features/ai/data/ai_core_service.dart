import '../../../core/settings/settings_repository.dart';
import '../domain/ai_core_models.dart';
import 'moonshot_api_client.dart';

class AiCoreService {
  const AiCoreService();

  Future<AiCoreSnapshot> check(SettingsRepository settings) async {
    final userKey = settings.aiApiKey;
    if (userKey == null) {
      await settings.ensureAiFirstOpenedAt();
      final allowed = settings.isBuiltInTrialAllowed();
      final remaining = settings.builtInTrialRemainingDays();
      if (!allowed) {
        return const AiCoreSnapshot(
          status: AiCoreStatus.trialExpired,
          message: 'AI核心已断开：未配置 API Key，内置试用已到期',
          builtInTrialAllowed: false,
          trialRemainingDays: 0,
        );
      }
      return AiCoreSnapshot(
        status: AiCoreStatus.missingConfig,
        message: 'AI核心已断开：未配置 API Key，可使用内置 API Key 试用 $remaining 天',
        builtInTrialAllowed: true,
        trialRemainingDays: remaining,
      );
    }

    try {
      await MoonshotApiClient(
        apiKeyProvider: () async => userKey,
      ).testConnection();
      return const AiCoreSnapshot(
        status: AiCoreStatus.connected,
        message: 'AI核心正在正常运转',
        usingUserKey: true,
      );
    } on Object catch (error) {
      return AiCoreSnapshot(
        status: AiCoreStatus.disconnected,
        message: 'AI核心已断开：$error',
        usingUserKey: true,
      );
    }
  }
}
