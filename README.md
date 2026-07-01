# SeekU

SeekU is a Flutter schedule assistant for Chongqing University students. The v0.1alpha build focuses on a Windows desktop local schedule loop: semesters, course editing, week/day views, local persistence, settings, and the first import pipeline shell.

## v0.1alpha scope

- Windows-first Flutter app.
- CQU blue-white visual direction with neutral surfaces and status colors.
- Multi-semester local schedule storage.
- Week view, day view, current date/current section highlighting.
- Manual course create, edit, detail, and delete flows.
- Editable default teaching time slots.
- Excel import entry point with file selection, import batch creation, optional source snapshot saving, and a preview placeholder until a desensitized sample format is available.

Out of scope for v0.1alpha: Android release, real Excel parsing, teaching WebView import, PDF/OCR import, AI parsing, Openlib recommendations, account system, and cloud sync.

## Development

```powershell
flutter pub get
flutter analyze
flutter test
```

The app uses `go_router`, `flutter_riverpod`, Drift-backed SQLite, and `shared_preferences`. Drift is wired through custom SQL in v0.1alpha to avoid a generated-code step while the domain model is still settling.
