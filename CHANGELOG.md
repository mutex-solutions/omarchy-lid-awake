# Changelog

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
