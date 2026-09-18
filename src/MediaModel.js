.pragma library

function hasMetadata(player) {
  return !!(player && (player.trackTitle || player.trackArtist || player.identity || player.desktopEntry))
}

function hasTrackMetadata(player) {
  return !!(player && (player.trackTitle || player.trackArtist))
}

function keyFor(player) {
  return player ? String(player.dbusName || player.identity || player.desktopEntry || "") : ""
}

function selectActivePlayer(players, lastActiveAt, preferredKey) {
  if (!players || players.length === 0) return null

  if (preferredKey) {
    for (var k = 0; k < players.length; k++) {
      if (keyFor(players[k]) === preferredKey && hasMetadata(players[k])) {
        return players[k]
      }
    }
  }

  var bestPlaying = null, bestPlayingOrder = -1
  var bestAny = null, bestAnyOrder = -1

  for (var i = 0; i < players.length; i++) {
    var p = players[i]
    if (!hasMetadata(p)) continue
    var key = keyFor(p)
    var order = (lastActiveAt && lastActiveAt[key]) || 0
    if (order > bestAnyOrder) {
      bestAny = p
      bestAnyOrder = order
    }
    if (p.isPlaying && order > bestPlayingOrder) {
      bestPlaying = p
      bestPlayingOrder = order
    }
  }
  return bestPlaying || bestAny
}

function filterSourcePlayers(players) {
  if (!players || players.length === 0) return []
  var list = []
  for (var i = 0; i < players.length; i++) {
    var p = players[i]
    if (hasMetadata(p)) list.push(p)
  }
  return list
}

function formatTime(seconds) {
  if (!seconds || isNaN(seconds) || seconds < 0) return "0:00"
  var total = Math.floor(seconds)
  var hrs = Math.floor(total / 3600)
  var mins = Math.floor((total % 3600) / 60)
  var secs = total % 60
  var secsStr = secs < 10 ? "0" + secs : String(secs)
  if (hrs > 0) {
    var minsStr = mins < 10 ? "0" + mins : String(mins)
    return hrs + ":" + minsStr + ":" + secsStr
  }
  return mins + ":" + secsStr
}
