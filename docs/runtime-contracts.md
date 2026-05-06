# Runtime Contracts

## Config

Default path:

```text
~/.config/trexbar-sway/config.json
```

Important fields:

- `runtime.stateDir`
- `runtime.refreshSeconds`
- `runtime.waybarSignal`
- `runtime.trexCommand`
- `runtime.quickShellCommand`
- `runtime.quickShellShell`
- `display.maxSessions`
- `display.staleAfterSeconds`

`runtime.trexCommand` is the path or command name for the required `trex` executable. The executable must support `snapshot --json`.

## Snapshot

Default path:

```text
~/.local/state/trexbar-sway/snapshot.json
```

The Ruby daemon owns this file. QuickShell and Waybar read it.

## Waybar

Command:

```bash
trexbar-sway waybar render
```

Shape:

```json
{"text":"TRX 3 1a 2ai","tooltip":"...","class":["trexbar","healthy"]}
```
