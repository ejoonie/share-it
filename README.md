# share-it
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
