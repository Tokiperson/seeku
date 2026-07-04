import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/settings_repository.dart';
import 'moonshot_embedded_credential.dart';

class AiCredentialResolver {
  const AiCredentialResolver();

  Future<String> resolveApiKey() async {
    final preferences = await SharedPreferences.getInstance();
    final settings = SettingsRepository(preferences);
    final userKey = settings.aiApiKey;
    if (userKey != null) {
      return userKey;
    }

    await settings.ensureAiFirstOpenedAt();
    if (!settings.isBuiltInTrialAllowed()) {
      throw const FormatException('AI API Key 未配置，内置试用已到期，请在设置中配置 API Key');
    }
    return MoonshotEmbeddedCredential.resolveApiKey();
  }
}
