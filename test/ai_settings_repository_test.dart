import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seeku/core/settings/settings_repository.dart';

void main() {
  test(
    'SettingsRepository stores user AI key and enforces built-in trial window',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final settings = SettingsRepository(preferences);

      await settings.setAiApiKey('  sk-user-local  ');
      expect(settings.aiApiKey, 'sk-user-local');
      expect(settings.hasAiApiKey, isTrue);

      await settings.clearAiApiKey();
      expect(settings.aiApiKey, isNull);

      final openedAt = DateTime(2026, 7, 1, 9);
      await settings.ensureAiFirstOpenedAt(now: openedAt);
      expect(
        settings.isBuiltInTrialAllowed(now: DateTime(2026, 7, 5, 8)),
        isTrue,
      );
      expect(
        settings.builtInTrialRemainingDays(now: DateTime(2026, 7, 5, 8)),
        2,
      );
      expect(
        settings.isBuiltInTrialAllowed(now: DateTime(2026, 7, 6, 9)),
        isFalse,
      );
      expect(
        settings.builtInTrialRemainingDays(now: DateTime(2026, 7, 6, 9)),
        0,
      );
    },
  );
}

