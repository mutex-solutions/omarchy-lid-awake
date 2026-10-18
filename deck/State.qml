import QtQuick
import Quickshell
import Quickshell.Io

// Lid Awake state, as a Deck section.
//
// The helper is the source of truth: the widget re-reads it rather than caching
// a toggle, because the inhibitor can be released by logind or from a terminal.
Item {
  id: s

  property bool enabled: false

  readonly property bool active: enabled
  readonly property string label: "Lid Awake"
  readonly property string detail: enabled ? "lid ignored" : "off"
  readonly property string icon: "󰌢"

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function toggle() {
    if (!toggleProc.running) toggleProc.running = true
  }

  Process {
    id: statusProc
    command: ["agent-mode", "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          s.enabled = JSON.parse(text || "{}").enabled === true
        } catch (e) {
        }
      }
    }
  }

  Process {
    id: toggleProc
    command: ["agent-mode", "toggle"]
    onExited: settleTimer.restart()
  }

  Timer {
    id: settleTimer
    interval: 250
    onTriggered: s.refresh()
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/agent-mode"
    watchChanges: true
    printErrors: false
    onFileChanged: s.refresh()
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: s.refresh()
  }

  Component.onCompleted: refresh()
}
