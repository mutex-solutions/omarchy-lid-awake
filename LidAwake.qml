import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// Lid Awake — keep the machine working with the lid shut.
//
// A standalone bar widget, not an entry in the indicators cluster: it is
// installed on its own, so it must own its whole face. (BarIndicator would
// hide itself when inactive, which is right inside the cluster and wrong
// here.)
//
// The state lives in the helper, not in this file. The widget reads
// `agent-mode status` and never remembers a toggle it has not seen confirmed —
// the inhibitor can be released from a terminal, by logind, or by the machine
// suspending anyway, and a cached flag would then lie.
BarWidget {
  id: root

  moduleName: "mutex-solutions.lid-awake"

  readonly property string pluginDir: Quickshell.env("HOME") + "/.config/omarchy/plugins/mutex-solutions.lid-awake"
  readonly property string helperPath: Quickshell.env("HOME") + "/.local/bin/agent-mode"

  property bool active: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌢"
    active: root.active
    useActiveColor: true
    dimmed: !root.active
    tooltipText: root.active ? "Restore lid close" : "Ignore lid close"
    onPressed: function(b) { if (b === 0) root.toggle() }
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function toggle() {
    if (!toggleProc.running) toggleProc.running = true
  }

  // The helper must be on PATH: the Hyprland lid binding calls it by name, so
  // `omarchy plugin add` alone would leave that binding broken. Install it from
  // the plugin's own bin/ on load — idempotent, and only when it differs, so a
  // running inhibitor is not disturbed on every shell start.
  Process {
    id: bootstrap
    command: ["bash", "-c",
      "cmp -s \"$1\" \"$2\" || install -Dm755 \"$1\" \"$2\"",
      "lid-awake", root.pluginDir + "/bin/agent-mode", root.helperPath]
    onExited: root.refresh()
  }

  Process {
    id: toggleProc
    command: [root.helperPath, "toggle"]
    // logind registers the inhibitor a moment after the helper returns, so a
    // status read fired immediately can still miss it.
    onExited: settleTimer.restart()
  }

  Process {
    id: statusProc
    command: [root.helperPath, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          root.active = JSON.parse(text || "{}").enabled === true
        } catch (e) {
          // Leave the last known state rather than claiming "off".
        }
      }
    }
  }

  Timer {
    id: settleTimer
    interval: 250
    onTriggered: root.refresh()
  }

  // The helper can equally be flipped from a terminal. Watching its state
  // directory reacts in milliseconds instead of waiting on a poll.
  FileView {
    path: Quickshell.env("HOME") + "/.local/state/agent-mode"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  // Backstop only: an inhibitor can die without the flag file moving.
  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: {
    bootstrap.running = true
    refresh()
  }
}
