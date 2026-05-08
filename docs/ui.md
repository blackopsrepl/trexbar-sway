# UI

The Waybar chip summarizes tmux session state from cached snapshots.

The full shipped UI contract is documented in `WIREFRAME.md`.

The QuickShell modal shows:

- session totals
- attached sessions
- AI agents
- session health
- CPU and memory
- git dirtiness
- backend errors

V1 actions are read-only: refresh and close/toggle the modal.

The modal is a full-screen overlay with a centered card. The card contains a header with status and action buttons, four summary tiles, a scrollable session list, and a footer for agent/error text when either is present.
