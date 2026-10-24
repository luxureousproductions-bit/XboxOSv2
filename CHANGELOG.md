# Changelog

All notable changes to XboxOSv2, newest first. Dates are when each update was finished. Updates before this one were rebuilt from the project's commit history.

---

## Unreleased — refresh branch (build 12)

### New: Startup intro
- When Pegasus starts with XboxOSv2, an Xbox intro covers the moment Pegasus hands over to the theme, then fades into Home. It never plays when you come back from a game.
- To use your own intro video, put it at `assets/video/intro.mp4` in the theme folder. Without one, the intro shows a still image (`assets/images/intro.jpg`) for a few seconds. The startup chime plays once, right as the theme appears.
- Turn it off in **Settings → Advanced → Startup intro**.

### Startup chime
- The chime now plays right as the theme appears. Before, it started when the theme finished loading, while Pegasus's own loading screen was still showing.

### Home
- The hero tile (your last-played game) now gets its rounded corners without a mask, like the system tiles in build 7. It looks the same.

## Build 7

### Home system strip
- System tile backgrounds now get their rounded corners in a single drawing step, instead of a mask that kept two hidden copies of the image on every tile. They look the same. If a device's graphics can't run that step, the tile shows the background without rounded corners instead of nothing.

## Build 6

### Home system strip
- The name bar on the selected system tile now gets its rounded bottom corners from simple shapes, instead of a mask that built two hidden off-screen images every time you moved to a new tile. It looks the same.

## Build 5

### Home system strip
- Each step along the system strip decoded that system's background image twice at full resolution: once only to check the file exists, then again to show it. The check now uses a tiny thumbnail, so each step does one full decode instead of two. Backgrounds look the same.

## Build 4

### Home rows
- What Home hides (hidden apps, hidden emulators, hidden titles, duplicate imports) is now worked out once for the whole library, instead of separately by each of the seven Home rows for every game. Rows rebuild faster at startup and when you change a Hide option.

## Build 3

### Settings
- Settings are now saved once you stop changing them, instead of on every press. Holding left or right to scroll through a row's options used to rewrite the whole settings file about 100 times; now it's about 5. Changes still apply immediately.
- Saving is guaranteed before anything that could end the session: launching a game, leaving Settings, or Pegasus going to the background.
- All screens now share one list of default values. Two places disagreed with the Settings page:
  - On a fresh install, the featured box behaved as **Favorites** while Settings said **Fanart Slideshow**. It now follows Settings.
  - Some locked rows on the Settings page assumed the wrong default tile shape.
- Settings shows the actual default for every row on a fresh install, not just the first option in the list.
- Fixed an error the Settings page wrote to the log for every row.

## Build 2

### Coming back from a game
- The theme now remembers where you were by the game itself (system, ROM file and title), not by its position in the library. A rescan, a late SD card or an import can no longer bring you back to the wrong game. If the game is gone, you land on Home instead of an empty details page.
- Launching now saves one setting instead of ten. Pegasus rewrites the whole settings file on every save, so this was ten full rewrites right before the game started.
- With instant return (Pegasus X), the any-button return or a cancelled launch, the return info is now cleared. Before, it stayed saved, and the next cold start (even days later) jumped back to that old screen.
- A failed launch (no launch command, app not installed) now leaves the splash right away instead of waiting for a button press.
- Games you'd stepped through before launching (Back history) now come back correctly. They used to be saved in a form that couldn't be restored.

### Smaller settings file
- RetroAchievements system lists are saved in a compact form, keeping only games that have achievements. A full list could be several MB, and it made every setting change slower. Lists saved by older builds are shrunk the first time they're used.
- The Home screen's random rows save one setting instead of four.

## Build 1

### Game details
- The **RetroAchievements** button only shows when the game has achievements, the same way the **Manual** button only shows when a manual exists. It also hides when RA isn't set up in Settings.
- Manuals are looked up only when Game details opens, and once per game. Before, the lookup ran in the background on every move on the Home screen.

