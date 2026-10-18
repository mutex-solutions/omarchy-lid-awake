#!/usr/bin/env bash
#
# lid-awake: install the lid toggle into the indicators cluster.
#
# Omarchy has no extension point for third-party indicators. The cluster loads
# exactly one path:
#
#     Qt.resolvedUrl("indicators/" + indicatorId + ".qml")
#
# relative to its own directory, with no scan of other plugins and no
# `kind: "indicator"`. So the only way to get the same experience as the
# original (concealed when off, revealed on cluster hover, ordered with the
# stock indicators) is to put the component inside a clone of that plugin and
# register it there.
#
# Idempotent: re-running updates the component and leaves everything else
# alone. `--uninstall` reverses it.
#
# Usage:
#   ./install.sh              install (restarts the shell)
#   ./install.sh --no-restart install without restarting
#   ./install.sh --uninstall  remove the entry and the component

set -euo pipefail

ENTRY="AgentMode"
ENTRY_NAME="Lid Awake"

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HELPER_SRC="$REPO_DIR/bin/agent-mode"
HELPER_DST="$HOME/.local/bin/agent-mode"
INDICATOR_SRC="$REPO_DIR/AgentMode.qml"

CLONE="$HOME/.config/omarchy/plugins/${USER}.indicators"
CLONE_COMPONENT="$CLONE/indicators/$ENTRY.qml"
CLONE_LIST="$CLONE/Indicators.qml"

