# Contributing to Spearfish

## Build from Source

### Requirements

- macOS 13.0 (Ventura) or later
- Xcode Command Line Tools (`xcode-select --install`)

### Development

```bash
git clone https://github.com/pravinboopathy/spearfish.git
cd spearfish
swift build
swift run
```

### Release Build

```bash
./scripts/build-app.sh    # Creates build/Spearfish.app
./scripts/create-dmg.sh   # Creates build/Spearfish.dmg
```

## Project Structure

```
Sources/
├── App/           # App entry point and delegate
├── Models/        # Data models (AppState, SpearfishWindow, KeybindConfiguration)
├── Services/      # Core logic (WindowService, HotkeyService, SpearfishService)
└── Views/         # UI components (PickerWindow, WindowCardView, ToastView)

Resources/
├── Info.plist             # App bundle configuration
├── Spearfish.entitlements # Entitlements for code signing
└── AppIcon.svg            # App icon source

scripts/
├── build-app.sh   # Build .app bundle
├── create-dmg.sh  # Create DMG installer
└── release.sh     # Full release workflow
```

## Creating a Release

```bash
./scripts/release.sh 1.0.0
```

This will:
1. Update version in Info.plist
2. Build the app and DMG
3. Commit and tag the release
4. Push to GitHub
5. Create a GitHub release with the DMG attached