### Fixes
- All Games now returns to the row you were on, as intended. An error had been stopping that code from running.
- The Filters panel dims the rows you're not on and bolds the one you are on, as designed.
- The Home featured video retries if it fails to start. The retry had never worked.
- Fixed about 60 errors per Home scroll that were written to `lastrun.log`.

### Performance
- System logos are resized to fit how big they're shown (5.9 MB → 3.2 MB), and the platform page logo loads without blocking.
- Tile art is smoothed when scaled down, which looks cleaner and costs no extra time.
- The Home screen stops animating behind other screens.
- The `lastrun.log` collection dump is off by default.

### Logging
- The first theme line in `lastrun.log` now shows the theme build number and which Pegasus features were found (Pegasus X or stock, PDF, manual lookup), plus the OS, resolution and HQ mode.

## October 13, 2026 — Search & App Drawer update

### New: Library Search
- Search your whole library from the new **Search** button on the Home page (between RetroAchievements and Settings) or the **Search** tile in the app drawer.
- Picking a result opens that game's details page, and **B** takes you back to your results.
- The search screen is titled **Search Library**; the RetroAchievements version is titled **RA Search**.

### RetroAchievements
- RA Search is faster and more responsive, and **B** after opening a game now returns you to your results.
- Your RA stats line now swaps smoothly between your **points** and your **rank** every 15 seconds, like the Xbox profile card. It appears on every RA page (overview, game achievements, and the "no achievements" page) and on the Home page when RA is set as the logo.

### App Drawer Rework
The app drawer has been rebuilt to work more like the Xbox guide.

**What shows up in it**
- Apps from Pegasus's **Android app import**.
- Your own entries in a collection named **Android** or with the shortname `android` — these merge with the Pegasus import into one list.
- Your Android games, in a collection with the shortname `androidgames`.
- If the same app is both imported by Pegasus and in your own collection, it only appears once, and your entry takes priority.

**Layout**
- Always shows exactly **4 apps** at a time, with larger icons.
- Apps are sorted into tabs (Games, Emulators, System, Other). Move any app to another tab from its quick menu (**Start**), or reset it to automatic.
- New **Search** tile next to Settings.

**Hiding apps**
- One **Hide** option in the quick menu opens a small panel with three choices:
  - **App drawer only** — hidden in the drawer, still shown in your library
  - **Library only** — hidden from your library, still shown in the drawer
  - **Both** — hidden everywhere

**Launching**
- Anything opened from the drawer **launches instantly**.
- In your library, Android games follow the **Added App Launch** setting.

**Tile Halo**
- With **Tile Halo** on, every highlight in the drawer gets the accent glow.

### Hide Apps & Emulators
- **Hide emulators** now works for Pegasus-imported emulators too — anything in the drawer's **Emulators** tab counts, as well as entries with the genre `Emulator`.
- **Hide apps** and **Hide emulators** are separate, and Android games are never hidden along with apps.
- Changes apply **right away** — no theme reload needed, including the hero tile on the Home page.

### Android System Tiles
- Android tiles are pinned to the front of the system row: **Android → Android Apps → Android Games**.
- New setting: **Hide Android Games System Tile** (off by default).

### Duplicate Cleanup
- If an app or game is in both the Pegasus import and your own collection, the duplicate no longer shows on the Home page, in All Games, or on the Android platform page.

### Fixes & Polish
- Media carousel videos start quickly again, and the highlight no longer distorts the thumbnail.
- The game details header bar now fades in when you reach the first "More games" row instead of the media carousel.
- Fixed a blue flash on the previously highlighted item when moving through the app drawer with Tile Halo on.
- Fixed crashes on Windows.
- "More info" help text reworded throughout Settings.

### ⚠️ Heads up
- The custom background file is now **lowercase**: `assets/images/backgrounds/background.png`. If you use your own background named `Background.png`, rename it to lowercase. When updating, delete the old `Background.png` first.

---

## October 2, 2026 — Readability polish

