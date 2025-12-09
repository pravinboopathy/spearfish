# Spearfish

Stop cycling. Start striking.

A macOS menu bar app that lets you mark specific windows and jump to them instantly with keyboard shortcuts.

## Features

- **Mark windows** to numbered slots (1-9) for instant recall
- **Quick jump** to any marked window with a single hotkey
- **Window picker** overlay showing all marked windows
- **Configurable keybindings** with leader modifier support
- **Menu bar app** that stays out of your way

## Installation

### Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permissions (required for window management)

### Build from Source

```bash
git clone https://github.com/pravinboopathy/spearfish.git
cd spearfish
swift build -c release
```

The binary will be at `.build/release/Spearfish`.

## Usage

### Default Keybindings

| Action | Shortcut |
|--------|----------|
| Toggle picker | `⌃H` (Ctrl+H) |
| Mark current window | `⌃M` (Ctrl+M) |
| Quick jump to slot | `⌃1-9` (Ctrl+1-9) |
| Mark to specific slot | `⌃⌥1-9` (Ctrl+Option+1-9) |
| Close picker | `Escape` or `⌃H` |

### Workflow

1. Focus a window you want to mark
2. Press `⌃M` to mark it to the next available slot, or `⌃⌥1` to mark it to slot 1
3. Press `⌃1` to instantly jump back to that window from anywhere
4. Press `⌃H` to see all marked windows in the picker

### Granting Accessibility Permissions

On first launch, Spearfish will prompt you to grant Accessibility permissions:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Enable **Spearfish** in the list
3. Restart Spearfish if needed

## Configuration

Keybindings can be customized. The default leader modifier is `Control`, but you can change it to `Option`, `Command`, or `Shift`.

Configuration options:
- `leaderModifier`: The main modifier key (control, option, command, shift)
- `togglePickerKey`: Key to toggle the picker (default: h)
- `markWindowKey`: Key to mark current window (default: m)
- `quickJumpModifiers`: Additional modifiers for quick jump (default: none)
- `markToPositionModifiers`: Additional modifiers for mark-to-position (default: option)

## Development

### Project Structure

```
Sources/
├── App/           # App entry point and delegate
├── Models/        # Data models (AppState, SpearfishWindow, KeybindConfiguration)
├── Services/      # Core logic (WindowService, HotkeyService, SpearfishService)
└── Views/         # UI components (PickerWindow, WindowCardView, ToastView)
```

### Build Commands

```bash
swift build              # Debug build
swift build -c release   # Release build
swift run                # Build and run
```

## License

MIT
