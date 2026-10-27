// gameOS theme
// Copyright (C) 2018-2020 Seth Powell 
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by the
// Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

// This file contains some helper scripts for formatting data


// For multiplayer games, show the player count as '1-N'
function formatPlayers(playerCount) {
    if (playerCount === 1)
        return playerCount

    return "1-" + playerCount;
}


// Show dates in Y-M-D format
function formatDate(date) {
    return Qt.formatDate(date, "yyyy-MM-dd");
}


// Show last played time as text. Based on the code of the default Pegasus theme.
// Note to self: I should probably move this into the API.
function formatLastPlayed(lastPlayed) {
    if (isNaN(lastPlayed))
        return "never";

    var now = new Date();

    var elapsedHours = (now.getTime() - lastPlayed.getTime()) / 1000 / 60 / 60;
    if (elapsedHours < 24 && now.getDate() === lastPlayed.getDate())
        return "today";

    var elapsedDays = Math.round(elapsedHours / 24);
    if (elapsedDays <= 1)
        return "yesterday";

    return elapsedDays + " days ago"
}


// Display the play time (provided in seconds) with text.
// Based on the code of the default Pegasus theme.
// Note to self: I should probably move this into the API.
function formatPlayTime(playTime) {
    var minutes = Math.ceil(playTime / 60)
    if (minutes <= 90)
        return Math.round(minutes) + " minutes";

    return parseFloat((minutes / 60).toFixed(1)) + " hours"
}

// Process the platform name to make it friendly for the logo
// Unfortunately necessary for LaunchBox
function processPlatformName(platform) {
  // Asset files are lowercase. Windows and Android ignore case in file names;
  // Linux doesn't, so a shortname like "SNES" found no logo there.
  platform = String(platform || "").toLowerCase();
  switch (platform) {
    case "panasonic 3do":
      return "3do";
      break;
    case "3do interactive multiplayer":
      return "3do";
      break;
    case "amstrad cpc":
      return "amstradcpc";
      break;
    case "apple ii":
      return "apple2";
      break;
    case "atari 800":
      return "atari800";
      break;
    case "atari 2600":
      return "atari2600";
      break;
    case "atari 5200":
      return "atari5200";
      break;
    case "atari 7800":
      return "atari7800";
      break;
    case "atari jaguar":
      return "atarijaguar";
      break;
    case "atari jaguar cd":
      return "atarijaguarcd";
      break;
    case "atari lynx":
      return "atarilynx";
      break;
    case "atari st":
      return "atarist";
      break;
    case "commodore 64":
      return "c64";
      break;
    case "tandy trs-80":
      return "coco";
      break;
    case "commodore amiga":
      return "amiga";
      break;
    case "sega dreamcast":
      return "dreamcast";
      break;
    case "final burn alpha":
      return "fba";
      break;
    case "sega game gear":
      return "gamegear";
      break;
    case "nintendo game boy":
      return "gb";
      break;
    case "nintendo game boy advance":
      return "gba";
      break;
    case "nintendo game boy color":
      return "gbc";
      break;
    case "nintendo gamecube":
      return "gc";
      break;
    case "sega genesis":
      return "genesis";
      break;
    case "mattel intellivision":
      return "intellivision";
      break;
    case "sammy atomiswave":
      return "atomiswave";
      break;
    case "sega master system":
      return "mastersystem";
      break;
    case "sega mega drive":
      return "megadrive";
      break;
    case "microsoft msx":
      return "msx";
      break;
    case "nintendo 64":
      return "n64";
      break;
    case "nintendo ds":
      return "nds";
      break;
    case "snk neo geo aes":
      return "neogeo";
      break;
    case "snk neo geo mvs":
      return "neogeo";
      break;
    case "snk neo geo cd":
      return "neogeocd";
      break;
    case "nintendo entertainment system":
      return "nes";
      break;
    case "snk neo geo pocket":
      return "ngp";
      break;
    case "snk neo geo pocket color":
      return "ngpc";
      break;
    case "sega cd":
      return "segacd";
      break;
    case "nec turbografx-16":
      return "turbografx16";
      break;
    case "sony psp":
      return "psp";
      break;
    case "sony playstation":
      return "psx";
      break;
    case "sony playstation 2":
      return "ps2";
      break;
    case "sony playstation 3":
      return "ps3";
      break;
    case "sony playstation vita":
      return "psvita";
      break;
    case "sega saturn":
      return "saturn";
      break;
    case "sega 32x":
      return "sega32x";
      break;
    case "super nintendo entertainment system":
      return "snes";
      break;
    case "nintendo wii":
      return "wii";
      break;
    case "nintendo wii u":
      return "wiiu";
      break;
    case "nintendo 3ds":
      return "3ds";
      break;
    case "microsoft xbox":
      return "xbox";
      break;
    case "microsoft xbox 360":
      return "xbox360";
      break;
    case "nintendo switch":
      return "switch";
      break;
    default:
      return platform;
  }
}

