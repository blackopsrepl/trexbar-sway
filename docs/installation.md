# Installation

`trexbar-sway` depends on `trex snapshot --json`. Install or build `trex` first, then verify the dependency:

```bash
make check-trex
```

Install the app under the user prefix:

```bash
make install-user
```

Install the SolverForge Linux Waybar wrapper:

```bash
make install-solverforge
```

Desktop module wiring lives in the SolverForge Linux default layer, not in symlinked `~/.config/waybar` files.

`install-user` installs `README.md`, `WIREFRAME.md`, `AGENTS.md`, `docs/`, `frontend/`, `packaging/`, `assets/`, `bin/`, and `lib/` under `~/.local/share/trexbar-sway`, then links `~/.local/bin/trexbar-sway`.
