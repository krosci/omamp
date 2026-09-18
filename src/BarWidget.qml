import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Ui
import qs.Commons
import "MediaModel.js" as MediaModel

BarWidget {
  id: root
  moduleName: "krosci.omamp"

  readonly property var players: Mpris.players ? Mpris.players.values : []

  property var lastActiveAt: ({})
  property int serial: 0
  property string preferredPlayerKey: ""

  function selectPlayer(key) {
    preferredPlayerKey = key
    var p = activePlayer
    if (p) touch(p)
  }

  function touch(p) {
    var key = MediaModel.keyFor(p)
    if (!key) return
    serial += 1
    var next = {}
    for (var k in lastActiveAt) next[k] = lastActiveAt[k]
    next[key] = serial
    lastActiveAt = next
  }

  readonly property var activePlayer: MediaModel.selectActivePlayer(players, lastActiveAt, preferredPlayerKey)
  readonly property var sourcePlayers: MediaModel.filterSourcePlayers(players)
  readonly property bool hasMedia: activePlayer !== null && !!(activePlayer.trackTitle || activePlayer.trackArtist || activePlayer.isPlaying)
  readonly property bool isPlaying: !!(activePlayer && activePlayer.isPlaying)
  readonly property string artUrl: activePlayer && activePlayer.trackArtUrl ? activePlayer.trackArtUrl : ""
  readonly property string title: activePlayer ? MediaModel.cleanTitle(activePlayer.trackTitle || "") : ""
  readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""
  readonly property string album: activePlayer && activePlayer.trackAlbum ? activePlayer.trackAlbum : ""
  readonly property string identity: activePlayer ? (activePlayer.identity || activePlayer.desktopEntry || "") : ""
  readonly property string desktopEntry: activePlayer ? (activePlayer.desktopEntry || "") : ""

  property real trackPosition: activePlayer ? (activePlayer.position || 0) : 0
  property real trackLength: activePlayer && activePlayer.length > 0 ? activePlayer.length : 0
  property bool isSeeking: false
  readonly property bool canSeek: !!(activePlayer && (activePlayer.canSeek || activePlayer.positionSupported))

  property bool panelOpen: false
  function close() { panelOpen = false }

  onPlayersChanged: {
    for (var i = 0; i < players.length; i++) touch(players[i])
  }

  Instantiator {
    model: root.players
    delegate: Connections {
      required property var modelData
      target: modelData
      function onIsPlayingChanged() { root.touch(modelData) }
      function onTrackTitleChanged() { root.touch(modelData) }
    }
  }

  Connections {
    target: root.activePlayer
    function onPositionChanged() {
      if (!root.isSeeking && root.activePlayer) {
        root.trackPosition = root.activePlayer.position || 0
      }
    }
    function onLengthChanged() {
      if (root.activePlayer) {
        root.trackLength = root.activePlayer.length > 0 ? root.activePlayer.length : 0
      }
    }
  }

  Timer {
    id: positionTimer
    interval: 500
    running: root.panelOpen && root.isPlaying && !root.isSeeking
    repeat: true
    onTriggered: {
      if (root.activePlayer) {
        root.trackPosition = root.activePlayer.position || 0
      }
    }
  }

  function seekTo(val) {
    if (root.activePlayer && (root.activePlayer.canSeek || root.activePlayer.positionSupported)) {
      root.activePlayer.position = val
      root.trackPosition = val
    }
  }

  function runAction(action) {
    var p = root.activePlayer
    if (!p) return
    if (action === "previous") { if (p.canGoPrevious) p.previous() }
    else if (action === "next") { if (p.canGoNext) p.next() }
    else if (action === "playPause") {
      if (p.isPlaying && p.canPause) p.pause()
      else if (!p.isPlaying && p.canPlay) p.play()
      else if (p.canTogglePlaying) p.togglePlaying()
    }
  }

  visible: (root.isPlaying || root.panelOpen) && root.hasMedia
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.isPlaying ? "󰏤" : "󰐊"
    foreground: root.bar ? root.bar.barForeground : Color.foreground
    tooltipText: root.hasMedia ? (root.title + (root.artist ? " — " + root.artist : "")) : "MediaPlayer"
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.runAction("playPause")
      } else if (b === Qt.MiddleButton) {
        root.runAction("next")
      } else {
        root.panelOpen = !root.panelOpen
      }
    }
    onWheelMoved: function(delta) {
      if (!root.hasMedia) return
      if (delta > 0) root.runAction("previous")
      else if (delta < 0) root.runAction("next")
    }
  }

  MediaPopup {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    playerWidget: root
    open: root.panelOpen
  }
}