// ── System metadata for sorting the showcase system tiles ──────────────────
// Keyed by the normalized short name (the output of processPlatformName, i.e.
// the same key used for the logo/background filenames). Unknown systems fall
// back to year 9999 / maker "zzz" so they sort to the end without breaking
// anything — just add a line here when you add a new system.
var systemData = {
  // Nintendo
  "nes":          { year: 1983, maker: "Nintendo" },
  "snes":         { year: 1990, maker: "Nintendo" },
  "n64":          { year: 1996, maker: "Nintendo" },
  "gc":           { year: 2001, maker: "Nintendo" },
  "wii":          { year: 2006, maker: "Nintendo" },
  "wiiu":         { year: 2012, maker: "Nintendo" },
  "switch":       { year: 2017, maker: "Nintendo" },
  "gb":           { year: 1989, maker: "Nintendo" },
  "gbc":          { year: 1998, maker: "Nintendo" },
  "gba":          { year: 2001, maker: "Nintendo" },
  "nds":          { year: 2004, maker: "Nintendo" },
  "3ds":          { year: 2011, maker: "Nintendo" },
  "virtualboy":   { year: 1995, maker: "Nintendo" },
  // Sega
  "sg1000":       { year: 1983, maker: "Sega" },
  "mastersystem": { year: 1985, maker: "Sega" },
  "genesis":      { year: 1988, maker: "Sega" },
  "megadrive":    { year: 1988, maker: "Sega" },
  "segacd":       { year: 1991, maker: "Sega" },
  "sega32x":      { year: 1994, maker: "Sega" },
  "saturn":       { year: 1994, maker: "Sega" },
  "dreamcast":    { year: 1998, maker: "Sega" },
  "gamegear":     { year: 1990, maker: "Sega" },
  // Sony
  "psx":          { year: 1994, maker: "Sony" },
  "ps2":          { year: 2000, maker: "Sony" },
  "ps3":          { year: 2006, maker: "Sony" },
  "psp":          { year: 2004, maker: "Sony" },
  "psvita":         { year: 2011, maker: "Sony" },
  // Microsoft
  "xbox":         { year: 2001, maker: "Microsoft" },
  "xbox360":      { year: 2005, maker: "Microsoft" },
  "msx":          { year: 1983, maker: "Microsoft" },
  // Atari
  "atari2600":    { year: 1977, maker: "Atari" },
  "atari5200":    { year: 1982, maker: "Atari" },
  "atari7800":    { year: 1986, maker: "Atari" },
  "atari800":     { year: 1979, maker: "Atari" },
  "atarist":      { year: 1985, maker: "Atari" },
  "atarilynx":    { year: 1989, maker: "Atari" },
  "atarijaguar":  { year: 1993, maker: "Atari" },
  "atarijaguarcd":{ year: 1995, maker: "Atari" },
  // SNK
  "neogeo":       { year: 1990, maker: "SNK" },
  "neogeocd":     { year: 1994, maker: "SNK" },
  "ngp":          { year: 1998, maker: "SNK" },
  "ngpc":         { year: 1999, maker: "SNK" },
  // NEC
  "turbografx16": { year: 1987, maker: "NEC" },
  "pcengine":     { year: 1987, maker: "NEC" },
  "pcenginecd":   { year: 1988, maker: "NEC" },
  "supergrafx":   { year: 1989, maker: "NEC" },
  // Commodore
  "c64":          { year: 1982, maker: "Commodore" },
  "amiga":        { year: 1985, maker: "Commodore" },
  "vic20":        { year: 1980, maker: "Commodore" },
  // Others
  "3do":          { year: 1993, maker: "Panasonic" },
  "intellivision":{ year: 1979, maker: "Mattel" },
  "colecovision": { year: 1982, maker: "Coleco" },
  "amstradcpc":   { year: 1984, maker: "Amstrad" },
  "apple2":       { year: 1977, maker: "Apple" },
  "coco":         { year: 1980, maker: "Tandy" },
  "atomiswave":   { year: 2003, maker: "Sammy" },
  "wonderswan":   { year: 1999, maker: "Bandai" },
  "wonderswancolor":{ year: 2000, maker: "Bandai" },
  "fba":          { year: 1985, maker: "Arcade" },
  "arcade":       { year: 1980, maker: "Arcade" },
  "mame":         { year: 1980, maker: "Arcade" }
};

