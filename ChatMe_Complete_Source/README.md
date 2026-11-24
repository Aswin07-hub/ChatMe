# ChatMe (formerly SAKTI)

## Setup

```bash
flutter pub get
flutter run
flutter build apk --debug
flutter build apk --release
```

## Environment

Configure `.env` for the ChatMe backend and Firebase project:

- `CHATME_API_URL` (legacy `SAKTI_API_URL` remains accepted)
- `FIREBASE_API_KEY`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_APP_ID`
- `FIREBASE_ANDROID_APP_ID`
- `GOOGLE_SIGN_IN_WEB_CLIENT_ID`

Firebase and Google Sign-In require matching Android credentials for
`com.example.sakti_app`. Add the authorized project app and SHA-1/SHA-256
fingerprints in Firebase, then add/replace `android/app/google-services.json`
and configure the matching OAuth client IDs.

Do not put private backend secrets in `.env`; bundled assets can be extracted
from an APK.

## Validation

- `flutter pub get`: passed
- `flutter analyze`: passed, no issues
- `flutter test`: 3 focused tests passed
- `flutter build apk --debug`: passed
- `flutter build apk --release`: passed

APK outputs:
- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`

AI assistant for Tamil Nadu government schemes - Flutter app (Android).

## Run / build
```bash
flutter pub get
flutter run                                   # debug on a device
flutter build apk --release --split-per-abi   # FAST + small APK (use this!)
```
If Gradle complains about the Android folder, run `flutter create --platforms=android .`
in an empty folder and copy only `lib/`, `assets/`, `pubspec.yaml`, `.env` and
`android/app/src/main/AndroidManifest.xml` into your own project.

## Where this source came from
Recovered from the Dart kernel embedded in your **debug** APK (`kernel_blob.bin`),
so `lib/*.dart` is your original code (+ the fixes below). The original
pubspec.yaml / android folder were not in the APK and were reconstructed.
`applicationId` is still `com.example.sakti_app` so Firebase, Google Sign-In and
phone OTP keep working. Only the visible name is ChatMe.
To change the package id: register a new Android app in Firebase (+ SHA-1/SHA-256) first.

## Performance fixes
* The uploaded APK was a DEBUG build (165 MB, JIT, validation layers) - the main cause of
  "slow". Release builds are several times faster and far smaller.
* Startup: UI shows a splash instantly; .env/Firebase/CSV load behind it
  (before: blank screen until a 570 KB CSV was parsed on the UI thread).
* CSV parsed in a background isolate; scheme search uses pre-lowercased fields and an
  O(1) id map (was lower-casing 4,000+ schemes on every query).
* HTTP: shared keep-alive client, backend warm-up ping, 30 s timeout + one retry,
  "server is waking up" message after 8 s.
* Voice: word highlight no longer rebuilds/re-parses the whole HTML bubble every word;
  idle infinite animation controllers removed.
* Debug `print`s now only run in debug mode.

## UI / UX / bug fixes
* Switching tabs no longer erases the chat (IndexedStack); Android back goes to Home first.
* Double-send / mixed-up replies prevented while a reply is pending.
* Bottom nav unreadable in dark mode (dark red on dark) fixed; theme + language remembered.
* Profile now survives app restarts; Sign Out really signs out of Firebase/Google.
* Login sheet crash after closing (used a dead context) fixed; friendly translated errors;
  digits-only phone/OTP; no setState-after-dispose.
* Drawer shows Sign Out when logged in (was always "Sign in").
* Mic/speech permission asked only when you tap the mic (not at launch).
* Voice highlight broke HTML tags -> now plain-text highlight.
* FAQ matching matched any question containing "what" -> word-overlap scoring.
* Hard-coded English strings localised (Tamil), stale "2024" footer/news dates removed,
  placeholder "Fabia Sakti User" removed, 48 dp tap targets, multi-line input,
  keyboard dismiss on scroll, long-press to select/copy text.

## Security note
`.env` is bundled as an asset, so anyone can extract it from the APK. Put no secret keys
there; keep keys on your backend.
