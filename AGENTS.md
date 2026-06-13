# AGENTS.md — MyMeds

## Quick commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Lint/static analysis
flutter test             # Run tests (only 1 stale widget test exists)
flutter run              # Run on connected device/emulator
flutter build apk        # Build Android APK
flutter build web        # Build for web (output: build/web/)
firebase deploy           # Deploy hosting + Firestore indexes/rules
```

## Architecture

Flutter app (SDK >=3.0.5) with **Provider** for state management.

```
lib/
  main.dart             # Entry point → inits Firebase, Alarm, NotificationService
  auth/                 # Login gate (auth_page.dart, main_page.dart)
  screens/              # 54 screen files — all UI pages
  components/           # Reusable widgets
  services/             # Firebase Auth, Firestore, Notifications, Alarm, OpenRouter AI, etc.
  models/               # Data models (user_model.dart, incident.dart, autonomy_score.dart)
  l10n/                 # Generated + ARB files (en, fr, ar)
  assets/               # Images, icons
  firebase_options.dart # Auto-generated Firebase config
```

## Firebase

- Project: `zoom-3c767` (see `.firebaserc`)
- Services used: Auth, Firestore, Storage, Messaging, Hosting (web)
- Firestore composite indexes defined in `firestore.indexes.json`
- Web hosting serves from `build/web/` with SPA rewrites

## Localization

- ARB files in `lib/l10n/` (app_en.arb, app_fr.arb, app_ar.arb)
- Codegen outputs to `lib/l10n/app_localizations.dart` via `flutter gen-l10n`
- Config: `l10n.yaml`, `flutter: generate: true` in pubspec.yaml
- Generated files: `app_localizations.dart`, `app_localizations_*.dart` — **do not edit these by hand**

## Build-time code generation

- **Launcher icons**: `dart run flutter_launcher_icons` (config in pubspec.yaml)
- **Native splash**: `dart run flutter_native_splash:create` (config in pubspec.yaml)
- **Localization**: run `flutter gen-l10n` or it runs automatically on `flutter run`/`flutter build`

## Testing

Only `test/widget_test.dart` exists — a boilerplate counter test from `flutter create`. It references the old default counter app and **will fail** against the current app. Run tests with `flutter test`. Firestore/emulator tests do not exist.

## Known gotchas

- **OpenRouter API key** is hardcoded in `lib/services/openrouter_service.dart`. Do not commit changes that expose this further.
- **Alarm** package requires `await Alarm.init()` before `runApp()` — order in `main()` matters.
- `flutter analyze` uses `flutter_lints/flutter.yaml` (standard Flutter lint set), no custom rules.
- The `assets/` folder is at the project root, NOT under `lib/` — both `assets/` and `lib/assets/` contain images.
- Session timeout is managed by `SessionTimeoutService` — inactivity triggers auto-logout.