function systemYear(shortName) {
  var d = systemData[processPlatformName(shortName)];
  return d ? d.year : 9999;
}

function systemMaker(shortName) {
  var d = systemData[processPlatformName(shortName)];
  return d ? d.maker : "zzz";
}

function processButtonArt(button) {
  var buttonModel;
  switch (button) {
    case "accept":
      buttonModel = api.keys.accept;
      break;
    case "cancel":
      buttonModel = api.keys.cancel;
      break;
    case "filters":
      buttonModel = api.keys.filters;
      break;
    case "details":
      buttonModel = api.keys.details;
      break;
    case "nextPage":
      buttonModel = api.keys.nextPage;
      break;
    case "prevPage":
      buttonModel = api.keys.prevPage;
      break;
    case "pageUp":
      buttonModel = api.keys.pageUp;
      break;
      case "pageDown":
        buttonModel = api.keys.pageDown;
        break;
    case "menu":   // Start (controller/11.png)
      buttonModel = api.keys.menu;
      break;
    default:
      buttonModel = api.keys.accept;
  }

  // `i < length`: see the same function in Global/ButtonHelpBar.qml.
  for (var i = 0; i < buttonModel.length; i++) {
    if (buttonModel[i].name().includes("Gamepad")) {
      var buttonValue = buttonModel[i].key.toString(16)
      // Last hex digit of the gamepad key = button index (A 0 ... Select a,
      // Start b); the glyph files are named in decimal (10.png, 11.png)
      return String(parseInt(buttonValue.substring(buttonValue.length-1, buttonValue.length), 16));
    }
  }
  // Unbound (keyboard-only): the default controller glyph.
  var fallback = { accept: "0", cancel: "1", details: "2", filters: "3",
                   prevPage: "4", nextPage: "5", pageUp: "6", pageDown: "7", menu: "11" };
  return fallback[button] || "0";
}

function steamAppID (gameData) {
  var str = gameData.assets.boxFront.split("header");
  return str[0];
}

function steamBoxArt(gameData) {
  return steamAppID(gameData) + '/library_600x900_2x.jpg';
}

function steamLogo(gameData) {
  return steamAppID(gameData) + "/logo.png"
}

function steamHero(gameData) {
  return steamAppID(gameData) + "/library_hero.jpg"
}

// Just use boxFront?
function steamHeader(gameData) {
  return steamAppID(gameData) + "/header.jpg"
}

function is3dPath(path) {
  if (!path) return false;
  var p = path.toLowerCase();
  return p.includes("box3d") || p.includes("box_3d") || p.includes("3dbox");
}

