# share-it
[![Deploy Front (S3)](https://github.com/ejoonie/share-it/actions/workflows/deploy-front.yml/badge.svg)](https://github.com/ejoonie/share-it/actions/workflows/deploy-front.yml)

## Flutter environment configuration

The Flutter app supports separate development and production configuration via
`--dart-define` values.

### Development

Development is the default environment and points to the local Rails API at
`http://localhost:3001`.

```sh
flutter run --dart-define=APP_ENV=dev
```

You can override the API server when testing on a device or emulator:

```sh
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

### Production

Production uses the production API base URL configured in the app. Replace the
example host with the deployed API host when building a release.

```sh
flutter run --release --dart-define=APP_ENV=prod
```

Use `API_BASE_URL` to target a different production host without changing code:

```sh
flutter build apk --release \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://api.example.com
```

## Production build scripts

Production release builds can be created with the scripts in `scripts/`. Each
script sets `APP_ENV=prod` and accepts an optional `API_BASE_URL` environment
variable to override the configured production API host.

```sh
# Android APK (default)
scripts/build_aos.sh

# Android App Bundle
OUTPUT_TYPE=appbundle scripts/build_aos.sh

# iOS release build without code signing (default)
scripts/build_ios.sh

# Build Android, then iOS
scripts/build_all.sh
```

Additional Flutter build options can be passed after the script command. For
example:

```sh
API_BASE_URL=https://api.example.com scripts/build_aos.sh --build-number 42
```

## Store upload scripts

Yes, store uploads can also be automated from shell scripts after the store
accounts, signing, and API credentials are configured.

- Android uploads use Google Play Developer API through `fastlane supply`.
- iOS uploads use App Store Connect API through `fastlane pilot` and must run on
  macOS with a signed `.ipa`.

```sh
# Upload Android App Bundle to the Google Play internal track
ANDROID_PACKAGE_NAME=com.sharablepiggy.app \
GOOGLE_PLAY_JSON_KEY=/path/to/play-service-account.json \
GOOGLE_PLAY_TRACK=internal \
scripts/upload_android.sh

# Upload a signed iOS IPA to App Store Connect
IOS_APP_IDENTIFIER=com.sharablepiggy.app \
APP_STORE_CONNECT_API_KEY_PATH=/path/to/app-store-connect-api-key.json \
IOS_ARTIFACT_PATH=build/ios/ipa/share_it.ipa \
scripts/upload_ios.sh
```

`ANDROID_ARTIFACT_PATH` defaults to
`build/app/outputs/bundle/release/app-release.aab`, and `IOS_ARTIFACT_PATH` can
be omitted when exactly one `.ipa` exists under `build/ios/ipa/`.

## Design system

The Flutter app uses the warm cream, blue-purple, and coral palette documented in
[the design system guide](doc/design-system.md). Open **Settings → Design system**
(the palette icon, debug builds only), or run the standalone live catalog:

```sh
flutter run -t lib/design_system_preview.dart
```

Import `package:share_it/design_system/design_system.dart` for shared tokens,
components, and `PiggyTheme.light`.

## Signed-out experience

Signed-out users see `WelcomeScreen` without creating an account or requesting
bootstrap data. Both welcome buttons open the existing email login/signup flow;
only successful authentication loads the app. Logout and expired/legacy guest
tokens return to the welcome screen. Connection failures preserve the token and
show a retry action. Incoming links are held until the authenticated screen opens.

Guest creation now returns HTTP 410, and the merge endpoint has been removed.
Historical guest records and the `is_guest` column remain for data preservation
and legacy-token rejection; no database deletion or automatic migration is run.
The app no longer offers access to or merging of historical guest data.

The welcome illustration is bundled at `assets/welcome_piggy.png`. Generation
provenance and the prompt are in [welcome-image.md](doc/welcome-image.md).
