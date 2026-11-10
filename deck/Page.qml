import QtQuick
import qs.Commons

// Lid Awake page, rendered by Deck and by the standalone widget's popup.
Item {
  id: page

  Translations { id: strings; directory: Qt.resolvedUrl("../i18n") }

  property var state: null
  property var host: null

  implicitHeight: col.implicitHeight

  component Rule: Rectangle {
    width: parent ? parent.width : 0
    height: 1
    color: Util.alpha(Color.foreground, 0.1)
  }

  Column {
    id: col
    width: parent.width
    spacing: Style.space(2)

    Item {
      width: parent.width
      height: Style.space(34)

      Text {
        anchors.left: parent.left
        anchors.leftMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        text: page.state && page.state.busy ? "Applying…" : "Keep awake with the lid shut"
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }

      Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(34)
        height: Style.space(18)
        radius: height / 2
        color: page.state && page.state.active
          ? Util.alpha(Color.accent, 0.85)
          : Util.alpha(Color.foreground, 0.2)

        Rectangle {
          width: Style.space(14)
          height: width
          radius: width / 2
          y: (parent.height - height) / 2
          x: page.state && page.state.active ? parent.width - width - Style.space(2) : Style.space(2)
          color: "#ffffff"
        }

        MouseArea {
          anchors.fill: parent
          enabled: page.state && !page.state.busy
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: if (page.state && !page.state.busy) page.state.toggle()
        }
      }
    }

    Rule { }

    Text {
      width: parent.width
      text: strings.t("lid-awake.noSuspendNoLockScreenNoScreensaverWhileTheLidIsShut")
          + "Requires the Hyprland lid binding; without it the machine stays "
          + "awake but still locks when closed."
      color: Util.alpha(Color.foreground, 0.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      leftPadding: Style.space(8)
      rightPadding: Style.space(8)
      topPadding: Style.space(6)
      bottomPadding: Style.space(6)
    }

    Repeater {
      model: page.state ? [
        { label: strings.t("lid-awake.lidSleepInhibitor"), value: page.state.enabled ? "Active" : "Off", ok: page.state.enabled },
        { label: strings.t("lid-awake.idleLockScreensaver"), value: page.state.idleStayAwake ? "Disabled" : "Enabled", ok: page.state.idleStayAwake },
        { label: strings.t("lid-awake.hyprlandLidBinding"), value: page.state.binding ? "Installed" : "Missing", ok: page.state.binding }
      ] : []
      Item {
        required property var modelData
        width: parent.width
        height: Style.space(22)
        Text {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.label
          color: Util.alpha(Color.foreground, 0.55)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        Text {
          anchors.right: parent.right
          anchors.rightMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.value
          color: page.state.enabled && !modelData.ok ? Color.urgent : Util.alpha(Color.foreground, 0.55)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