// Pegasus X (build 2124+) lists a game's 3D box renders in extra.box3d
// (file:/// URLs), decided from folder/file names in any spelling. Stock
// Pegasus doesn't, so the file-name test above stays as the fallback.
function urlKey(u) {
  var s = String(u || "");
  if (s.indexOf("file://") === 0) s = s.substring(7);
  try { s = decodeURIComponent(s); } catch (e) {}
  return s;
}
function box3dList(game) {
  var l = (game && game.extra) ? game.extra.box3d : null;
  if (!l) return [];
  return (typeof l === "string") ? [l] : l;
}
function is3dFor(game, path) {
  if (!path) return false;
  var l = box3dList(game);
  if (l.length) {
    var k = urlKey(path);
    for (var i = 0; i < l.length; i++) if (urlKey(l[i]) === k) return true;
  }
  return is3dPath(String(path));
}

function get3dBoxArt(data) {
  if (data != null) {
    var px = box3dList(data);
    if (px.length) return px[0];             // Pegasus X: known 3D box
    // In Pegasus, box3d and box2dFront are NOT separate QML properties — both are stored in
    // the single BOX_FRONT slot. boxFrontList holds ALL box images for this game.
    // Scan the list for the first entry whose file path identifies it as 3D box art
    // (same logic MediaItem.qml already uses for the "3D Box" label).
    var list = data.assets.boxFrontList;
    if (list) {
      for (var i = 0; i < list.length; i++) {
        if (is3dFor(data, list[i])) return list[i];
      }
    }
    // No 3D art found in the list.
    if (is3dFor(data, data.assets.boxFront)) return data.assets.boxFront;
  }
  return "";
}

function getMiximage(data) {
  if (data != null) {
    // In Pegasus Frontend, steamgrid/miximage images are stored as UI_STEAMGRID,
    // exposed in QML as data.assets.steam / data.assets.steamList.
    // Folder names 'steam', 'steamgrid', and 'grid' all map to this slot.
    // Skyscraper outputs these in a 'steamgrid' folder; some setups use 'miximage'.
    if (data.assets.steamList) {
      // Prefer any entry whose file path specifically identifies it as a miximage.
      for (var i = 0; i < data.assets.steamList.length; i++) {
        var p = data.assets.steamList[i].toLowerCase();
        if (p.includes("miximage") || p.includes("mix_image"))
          return data.assets.steamList[i];
      }
      // Fall back to the first steamgrid/steam entry.
      if (data.assets.steam) return data.assets.steam;
    }
    // Also scan boxFrontList for paths that look like miximage
    // (some scrapers file miximage under the box front slot).
    if (data.assets.boxFrontList) {
      for (var j = 0; j < data.assets.boxFrontList.length; j++) {
        var bp = data.assets.boxFrontList[j].toLowerCase();
        if (bp.includes("miximage") || bp.includes("mix_image"))
          return data.assets.boxFrontList[j];
      }
    }
  }
  return "";
}

function boxArt(data, style) {
  if (style === undefined) style = "2D";
  if (data != null) {
    if (style === "3D") {
      var art3d = get3dBoxArt(data);
      if (art3d) return art3d;
      // No 3D art found — fall through to 2D
    } else if (style === "Miximage") {
      var mix = getMiximage(data);
      if (mix) return mix;
      // No miximage found — fall through to 2D
    }
    // "2D" (default) or fallback from 3D/Miximage
    if (data.assets.boxFront && data.assets.boxFront.includes("/header.jpg"))
      return steamBoxArt(data);
    if (data.assets.boxFront)
      return data.assets.boxFront;
    if (data.assets.boxBack)
      return data.assets.boxBack;
    if (data.assets.poster)
      return data.assets.poster;
    if (data.assets.banner)
      return data.assets.banner;
    if (data.assets.tile)
      return data.assets.tile;
    if (data.assets.cartridge)
      return data.assets.cartridge;
    var mix = getMiximage(data);
    if (mix)
      return mix;
    if (data.assets.logo)
      return data.assets.logo;
  }
  return "";
}

function logo(data) {
  if (data != null) {
    if (data.assets.boxFront && data.assets.boxFront.includes("/header.jpg")) 
      return steamLogo(data);
    else {
      if (data.assets.logo != "")
        return data.assets.logo;
    }
  }
  return "";
}

function fanArt(data) {
  if (data != null) {
    if (data.assets.boxFront && data.assets.boxFront.includes("/header.jpg")) 
      return steamHero(data);
    else {
      if (data.assets.background != "")
        return data.assets.background;
      else if (data.assets.screenshots[0])
        return data.assets.screenshots[0];
    }
  }
  return "";
}

