import QtQuick
import qs.Commons
import qs.Ui
import "MediaModel.js" as MediaModel

Row {
  id: root

  property var bar: null
  property real trackPosition: 0
  property real trackLength: 0
  property bool canSeek: false
  property bool isSeeking: false
  property real liveValue: trackPosition

  onTrackPositionChanged: if (!isSeeking) liveValue = trackPosition

  signal seekRequested(real position)

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(8)

  readonly property real range: Math.max(0.0001, trackLength)
  readonly property real progress: Math.max(0, Math.min(1, liveValue / range))

  Text {
    id: elapsedLabel
    textFormat: Text.PlainText
    text: MediaModel.formatTime(root.liveValue)
    color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.35)
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.caption
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(36)
    horizontalAlignment: Text.AlignRight
  }

  Item {
    id: sliderContainer
    width: Math.max(Style.space(80), root.width - elapsedLabel.width - durationLabel.width - root.spacing * 2)
    height: Style.space(16)
    anchors.verticalCenter: parent.verticalCenter
    opacity: root.canSeek ? 1.0 : 0.4

    Rectangle {
      id: track
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      height: Style.space(3)
      color: root.bar ? Style.selectedFillFor(root.bar.foreground, Color.accent) : "#333"
      radius: 0

      Rectangle {
        id: fill
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * root.progress
        color: root.bar ? root.bar.foreground : Color.foreground
        radius: 0

        Behavior on width {
          enabled: !root.isSeeking
          NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
      }

      Rectangle {
        id: knob
        width: Style.space(4)
        height: Style.space(12)
        color: root.bar ? root.bar.foreground : Color.foreground
        radius: 0
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(track.width - width, track.width * root.progress - width / 2))

        Behavior on x {
          enabled: !root.isSeeking
          NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      enabled: root.canSeek
      cursorShape: root.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor

      function valueFromX(x) {
        var clamped = Math.max(0, Math.min(track.width, x))
        return (clamped / track.width) * root.range
      }

      onPressed: function(mouse) {
        if (mouse.button !== Qt.LeftButton) return
        root.isSeeking = true
        root.liveValue = valueFromX(mouse.x)
      }
      onPositionChanged: function(mouse) {
        if (!root.isSeeking) return
        root.liveValue = valueFromX(mouse.x)
      }
      onReleased: function(mouse) {
        if (mouse.button !== Qt.LeftButton) return
        var targetVal = valueFromX(mouse.x)
        root.liveValue = targetVal
        root.seekRequested(targetVal)
        root.isSeeking = false
      }
      onWheel: function(wheel) {
        if (!root.canSeek) return
        var delta = wheel.angleDelta.y > 0 ? 5 : -5
        var next = Math.max(0, Math.min(root.trackLength, root.liveValue + delta))
        root.liveValue = next
        root.seekRequested(next)
      }
    }
  }

  Text {
    id: durationLabel
    textFormat: Text.PlainText
    text: root.trackLength > 0 ? MediaModel.formatTime(root.trackLength) : "--:--"
    color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.35)
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.caption
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(36)
    horizontalAlignment: Text.AlignLeft
  }
}
