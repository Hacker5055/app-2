# Build and release

## Toolchain

| Tool | Version used | Notes |
| ---- | ------------ | ----- |
| Flutter | 3.27.0+ (stable) | Dart 3.6+, `flutter_localizations` |
| JDK | 17 | Required by Android Gradle Plugin 8.x |
| Gradle | 8.10.2 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin | 8.7.3 | `android/settings.gradle` |
| Kotlin | 2.1.0 | `org.jetbrains.kotlin.android` |
| compileSdk / targetSdk | 35 | `flutter_blue_plus 1.35.x` needs ≥ 33 |
| minSdk | 21 | Android 5.0, BLE peripheral mode not required |

`flutter doctor --android-licenses` must have been accepted once. No NDK is required
because the app ships no native C/C++ code — only Dart and a 60-line Kotlin activity.

The repository intentionally does not commit `android/gradlew`, `gradlew.bat` or
`gradle-wrapper.jar` binaries. The Flutter tool injects the wrapper into `android/`
on the first build; if it is missing for any reason, run `flutter create
--platforms=android .` once (existing files, including the manifest, are not
overwritten), or generate it with a local Gradle installation.

## The release build

```bash
flutter clean
flutter pub get
flutter build apk --release --target-platform android-arm64
```

Artifact: `build/app/outputs/flutter-apk/app-release.apk`

Why `--target-platform android-arm64`:

* virtually every phone shipped since 2017 is arm64-v8a,
* the APK carries a single `libflutter.so` + `libapp.so` pair instead of three,
* combined with `minifyEnabled` + `shrinkResources` the result is typically
  **~20–24 MB** rather than ~45 MB for a universal build.

Verify the ABI:

```bash
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep -E "lib/.*\.so"
# lib/arm64-v8a/libapp.so
# lib/arm64-v8a/libflutter.so
```

## Signing

The Gradle script uses `android/key.properties` when present and falls back to the
debug keystore otherwise (so the exact command above always yields an installable
APK). To sign for distribution:

```bash
keytool -genkeypair -v -keystore ~/upload-keystore.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias upload

cp android/key.properties.example android/key.properties
$EDITOR android/key.properties     # storePassword, keyPassword, keyAlias, storeFile
flutter build apk --release --target-platform android-arm64
```

`android/key.properties` and `*.jks` are git-ignored.

## Shrinking

`android/app/build.gradle` enables R8 and resource shrinking for `release`, with the
keep rules in `android/app/proguard-rules.pro` covering:

* `io.flutter.**` embedding + plugin registrant,
* `com.lib.flutter_blue_plus`, `com.baseflow.permissionhandler`,
  `xyz.luan.audioplayers`, `dev.fluttercommunity.plus.**`,
* enum `values()` / `valueOf()` used by platform channel serialisation.

If a release build crashes on a plugin after adding a new dependency, bisect with:

```bash
flutter build apk --release --target-platform android-arm64 --no-shrink
```

## App bundle / split APK

```bash
flutter build appbundle --release            # .aab for Play
flutter build apk --release --split-per-abi  # per-ABI APKs
```

The bundle is configured for `en` and `ar` resources only
(`resourceConfigurations += ["en", "ar"]`), which trims plugin translations.

## Manifest merge checks

```bash
# What actually ends up in the APK
aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
# android.permission.BLUETOOTH_SCAN
# android.permission.BLUETOOTH_CONNECT
# android.permission.ACCESS_FINE_LOCATION (maxSdkVersion=30)
# android.permission.ACCESS_COARSE_LOCATION (maxSdkVersion=30)

aapt dump badging build/app/outputs/flutter-apk/app-release.apk | head -5
```

Confirm that `usesPermissionFlags="neverForLocation"` survived the merge — it appears
in the merged manifest as `android:usesPermissionFlags="neverForLocation"`; `aapt2
dump xmltree --file AndroidManifest.xml <apk>` shows it verbatim.

## CI sketch

```yaml
name: android-release
on: { push: { branches: [main] } }
jobs:
  apk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: '17' }
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: '3.27.0', cache: true }
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk --release --target-platform android-arm64
      - uses: actions/upload-artifact@v4
        with:
          name: bluetooth-finder-radar-arm64
          path: build/app/outputs/flutter-apk/app-release.apk
```

## Versioning

`pubspec.yaml` → `version: 1.0.0+1` (`name+build`). The build number becomes the
Android `versionCode`; bump it for every Play upload. The UI reads
`AppConstants.appVersion` for the footer badge — keep both in sync when releasing.
