# Lid Awake

Keep an Omarchy laptop working with the lid shut, from a bar toggle.

When it is on: no suspend, no lock, no screensaver, and closing the lid does
nothing. When it is off: everything behaves normally.

Built for leaving a long-running task — a build, an agent session, a download —
alive while the machine is closed and carried.

## Two ways to install, and they are not equivalent

Omarchy has **no extension point for third-party indicators**. The cluster loads
one path and one path only:

```qml
source: Qt.resolvedUrl("indicators/" + indicatorId + ".qml")
```

So a plugin installed with `omarchy plugin add` cannot join the indicator
cluster. It becomes a standalone bar slot instead — same toggle, different
behaviour: always visible, no hover reveal, no ordering with the other
indicators.

| | `./install.sh` | `omarchy plugin add` |
|---|---|---|
| Lives in the indicator cluster | **yes** | no |
| Concealed when off, revealed on hover | **yes** | no |
| Orders with the other indicators | **yes** | no |
| Installed via `omarchy plugin add` | no | **yes** |
| Survives `omarchy plugin update` | script re-run | **yes** |
| Touches another plugin's files | **yes** | no |

**Use `install.sh` if you want the behaviour the plugin was designed around.**
Use `omarchy plugin add` if you would rather not have an installer modify a
clone of another plugin.

## Install (indicator cluster)

```bash
git clone https://github.com/mutex-solutions/omarchy-lid-awake
cd omarchy-lid-awake
./install.sh
```

What it does, idempotently:

1. installs `bin/agent-mode` to `~/.local/bin`
2. clones `omarchy.indicators` to `<user>.indicators` if that clone does not exist
3. copies `AgentMode.qml` into the clone's `indicators/`
4. registers it in `defaultIndicatorEntries`
5. enables the clone and disables the stock cluster — two clusters is the
   failure mode that looks like the plugin doing nothing
6. tells you about the lid binding (see below) — it does **not** edit your
   Hyprland config
7. restarts the shell

`./install.sh --uninstall` reverses 1–5.

### The one manual step

Omarchy's lid binding runs `omarchy-system-lid-close`, which locks when no
external monitor is attached. Nothing reachable from an inhibitor can stop a
compositor binding, so the binding has to call this plugin instead:

```lua
-- ~/.config/hypr/bindings.lua
hl.unbind("switch:on:Lid Switch")
o.bind("switch:on:Lid Switch", nil,
  os.getenv("HOME") .. "/.local/bin/agent-mode lid-close", { locked = true })
```

Then confirm there is exactly **one** lid bind — a duplicate means a double lock:

```bash
hyprctl reload
hyprctl configerrors
hyprctl binds | grep -c 'switch:on:Lid Switch'   # must be 1
```

## Install (standalone widget)

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-lid-awake --enable
```

The helper installs itself from `bin/` on first load, so this path needs no
other command. The lid binding above is still required.

### Other commands

```bash
omarchy plugin update mutex-solutions.lid-awake
omarchy plugin disable mutex-solutions.lid-awake
omarchy plugin remove mutex-solutions.lid-awake
```

## Usage

Click the laptop icon. Inside the cluster it is concealed while off and appears
when you hover the indicator group; as a standalone widget it is always present
and dimmed while off.

```bash
agent-mode status     # {"enabled":false,"class":"disabled",...}
agent-mode on | off | toggle
agent-mode lid-close  # what the Hyprland binding calls
```

The widget reads the helper's state and watches its state directory, so flipping
it from a terminal updates the bar immediately — no click needed.

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

- **Why the cluster matters.** `BarIndicator` sorts entries into active and
  inactive blocks, so an active indicator always sits nearer the clock. Outside
  the cluster a widget can only ever be entirely before or entirely after both
  blocks, and no fixed position satisfies that in every combination.
- **The helper is the source of truth.** The widget never assumes a toggle
  worked; it re-reads. An inhibitor can be released by logind, by the helper, or
  by a logout, and a cached flag would keep showing "on".
- **State deliberately lives outside `~/.local/state/omarchy/indicators`.** The
  shell's idle service watches that directory and drops a refresh whenever its
  probe is already in flight. Writing this flag there raced the service and left
  it at `stayAwake=false` with the lock timer armed — the exact failure the mode
  exists to prevent.
- **No dependencies beyond Omarchy.** The helper uses Omarchy's own
  `omarchy-toggle-idle`, `omarchy-hw-*`, `omarchy-system-lock` and
  `omarchy-hyprland-monitor-clamshell`; the widgets use Quickshell only.

## Requirements

- Omarchy 4.x
- `systemd-inhibit`, `loginctl` (both standard)
- No root, no extra packages

## Licence

MIT — see [LICENSE](LICENSE).
