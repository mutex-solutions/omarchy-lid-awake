# Lid Awake

Keep an Omarchy laptop working with the lid shut, from a bar toggle.

When it is on: no suspend, no lock, no screensaver, and closing the lid does
nothing. When it is off: everything behaves normally.

Built for leaving a long-running task — a build, an agent session, a download —
alive while the machine is closed and carried.

## Install

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-lid-awake --enable
```

That is the whole install. The widget's helper is installed from the plugin's
own `bin/` on first load, so there is nothing else to fetch.

**One manual step remains, and it is not optional.** Omarchy's lid-close
binding runs `omarchy-system-lid-close`, which locks when no external monitor is
attached. Nothing reachable from an inhibitor can stop a compositor binding, so
the binding has to call this plugin instead:

```lua
-- ~/.config/hypr/bindings.lua
hl.unbind("switch:on:Lid Switch")
o.bind("switch:on:Lid Switch", nil,
  os.getenv("HOME") .. "/.local/bin/agent-mode lid-close", { locked = true })
```

Without it the machine stays awake but still locks on lid close.

Reload Hyprland after editing (`hyprctl reload`), then click the widget once and
close the lid to confirm.

### Other commands

```bash
omarchy plugin update mutex-solutions.lid-awake   # git fast-forward + validate
omarchy plugin disable mutex-solutions.lid-awake
omarchy plugin remove mutex-solutions.lid-awake
```

## Usage

Click the laptop icon in the bar. It is dimmed when off and highlighted when on.

```bash
agent-mode status     # {"enabled":false,"class":"disabled","text":"...","tooltip":"..."}
agent-mode on | off | toggle
agent-mode lid-close  # what the Hyprland binding calls
```

The widget polls the helper and watches its state file, so flipping it from a
terminal updates the bar immediately — no click needed.

## Why three mechanisms

"Lid does nothing" is not one setting. Three independent things act on a lid
close, and each needs its own defeat:

| Mechanism | Defeat |
|---|---|
| logind `HandleLidSwitch=suspend` | a `systemd-inhibit` block on `handle-lid-switch:sleep:idle` |
| Hyprland lid binding → lock | the binding above calls `agent-mode lid-close` instead |
| `omarchy.idle` → screensaver 150 s, lock 300 s | `omarchy-toggle-idle stay-awake` |

**No root required.** `man 5 logind.conf`: low-level inhibitor locks
(`handle-lid-switch`) are honoured regardless of `LidSwitchIgnoreInhibited` —
that setting only governs the high-level `sleep` lock. So `HandleLidSwitch` can
stay at `suspend` and a plain user inhibitor still wins.

## Design notes

- **The helper is the source of truth.** The widget never assumes a toggle
  worked; it re-reads. An inhibitor can be released by logind, by the helper, or
  by the user logging out, and a cached flag would keep showing "on".
- **State deliberately lives outside `~/.local/state/omarchy/indicators`.**
  The shell's idle service watches that directory and drops a refresh whenever
  its probe is already in flight. Writing this flag there raced the service and
  left it at `stayAwake=false` with the lock timer armed — the exact failure the
  mode exists to prevent. See the comment at the top of `bin/agent-mode`.
- **Standalone, not an indicator-cluster entry.** This is installable on its own,
  so it owns its whole bar face. `BarIndicator` hides itself when inactive,
  which is right inside the cluster and wrong here.
- **No dependencies beyond Omarchy.** The helper uses Omarchy's own
  `omarchy-toggle-idle`, `omarchy-hw-*`, `omarchy-system-lock` and
  `omarchy-hyprland-monitor-clamshell`; the widget uses Quickshell only.

## Requirements

- Omarchy 4.x
- `systemd-inhibit`, `loginctl` (both standard)
- No root, no extra packages

## Uninstall

```bash
omarchy plugin remove mutex-solutions.lid-awake
rm -f ~/.local/bin/agent-mode
```

Then delete the lid-switch block from `~/.config/hypr/bindings.lua` and
`hyprctl reload`. Omarchy's own binding returns.

## Licence

MIT — see [LICENSE](LICENSE).
