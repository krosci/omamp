import QtQuick
import qs.Commons
import qs.Ui

Row {
  id: root

  property var bar: null
  property real volume: 1.0
  property bool volumeSupported: true
  property bool isDragging: false
  property real liveValue: volume

  onVolumeChanged: if (!isDragging) liveValue = volume

  signal volumeRequested(real value)

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(8)

  readonly property real clampedVolume: Math.max(0, Math.min(1.0, liveValue))
  readonly property string volumeIcon: {
    if (clampedVolume <= 0.001) return "󰝟"
    if (clampedVolume < 0.34) return "󰕿"
    if (clampedVolume < 0.67) return "󰖀"
    return "󰕾"
  }

  // Mute / Unmute quick toggle button
  Text {
    id: iconBtn
    textFormat: Text.PlainText
    text: root.volumeIcon
    color: root.bar ? root.bar.foreground : Color.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(20)
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: root.volumeSupported ? Qt.PointingHandCursor : Qt.ArrowCursor
      enabled: root.volumeSupported
      onClicked: {
        var target = root.liveValue > 0.01 ? 0.0 : 1.0
        root.liveValue = target
        root.volumeRequested(target)
      }
    }
  }

  Item {
    id: sliderContainer
    width: Math.max(Style.space(80), root.width - iconBtn.width - percentLabel.width - root.spacing * 2)
    height: Style.space(16)
    anchors.verticalCenter: parent.verticalCenter
    opacity: root.volumeSupported ? 1.0 : 0.4

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
        width: parent.width * root.clampedVolume
        color: root.bar ? root.bar.foreground : Color.foreground
        radius: 0

        Behavior on width {
          enabled: !root.isDragging
          NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }
      }

      Rectangle {
        id: knob
        width: Style.space(4)
        height: Style.space(12)
        color: root.bar ? root.bar.foreground : Color.foreground
        radius: 0
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(track.width - width, track.width * root.clampedVolume - width / 2))

        Behavior on x {
          enabled: !root.isDragging
          NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      enabled: root.volumeSupported
      cursorShape: root.volumeSupported ? Qt.PointingHandCursor : Qt.ArrowCursor

      function valueFromX(x) {
        var clamped = Math.max(0, Math.min(track.width, x))
        return track.width > 0 ? (clamped / track.width) : 0
      }

      onPressed: function(mouse) {
        if (mouse.button !== Qt.LeftButton) return
        root.isDragging = true
        root.liveValue = valueFromX(mouse.x)
      }
      onPositionChanged: function(mouse) {
        if (!root.isDragging) return
        root.liveValue = valueFromX(mouse.x)
        root.volumeRequested(root.liveValue)
      }
      onReleased: function(mouse) {
        if (mouse.button !== Qt.LeftButton) return
        var targetVal = valueFromX(mouse.x)
        root.liveValue = targetVal
        root.volumeRequested(targetVal)
        root.isDragging = false
      }
      onWheel: function(wheel) {
        if (!root.volumeSupported) return
        var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
        var next = Math.max(0, Math.min(1.0, root.liveValue + delta))
        root.liveValue = next
        root.volumeRequested(next)
      }
    }
  }

  Text {
    id: percentLabel
    textFormat: Text.PlainText
    text: Math.round(root.clampedVolume * 100) + "%"
    color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.35)
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.caption
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(36)
    horizontalAlignment: Text.AlignRight
    renderType: Text.NativeRendering
  }
}
