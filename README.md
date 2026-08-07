# Seed to Supper — Flutter (iOS + Android)

Native Flutter field companion for **From Seed to Supper**.  
Same live API as web + Compose Android. **No FlutterFlow.**

## Identity

| | |
|--|--|
| Bundle / applicationId | `store.mixapps.seedtosupper` |
| Display name | Seed to Supper |
| Version | `1.0.0+1` in `pubspec.yaml` |
| API | `https://mixapps.store/from-seed-to-supper/api/index.php` |

Demo: `grower@seedtosupper.demo` / `garden123`

## Features

- Demo / email login  
- **Today** + complete tasks  
- **Growing** · plant · harvest  
- **Capture** — camera → photo upload  
- **Journal**  
- **More** — beds list, open web map, sign out  

## Local run

```powershell
cd E:\Projects\mix-apps\MiX-Apps-Website\from-seed-to-supper-flutter
flutter pub get
flutter run
# Android APK:
flutter build apk --debug
```

## Codemagic iOS (TestFlight)

1. Create **App ID** + **ASC app** for `store.mixapps.seedtosupper` (if not done).  
2. Push this folder to GitHub (standalone repo recommended).  
3. Codemagic → Add app → select repo → ensure `codemagic.yaml` picked up.  
4. Env group **`global`** (same SpeakEasy secrets):  
   - `CERTIFICATE_PRIVATE_KEY`  
   - `APP_STORE_CONNECT_PRIVATE_KEY`  
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`  
   - `APP_STORE_CONNECT_ISSUER_ID`  
5. Start workflow **`fsts-ios`**.  
6. TestFlight after processing.

Health: `python tools/codemagic-list-apps.py` from monorepo root.

## Process docs

`../from-seed-to-supper/ios-ship/FLUTTERFLOW-CODEMAGIC-PLAYBOOK-2026.md`  
(still useful for Apple/Codemagic health; ignore FlutterFlow UI path)

## Android note

Compose app remains at `from-seed-to-supper-android/`. This Flutter project can also ship Android APKs via workflow `fsts-android`.
