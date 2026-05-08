# CLI

```text
trexbar-sway config init|validate
trexbar-sway snapshot
trexbar-sway refresh
trexbar-sway daemon [--once]
trexbar-sway panel
trexbar-sway ui open|close|toggle|status
trexbar-sway waybar render|refresh|panel
```

Global flags:

- `--config PATH`
- `--format json|text`
- `--pretty`
- `--once`

Behavior notes:

- `snapshot` refreshes cached state and always prints JSON.
- `refresh` refreshes cached state and prints JSON only with `--format json`.
- `daemon --once` performs one refresh and exits.
- `waybar render` reads cached state only.
- `waybar refresh` refreshes cached state.
- `waybar panel` opens the QuickShell modal.
