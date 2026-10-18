# Changelog

## 0.2.0 — 2026-10-18

Install path that reproduces the original behaviour exactly.

- `install.sh` installs the indicator into a clone of `omarchy.indicators` and
  registers it there. This is the only way to join the indicator cluster:
  the cluster loads `Qt.resolvedUrl("indicators/" + id + ".qml")` relative to
  its own directory, with no scan of other plugins and no `kind: "indicator"`.
- Idempotent, with `--uninstall` and `--no-restart`.
- Detects a per-widget `items` setting in `shell.json`, which overrides
  `defaultIndicatorEntries`, and says so instead of silently doing nothing.
- Disables the stock cluster when enabling the clone: two clusters is the
  failure mode that looks like the plugin doing nothing.
- Does **not** edit `bindings.lua`; it detects the lid binding and prints the
  block if it is missing. Rewriting someone's Hyprland config unattended is how
  sessions break.
- The standalone plugin (`omarchy plugin add`) stays, documented as the
  different-behaviour path: always visible, no hover reveal, no ordering.

## 0.1.0 — 2026-10-18

First release, extracted from the `sysadmin` homelab repo.

- Standalone bar widget (`mutex-solutions.lid-awake`) — previously an entry
  inside a cloned `omarchy.indicators` plugin, which meant it could not be
  installed without also cloning the indicators plugin.
- `bin/agent-mode` ships with the plugin and is installed to `~/.local/bin`
  on first load, so `omarchy plugin add` is a complete install apart from the
  documented Hyprland lid binding.
- State is read from the helper rather than cached, so a toggle from a terminal
  updates the bar on the next file change.
