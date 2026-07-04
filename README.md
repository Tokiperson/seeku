# SeekU 📚✨

> A Windows-first Flutter schedule assistant for Chongqing University students.<br>
> 面向重庆大学学生的本地课表、导入预览与 AI 结构化识别助手。

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.8%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Version](https://img.shields.io/badge/version-0.1.0--snapshot.2-blue)](pubspec.yaml)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

SeekU is an early-stage Flutter app for managing CQU course schedules locally. It focuses on a reliable desktop-first schedule loop: semester data, course editing, week/day views, Excel import, AI-assisted PDF/image import, preview validation, and offline persistence.

中文一句话：SeekU 是一个为重庆大学场景定制的智能课表管理工具，目标是把「导入、校验、查看、编辑、离线保存」做成一个安静可靠的本地闭环。

## Highlights

- 🗓️ **Week / day schedule views** with CQU-style teaching sections.
- 🏫 **Multi-semester local storage** backed by SQLite.
- ✍️ **Manual course CRUD** with detail and edit flows.
- 📥 **Excel / CSV import** with preview, validation, conflict detection, and confirm-to-save.
- 🤖 **AI PDF / image import prototype** through Moonshot / Kimi, always routed into preview before saving.
- 🔑 **Local AI API Key settings** with startup status check and a short built-in trial fallback.
- 🧭 **AI core status button** on the home screen for quick health checks.
- 🧪 **Regression tests** for rules, database behavior, schedule widgets, import parsing, and AI JSON parsing.

## Current Snapshot

Current app version: `0.1.0-snapshot.2+2`

Implemented in this snapshot:

- Real Excel / CSV schedule parsing for the current desensitized CQU sample format.
- Target semester selection before import.
- Removal of visible import-batch history from the import page while keeping internal batch records.
- AI import entry points for PDF and image schedule sources.
- Moonshot / Kimi client skeleton using file upload, `file-extract`, visual input, and JSON Mode.
- Fixed JSON prompt contract for AI schedule extraction.
- Local validation and conflict detection for both Excel and AI-generated drafts.
- Campus inference from imported classroom text: if the first trimmed classroom character is `A-Z` or `a-z`, it is stored as uppercase `campus`; otherwise campus remains empty.
- AI status detection at startup and from the home screen.
- User-configured local AI API Key support.

Still experimental:

- AI import quality depends on the upstream model, network, and PDF/image clarity.
- PDF import currently prioritizes text extraction through Kimi file extraction rather than local OCR/rendering.
- AI Key storage is still plain local preferences and should move to secure storage later.

## Quick Start

### Requirements

- Flutter SDK with Dart `>=3.8.0 <4.0.0`
- Windows development environment for desktop builds
- SQLite runtime available on Windows

### Install and Check

```powershell
flutter pub get
flutter analyze
flutter test
```

### Run on Windows

```powershell
flutter run -d windows
```

The project uses a native-assets hook for SQLite:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: system
      name_windows: winsqlite3
```

If Windows SQLite is missing or misconfigured, desktop startup/build may fail before the app UI appears.

## AI Setup

SeekU can run without AI features. For AI import and AI core checks:

1. Open **Settings**.
2. Fill in a Moonshot / Kimi API Key.
3. Save it locally.
4. Return to the home page and use the AI status button in the lower-right corner.

Behavior:

- If a user API Key is configured, SeekU uses it first and runs a connection check on startup.
- If no key is configured, SeekU reminds the user on every startup.
- A built-in trial key path is allowed only within 5 days from the first app open.
- After 5 days, AI features require a user-provided key.
- AI outputs never write directly into the schedule. They must pass through preview, validation, conflict detection, and user confirmation.

Security note: current API Key persistence uses `shared_preferences` for early development convenience. It is not a secure secret store. See the roadmap below.

## Import Flow

All automatic imports follow the same local pipeline:

```text
Source file
→ optional raw snapshot
→ parser / AI parser
→ CourseDraft[]
→ validation
→ conflict detection
→ user preview
→ confirmed local save
```

Supported sources today:

| Source | Status | Notes |
| --- | --- | --- |
| Excel `.xlsx` | ✅ Working | Parses the current CQU-style matrix sample. |
| CSV `.csv` | ✅ Working | Useful for shifted weekday-column variants. |
| Old Excel `.xls` | ⚠️ Detected | User should convert to `.xlsx` or `.csv`. |
| PDF | 🧪 Experimental | Uploads to Kimi file extraction, then asks the model for structured JSON. |
| Image `.png/.jpg/.jpeg/.webp` | 🧪 Experimental | Uses visual model input and structured JSON output. |
| Teaching web page | 🚧 Planned | WebView / DOM capture is still pending. |

## Project Structure

```text
lib/
  app/                 # App shell, router, theme
  core/                # Database, providers, settings, rules
  features/
    ai/                # AI core status, API client, prompt, JSON parser
    excel_import/      # Excel / CSV schedule parser
    import/            # Import domain models, repository, preview page
    schedule/          # Week/day views, course detail, course form
    settings/          # App settings, semester setup, API Key setup
```

Key files worth knowing:

- [`docs/planningMap.md`](docs/planningMap.md) - roadmap and implementation map.
- [`lib/features/import/domain/import_models.dart`](lib/features/import/domain/import_models.dart) - import draft, validation, conflicts, campus inference.
- [`lib/features/ai/data/moonshot_api_client.dart`](lib/features/ai/data/moonshot_api_client.dart) - Moonshot / Kimi API integration.
- [`lib/features/import/presentation/import_page.dart`](lib/features/import/presentation/import_page.dart) - multi-source import UX.
- [`lib/features/settings/presentation/settings_page.dart`](lib/features/settings/presentation/settings_page.dart) - semester, import, and AI Key settings.

## Roadmap

### v0.1 Local Schedule Loop

- Finish multi-semester management UX.
- Improve import preview editing and failed-item correction.
- Collect more desensitized CQU Excel / PDF / image samples.
- Harden Excel variants, whole-week courses, and special practice courses.
- Add teaching web import through WebView and DOM / HTML capture.

### v0.2 AI and Resource Layer

- Improve AI request logs, retry strategy, error categories, and progress states.
- Migrate API Key storage from `shared_preferences` to secure local storage.
- Add better PDF/image handling, possibly local rendering/OCR fallback.
- Start CQU-Openlib resource linking and summary display.

### Later

- Account system and configuration migration.
- Cloud sync and conflict resolution.
- More complete mobile adaptation.

The living roadmap is maintained in [`docs/planningMap.md`](docs/planningMap.md).

## Development Notes

- Prefer existing feature folders and domain models over new one-off abstractions.
- Import results must not bypass preview confirmation.
- AI outputs are treated as untrusted draft data and must go through local validation.
- Do not commit real API Keys, raw private course data, or personal screenshots.
- `log/`, `AIUsage/`, and `trash/` are local collaboration folders and are ignored by Git.
- If a request asks to delete files, project instructions require moving them to `trash/` first.

## Testing

Run all tests:

```powershell
flutter test
```

Useful coverage areas currently include:

- Schedule grid models and course rules
- Database storage behavior
- Excel / CSV import parser variants
- AI JSON parser behavior
- AI settings trial-window logic
- Desktop and Android widget smoke tests

## Contributing

This project is still moving quickly, so contributions should be small, focused, and aligned with the roadmap.

Recommended flow:

1. Open or discuss an issue / task first.
2. Keep changes scoped to one feature or bug fix.
3. Add or update tests for parser, repository, or UI behavior when applicable.
4. Run `flutter analyze` and `flutter test` before submitting.
5. Never include secrets, private API Keys, or personal schedule data in commits.

## License

SeekU is released under the [MIT License](LICENSE).

## Acknowledgements

- Built with [Flutter](https://flutter.dev/) and [Dart](https://dart.dev/).
- State management by [Riverpod](https://riverpod.dev/).
- Routing by [go_router](https://pub.dev/packages/go_router).
- Local persistence powered by Drift / SQLite.
- AI import prototype targets [Moonshot / Kimi](https://platform.moonshot.cn/) compatible APIs.

---

SeekU is not an official Chongqing University product. It is a student-oriented open-source tool and should be used with care when importing or storing personal schedule data.
