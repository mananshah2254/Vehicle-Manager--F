# How to Run the Vehicle Manager Project

## Prerequisites

1. **Install Flutter SDK**
   - Download from: https://flutter.dev/docs/get-started/install
   - Make sure Flutter is in your PATH
   - Verify installation: `flutter doctor`

2. **For iOS Development** (macOS only):
   - Install Xcode from the App Store
   - Run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
   - Accept Xcode license: `sudo xcodebuild -runFirstLaunch`

3. **For Web Development**:
   - Chrome browser (already installed on most systems)

## Setup Steps

1. **Navigate to project directory:**
   ```bash
   cd /Users/mananshah/vehicle_manager
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Check available devices:**
   ```bash
   flutter devices
   ```

## Running the App

### Option 1: Run on Web (Easiest)
```bash
flutter run -d chrome
```

### Option 2: Run on iOS Simulator
```bash
# First, open iOS Simulator (if not already open)
open -a Simulator

# Then run the app
flutter run -d ios
```

### Option 3: Run on Connected iOS Device
```bash
# Connect your iPhone via USB
# Trust the computer on your iPhone when prompted
flutter run -d ios
```

### Option 4: Let Flutter choose automatically
```bash
flutter run
```

## Troubleshooting

### If Flutter command not found:
- Add Flutter to your PATH in `~/.zshrc`:
  ```bash
  export PATH="$PATH:/path/to/flutter/bin"
  ```
- Then run: `source ~/.zshrc`

### If dependencies fail:
```bash
flutter clean
flutter pub get
```

### If iOS build fails:
```bash
cd ios
pod install
cd ..
flutter run -d ios
```

## Quick Test

After running, you should see:
1. Login screen with email/password fields
2. Sign up option to create an account
3. Dashboard to manage vehicles after login

## Code Status

✅ All code is properly formatted and has no errors
✅ All imports are correct
✅ Dependencies are properly configured

