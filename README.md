<div align="center">

# Spearfish

**Stop cycling. Start striking.**

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)](https://github.com/pravinboopathy/spearfish/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/pravinboopathy/spearfish)](https://github.com/pravinboopathy/spearfish/releases/latest)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Resources/SpearfishIcon-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="Resources/SpearfishIcon-light.svg">
  <img src="Resources/SpearfishIcon-light.svg" alt="Spearfish" width="200">
</picture>

[Download](https://github.com/pravinboopathy/spearfish/releases/latest) · [Quick Start](#quick-start) · [Configuration](docs/configuration.md)

</div>

---

A fast, keyboard-driven **window switcher for macOS**. Inspired by [Harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2), Spearfish lets you mark windows and jump to them instantly — no more cycling through `⌘-Tab`.

**Spearfish** is a lightweight menu bar app that brings Harpoon-style navigation to your desktop. Mark your most important windows, assign them to slots, and switch between them with a single keystroke. Perfect for developers, designers, and power users who want a better **macOS window manager** alternative.

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
3. Launch Spearfish from Applications
4. Grant Accessibility permissions when prompted:
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

## Inspiration

Spearfish is inspired by [Harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2), the beloved Neovim plugin by [ThePrimeagen](https://github.com/ThePrimeagen) for marking and jumping between files. If you've ever wished you could harpoon your macOS windows the same way you harpoon buffers in Neovim, Spearfish is for you.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for build instructions and development setup.

## License

MIT
