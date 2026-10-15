# XboxOSv2

**A modern, Xbox-inspired theme for [Pegasus Frontend](https://pegasus-frontend.org), built for Android handhelds and controller-first play.**

XboxOSv2 is a fork of a fork of [gameOS](https://github.com/PlayingKarrde/gameOS) — it continues the work of [XboxOS](https://github.com/alfredolvera/XboxOS) and modernizes it with a Home page modeled on the Xbox dashboard, an Xbox-guide-style app drawer, library search, full RetroAchievements integration, a Discover video mode, and a deep set of customization options.

<!-- 📷 HERO IMAGE: Home page, full width -->
<img width="1920" height="1080" alt="1000813882" src="https://github.com/user-attachments/assets/bc4ff12a-f80e-4691-80bd-993867c2dafc" />


📋 **What's new?** See the [changelog](CHANGELOG.md).

---

## Contents

- [Installation](#installation)
- [Controls at a glance](#controls-at-a-glance)
- [Home page](#home-page)
- [App drawer](#app-drawer)
- [Library search](#library-search)
- [Platform page](#platform-page)
- [All Games menu](#all-games-menu)
- [Discover](#discover)
- [Game details](#game-details)
- [Game manuals](#game-manuals) *(in development, needs Pegasus X)*
- [RetroAchievements](#retroachievements)
- [Settings](#settings)
- [Base mode vs High Quality mode](#base-mode-vs-high-quality-mode)
- [Setting up Android apps & games](#setting-up-android-apps--games)
- [Customizing with your own images](#customizing-with-your-own-images)
- [Metadata & media](#metadata--media)
- [Tips & hidden features](#tips--hidden-features)
- [Credits](#credits)

---

## Installation

1. Download the [latest release](https://github.com/luxureousproductions-bit/XboxOSv2/releases/latest).
2. Extract it into your [Pegasus theme directory](https://pegasus-frontend.org/docs/user-guide/installing-themes/).
3. Select **XboxOSv2** in Pegasus's settings and restart Pegasus.

> **Tip:** On older or budget devices, leave **High Quality Mode** off (it's off by default). See [Base mode vs High Quality mode](#base-mode-vs-high-quality-mode).

---

## Controls at a glance

Button prompts on screen always match your controller and Pegasus's button mapping. The table below uses the Xbox layout.

| Button | Home | Platform page | Game details | Anywhere |
|---|---|---|---|---|
| **A** | Select | Open game | Select | |
| **B** | Open **Discover** | Back | Back | |
| **X** | Refresh rows | Sort & filters | Toggle favorite | |
| **Y** | Settings | Settings *(or per-system tiles)* | Settings | |
| **LB / RB** | Jump to the nav bar | Previous / next system *(or nav bar)* | Jump to the nav bar | |
| **LT / RT** | | Jump by letter | | |
| **Select** | | | | Open / close the **App drawer** |

---

## Home page

The Home page is the heart of the theme, laid out like the Xbox dashboard.

<!-- 📷 Home page — system row + collection rows -->
<img width="1920" height="1080" alt="1000813883" src="https://github.com/user-attachments/assets/cefe52e5-5e0b-493a-a52e-dea7b9926f27" />
<img width="1920" height="1080" alt="1000813885" src="https://github.com/user-attachments/assets/95d88cf7-3b2d-4e5a-9d07-d89a1b8e92e6" />


**Top bar**
- **Profile corner:** the Xbox logo (two styles), your **RetroAchievements profile** (avatar, username and stats), or nothing. Optionally tinted to your accent color.
- **Nav bar:** Home · Discover · RetroAchievements · **Search** · Settings.
- **Status:** clock (12/24hr), Wi-Fi indicator and battery (icon, percentage, both, or off).

**System row**
- Starts with a large **hero tile** showing the game you played last — press A to jump straight back in.
- Every system gets its own tile with its logo, and its own **background art** behind the page when highlighted.
- Android tiles are always pinned to the front, in order: **Android → Android Apps → Android Games**.
- Sort the row alphabetically, by release year, manufacturer, game count, or Pegasus's default order.

**Collection rows** — up to six, each fully configurable:
- **Content:** Recently Played, Most Played, Recommended, Top by Publisher, Top by Developer, Top by Genre, Top by Genre 2, Favorites, **System** ("Play something new" from a random system), or None.
- **Tile shape:** Wide, Tall, Square, Box Art or 3D Box — plus size (Small/Medium/Large) and an exact aspect ratio.
- Pick how many games each row shows.

**Featured box** — a large tile pinned to any of the rows, showing your **Favorites**, a **Fanart slideshow**, or **Discover videos**.

**Backgrounds**
- Highlighted games crossfade their fanart behind the page, with an optional screenshot fallback for games without fanart.
- Optional **Dynamic Background** adds a slow, gentle zoom and drift.
- Use your own image instead — see [Customizing](#customizing-with-your-own-images).

<!-- 📷 Backgrounds — crossfade / custom background -->
<img width="960" height="540" alt="1000813867" src="https://github.com/user-attachments/assets/7b4a61eb-bbbb-48fc-bebf-a35fd57a278b" />
<img width="1920" height="1080" alt="1000813886" src="https://github.com/user-attachments/assets/40e3f0d4-0a9c-4820-ab00-5b38b7f3aeba" />


**Tiles** — preview videos play on the highlighted tile, an optional **Tile Halo** glow, an optional animated highlight pulse, and an optional colored edge on favorited games.

---

## App drawer

Press **Select** from anywhere to slide out the app drawer — modeled on the Xbox guide.

<!-- 📷 App drawer -->
<img width="1920" height="1080" alt="1000813887" src="https://github.com/user-attachments/assets/99217aa3-1282-4768-b41c-084f993b9bfe" />
<img width="1920" height="1080" alt="1000813888" src="https://github.com/user-attachments/assets/cd285030-ec1c-4f40-8e67-e95107c6bc69" />

**Layout**
- **Home** and **My games & apps** shortcuts at the top.
- **Tabs** (switch with **LB / RB**): All · Favorites · Games · Emulators · System · Other — plus a **Hidden** tab when you choose to show it.
- The list always shows exactly **4 apps** at a time with large icons.
- **Action tiles** along the bottom: show/hide the Hidden tab, Discover, RetroAchievements, **Search**, Settings.

**What appears in it**
- Apps from **Pegasus's Android app import**.
- Your own entries in a collection named **Android** (or with the shortname `android`) — these merge with the Pegasus import into one list.
- Your Android games, in a collection with the shortname `androidgames`.
- If an app is in both the Pegasus import and your own collection, **it only appears once** — your entry wins.

**Quick menu** — highlight an app and press **Start**:
- **Add to / Remove from Favorites**
- **Hide ›** opens a small panel with three choices:
  - **App drawer only** — hidden in the drawer, still in your library
  - **Library only** — hidden from your library, still in the drawer
  - **Both** — hidden everywhere
  - **Unhide** — appears once something is hidden
- **Move to** Games / Emulators / System / Other
- **Reset to automatic**

**Sorting** — apps are placed into tabs automatically. Your own entries follow their genre tag (`Emulator` goes to Emulators; anything in your Android Games collection goes to Games). Pegasus imports are recognized from a built-in list of common system apps and emulators; anything unrecognized lands in **Other** — move it once and the drawer remembers.

**Launching** — anything opened from the drawer **launches instantly**.

---

## Library search

Search your whole library from the **Search** button on the Home page's nav bar or the **Search** tile in the app drawer.

<!-- 📷 Search Library — keyboard + results -->
<img width="1920" height="1080" alt="1000813880" src="https://github.com/user-attachments/assets/ffdddaf9-1091-4f22-9854-78c04feff227" />
<img width="1920" height="1080" alt="1000813881" src="https://github.com/user-attachments/assets/99889015-4601-4ebf-a628-1a2890e52a20" />

- On-screen keyboard built for controllers.
- Results show box art, the system, and your RetroAchievements progress.
- **LT / RT** jump through results by letter.
- Pick a result to open its **Game details** page — press **B** to come straight back to your results.

---

## Platform page

Open any system tile to browse that system's games in a grid.

<!-- 📷 Platform page grid -->
<img width="1920" height="1080" alt="1000813879" src="https://github.com/user-attachments/assets/226d27e5-9348-4999-adec-8b7f5c794f2e" />
<img width="1920" height="1080" alt="1000813897" src="https://github.com/user-attachments/assets/28e6e875-3dad-4815-abfa-5bd570db5c80" />


- **LT / RT** jump to the next / previous letter.
- **LB / RB** cycle through systems — or, with *LB/RB Function* set to *Nav Bar*, step along the header icons instead.
- **X** opens **Sort & filters**:
  - Search by title
  - Filter by genre (LT/RT jump by letter in the genre list)
  - Sort by Title, Last Played, Most Played or Rating
  - Favorites only
  - Press **X** again inside the panel to clear every filter at once.
- **Per-system tiles:** turn on *Per-system tile settings*, then press **Y** on a platform page to give *that system* its own tile shape, ratio, art, logo, tiles-per-row and titles. Systems you don't change keep following your main settings.
- An optional **game counter** in the header shows the live count as you filter.

---

## All Games menu

Your entire library in one place — open it from **My games & apps**.

<!-- 📷 All Games — list view + grid view + filters -->
<img width="1920" height="1080" alt="1000813876" src="https://github.com/user-attachments/assets/234b2804-ae2b-4276-b507-18aef0688f65" />
<img width="1920" height="1080" alt="1000813877" src="https://github.com/user-attachments/assets/7cddf513-620c-47a9-840a-38fe7cbd18a9" />
<img width="1920" height="1080" alt="1000813878" src="https://github.com/user-attachments/assets/695c648c-0df9-405e-80cf-041329298775" />


- **Two views:**
  - **List** — a scrolling list with a preview panel (video, box art, genre, last played, rating).
  - **Grid** — full-page tiles with their own shape, ratio, art and tiles-per-row, or set *Match Platform page* to mirror the Platform page.
- **X — Filters:** search by title, filter by **system** or **genre** (LT/RT letter jumps in both pickers), sort by Title, Last Played, Rating or Release Date, Favorites only.
- **Y — Quick settings:** change the view, video previews and display options without leaving the page; changes apply instantly.
- **A** launches straight from the list.

---

## Discover

A full-screen, lean-back video mode for finding something to play.


<!-- 📷 Discover -->
<img width="1920" height="1080" alt="Discover" src="https://github.com/user-attachments/assets/74a4465d-a825-4be8-959a-d2e01ac53583" />

- Plays game preview videos one after another, picking at random and auto-advancing when a video ends.
- **Left / Right** or **LB / RB** — jump to another game.
- **A** — launch the game · **Y** — open its details · **X** — hide the on-screen info for a clean view · **B** — back.
- **From a Platform page, Discover only plays that system's games.** From anywhere else it covers your whole library.
- If the Featured box is set to *Discover videos*, opening Discover **continues the same video** — and backing out hands it back to the Home page.

---

## Game details

<!-- 📷 Game details + media carousel -->
<img width="1920" height="1080" alt="1000813890" src="https://github.com/user-attachments/assets/781466e2-fb7c-4a4c-9563-e7e4573a6d53" />
<img width="1920" height="1080" alt="1000813891" src="https://github.com/user-attachments/assets/3a19a1fb-beb7-4da7-9847-9bc3e588527e" />
<img width="1920" height="1080" alt="1000813892" src="https://github.com/user-attachments/assets/a907732f-2970-4e76-8e44-143bf44ea276" />


- **Play** (shows **Open** for apps and emulators), **Full details**, **Manual** *(when the game has one, see [Game manuals](#game-manuals))*, **RetroAchievements**, **Favorite** and **Back** buttons.
- Publisher, developer, release date, genre and rating.
- **Media carousel** — video, screenshots, title screen, fanart, 2D box, 3D box, back of box, cartridge, miximage and logo. Each type can be turned on/off; select one to view it full screen.
- **"More" rows** below the carousel:
  - **More by Publisher / Developer** — falls back to **Picked For You** when there's nothing else from them.
  - **More by Genre** — match on the full genre, just the main genre, or just the subgenre (see [Metadata](#metadata--media)).
- Background preview video, optional blur and scanlines, and a choice of screenshot or fanart backdrop.
- Box art style: 2D, 3D or Miximage.

---

## Game manuals

> [!IMPORTANT]
> **Game manuals need Pegasus X, which is still in development.** Pegasus can't open PDF files on its own, so the pages are drawn by [Pegasus X](https://github.com/luxureousproductions-bit/pegasus-frontend), an unofficial Android fork of Pegasus that adds PDF support. It isn't released yet and may change. On the regular Pegasus app nothing breaks: the **Manual** button simply doesn't appear.

Read a game's original manual without leaving the theme. When a game has a manual, a **Manual** button appears on its Game details page.

<!-- 📷 Game manuals: the Manual button on Game details -->
<img width="1920" height="1080" alt="1000819699" src="https://github.com/user-attachments/assets/ea81d263-cdda-4bcb-bcc0-1ceb38131255" />

<!-- 📷 Game manuals: reading a page -->

<!-- 📷 Game manuals: zoomed in -->
<img width="1920" height="1080" alt="1000819697" src="https://github.com/user-attachments/assets/7006018b-3ff8-41f9-baf4-5753197c7fdf" />

<!-- 📷 Game manuals: 2-page view -->

<!-- 📷 Game manuals: page overview with bookmarks -->
<img width="1920" height="1080" alt="1000819698" src="https://github.com/user-attachments/assets/56606247-22d4-4f4c-9ea4-cc287315c42c" />

**Reading**
- Opens on page 1, with the page fitted to the screen and a progress bar showing how far through you are.
- **View (X)** switches between **1 page** and **2 pages** side by side. Two-page view pairs pages like the printed booklet: the cover on its own, then 2–3, 4–5 and so on, so maps and spreads line up.
- **Zoom (LB / RB)** zooms out and in, in steps. Zoomed in, the D-pad moves around the page, and pressing left or right at the edge turns the page. A small map in the corner shows which part you're looking at.
- **Manuals scanned as two-page spreads** are detected automatically and shown as large as possible.

**Finding your place**
- **Pages (Y)** shows every page as a thumbnail. Pick one to jump straight to it.
- **Bookmark (A)** marks the page you're on with a ribbon. Bookmarks are saved for each manual and show as ticks on the progress bar. In the page overview, **X** shows only your bookmarked pages.

**Controls**

| Button | Action |
|---|---|
| **A** | Bookmark / remove bookmark |
| **X** | View: 1 page / 2 pages |
| **Y** | Page overview (inside it: **X** bookmarks only) |
| **B** | Back |
| **LB / RB** | Zoom out / in |
| **LT / RT** | Skip 5 pages back / forward |
| **Left / Right** | Previous / next page (zoomed in: move around the page) |

On a touchscreen, tap the left or right side of the page to turn it, or the middle to zoom.

**Adding manuals**

Put each manual, as a PDF, in a `manuals` folder inside the system's `media` folder, named like the game's artwork:

```
psx/media/box2dfront/Final Fantasy VII/Final Fantasy VII.png    ← the game's art
psx/media/manuals/Final Fantasy VII/Final Fantasy VII.pdf       ← its manual
```

- If Skraper downloaded manuals for you, they're usually in the right place already.
- `media/manual` (singular) works too, and so does a plain `manuals` folder next to your ROMs.
- **Multi-disc games** in their own folder work: the manual can sit in a matching folder like above, or directly in `media/manuals` named after the game.
- To point a game at a specific file, add `x-manual: <path to the PDF>` to its entry in your metadata file.

---

## RetroAchievements

Sign in under **Settings → Retro Achievements** with your username and your **Web API key** (from [retroachievements.org/settings](https://retroachievements.org/settings)).

<!-- 📷 RetroAchievements -->
<img width="1920" height="1080" alt="1000813893" src="https://github.com/user-attachments/assets/8f7227d6-acf6-47f5-9aa2-da4f84e631d3" />
<img width="1920" height="1080" alt="1000813894" src="https://github.com/user-attachments/assets/933383ee-7c25-476e-8d2a-a6f72eb85b02" />
<img width="1920" height="1080" alt="1000813895" src="https://github.com/user-attachments/assets/9606f3ed-30ae-4c9a-8274-03e667693b69" />

- **Profile header** — avatar, username, member-since date, and your points (hardcore, softcore and True Points), **alternating with your Rank** every 15 seconds — just like the Xbox profile card. Shown on every RA page and on the Home page when the profile corner is set to RetroAchievements.
- **Overview** — your recently played games with progress bars and completion percentage.
- **RA Search** (X) — find any game in your library and jump straight to its achievements; **B** brings you back to your results.
- **Game achievements** — filter **All / Earned / Locked** with LB/RB, sort by Default, Points, Rarity or Date with Y, and see each achievement's rarity.
- From any **Game details** page, the trophy button opens that game's achievements directly.

---

## Settings

Every setting has a **More info** page — press **X** on any row for a plain-language explanation.

<!-- 📷 Settings -->
<img width="1920" height="1080" alt="1000813896" src="https://github.com/user-attachments/assets/165f3113-45bc-483c-830c-6eb0fcc54cb5" />

| Page | What's in it |
|---|---|
| **General** | UI scale, High Quality Mode, launch screen delay, button help, mouse hover, background & accent colors (30+ each), dimming and bottom fade |
| **Home page** | Profile corner logo, hero art, system sort, games per row, background art, custom & dynamic backgrounds, opacity |
| **Collections** | Content, tile shape, size and ratio for each of the six Home rows |
| **Tiles** | Game & system titles, Tile Halo, favorite accent, highlight animation, game counter, video thumbnails, featured box |
| **Platform page** | Tile shape, ratio, art, logo, columns, LB/RB function, per-system tiles |
| **All Games Menu** | List/Grid view, video previews, blur, scanlines, grid tiles, Match Platform |
| **Game details** | Box art style, More by Genre, background, logo, default to full details, video, blur, scanlines |
| **Media Carousel** | Turn each media type on or off |
| **Audio** | Menu sounds, startup chime, volume, and video audio for each screen |
| **Retro Achievements** | Username and API key |
| **Advanced** | Hide apps / emulators from Home, Android system tiles, Added App Launch, status bar indicators |
| **Tips & Tricks** | Lesser-known features that have no button prompt, each with a short explanation |

---

## Base mode vs High Quality mode

XboxOSv2 runs well on low-end devices out of the box. **High Quality Mode** (Settings → General) adds extras for capable hardware:

- Sharper full-screen videos
- Video previews start sooner
- Crisper artwork and icons
- Smoother transitions and fades
- A blurred backdrop behind the app drawer

Off by default. A theme reload is recommended after changing it.

---

## Setting up Android apps & games

**Pegasus-imported apps**
Turn on Pegasus's **Android Apps** data source. Your installed apps appear in the app drawer automatically, in a collection named **Android**.

**Your own apps** — add them in a metadata file using the collection name `Android` (it merges with the Pegasus import) or the shortname `android`. Add a `genre` to control how they're treated:

```
collection: Android
shortname: android

game: Dolphin
genre: Emulator
launch: am start -n <package>/<activity>
```

**Your Android games** — use the shortname `androidgames`:

```
collection: Android Games
shortname: androidgames
```

**Genre tags that matter**

| Genre | Effect |
|---|---|
| `Emulator` | Goes in the drawer's **Emulators** tab; hidden from Home by *Hide emulators from Home* |
| `Application` | Hidden from Home by *Hide apps from Home*; the details page button says **Open** |

**Related settings (Advanced)**
- **Hide apps from Home / Hide emulators from Home** — keeps apps and/or emulators off the Home page. Takes effect immediately. Pegasus-imported apps in the drawer's **Emulators** tab count as emulators; apps in the **Games** tab are never hidden as apps.
- **Hide Android System Tile** — hides the Android tile (and `android` shortname tiles) from the system row, since the drawer has them. On by default.
- **Hide Android Games System Tile** — same for `androidgames`. Off by default.
- **Added App Launch** — whether your own apps and Android games launch **instantly** or open their **details page** first when picked outside the drawer. Pegasus imports always launch instantly.

**Duplicates** — if the same app or game is in both the Pegasus import and your own collection, only your entry is shown — on the Home page, in All Games, on the Android platform page and in the drawer. Names must match.

---

## Customizing with your own images

| What | Where | Notes |
|---|---|---|
| **Home background** | `assets/images/backgrounds/background.png` | Turn on *Custom Background*. Turn off *Showcase Background Art* to see it behind the whole page |
| **System background art** | `assets/images/systembackground/<system>.png` | Shown behind the Home page when a system tile is highlighted. `.png`, `.jpg`, `.jpeg` and `.webp` all work |
| **System logos** | `assets/images/logospng/<shortname>.png` | Used on system tiles, headers, Discover and search results. Systems without a logo show their name instead |

---

## Metadata & media

[Skraper](https://www.skraper.net/) is recommended for media. These are the minimum recommended media types — more gives you more visual variety:

| Skraper media | Used as |
|---|---|
| videos | Video |
| screenshot | Screenshot |
| fanart | Fan Art |
| box2dfront | Box Art |
| box2dback | Back of box |
| box3d | 3D Box |
| wheel | Logo |
| support | Cartridge |
| screenshottitle | Title Screen |
| steamgrid | Miximage |
| manuals | Game manual *(PDF, needs Pegasus X, see [Game manuals](#game-manuals))* |

**Genre & subgenre** — write genres as `Genre / Subgenre` to power *More by Genre*. All of these separators work: `/` or `,`, with or without spaces (`Action/Platformer`, `Action / Platformer`, `Action, Platformer`, …).

---

## Tips & hidden features

These are things the theme doesn't show a button prompt for. You'll also find them in the theme itself, under **Settings → Tips & Tricks**.

**Navigation**
- **Discover follows the Platform page.** Open Discover from a system's Platform page and it only plays that system's games. From anywhere else it covers your whole library.
- **Jump by letter.** On the Platform page and in search results, **LT / RT** jump to the previous or next letter.
- **Shortcut to the nav bar.** On the Home page and Game details, **LB / RB** jump straight up to the nav bar. On the Home page, coming back down returns you to the row you were on.
- **Skipping in Discover.** **LB, RB, Left and Right** all skip to another game, and when a video ends Discover moves on by itself.
- **Mouse support.** The mouse wheel moves the selection through lists and grids, and the mouse back button works like **B**.

**Home page**
- **The hero tile** at the start of the system row is always the game you played most recently.
- **Featured box and Discover.** With *Featured box shows* set to *Discover Videos*, opening Discover carries on with the same video, and backing out hands it back to the Home page.
- **Random rows stay put.** Rows like Recommended and Top by Genre keep their picks until you press **Refresh (X)**. Two rows set to *System* always pick different systems.

**Game manuals**
- **Skip ahead in a manual.** **LT / RT** skip 5 pages back or forward.
- **Leave zoom with a tap.** On a touchscreen, tapping a zoomed page returns it to the full page.

**Platform page**
- **Per-system tiles.** With *Per-system tile settings* on, **Y** on a Platform page opens that system's own tile settings instead of the main Settings.

**Search**
- **Forgiving search.** Search ignores capitals, punctuation and region tags like "(USA)", and finds "Legend of Zelda, The" when you type "The Legend of Zelda".

**App drawer**
- **The Hidden tab** only appears once something is hidden. The first tile along the bottom of the drawer shows or hides it.
- **Moving apps between tabs** (Start → Move to) is remembered, and overrides both the automatic sorting and the app's genre tag. Use *Reset to automatic* to undo it.
- **Duplicate apps.** An app that's in both the Pegasus import and your own collection is only shown once, with your entry taking priority. The two names must match exactly.

**Customizing**
- **Your own system backgrounds.** Put an image in `assets/images/systembackground/`, named after the system's shortname (for example `snes.png`). It shows behind the Home page when that system's tile is highlighted. `.png`, `.jpg`, `.jpeg` and `.webp` all work.

---

## Credits

XboxOSv2 is a fork of [gameOS](https://github.com/PlayingKarrde/gameOS) by the original and true UI god, **Seth Powell**, and continues the work of **XboxOS** by **Alfred Olvera**.

Ideas and inspiration also come from **Yan Miller's Sleipnir** theme and **MrJud's AquaFlow**, as well as community feedback.

I'm not a developer and won't pretend to be — this started as a tinkering project to make the changes I wanted to see in a theme I loved, and I'm sharing the result in case others enjoy it too. Ai assistance utilized.

Licensed under the GNU GPL v3, like gameOS.
