import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Lid Awake state, as a Deck section.
//
// The helper is the source of truth: the widget re-reads it rather than caching
// a toggle, because the inhibitor can be released by logind or from a terminal.
Item {
  id: s

  Translations { id: strings; directory: Qt.resolvedUrl("../i18n") }

  property bool enabled: false
  property bool idleStayAwake: false
  property bool binding: false
  readonly property bool busy: toggleProc.running
  readonly property string pluginDir: Quickshell.env("HOME") + "/.config/omarchy/plugins/mutex-solutions.lid-awake"
  readonly property string helperPath: Quickshell.env("HOME") + "/.local/bin/agent-mode"

  readonly property bool active: enabled
  readonly property string label: strings.t("lid-awake.lidAwake")
  readonly property string detail: enabled ? "lid ignored" : "off"
  readonly property string icon: "󰌢"

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function toggle() {
    if (!toggleProc.running) toggleProc.running = true
  }

  // Deck-only installs need the helper too; the standalone widget is disabled.
  Process {
    id: bootstrap
    command: ["bash", "-c", "cmp -s \"$1\" \"$2\" || install -Dm755 \"$1\" \"$2\"",
      "lid-awake", s.pluginDir + "/bin/agent-mode", s.helperPath]
    onExited: s.refresh()
  }

  Process {
    id: statusProc
    command: [s.helperPath, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var report = JSON.parse(text || "{}")
          s.enabled = report.enabled === true
          s.idleStayAwake = report.idleStayAwake === true
          s.binding = report.binding === true
        } catch (e) {
        }
      }
    }
  }

  Process {
    id: toggleProc
    command: [s.helperPath, "toggle"]
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

  Component.onCompleted: if (!bootstrap.running) bootstrap.running = true
}
