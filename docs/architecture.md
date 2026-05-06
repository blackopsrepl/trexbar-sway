# Architecture

`trexbar-sway` has four active layers:

1. Ruby CLI.
2. Ruby runtime for config, refresh, cached state, and presentation.
3. Runtime files in `~/.local/state/trexbar-sway`.
4. Waybar JSON chip plus QuickShell detail modal.

The backend boundary is `trex snapshot --json`. The frontend and Waybar never run tmux commands directly.
