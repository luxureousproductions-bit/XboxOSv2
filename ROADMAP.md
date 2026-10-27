# XboxOSv2 – roadmap

What's planned after the refresh branch, in rough order. Each item is its own
staged build. Goal for the whole theme: look and feel like the Xbox dashboard
(2023).

## 1. App drawer on Windows / Linux

The drawer already reads entries "you added yourself" (genre hints), so a PC
apps collection mostly works today. In a test with a hand-written collection
(emulators, launchers, tools, power entries, a few games), the Emulators tab
filled correctly; everything else needs the steps below.

**What the drawer becomes on a PC:** one place for everything that isn't a
console game in your library: emulators, launchers (Steam, Playnite, GOG,
Lutris, Heroic), everyday apps (Discord, a browser, File Explorer), and power
entries (sleep, restart, shut down). Same look, same tabs, same quick menu
(favourite, hide, move to tab) as on Android.

1. **Source collection.** On a PC the drawer reads a collection named
   **"PC Apps"** (shortname `pcapps`), not "Android". Settings › System gets an
   "App drawer source" row listing your collections, for anyone who names it
   differently. Android keeps "Android".
2. **Starter file.** Ship `extras/pc-apps/metadata.pegasus.txt`: a ready-made
   collection with commented-out entries for common emulators, launchers and
   tools, plus Windows and Linux power commands (sleep, restart, shut down),
   each with its genre set (Emulator / Launcher / App / System). You uncomment
   what you have, fix the paths, and drop the folder in your Pegasus game
   folders. A small icon set (generic, no brand logos) comes with it.
3. **Tabs on a PC.** All · Favorites · Games · Emulators · Launchers · System ·
   Other. The genre in the file picks the tab: `Game` → Games, `Emulator` →
   Emulators, `Launcher` → Launchers, `System` → System, anything else → Other.
   The quick menu's "Move to…" moves an entry, as on Android. The System tab
   gets a PC icon instead of the phone.
4. **PC games in the drawer (optional).** A setting adds your Steam, GOG,
   Playnite or Lutris collections to the Games tab, so installed PC games can
   be launched from the drawer too. Off by default (they're already in the
   library).
5. **Art.** Uses the entry's icon or box art; wide images (Steam headers) sit
   centred on the icon plate instead of being cropped. No art → the letter tile,
   as now.
6. **Mouse and keyboard.** Tab (already) or a click on Apps opens it; hover
   picks a row, click launches, right-click opens the quick menu, the wheel
   scrolls, Esc closes.
7. **Home.** The "Hide Android System Tile" settings read "Hide PC Apps system
   tile" on a PC.

Builds: (A) source collection + tab mapping + PC icon; (B) starter file and
icons; (C) mouse, right-click and wide art; (D) optional PC games.

## 2. Quality modes per platform (future note)

- **Base and High Quality on both platforms, tuned per platform:**
  Android base renders like 720p, HQ like 1080p; Windows/Linux base 1080p,
  HQ 4K. Today the theme scales image decode sizes and blurs this way (build
  50); rendering the whole screen at a lower resolution would need a
  prototype first (a full-screen layer breaks video cropping, see
  ItemHighlight).
- **Refresh rate:** a theme can't set the display's refresh rate — Pegasus
  draws at the screen's own rate. A frame cap isn't available to themes
  either. (Worth revisiting in the Pegasus fork.)
- **App drawer blur as its own setting** instead of locked to High Quality:
  Off / On. Base mode renders the blur at a lower resolution than HQ. The
  Xbox guide itself doesn't blur when it slides out, so the default is Off.

## 3. Clean-up and release

- Delete the old `windows-wip`, `pdf-manuals` and `perf-tiles` branches
  (everything useful from `windows-wip` is in `refresh` as of build 51).
- Merge `refresh` into `main`.
