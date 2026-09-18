import QtQuick
import qs.Commons

Item {
  id: root

  property string text: ""
  property color color: Color.foreground
  property string fontFamily: Style.font.family
  property real pixelSize: Style.font.title
  property bool bold: false
  property bool active: true

  readonly property real overflow: Math.max(0, label.implicitWidth - root.width)

  implicitHeight: label.implicitHeight
  clip: true

  onOverflowChanged: if (overflow <= 0) label.x = 0

  Text {
    id: label
    textFormat: Text.PlainText
    text: root.text
    color: root.color
    font.family: root.fontFamily
    font.pixelSize: root.pixelSize
    font.bold: root.bold
    horizontalAlignment: Text.AlignLeft
    elide: root.overflow > 0 ? Text.ElideNone : Text.ElideRight
    width: root.overflow > 0 ? implicitWidth : root.width
  }

  SequentialAnimation {
    running: root.active && root.overflow > 0
    loops: Animation.Infinite

    PauseAnimation { duration: 900 }
    NumberAnimation {
      target: label; property: "x"; to: -root.overflow
      duration: Math.max(1200, root.overflow * 18); easing.type: Easing.InOutQuad
    }
    PauseAnimation { duration: 900 }
    NumberAnimation {
      target: label; property: "x"; to: 0
      duration: Math.max(1200, root.overflow * 18); easing.type: Easing.InOutQuad
    }
  }
}
