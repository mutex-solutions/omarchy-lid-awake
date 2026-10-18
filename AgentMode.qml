import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// Agent mode: hold the machine awake and unlocked with the lid shut.
//
// A real member of the indicator cluster rather than a standalone bar module,
// which is what makes it order correctly: BarIndicator places it in the active
// or inactive block along with the stock indicators, so an active indicator is
// always nearer the clock than an inactive one. Sitting outside the cluster it
// could only ever be entirely before or entirely after both blocks, and no
// fixed position satisfies that in every combination.
//
// Opacity, hover reveal, dimming and the tooltip all come from BarIndicator.
//
// This file is installed into a clone of the indicators plugin by install.sh,
// because Omarchy has no extension point for third-party indicators.
BarIndicator {
  id: root

  property bool agentMode: false

  active: root.agentMode
  activeText: "󰌢"
  inactiveText: "󰌢"
  // Omarchy's indicator convention: the inactive tooltip names the feature, the
  // active one names what a click will do.
  activeTooltipText: "Allow Lid Close"
  inactiveTooltipText: "Lid Awake"

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  onPressed: function() { toggleProc.running = true }

  Component.onCompleted: refresh()

  Process {
    id: toggleProc
    command: ["agent-mode", "toggle"]
    // logind registers the inhibitor a moment after the helper returns, so a
    // status read fired immediately can still miss it.
    onExited: settleTimer.restart()
  }

  Process {
    id: statusProc
    command: ["agent-mode", "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          root.agentMode = JSON.parse(text || "{}").enabled === true
        } catch (e) {
        }
      }
    }
  }

  Timer {
    id: settleTimer
    interval: 250
    onTriggered: root.refresh()
  }

  // agent-mode can equally be flipped from a terminal. Watching its state
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
}
