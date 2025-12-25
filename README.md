<div align="center">

# Spearfish

**Fast Window Switching for macOS**

*Stop cycling. Start striking.*

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)](https://github.com/pravinboopathy/spearfish/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/pravinboopathy/spearfish)](https://github.com/pravinboopathy/spearfish/releases/latest)

[Download](https://github.com/pravinboopathy/spearfish/releases/latest) · [Quick Start](#quick-start) · [Configuration](docs/configuration.md)

</div>

---

Tired of mashing `⌘-Tab` through dozens of windows to find the one you need? **Spearfish** is a lightweight macOS menu bar app that lets you mark your most-used windows and jump to them instantly with keyboard shortcuts.

No more cycling. No more hunting. Just strike.

<!-- Add a demo GIF here: ![Spearfish Demo](assets/demo.gif) -->

## Why Spearfish?

- **Instant access** — Jump directly to any marked window in milliseconds
- **Keyboard-driven** — Never leave the keyboard to find a window
- **Lightweight** — Lives quietly in your menu bar, uses minimal resources
- **Customizable** — Configure keybindings to match your workflow
- **9 window slots** — Mark up to 9 windows for instant recall

### Perfect for

- **Developers** juggling terminal, editor, browser, and documentation
- **Designers** switching between creative tools and references
- **Power users** with multi-monitor setups and many open windows
- **Anyone** tired of the ⌘-Tab shuffle

## Quick Start

1. **Mark a window** — Focus any window and press `⌃M`
2. **Do other work** — Switch apps, open new windows, whatever
3. **Jump back** — Press `⌃1` to instantly return to your marked window

That's it. Your most important windows are now one keystroke away.

## Installation

### Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permissions (required for window management)

### Download

1. Download `Spearfish.dmg` from the [latest release](https://github.com/pravinboopathy/spearfish/releases/latest)
2. Open the DMG and drag Spearfish to Applications
3. Run this command in Terminal to allow the unsigned app:
   ```bash
   xattr -cr /Applications/Spearfish.app
   ```
4. Launch Spearfish from Applications
5. Grant Accessibility permissions when prompted:
   - Open **System Settings** → **Privacy & Security** → **Accessibility**
   - Enable **Spearfish** in the list
   - Restart Spearfish

## Keybindings

| Action | Shortcut |
|--------|----------|
| Mark current window | `⌃M` (Ctrl+M) |
| Jump to slot | `⌃1-9` (Ctrl+1-9) |
| Mark to specific slot | `⌃⌥1-9` (Ctrl+Option+1-9) |
| Toggle picker | `⌃H` (Ctrl+H) |
| Close picker | `Escape` or `⌃H` |

All keybindings are customizable. See [Configuration](docs/configuration.md) for details.

## Configuration

Customize keybindings by editing `~/.config/spearfish/config.json`.

See [docs/configuration.md](docs/configuration.md) for all options and examples.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for build instructions and development setup.

## License

MIT
