import QtQuick
import qs.Commons

// Lid Awake page, rendered by Deck and by the standalone widget's popup.
Item {
  id: page

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
        text: "Keep awake with the lid shut"
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
          cursorShape: Qt.PointingHandCursor
          onClicked: if (page.state) page.state.toggle()
        }
      }
    }

    Rule { }

    Text {
      width: parent.width
      text: "No suspend, no lock screen, no screensaver while the lid is shut. "
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
  }
}
