# Lid Awake

**Close the lid. Your agent keeps working on Omarchy.**

Lid Awake keeps an Omarchy laptop awake *and unlocked* with the lid shut: no
suspend, no lock screen, no screensaver.

Built for work you walk away from: an agent session, a build, a download. Shut
the lid, bag the laptop, open it an hour later: still running, still unlocked,
still exactly where you left it. Close the lid, come back to a finished job
instead of a lock screen.

Most lid plugins stop at suspend. This one also defeats the compositor's
lid-close lock and the idle timer. That is the difference between *the process survived*
and *you can still type into it*.

## Install

Two ways, and they are not the same experience.

**Recommended: lives in the indicator cluster.**

```bash
git clone https://github.com/mutex-solutions/omarchy-lid-awake
cd omarchy-lid-awake
./install.sh
```

Concealed when off, revealed when you hover the indicators, ordered with the
rest of the group. `./install.sh --uninstall` reverses it.

**Standalone widget:**

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-lid-awake --enable
```

One command, no files touched outside its own directory, but it sits in the bar
permanently rather than joining the cluster. Omarchy has no extension point for
third-party indicators, so a plugin cannot have both.

### One manual step

Omarchy's lid binding runs `omarchy-system-lid-close`, which locks. Nothing a
user-space inhibitor can do will stop a compositor binding, so point it at this
plugin instead:

```lua
-- ~/.config/hypr/bindings.lua
hl.unbind("switch:on:Lid Switch")
o.bind("switch:on:Lid Switch", nil,
  os.getenv("HOME") .. "/.local/bin/agent-mode lid-close", { locked = true })
```

Then check there's exactly **one** lid bind. A duplicate means a double lock:

```bash
hyprctl reload && hyprctl configerrors
hyprctl binds | grep -c 'switch:on:Lid Switch'   # must be 1
```

Skip this and the machine stays awake but still locks, which is precisely the
problem you installed it to avoid.

## Inside Deck

The same state is available as a Deck section:

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-lid-awake
```

```json
{ "id": "lidawake", "title": "Lid Awake",
  "file": "/home/YOU/.config/omarchy/plugins/mutex-solutions.lid-awake/deck/Section.qml",
  "page": "/home/YOU/.config/omarchy/plugins/mutex-solutions.lid-awake/deck/Page.qml" }
```

`install-bundle.sh` in the Deck repo wires this up with the other sections.

## Use it

Click the laptop icon, or from a terminal:

```bash
agent-mode                       # {"enabled":false,...}
agent-mode on | off | toggle
agent-mode lid-close             # what the Hyprland binding calls
```

The bar updates from either side within a second. Flip it in a terminal and
watch the icon follow. No click needed.

## How it works

"Lid does nothing" is not one setting. Three separate things react to a lid
close, so three separate things have to be told not to:

| What | How |
|---|---|
| logind suspends on lid close | `systemd-inhibit` block on `handle-lid-switch:sleep:idle` |
| Hyprland locks on lid close | the binding above calls `agent-mode lid-close` |
| Idle screensaver (150 s) and lock (300 s) | `omarchy-toggle-idle stay-awake` |

**No root.** `man 5 logind.conf`: low-level inhibitor locks are honoured
regardless of `LidSwitchIgnoreInhibited`, so `HandleLidSwitch` stays at its
default and a plain user inhibitor still wins.

## Notes

- **The helper is the source of truth.** The widget never assumes a toggle
  worked; it re-reads. An inhibitor can be released by logind, by the helper, or
  by a logout, and a cached flag would keep showing "on".
- **State lives in `~/.local/state/agent-mode`, deliberately not under
  `~/.local/state/omarchy/indicators`.** The shell's idle service watches that
  directory and drops refreshes while its probe is in flight; writing there
  raced it and left `stayAwake=false` with the lock timer armed.
- **No dependencies beyond Omarchy.** `systemd-inhibit`, `loginctl`, and
  Omarchy's own helpers. No Python, no root, no extra packages.

## Requirements

Omarchy 4.x, `systemd-inhibit`, `loginctl`.

## Licence

MIT. See [LICENSE](LICENSE).
