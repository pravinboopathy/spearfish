# Configuration

Spearfish stores its configuration at `~/.config/spearfish/config.json`. Edit this file to customize keybindings.

## Example Configuration

```json
{
  "leaderModifier": "control",
  "markToPositionModifiers": ["option"],
  "markWindowKey": "m",
  "quickJumpModifiers": [],
  "togglePickerKey": "h"
}
```

## Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `leaderModifier` | `control`, `option`, `command`, `shift` | `control` | The main modifier key for all shortcuts |
| `togglePickerKey` | `h`, `m`, `tab`, `escape` | `h` | Key to toggle the picker (with leader) |
| `markWindowKey` | `h`, `m`, `tab`, `escape` | `m` | Key to mark current window (with leader) |
| `quickJumpModifiers` | `[]`, `["shift"]`, `["option"]`, etc. | `[]` | Additional modifiers for quick jump (leader+modifiers+1-9) |
| `markToPositionModifiers` | `["option"]`, `["shift"]`, etc. | `["option"]` | Additional modifiers for mark-to-position (leader+modifiers+1-9) |

## Example: Using Command as Leader

To use `⌘` (Command) instead of `⌃` (Control):

```json
{
  "leaderModifier": "command",
  "markToPositionModifiers": ["option"],
  "markWindowKey": "m",
  "quickJumpModifiers": [],
  "togglePickerKey": "h"
}
```

This changes shortcuts to `⌘H` (picker), `⌘M` (mark), `⌘1-9` (jump), `⌘⌥1-9` (mark to slot).

After editing, restart Spearfish for changes to take effect.
