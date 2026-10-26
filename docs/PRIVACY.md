# Privacy

Bluetooth Finder Radar is an offline tool. It does not have an internet permission,
so it cannot send anything anywhere — this is enforced by the Android manifest, not
just by policy.

## What is processed

| Data | Where it lives | Retention |
| ---- | -------------- | --------- |
| BLE advertisements (id, name, RSSI, manufacturer data, service UUIDs) | memory only | dropped 18 s after the device stops advertising |
| Signal history for sparklines (48 samples/device) | memory only | discarded when the app closes |
| Preferences (mock mode, units, language, sound, haptics, calibration) | `shared_preferences` on device | until you clear app data |
| Sweep samples (heading + RSSI) | memory only | discarded when the sheet closes |

Nothing is uploaded. No account, no analytics SDK, no advertising identifier, no
crash reporter, no remote config.

## Location

The app never requests or reads location and never derives coordinates. On Android 12+
`BLUETOOTH_SCAN` is declared with `android:usesPermissionFlags="neverForLocation"`,
which also tells the Play Store that no location declaration is required.

On Android 11 and lower the operating system itself requires a location permission to
perform a BLE scan. The app asks for `ACCESS_FINE_LOCATION` only on those versions
(`maxSdkVersion="30"`), uses it exclusively to obtain scan results, and never stores or
transmits a position. The permission gate explains this on screen.

## Backups

`android:allowBackup="false"`, `fullBackupContent="false"` and
`dataExtractionRules` exclude preferences from both cloud backup and device-to-device
transfer.

## Third parties

The app speaks only to the Android Bluetooth stack and the local audio/haptics APIs.
There is no network client in the dependency list (`flutter_blue_plus`,
`permission_handler`, `device_info_plus`, `flutter_compass`, `provider`,
`shared_preferences`, `audioplayers`, `confetti`); none of them require internet.

## Permissions summary

| Permission | Why |
| ---------- | --- |
| `BLUETOOTH_SCAN` (neverForLocation) | discover advertisements |
| `BLUETOOTH_CONNECT` | read device names, discover GATT services, optional find-my alert |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` (≤ API 30 only) | legacy scan requirement on Android 11 and lower |
| `BLUETOOTH` / `BLUETOOTH_ADMIN` (≤ API 30 only) | legacy adapter control |
| `FLAG_KEEP_SCREEN_ON` (not a permission) | keep the radar visible while walking |

No storage, camera, microphone, contacts, phone-state or internet permissions.
