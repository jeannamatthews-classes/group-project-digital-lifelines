# Digital Lifelines — Setup & Run Guide

This guide walks you through getting the app running on your own machine and device, whether you're on Android or iOS.

## 1. Prerequisites

Install these first:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- [Git](https://git-scm.com/downloads)
- **For Android:** [Android Studio](https://developer.android.com/studio) (includes Android SDK)
- **For iOS:** A Mac with [Xcode](https://apps.apple.com/us/app/xcode/id497799835) installed, plus [CocoaPods](https://cocoapods.org/):
```bash
  sudo gem install cocoapods
```

Check your setup is healthy:
```bash
flutter doctor
```
Fix anything marked with a red ✗ before continuing.

## 2. Clone the repo

```bash
git clone https://github.com/Ashikahamedpranto/digital-lifelines.git
cd digital-lifelines
```

## 3. Install dependencies

```bash
flutter pub get
```

**iOS only** — also install CocoaPods dependencies:
```bash
cd ios
pod install
cd ..
```

## 4. Run the app

**Check connected devices/emulators:**
```bash
flutter devices
```

**Run on a specific device:**
```bash
flutter run -d <device-id>
```

This launches the app in debug mode. Keep the terminal open — closing it or unplugging will stop the app (this is normal for debug mode).

## 5. Install it permanently (so it survives unplugging)

**Android:**
```bash
flutter build apk --release
flutter install -d <device-id>
```

**iOS:**
```bash
flutter build ios --release
flutter install -d <device-id>
```

> **iOS note:** Xcode will ask you to sign in with an Apple ID the first time, to sign the app. A free personal Apple ID works, but the app will expire after 7 days and need reinstalling.

**First launch on iOS** may show an "Untrusted Developer" warning. Fix it via:
`Settings → General → VPN & Device Management → [Developer Profile] → Trust`

## 6. Common issues

| Problem | Fix |
|---|---|
| `flutter doctor` shows Xcode issues | Run `sudo xcode-select --switch /Applications/Xcode.app` |
| Build fails with "no space left" | Clear derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData` |
| App won't install on iPhone | Open `ios/Runner.xcworkspace` in Xcode and hit Run once directly |
| Two devices building at once fails | Run `flutter run` on one device at a time, not simultaneously |

## Questions?
If you run into any issues not covered here, just ask Ashik.