- New **Bottom fade** setting: how strongly the last row fades out above the button prompts on the Platform page, All Games, Game details and the RetroAchievements pages.
- New **Grid background dimming** setting (Sept 27): slightly darkens the area below the header on those same pages so tiles and text stand out.

---

## September 19, 2026 — All Games grid & per-system tiles

### All Games
- New **Grid view** for the All Games menu, alongside the original List view.
- The grid has its own tile shape, ratio, art, logo and tiles-per-row, or turn on **Match Platform** to mirror the Platform page.

### Platform page
- **Per-system tile settings:** press **Y** on a Platform page to give that system its own tile shape, ratio, art, logo, tiles per row and titles.

### Home page
- New **System** row type: "Play something new" from a randomly picked system. Two System rows always pick different systems.
- New **System tile titles** setting: show system names on focus, always, or never.

### Settings
- Settings pages are now grouped under section headers (Layout, Background, Titles, Appearance and more).

### Mouse
- The mouse wheel now moves the selection through lists and grids instead of drifting the view.

---

## September 12, 2026 — High Quality Mode

- New **High Quality Mode** for capable devices: sharper full-screen video, faster video previews, crisper art and icons, smoother transitions, and a blurred backdrop behind the app drawer. Off by default, so low-end devices keep running smoothly.
- New **Dynamic Background**: a slow, gentle zoom and drift on the Home page background.
- New **Screenshot Fallback**: games without fanart can show a screenshot as the Home background instead.
- New **Added App Launch** setting: apps and Android games you added yourself can launch instantly or open their details page first.
- New **LB/RB Function** setting for the Platform page: cycle systems, or step along the nav bar.

---

## September 1, 2026 — App Drawer

*(built August 18 – September 1)*

- New **App drawer**, opened with **Select** from anywhere and modeled on the Xbox guide.
- Shows your Pegasus-imported Android apps and your own app entries, sorted into tabs.
- Quick menu to favorite, hide, or move apps between tabs.
- New **Hide Android System Tile** setting (Aug 26), since the drawer now holds those apps.
- Every setting now has a **More info** page (Aug 25): press **X** on a setting to see what it does.

---

## August 17, 2026 — On-screen keyboard & UI scale

- New controller-friendly **on-screen keyboard**, used for searching and for entering your RetroAchievements login.
- New **UI Scale** setting (Aug 12) to enlarge text for handheld screens.
- Long text such as genres or titles now scrolls once to reveal itself instead of being cut off.

---

## August 14, 2026 — Featured box

*(built August 6 – August 14)*

- New **Featured box** on the Home page, pinned to the collection row of your choice.
- Shows your **Favorites**, a **Fanart slideshow**, or **Discover videos** that carry straight into the Discover page.
- New **Favorited Tile Accent**: a colored edge on favorited games so they stand out.
- "Favorite Games" renamed to **My Favorites**.

---

## June 18, 2026 — Tile size options

- Every Home collection row now has its own **tile size** (Small / Medium / Large) and exact **tile ratio**.
- Platform page tiles get an exact **tile ratio** too, replacing the old fixed Wide/Tall ratios.
- More **Launch screen delay** choices.

---

## June 13, 2026 — Status bar, mouse & touch

- Clock, battery and Wi-Fi now appear consistently on every page and follow the same settings everywhere.
- Mouse and touchscreen fixes throughout the theme.
- New **Randomize System Tile Fanart** (Jun 10): the background behind a system tile is picked at random from that system's games.

---

## June 7, 2026 — Home page redesign

*(built May 19 – June 7)*

### Home page
- Redesigned Home page modeled on the Xbox dashboard.
- New **system row** with a large **hero tile** for your last-played game, and **system background art** behind the page as you move along the row (May 27).
- New **Hero box art** setting: fanart, box front or screenshot.
- New **System sort** setting (Jun 2): alphabetical, release year, manufacturer, and more.
- New **Profile corner** (May 29): two Xbox logo styles, or your **RetroAchievements profile**, optionally tinted to your accent color with **Logo Color Match**.
- Home background controls: **Showcase Background Art**, **Background Opacity**, and **Custom Background** using your own image (May 20).
- **Tile Halo** (Jun 7): a soft accent glow around the highlighted tile.
- New **Gradient** color options.

