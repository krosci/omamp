import { test, describe } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

function loadMediaModel() {
  const filePath = path.resolve(process.cwd(), "src/MediaModel.js");
  const content = fs.readFileSync(filePath, "utf8").replace(".pragma library", "");
  const context = {};
  vm.createContext(context);
  vm.runInContext(content, context);
  return context;
}

const MediaModel = loadMediaModel();

describe("MediaModel.cleanTitle", () => {
  test("removes parenthetical features and credits", () => {
    assert.equal(MediaModel.cleanTitle("Starboy (feat. Daft Punk)"), "Starboy");
    assert.equal(MediaModel.cleanTitle("Song Title (ft. Drake)"), "Song Title");
    assert.equal(MediaModel.cleanTitle("Track (with Beyoncé)"), "Track");
  });

  test("removes bracketed content like remixes and remasters", () => {
    assert.equal(MediaModel.cleanTitle("Song Title [2024 Remaster]"), "Song Title");
    assert.equal(MediaModel.cleanTitle("Track [Official Remix]"), "Track");
    assert.equal(MediaModel.cleanTitle("Track (feat. Artist) [Live]"), "Track");
  });

  test("preserves titles when trimming would result in an empty string", () => {
    assert.equal(MediaModel.cleanTitle("(Intro)"), "(Intro)");
    assert.equal(MediaModel.cleanTitle("[Untitled]"), "[Untitled]");
    assert.equal(MediaModel.cleanTitle("(Theme)"), "(Theme)");
  });

  test("normalizes multiple whitespace and handles empty or non-string inputs", () => {
    assert.equal(MediaModel.cleanTitle("  Song   Name  "), "Song Name");
    assert.equal(MediaModel.cleanTitle(""), "");
    assert.equal(MediaModel.cleanTitle(null), "");
    assert.equal(MediaModel.cleanTitle(undefined), "");
    assert.equal(MediaModel.cleanTitle(123), "");
  });
});

describe("MediaModel.formatTime", () => {
  test("formats seconds under one minute", () => {
    assert.equal(MediaModel.formatTime(0), "0:00");
    assert.equal(MediaModel.formatTime(5), "0:05");
    assert.equal(MediaModel.formatTime(42), "0:42");
  });

  test("formats minutes and seconds", () => {
    assert.equal(MediaModel.formatTime(60), "1:00");
    assert.equal(MediaModel.formatTime(75), "1:15");
    assert.equal(MediaModel.formatTime(630), "10:30");
  });

  test("formats hours when duration exceeds 60 minutes", () => {
    assert.equal(MediaModel.formatTime(3600), "1:00:00");
    assert.equal(MediaModel.formatTime(3665), "1:01:05");
    assert.equal(MediaModel.formatTime(7325), "2:02:05");
  });

  test("handles negative, invalid, or null values gracefully", () => {
    assert.equal(MediaModel.formatTime(-10), "0:00");
    assert.equal(MediaModel.formatTime(NaN), "0:00");
    assert.equal(MediaModel.formatTime(null), "0:00");
    assert.equal(MediaModel.formatTime(undefined), "0:00");
  });
});

describe("MediaModel.playerDisplayName", () => {
  test("prefers identity property", () => {
    assert.equal(MediaModel.playerDisplayName({ identity: "Spotify", desktopEntry: "spotify" }), "Spotify");
  });

  test("capitalizes desktopEntry when identity is missing", () => {
    assert.equal(MediaModel.playerDisplayName({ desktopEntry: "vlc" }), "Vlc");
    assert.equal(MediaModel.playerDisplayName({ desktopEntry: "firefox" }), "Firefox");
  });

  test("parses and capitalizes dbusName when identity and desktopEntry are missing", () => {
    assert.equal(
      MediaModel.playerDisplayName({ dbusName: "org.mpris.MediaPlayer2.spotify" }),
      "Spotify"
    );
    assert.equal(
      MediaModel.playerDisplayName({ dbusName: "org.mpris.MediaPlayer2.chromium.instance123" }),
      "Chromium"
    );
  });

  test("returns default when no identifiers are present", () => {
    assert.equal(MediaModel.playerDisplayName(null), "");
    assert.equal(MediaModel.playerDisplayName({}), "Player");
  });
});

describe("MediaModel.hasMetadata & hasTrackMetadata", () => {
  test("identifies players with actual track or playback activity", () => {
    assert.equal(MediaModel.hasMetadata({ trackTitle: "Song" }), true);
    assert.equal(MediaModel.hasMetadata({ trackArtist: "Artist" }), true);
    assert.equal(MediaModel.hasMetadata({ isPlaying: true }), true);
  });

  test("rejects idle players without media or track data", () => {
    assert.equal(MediaModel.hasMetadata({ desktopEntry: "spotify", isPlaying: false, trackTitle: "" }), false);
    assert.equal(MediaModel.hasMetadata(null), false);
    assert.equal(MediaModel.hasMetadata({}), false);
  });

  test("hasTrackMetadata strictly checks title and artist", () => {
    assert.equal(MediaModel.hasTrackMetadata({ trackTitle: "Song" }), true);
    assert.equal(MediaModel.hasTrackMetadata({ trackArtist: "Artist" }), true);
    assert.equal(MediaModel.hasTrackMetadata({ isPlaying: true }), false);
    assert.equal(MediaModel.hasTrackMetadata(null), false);
  });
});

describe("MediaModel.selectActivePlayer", () => {
  test("returns null when player list is empty or invalid", () => {
    assert.equal(MediaModel.selectActivePlayer([], {}), null);
    assert.equal(MediaModel.selectActivePlayer(null, {}), null);
  });

  test("prioritizes currently playing player", () => {
    const paused = { dbusName: "paused", isPlaying: false, trackTitle: "Song A" };
    const playing = { dbusName: "playing", isPlaying: true, trackTitle: "Song B" };
    assert.equal(MediaModel.selectActivePlayer([paused, playing], { paused: 10, playing: 5 }), playing);
  });

  test("selects most recently active paused player when none are playing", () => {
    const p1 = { dbusName: "p1", isPlaying: false, trackTitle: "Song 1" };
    const p2 = { dbusName: "p2", isPlaying: false, trackTitle: "Song 2" };
    assert.equal(MediaModel.selectActivePlayer([p1, p2], { p1: 1, p2: 5 }), p2);
  });

  test("respects preferredKey if specified and player has metadata", () => {
    const p1 = { dbusName: "p1", isPlaying: true, trackTitle: "Song 1" };
    const p2 = { dbusName: "p2", isPlaying: false, trackTitle: "Song 2" };
    assert.equal(MediaModel.selectActivePlayer([p1, p2], { p1: 10, p2: 5 }, "p2"), p2);
  });

  test("ignores idle players with empty metadata", () => {
    const idle = { dbusName: "idle", isPlaying: false, trackTitle: "" };
    assert.equal(MediaModel.selectActivePlayer([idle], {}), null);
  });
});

describe("MediaModel.filterSourcePlayers", () => {
  test("filters out idle players without media", () => {
    const active = { dbusName: "active", trackTitle: "Song", isPlaying: true };
    const idle = { dbusName: "idle", trackTitle: "", isPlaying: false };
    const list = MediaModel.filterSourcePlayers([active, idle]);
    assert.equal(list.length, 1);
    assert.equal(list[0], active);
  });
});
