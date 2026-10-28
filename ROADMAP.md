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
3. **Tabs on a PC (proposal, mocked up):** All · Favorites · Games ·
   Emulators · Launchers · Apps · Tools. The genre in the file picks the tab:
   `Game` → Games, `Emulator` → Emulators, `Launcher` → Launchers (Steam, Epic,
   GOG Galaxy, Playnite, Heroic, Battle.net, EA app), `App` → Apps (Discord,
   browser, Spotify, OBS), `Tool` → Tools (File Explorer / Files, Task Manager,
   OS settings, controller tools). Same icons on Windows and Linux; Tools uses a
   monitor icon instead of the phone. "Move to…" in the quick menu works as on
   Android.
   **Power tile (PC only):** joins the bar at the foot of the drawer and pops
   out like the guide's menus: Sleep, Restart, Shut down, Exit to desktop —
   entries tagged `Power` in the PC Apps file.
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

Builds: (A) source collection + tab mapping + PC icon — done, build 57; (B) starter
file — done, build 57, icon set and PC Apps tile art build 59; (C) mouse, right-click and wide art — done, build 58;
(D) optional PC games — done, build 59 (no Discover tile on PC either); the "App drawer source" setting — done, build 61. **Section complete.**

## 2. All Games as the Xbox "Full library" (big phase, after the PC drawer)

Rebuild the All Games screen to look like the Xbox's Full library: a left
rail (Search, Games, Apps, Groups, Full library, Manage) with counts, a top
tab strip (All games, and the theme's own groupings), a "Sort by" dropdown
and a Filters button, an item count, and a grid of big square art tiles with
the title on the focused tile. The accent colour stays user-selectable, as it
is on the Xbox. Many staged steps; plan and mock it up before starting.

## 3. Home as the Xbox Series home (future phase)

The end goal is a close copy of the Xbox Series UI, page by page. For Home:

- **Top row of 9 tiles**, matching the Xbox: the same gap from the top of the
  screen to the row, the same left/right margins and gaps between tiles, and
  the same focus growth (the focused tile grows to about 1.7x with its name
  bar). On handhelds 9 tiles read small, so a setting offers **7** (today's
  count, adjusted to the same margins and gaps).
- **The four wide tiles under the row** (on the Xbox: Browse your games,
  Customize your Home, a featured game, a promo): undecided. Options to mock
  up: shortcuts (All Games, Settings / Customize, Discover, Achievements), the
  last-played or a featured game, or drop them and start Collections 1–6
  there.
- **Rows below** stay Collections 1–6, keeping the same left/right margins as
  the top row.

Mock up before starting.

## 4. Quality modes per platform (future note)

- **Base and High Quality on both platforms, tuned per platform:**
  Android base renders like 720p, HQ like 1080p; Windows/Linux base 1080p,
  HQ 4K. Today the theme scales image decode sizes and blurs this way (build
  50); rendering the whole screen at a lower resolution would need a
  prototype first (a full-screen layer breaks video cropping, see
  ItemHighlight).
- **Refresh rate:** a theme can't set the display's refresh rate — Pegasus
  draws at the screen's own rate. A frame cap isn't available to themes
  either. (Worth revisiting in the Pegasus fork.)
- **App drawer blur as its own setting** — done, build 60 (Off by default;
  base mode blurs at half size).

## 5. Clean-up and release

- Delete the old `windows-wip`, `pdf-manuals` and `perf-tiles` branches
  (everything useful from `windows-wip` is in `refresh` as of build 51).
- Merge `refresh` into `main`.