// Place Steam collections at the beginning of the list
function reorderCollection(model) {
  for(var i=0; i<model.count; i++) {
    if (model.get(i).name == "Steam") {
      model.move(i,0);
      return model;
    }
  }
  return model;
}

// Shuffle function
function shuffle(model){
  var currentIndex = model.count, temporaryValue, randomIndex;

  // While there remain elements to shuffle...
  while (0 !== currentIndex) {
      // Pick a remaining element...
      randomIndex = Math.floor(Math.random() * currentIndex)
      currentIndex -= 1
      // And swap it with the current element.
      // the dictionaries maintain their reference so a copy should be made
      // https://stackoverflow.com/a/36645492/6622587
      temporaryValue = JSON.parse(JSON.stringify(model.get(currentIndex)))
      model.set(currentIndex, model.get(randomIndex))
      model.set(randomIndex, temporaryValue);
  }
  
  return model;
}

// The Home rows' random candidates — publishers, developers and genres — in
// ONE pass over the library, reading each game in place. The rows used to
// call uniqueValuesArray twice and uniqueGenreValues twice, and each copied
// the whole library to a JS array first (toVarArray): four copies of ~4,400
// games before the theme could appear. Same rules as those two functions.
function homePools(omitApplication, omitEmulator) {
  const pubs = new Set(), devs = new Set(), genres = new Set();
  const okGenre = (v) => {
    if (!v) return false;
    const l = v.toLowerCase();
    return l !== "application" && !(omitEmulator && l === "emulator");
  };
  const all = api.allGames;
  const n = all.count;
  for (let i = 0; i < n; i++) {
    const game = all.get(i);
    const gl = game.genreList || [];
    // Genre pool: every game but apps (and emulators when hidden).
    for (let j = 0; j < gl.length; j++) {
      const g = gl[j];
      if (!okGenre(g)) continue;
      genres.add(g);
      const m = g.match(/\s*[/,]\s*/);
      if (m) {
        const p = g.substring(0, m.index).trim();
        const q = g.substring(m.index + m[0].length).trim();
        if (okGenre(p)) genres.add(p);
        if (okGenre(q)) genres.add(q);
      }
    }
    // Publisher / developer pools skip games the rows filter out.
    if (omitApplication || omitEmulator) {
      let skip = false;
      for (let j = 0; j < gl.length; j++) {
        const l = (gl[j] || "").toLowerCase();
        if ((omitApplication && l === "application") || (omitEmulator && l === "emulator")) { skip = true; break; }
      }
      if (skip) continue;
    }
    const pub = game.publisher ? String(game.publisher).trim() : "";
    const dev = game.developer ? String(game.developer).trim() : "";
    if (pub) pubs.add(pub);
    if (dev) devs.add(dev);
  }
  return { publishers: [...pubs].sort(), developers: [...devs].sort(), genres: [...genres].sort() };
}

// Escapes a string for literal use in a RegExp. Genre and publisher names carry
// characters that are regex syntax — "Role-Playing (RPG)" as a raw pattern
// becomes a capture group and matches nothing, which is why some rows came up
// empty.
function escapeRegExp(str) {
  return String(str).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function shuffleArray(array) {
  var currentIndex = array.length, temporaryValue, randomIndex;

  // While there remain elements to shuffle...
  while (0 !== currentIndex) {

      // Pick a remaining element...
      randomIndex = Math.floor(Math.random() * currentIndex);
      currentIndex -= 1;

      // And swap it with the current element.
      temporaryValue = array[currentIndex];
      array[currentIndex] = array[randomIndex];
      array[randomIndex] = temporaryValue;
  }

  return array;
}

function returnRandom(array) {
  return array[Math.floor(Math.random() * array.length)];
}


// True for any common video file, any capitals (.MP4, .mkv and .avi are usual on PC).
function isVideoFile(path) {
  return /\.(mp4|webm|mkv|avi|mov|m4v|wmv|flv|mpe?g|ogv)$/i.test(String(path || ""));
}