### Sounds
- New **menu sounds** with a volume setting, and a **startup chime** (May 29–30).
- Separate video audio settings for Home tiles, Discover, Game details and All Games.

### Platform page
- New **Grid art** (fanart, screenshot or box front) and **Grid Game Logo** settings (Jun 1).

### Other
- New **Launch screen delay** setting (Jun 5).
- Collection rows renamed: **Most Popular**, **Games We Picked For You**.

---

## May 22, 2026 — Full Library (All Games menu)

- New **All Games** menu (originally "Full Library"): your whole library in one scrolling list with a preview panel.
- Filters, sorting, and video previews with optional blur and scanlines (May 31).

---

## May 17, 2026 — Discover

- The random video mode (added May 3) became the **Discover** page: full-screen game videos that auto-advance, with launch, details and hide-info controls. Opened with **B** on the Home page.
- **Clock, battery and Wi-Fi** settings (May 16).
- RetroAchievements screens get their own status bar (May 15).

---

## May 9, 2026 — Settings & look refresh

- Settings options standardized to **Yes / No**.
- New **color layout** options (May 7).
- Load-time optimizations for older Android devices (May 6).
- Updated the theme to Qt 5.15 throughout.

---

## May 4, 2026 — RetroAchievements

*(built May 1 – May 4)*

- **RetroAchievements integration**: sign in with your username and API key in Settings.
- **Overview** of your recently played games with achievement progress.
- **Per-game achievements** page, opened from the trophy button on any game's details page.
- Smarter title matching (handles "The" suffixes and prefers official entries over hacks), plus more supported consoles, including PS2 and PSP.
- New **random video mode** on the Home page (May 3), which later became Discover.
- **Wi-Fi and battery** indicators on the Home page (May 4).

---

## April 29, 2026 — More lists & genres

*(built April 22 – April 29)*

- New **More by Publisher / Developer** row on Game details, falling back to recommended games when there's nothing else.
- New **More by Genre Display** setting (Apr 28): match on the full genre, the main genre, or the subgenre.
- Genres split correctly on `/` or `,`, with or without spaces.
- Apps and emulators show an **Open** button instead of **Play game**.
- Performance passes for faster loading and smoother transitions on lower-end hardware (Apr 25–26).
- New **Omit genre: Application / Emulator from Showcase** settings (Apr 24).

---

## April 20, 2026 — XboxOS-V2

- The theme is renamed **XboxOS-V2** (version 2.0).
- **Search by genre** on the Platform page, including subgenres.
- **Publisher, developer and release date** on Game details.
- New **3D Box** tile shape on the Platform page.
- **Refresh** (X) reshuffles the Home rows, and your random rows are remembered between sessions.
- New **Showcase Art** setting: fanart or screenshot on Home tiles.

---

## April 15, 2026 — Media carousel controls (v1.2)

- Turn each **media carousel** type on or off: video, screenshots, title screen, fanart, 2D box, 3D box, back of box, cartridge, miximage and logo.
- New **Box Art** style setting: 2D, 3D or Miximage.
- New **Game Counter** toggle.
- Preview videos now play when highlighted in the media carousel (Apr 13).

---

## April 9, 2026 — First fork update (v1.0)

- Added **3D box, miximage, title screen, back of box and cartridge** media to Game details.
- New Home row types: **Top by Developer** and **Top by Genre 2**.
- Added a **6th** Home collection row.
- Fanart priority fixes on the Home page.

---

## Origins

- **2018 – 2020:** [gameOS](https://github.com/PlayingKarrde/gameOS) by **Seth Powell**.
- **November 2020 – January 2021:** **XboxOS V1** by **Alfred Olvera**.
- **April 2026:** XboxOSv2 development begins, by Esteban (MisterE88).