say()  { printf '  %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }
die()  { printf 'lid-awake: %s\n' "$*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "missing '$1'. Is this an Omarchy machine?"
}

need omarchy
need omarchy-shell

is_enabled() {
  omarchy-shell shell listPlugins 2>/dev/null \
    | grep -q "\"id\":\"$1\",\"name\":[^}]*\"enabled\":true"
}

install_lid_awake() {
  echo "lid-awake: installing $ENTRY_NAME"

  [ -f "$HELPER_SRC" ]    || die "missing $HELPER_SRC"
  [ -f "$INDICATOR_SRC" ] || die "missing $INDICATOR_SRC"

  # 1. The helper. The lid binding calls it by name, so it must be on PATH.
  install -Dm755 "$HELPER_SRC" "$HELPER_DST"
  say "helper      -> $HELPER_DST"

  # 2. The indicators clone. `plugin clone` copies the stock plugin under
  #     <user>.indicators; it is not git-managed and will not be overwritten by
  #     Omarchy updates, which is exactly what makes it safe to patch.
  if [ ! -d "$CLONE" ]; then
    omarchy plugin clone omarchy.indicators >/dev/null 2>&1 \
      || die "omarchy plugin clone omarchy.indicators failed"
    say "clone       -> ${CLONE##*/} (created)"
  else
    say "clone       -> ${CLONE##*/} (already present)"
  fi
  [ -d "$CLONE/indicators" ] || die "clone has no indicators/ directory: $CLONE"

  # 3. The component itself.
  install -Dm644 "$INDICATOR_SRC" "$CLONE_COMPONENT"
  say "component   -> indicators/$ENTRY.qml"

  # 4. Register it. Append to the default list rather than rewriting the line,
  #     so a user's own entries survive. `items` in shell.json would override
  #     this list entirely, so say so if one is set.
  if grep -q "\"$ENTRY\"" "$CLONE_LIST"; then
    say "registered  -> already in defaultIndicatorEntries"
  else
    sed -i "/readonly property var defaultIndicatorEntries/ s/][[:space:]]*$/ , \"$ENTRY\" ]/" "$CLONE_LIST"
    grep -q "\"$ENTRY\"" "$CLONE_LIST" \
      || die "could not register $ENTRY. Edit $CLONE_LIST by hand and add \"$ENTRY\" to defaultIndicatorEntries"
    say "registered  -> defaultIndicatorEntries"
  fi

  # A per-widget `items` setting overrides the default list. If one exists, the
  # user has to add the entry there too, and silently doing nothing would look
  # like a broken install.
  if command -v jq >/dev/null 2>&1 \
     && jq -e --arg id "${USER}.indicators" \
        '.bar.layout | to_entries[] | .value[] | select(.id == $id) | .items' \
        "$HOME/.config/omarchy/shell.json" >/dev/null 2>&1; then
    warn "this widget has an 'items' setting in shell.json, which overrides"
    warn "defaultIndicatorEntries. Add \"$ENTRY\" to it as well:"
    warn "  omarchy bar set ${USER}.indicators items '<json array>' --json"
  fi

  # 5. Exactly one cluster. Two widgets both drawing indicators is the failure
  #     mode that looks like the plugin doing nothing.
  if ! is_enabled "${USER}.indicators"; then
    omarchy plugin enable "${USER}.indicators" --section center >/dev/null 2>&1 \
      || die "could not enable ${USER}.indicators"
    say "enabled     -> ${USER}.indicators (center)"
  else
    say "enabled     -> ${USER}.indicators (already)"
  fi

  if is_enabled "omarchy.indicators"; then
    omarchy plugin disable omarchy.indicators >/dev/null 2>&1 || true
    say "disabled    -> stock omarchy.indicators (one cluster only)"
  fi

  # 6. The lid binding. This is deliberately not edited automatically:
  #     rewriting someone's Hyprland config unattended is how sessions break.
  if grep -qs 'agent-mode lid-close' "$HOME/.config/hypr/bindings.lua"; then
    say "lid binding -> present"
  else
    cat <<'MSG'

  ACTION REQUIRED: add this to ~/.config/hypr/bindings.lua:

      hl.unbind("switch:on:Lid Switch")
      o.bind("switch:on:Lid Switch", nil,
        os.getenv("HOME") .. "/.local/bin/agent-mode lid-close", { locked = true })

  Without it the machine stays awake but still locks on lid close.
  Then confirm exactly one lid bind exists:

      hyprctl binds | grep -c 'switch:on:Lid Switch'   # must be 1

MSG
  fi

  # 7. Reload the shell so the new component is instantiated.
  if [[ " $* " != *" --no-restart "* ]]; then
    omarchy restart shell >/dev/null 2>&1 || true
    say "shell       -> restarted"
  fi

  echo "lid-awake: done. Click the laptop icon in the indicator cluster."
}

uninstall_lid_awake() {
  echo "lid-awake: removing $ENTRY_NAME"

  if [ -f "$CLONE_COMPONENT" ]; then
    rm -f "$CLONE_COMPONENT"
    say "removed     -> indicators/$ENTRY.qml"
  else
    say "component   -> not installed"
  fi

  if [ -f "$CLONE_LIST" ] && grep -q "\"$ENTRY\"" "$CLONE_LIST"; then
    # Handles both positions the entry can appear in.
    sed -i "s/, \"$ENTRY\"//; s/\"$ENTRY\", //" "$CLONE_LIST"
    say "removed     -> defaultIndicatorEntries"
  fi

  if [[ " $* " != *" --no-restart "* ]]; then
    omarchy restart shell >/dev/null 2>&1 || true
    say "shell       -> restarted"
  fi

  cat <<'MSG'

  Left in place on purpose:
    ~/.local/bin/agent-mode        (remove with: rm ~/.local/bin/agent-mode)
    ~/.config/hypr/bindings.lua    (delete the lid-switch block yourself)
    ~/.config/omarchy/plugins/<user>.indicators  (other indicators live here)

  The stock cluster returns with:  omarchy plugin enable omarchy.indicators
MSG
}

case "${1:-install}" in
  install)      install_lid_awake "$@" ;;
  --no-restart) install_lid_awake "$@" ;;
  --uninstall)  uninstall_lid_awake "$@" ;;
  -h|--help)
    sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    ;;
  *) die "unknown option '$1'. Try --help" ;;
esac
