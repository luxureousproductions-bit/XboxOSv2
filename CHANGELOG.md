# Changelog

All notable changes to XboxOSv2, newest first. Dates are when each update was finished. Updates before this one were rebuilt from the project's commit history.

---

## Unreleased — seriesSX branch (build 88)

The Xbox Series dashboard redesign, page by page, branched from refresh build 63.

- **Leaderboards on a game's page** (rail: Achievements, Leaderboards, Stats). Every leaderboard of the game as a card: its name and description, the #1 entry, and **your** score and rank (or "No entry yet"). A opens the top 100 over the page, opening on your row (in the accent; when you're further down it's added at the end), with LB / RB to jump to the top or to you. Two requests when Leaderboards opens, one when a leaderboard does.
- **Stats tiles at the console's size:** two columns of big tiles (title, a large value, a line under it) that you move through with the cursor and that scroll, instead of three columns of small ones.
- RA game page: a **Mythic** game's fanart is at **60%** (others stay at 50%).
- Fixed: the game page could read the old view for a moment when you changed it on the rail (so Leaderboards wouldn't load); it now goes by the rail position itself.
- Fluent icons are decoded at twice their drawn size, so the bigger ones stay sharp.
- Test harness: the fake RA server serves leaderboards (GetGameLeaderboards, GetUserGameLeaderboards, GetLeaderboardEntries).

## build 87

- **Fixed (for real this time): the system tiles flashing when you go up to the strip.** Build 86's change didn't touch the cause. Measured on your recording: the strip glides down, jumps back to where it started for one frame, then carries on. Measured in the harness: switching the page into "glide" mode moved it ~40 px the wrong way before the glide began. Root cause: Home's page list snaps to whole rows (for the wheel and touch), and changing how it follows focus makes it re-snap; on a fast screen that snap landed a frame into the glide. Row snapping is now off while the glide runs and back on when it lands. Build 86's one-step Up is kept.

## build 86

- **Fixed: the system tiles flashing when you go up from a row to the strip.** Root cause: as the page glides down to the strip, one frame was drawn back at the starting position (measured in a screen recording: the strip moved down smoothly, then jumped back once, then carried on), which reads as every tile flashing. Up only switched the page to "glide" mode before changing rows when you were on the row right below the strip; from any other row, or across a hidden row, it stepped one row at a time in "follow the focused row" mode, and the list started its own scroll before the glide took over. Up now works out the destination first, switches to glide mode, and goes straight there.
- RA game page: the fanart behind the top is at **50%** (was 30%).

## build 85

- **Fixed: the Home background running one step behind and flashing between rows and the system tiles.** Root cause: the background only fades once its picture has finished decoding, and a big one (a system background, especially with High Quality Mode's 1.1 s fade) could finish *after* you'd already moved on. It was faded in anyway (the previous item's art behind the new one), then a second full fade went to the right picture. A picture that arrives after you've moved on is now dropped, and the current one fades in straight away.
- **Fixed: App Drawer icons popping in on the first open of each session.** Root cause: since the drawer started being built on first open (to speed up startup), its icon pre-loader ran in the same moment as the rows, so icons decoded while the drawer slid in. The drawer is now built in the background from 7 s after start, at the first moment you've been idle for 1.5 s, so the icons are decoded before you open it (opening it sooner still builds it at once). Startup is unchanged, and the one-off build frame doesn't land mid-scroll.

## build 84

- **Works with Pegasus X's RetroAchievements matching.** Pegasus X hashes your ROMs the way RA does and writes the result into your metadata as `x-ra-id`, which the theme uses as the match everywhere (Game details' RA button, Launch game, box art and fanart on the achievements page, the Awards photos). When Pegasus X found a ROM isn't on RA (`x-ra-id: 0`), the theme no longer guesses by title, so the game gets no RA button and isn't paired with a look-alike. Without Pegasus X, title matching works as before.
- A match you pick in the theme (Change match / Find in your library) now beats the metadata ID, so the picker always wins over an older or title-based match.

## build 83

- **Tell the theme which RA game a game is, two ways.** Both beat title matching, in both directions (Game details' RA button, and Launch game / box art / fanart on the achievements page and the Awards photos):
  - **In your metadata:** add `x-retroachievements: <RA game ID>` to a game in its `metadata.pegasus.txt` (the number in the game's retroachievements.org address). `x-ra-id` works too.
  - **In the theme:** on a game's achievements page, **Find in your library** (when it isn't matched) or the **Change match** button (link icon, right of Launch game) opens a picker: a list with the best guesses on top, and a search box with the on-screen keyboard (Y). Opened from your game (its details or RA Search), it picks the RA game; opened from the RA page, it picks which of your games this is. The pair is remembered in the theme's settings.
- **Filters pop-up, Set column** (RA's version of the console's Original / Add-on): **All** (base set plus subsets), **Base set**, **Subsets** and **Unofficial**. Subsets ("[Subset - Bonus]" and the like) are found in the console's RA game list and loaded after the base set, with your progress, each card tagged with its subset; the page's numbers and the Mythic card stay the base set's, as RA's mastery does. Unofficial achievements load only when you pick that filter (one request) and always show locked, since they can't be earned. Achievement types moved to a third column.
- Fixed: after closing the Filters pop-up, keys kept going to the hidden pop-up (B didn't leave the page).
- Test harness: the fake RA server serves console game lists with subsets and unofficial achievements (GetGameList, GetGameExtended).

## build 82

- **Games whose title is spelled a little differently on RA now match your library.** The theme pairs your games with RA by title, and a space or an accent was enough to miss: RA's "~Hack~ Pokémon **FireRed**: Rocket Edition" never matched "Pokémon **Fire Red**: Rocket Edition", so that game had no RA button on Game details and its achievements page said "Not in your library". Titles now match ignoring spaces, accents ("Pokemon" = "Pokémon") and "&" vs "and". This fixes the details-page RA button, the Launch game button, box art and fanart on the achievements page, the Awards photos and the progress bars in Search.
- **Game achievements top, rearranged:** box art and title top left, with the **Mythic Achievement** card under them, as on the console. Until a game is 100% the card shows a **locked wreath** (a padlock in a laurel wreath, in greys) with your achievement count, percent and a bar; at 100% it shows the Mythic star with how and when.
- **Filters pop-up** (A on Filter), after the Xbox one: two columns of radio buttons and Apply. Left is RA's achievement types (All, Progression, Win condition, Missable); right is All, Locked, Unlocked, **Rare** (under 10% of players) and **Common**. Nothing changes until Apply; B closes it. The Filter box shows what's on (e.g. "Filter: Locked · Missable"); LB/RB still step through the right column.
- Test harness: with `FAKE_RA_LIB`, the mastered fake game is titled the RA way ("~Hack~ SkyRally 87" for "Sky Rally 87") to exercise the matching.

## build 81

- **Awards tiles are photos.** Each tile is filled by your fanart for the game when it's in your library (else its screenshot or box art), or RA's game icon cropped to fill it when it isn't (those are small, so they look softer). The name and award sit on a dark fade at the bottom, white in both themes. Mythic tiles get an accent rim and the Mythic star in the corner; beaten ones keep the flag.

## build 80

- **Game achievements page, revised.** Top left is now the game's **box art** (yours when the game is in your library, else RA's), as big as the top allows in its own shape. The fanart behind it is at **30%** over near-black, and only a **100% (Mythic) game** gets the accent background and fade; that card now reads **Mythic Achievement**. A **Launch game** button sits under the stats (Up from Sort / Filter, or Right from the rail on Stats); it says "Not in your library" and is greyed out when there's no copy to launch. A on an achievement no longer launches the game, and the A prompt only shows where A does something (Launch, Change, Select).
- **Achievement art** is the badge itself, clear, at the card's full height; the blurred blow-up behind it is gone.
- RA header: **Mythic Achievements** instead of Mythic Games.
- Looking up your copy of an RA game uses a title index built once (instead of one pass over the library per lookup); box art, fanart, Launch and the Pegasus stats all share that lookup.
- Test harness: the fake RA server serves box art, and `FAKE_RA_LIB=<testenv/lib>` gives two of its games titles from the fake library (one mastered) so in-library paths can be checked.

## build 79

- **Stats for each game** (left from the achievement list, then down to Stats on the rail): tiles with **time played, times launched and last played** (from Pegasus, when the game is in your library), points (hardcore and softcore), RetroPoints, unlocked in hardcore, your rarest unlock, first and latest unlock, your award and when, how many people play it, and **your rank** among them (one RA request, only when Stats opens). The rail works like the Settings page list: an accent plate while you're on it, Up/Down switch views straight away, Right goes back to the list.

## build 78

- **A game's achievements page, redesigned after the Xbox Series game Progress page.** The top shows your fanart for the game (when you came from its details page; otherwise RA's in-game screenshot), dimmed and fading into your accent, with the game's art and title, a **Path to Mythic** card (achievements to go and a bar, or the full Mythic star with how and when once it's 100%), and Points, Achievements and Overall progress. Below: a rail, Sort (Default, Points, Rarity, Date unlocked) and Filter (All, Unlocked, Locked, **Missable**), then every achievement as a card with **wide art** (the badge on a soft blow-up of its own colours), name, description, how many players have it, when you unlocked it and in which mode, and its points with a diamond when it's rare (under 10%). Locked ones use RA's grey badge with a lock. Focus is the accent frame. Same buttons as before: A launches the game if it's in your library, X refreshes, Y sorts, LB/RB filter, B goes back.
- Test harness: the fake RA server also serves each game's achievements and stand-in badges and screenshots, so RA pages show pictures in cloud sessions.

## build 77

- **Mythic star:** the four smaller points behind the main star are longer and thicker.
- **Awards rail** focuses like the Settings page list instead of with the accent frame: an accent plate while you're on the rail, a grey plate with an accent edge while you're in the tiles.

## build 76

- **Detailed RA header emblems**, drawn from your accent colour so every preset and custom colour gets its own metal and gem shades: **Total Points** is a scalloped medallion with an engraved ring, studs, a cut-gem coin and a raised P; **Total Achievements** a gem-cut hexagon with rivets, shaded facets and a glossy trophy in laurels; **Mythic Games** a thick bevelled four-point star with a cut diamond, a slimmer star behind it, rays and sparkles. Original designs (RetroAchievements/raEmblems.js), drawn as SVG once per accent; opening the RA page costs the same as before.
- **The selected tab glows** softly in your accent, as on the console.

## build 75

- **RA pages focus like the rest of the theme:** the Xbox frame in your accent (rounded, with a soft glow that follows Settings › Frame glow) instead of a white box, on the game cards, award tiles, quick buttons, Sort, Filter and the Awards rail. Cards and tiles have rounded corners.
- **Mythic now means 100%, as on the Xbox.** A game you've completed in softcore (RA "Completed") gets the Mythic frame and accent fade too, not only hardcore "Mastered" games. The label still says which. The header stat is now **Mythic Games** (with how many are in hardcore), and the quick button, Filter and Awards rail say Mythic.
- **Awards: the left column's focus frame was cut off.** Root cause: the grid is clipped (so tiles don't slide over the header) but had no inner padding on the left, so the frame's ring and glow, which draw outside the tile, were clipped. Every side now has padding the size of the frame.
- **Gaming list:** the focused card stays in the top slot while scrolling (no sliver of the card above), and both lists stop above the button prompts instead of running under them.

## build 74

- **RetroAchievements redesign, step 5 of 5: icons.** Sort gets a proper dropdown chevron, Filter its funnel icon, and beaten games a flag (on the Gaming cards and the Awards tiles). They're Microsoft's Fluent UI System Icons, the family Xbox's own menus are drawn in (MIT licence, credited in THIRD_PARTY_NOTICES.md); white on Dark, dark on Light. The header's mastery star, achievements hexagon and points mark are original shapes drawn for the theme, not Xbox's artwork.

## build 73

- **RetroAchievements redesign, step 4 of 5: the Awards tab** (tabs are now Recent · Gaming · Awards · Search). Your trophy case, newest first: each award as a tile with the game's icon, name, the kind of award and its date; mastered games keep the Mythic-style frame. The rail filters by kind with counts: All awards, Mastered, Beaten, Completed, Events & site. Left from the first column reaches the rail, Up/Down there change the filter, Right goes back; A opens the game's achievements.
- **Gaming and Awards lists no longer slide over the header or the Sort row when scrolled** (they're clipped, with room left for the focus outline and the frame's glow).

## build 72

- **RetroAchievements redesign, step 3 of 5: the Gaming tab** (the RA page now opens on it; tabs are Recent · Gaming · Search). Every game you've played as a card: RA icon, name, system, achievements unlocked, a big percentage and a progress bar, with MASTERED / COMPLETED / BEATEN labels. **Mastered games wear a Mythic-style frame** in your accent (light rim, soft glow, star seal) and their card warms toward the accent, as on the Xbox. Above the list: quick buttons (**Closest to mastery**, **Recently unlocked**, **Mastered**), **Sort** (Recent, Completion, Title, Unlocked) and **Filter** (All, In progress, Mastered, Beaten, Completed); A changes them, Up/Down move between rows. Cards show achievements rather than points: RA's completion list has no per-game points without one request per game. Left rail: Achievements; Followed users comes in its own step.
- **RA pages on Light:** the dimming layer is kept to 40% there too (as the Library got in build 69), so the page stays light.

## build 71

- **RetroAchievements redesign, step 2 of 5: the header**, after the Xbox Series Gaming tab. A band in your accent's dark shades (the ones Xbox pairs with each colour) with your avatar, name and points top left, the tabs in the middle and three stats: **Total Points** with a bar to the next 5,000-point milestone and your rank, **Total Achievements** out of everything in the games you've played, and **Mastered Games** (RA's 100% in hardcore, Xbox's "Mythic") with your beaten and completed counts. LB/RB change tabs; for now they're Recent and Search (Search opens the RA search, like X). Gaming and Awards arrive in the next steps. Y (Refresh) reloads the new totals too.

## build 70

- **RetroAchievements redesign, step 1 of 5: the data** (nothing new on screen yet). The first time you open the RA page, the theme now also loads every game you've played with your progress and award level (RA's completion list, 500 games per request), and your award counts: mastered, completed, beaten, events. These feed the Gaming and Awards tabs in the next steps. Loaded once per session, not at startup.
- **Test harness: a fake RetroAchievements server** (`tools/harness/fake_ra.py`, 620 games, every award kind), so the RA pages can be tested in cloud sessions. The theme's API address is one property now (`apiBase`) for this.

## build 69

- **Bottom fades fade into your background, not black.** Root cause: `theme.main` is stored as text, so the fades in the Library, Game details and the three RetroAchievements pages built their colour from channels that don't exist and drew black on every background. Barely visible on Dark; a black smear on Light. They use a real colour now (`mainA()` in theme.qml), the same fix as the accent tints in build 62.
- **Light polish:**
  - **Library list:** unselected names are readable (60% instead of 28%), and the dimming and the list column's darker strip are kept to 40% strength, so the page stays light instead of turning mid-grey.
  - **Game details:** the round buttons beside Play game sit on a dark see-through disc, and the row titles ("Media" and the rest) turn dark.
  - Still dark on Light, to restyle later: the Filters pop-up and the App Drawer.

## build 68

- **Merged refresh build 64** (the NavPill nav buttons, below). refresh takes no more changes; everything continues here.

## build 67

- **Background is Dark or Light, like the Xbox** (Settings › Appearance). Dark is the dashboard's own surface, #1F1F1F; Light is #F2F2F2. The other 31 backgrounds are gone: on first start White becomes Light and every other one becomes Dark. The default is Dark (was Black).

## build 66

- **Custom accent colour** (Settings › Appearance › Custom color): type any hex code on the on-screen keyboard (107C10, #EB4910, or 3 digits like #1C1). Saving it switches the accent to Custom, as on the Xbox. A code that isn't a colour is refused with a short message and nothing changes. Its darker shades are worked out the way Xbox's presets are: same hue, lightness ×0.68 and ×0.39.

## build 65

- **Accent colours are now Xbox's own 21 presets**, in Xbox's order, with the exact values the console uses (Xbox Green, Ocean Blue, Azure, Cobalt, Purple, Orchid, Magenta, Crimson, Red, Orange, Brown, Steel, Lime, Teal, Sea Teal, Flame, Pink, Graphite, Khaki, Sage, Gray; Xbox shows them unnamed, so the names are ours). Each comes with the darker shades Xbox pairs it with, for headers and toasts in later pages. The default is Xbox Green (was Lime).
- **Your old accent carries over** to the closest preset on first start (e.g. Indigo → Purple, Sky Blue → Ocean Blue). Names in both lists keep their name.
- **Video glyph on Game details media tiles** is filled with the accent directly. Root cause it had to change: it was one solid PNG per colour name (66 files in assets/images/colorspng), which can't follow new or custom colours. Those files are gone.

## build 64

- **"Startup chime" is now "Achievement/Welcome Toast"** (Settings › Previews & sound), the sound's real name. Only the label changed: your on/off choice is kept. The card spans two columns so the longer name fits.

## refresh branch (build 64), merged into seriesSX build 68

- **Nav icons go from outline to filled, as on the Xbox:** in every nav bar (Home, Library, Game details) the library, RetroAchievements, settings and home icons are outlines at rest and fill in white when focused. The App Drawer's RetroAchievements and settings tiles do the same. Discover and Search stay outlines, as on the Xbox.
- **New home icon:** an outline house (filled when focused), also in the App Drawer's Home row.
- **Focus ring:** a thin accent ring with a hair of dark gap before the black disc. Its glow now follows Settings › Frame glow (off = a plain ring).
- One shared component draws every nav button now (Global/NavPill.qml), so the three bars can't drift apart. Measured against build 63 with the test harness: no performance change.

## refresh branch (build 63)

- **Test harness in the repo** (`tools/harness/`, no theme change): the setup, scripts, standard performance scenario, an A/B compare script and the build 63 baseline, so later work can be checked against the performance gains of the refresh. Pegasus for it lives on the `harness-pegasus` branch.

- **Home nav buttons restyled to match the Xbox:** each icon sits in a faint, see-through dark pill and stays white. The focused one grows a little and becomes a near-black disc with a glowing ring in your accent colour, its name underneath.

## build 62

- **Home nav buttons in round pills:** each sits in its own round pill; the focused one filled with the accent colour (restyled in build 63).
- **App Drawer icons no longer pop in on Windows / Linux.** Root cause: build 58 made PC icons *fit* instead of crop, but the pre-loader that decodes every icon once at startup still asked for *crop*. Qt keys its image cache on the fill mode, so the rows never found the pre-decoded icons and decoded each one when it appeared. The pre-loader now asks for the same thing the rows do. No extra cost; Android was never affected.
- **Accent tints fixed:** theme.accent is stored as text, so every "accent at X% opacity" drew with undefined channels — the Settings rail glow, the drawer's letter tiles and three All Games panel tints. They now use a real colour (`accentA()` in theme.qml). The Settings rail's dark text on light accents (e.g. Lime) works for the same reason.

## build 61

- **App drawer source (Windows / Linux):** Settings › System › "App drawer source" picks which collection fills the App Drawer. **Auto** (default) is the "PC Apps" collection, as before; or pick any of your collections by name if yours is called something else. The chosen one is kept off the system row by "Hide PC Apps system tile". If the chosen collection disappears, the drawer goes back to Auto. This finishes the PC App Drawer plan.

## build 60

- **Power entries stay out of the library (PC):** Sleep, Restart, Shut down and the rest (genre Power) only live behind the drawer's Power tile now. They no longer show in the Home hero (after you used Sleep it took the hero), Home rows, All Games or the PC Apps page.
- **"Hide Android Games System Tile" is gone on Windows / Linux**, where it did nothing; "PC games in the App Drawer" takes its place.
- **App drawer blur is its own setting** (Settings › General, off by default, on Android and PC): it used to come only with High Quality Mode. With High Quality Mode on, the blur is drawn sharper; without it, at half size.
- **Settings follows UI Scale:** the text grows with it and the rows a little less, straight away (no reload).
- **Settings follows your background colour** instead of a locked charcoal, straight away. The cards stay dark; on White and Silver the title, the page list, the clock and the button prompts turn dark.

## build 59

### App Drawer on Windows / Linux (part 3)
- **PC games in the App Drawer (optional, off by default):** Settings › System › "PC games in the App Drawer" adds your Steam, GOG and Lutris imports, Playnite's PC collections, and collections of your own with a PC shortname (steam, gog, epic, heroic, lutris, pc, windows, linux) to the drawer's **Games** tab. The row only exists on Windows / Linux.
- **No Discover tile in the drawer on a PC.** The Hidden tile stays.
- **Icon set for the starter files:** every starter entry now has its own icon (generic glyphs on category colours: blue tools, grey power, purple launchers, green emulators, orange apps; no brand logos). The icons ship in each folder's `icons/`, so copy the whole folder.
- **PC Apps system tile** has its own logo and background art.
- Android is unchanged.

## build 58

### App Drawer: mouse (part 2 of the PC drawer)
- **Hover** picks an app, a nav row (Home, My games & apps) or a tile in the bottom bar; the **wheel** steps through the app list; **click** launches.
- **Right-click an app** opens its quick menu (as Start does); right-click again, or the mouse Back button, closes the innermost thing first — the Hide panel, then the quick menu, then the drawer.
- **Wide art on a PC** (Steam headers and the like) sits whole on the icon plate instead of being cropped to its middle. Android icons are unchanged.

## build 57

### App Drawer on Windows / Linux (part 1)
- **On a PC the drawer reads a collection called "PC Apps"** (shortname `pcapps`) instead of Android's apps, and keeps it off the system row the same way (Settings › System › "Hide PC Apps system tile").
- **PC tabs:** All · Favorites · Games · Emulators · Launchers · Apps · Tools, with new Launchers, Apps and Tools icons. Each entry's **genre** picks its tab (Game, Emulator, Launcher, App, Tool); the quick menu's "Move to…" offers the PC tabs.
- **Power tile:** entries with the genre **Power** sit behind a new tile at the foot of the drawer, which pops out like the guide's power menu (Sleep, Restart, Shut down, then the rest).
- **Starter files** in `extras/pc-apps/` for Windows and for Linux: File Explorer / Files, Task Manager, Settings and the four power entries switched on; common launchers, emulators and apps ready to switch on by deleting a `#`. Apps open without Pegasus waiting for them to close. See extras/pc-apps/README.md.
- Android is unchanged.

## build 56

- **Media viewer sound:** a video opened full screen from Game details' media row now has its own Sound setting (Settings › Previews & sound › Media viewer). Like Discover it always plays; Preview sound Off at the top mutes it too. It used to always play with sound.

## build 55

### Previews & sound, simplified
- **One short table:** Preview and Sound for Home rows, Library, Game details and More like this, plus Discover's sound. About half as many settings as before.
- **The switches at the top now show what they do.** With **Video previews** off, the table is replaced by one line saying previews are off everywhere (your choices are kept). With **Preview sound** off, the Sound column goes. A screen whose preview is off shows "—" for its sound instead of a greyed "On". (Before, the rows kept showing their own saved values, greyed, which read as if the switches did nothing.)
- **Library is one choice** for All Games and every system. Preview and Sound are gone from each system's Y panel and from All Games' (a system that had its own now follows Library).
- **"While it plays" settings moved to where they apply:** Library › While a preview plays (Grid: hide logo, List: hide), Home rows › Hide logo, Game details › More like this › Hide logo.

## build 54

- **Frame glow is honoured everywhere:** the focus ring on Settings rows and grid cards, the Y panels and the App Drawer's menus, and the page list's accent plate, now glow only when Settings › Appearance › Frame glow is on (they always glowed before).

## build 53

### PC fixes from Windows testing
- **Settings › Library and Previews & sound: mouse hover and wheel work.** Two causes. The wheel went to the page's hidden list (its wheel helper sat over the same area and still took the wheel on the grid pages). Hover picked a card without moving focus off the page list, so nothing showed, and Qt delivers "entered" before the theme's pointer tracker updates, so the first check saw a stale time and ignored the hover. Hover and the wheel now move focus into the grid, and the hover check also runs as the pointer moves inside a card.
- The same hover fix for Settings list rows (which now get picked by hover too), the Y panel, the drawer's quick menu, Game details' media row and the Achievements lists.
- **All Games list view: the Start "More Details" prompt is clickable.**

## build 52

### Xbox proportions
- **Settings** measured against the Xbox's own: the page list is a quarter of the screen, its rows 64 px tall at 1080p with the text 108 px in (the cog and "Settings" line up with it); the page title sits just past the divider and the settings column is the Xbox's two-card width (Previews & sound gets more room for its five columns). Rows and grid cards are a touch shorter, with the Xbox's wider gaps.
- **Y panels** (All Games, each system) narrowed to the Xbox pop-up width, 64 px rows.

### App drawer menus behave like the guide's
- The quick menu now **pops out beside the drawer**, level with the app it acts on, sliding out from behind it — instead of a box in the middle of the screen. Its **Hide** options cascade out to the right of the Hide row. Both use the green focus ring, a lighter dim, and the guide's row height. Mouse hover picks a row.
- Keyboard: the **Menu** key opens the quick menu (Start on a controller).

## build 51

### Mouse wheel
- A quick spin plays the navigation sound once instead of on every notch (every list, grid and Settings), and Home snaps between rows while the wheel spins instead of queueing one slide per notch.

### Testing notes
- **TESTING-windows.txt** brought up to date for the refresh branch: install, codecs, PC defaults, Ctrl+F, keyboard and mouse controls, and what to send back.

## build 50

### Windows / Linux: big screens and speed
- **1440p and 4K:** single images (logos, icons, Retro Achievements badges, Game details art) decode sharper in step with the screen; background blurs (Game details, the launch screen, All Games, the App Drawer backdrop) render at 1080p size and scale up — the same look for a quarter of the GPU memory at 4K. System tiles and the Home background decode for a 1080p screen in normal mode and for the real screen in High Quality Mode. Per-tile art is deliberately not grown. Android is untouched (the scale is exactly 1 there).
- **Snappier with a mouse or keyboard:** selection animations (tile grow and fades, row and grid slides, the system strip) run at half length on PC.
- **Fast tapping counts as racing on PC:** presses closer than a quarter second get the same light drawing as holding the D-pad on Home rows (no tile animations, art fills in when you stop).
- **Ctrl+F** toggles the frame rate counter (the same switch as Settings › System).
- **Retro Achievements:** a game's filter tabs (All / Earned / Locked) and sort chips are clickable.

## build 49

### Windows / Linux: videos
- **Every video player stops before it's destroyed** (changing screen, a row rebuilding, or Pegasus unloading the theme to start a game). Destroying a playing video is what the Windows media backend crashes on.
- **When videos can't play** (no codecs — Pegasus's Windows notes recommend the K-Lite Codec Pack, Basic): every failure is written to lastrun.log, and once two different files have failed the theme stops trying — previews, the Game details video and the carousel video fall back to art. **Discover** shows the game's art instead of black, with a one-line hint about the codec pack. Never applies on Android.
- **Game details** only fades its picture once the video is really showing frames (it used to fade after a fixed second, leaving black when the video never started).
- Videos are recognised in any common format and capitals: .MP4, .mkv, .avi, .mov, .m4v, .wmv and more.

### The hero follows launches on every platform
- On Windows/Linux, Pegasus only records "last played" once a game closes (and not during a library scan), so the hero box could show an older game. The theme now notes each launch itself and the hero uses it when it's newer — unless Home is hiding that game.

## build 48

### Y panels, Xbox 2023 style
- All Games' and each system's Y panel are redrawn to match Settings: a charcoal card with a hairline edge (no coloured outline, as on the Xbox), the same setting cards with the green focus ring, values in bold between ‹ ›, On/Off for Yes/No, and accent group names (Previews, Preview panel).
- A system's panel shows a tag beside its name — **OWN SETTINGS** or **FOLLOWS SYSTEMS** — and its first row explains the choice. **X Back to Systems** appears when the system has its own settings.
- The panel fits its rows (scrolling inside when there are more than fit), and its prompts — Back to Systems, All settings, Back — are clickable. Mouse: hover picks a row, clicking it changes it.

## build 47

### A system's Y panel matches All Games'
- In **list view** the panel shows the list rows — View, Preview, Sound, *While it plays, hide*, Blurred background, Scanlines — and in **grid view** the grid rows, with *Hide logo while it plays*. It used to show the grid rows in both views and grey them out in a list.
- *While it plays, hide* and *Hide logo while it plays* can now be set per system (they follow Systems until the system has its own settings).

## build 46

### Diagnostics, one panel
- Settings › System › Diagnostics is a single read-only panel — theme build, frontend, features, display, library — instead of five rows whose More info repeated the same line. Frame rate counter and Write diagnostics to log sit under it; the cursor steps over the panel.

## build 45

### Previews & sound: straight columns
- The "—" and "Always" placeholders can be focused now, so Up/Down/Left/Right move through every column in straight lines instead of skipping to whatever card was nearest. They have nothing to change; the help bar shows just Back on them.

### Mouse and keyboard on the grid pages
- Keyboard: Enter starts and finishes changing a value, the arrow keys change it, Esc finishes (or leaves the page when not changing).
- Mouse: clicking the ‹ arrow of the focused setting steps back, anywhere else on it steps forward; the mouse Back / right button finishes changing before it leaves the page.

## build 44

### Settings rail, Xbox style
- The page list runs from the screen's edge to a divider line. **While you're on the list**, the selected page is a solid accent plate with a soft glow (dark text on light accents like Lime). **While you're inside a page**, it's a grey plate with an accent edge against the divider. Icons removed, as on the Xbox.

### Changing values on the grid pages (Library, Previews & sound)
- **A on a setting starts changing it:** the ‹ › arrows light up and Left/Right change the value. **A or B** finishes; Up/Down finish and move on. Outside that, the D-pad only moves between settings. RB / LB still change the focused value directly. The help bar shows *Change* on a setting and *Done* while changing.

## build 43

### Settings grid pages: steady navigation
- **A or RB no longer throws the focus back to the first card.** The Library page rebuilds its cards when a saved value changes (it lists the systems with their own settings), and every rebuild reset the focus to All Games › View. The focus now stays on the same setting.
- **Left/Right and Up/Down move like a table.** The grid used to pick the nearest card by on-screen distance, which around the wide cards (Volume, Startup chime, All preview sound) chose odd targets and could refuse Right. Now Left/Right go to the next card in the row, and Up/Down go to the next row, staying in the column you're in — passing a wide card and coming back returns you to the same column. Where a row has nothing in your column ("—"), Up/Down land on the nearest card in that row.

## build 42

### Clickable button prompts (Windows / Linux, and touch)
- **Every prompt in the help bar does what its button does when clicked or tapped** — on Home, All Games and each system, Game details (with the media viewer and the manual), Discover, Settings (list and grid pages), Retro Achievements, and the search results. **Apps** opens the App Drawer.
- The prompts the panels draw themselves are clickable too: Sorting & Filters (and its genre and system lists), the Y panel, the search results and the Retro Achievements pages.
- How it works: a click travels the same way the key does — from whatever has focus up through the screen — so the tile under the cursor takes A, an open panel takes its own buttons, and the page takes the rest. A click on B that nothing else claims goes through the same path as the mouse Back button.

### Esc on Home opens the Pegasus menu (Windows / Linux)
- On Home, **Esc** now reaches Pegasus's own menu (themes, settings, quit) instead of opening Discover — a keyboard had no other way there but F1. A controller's B (and Backspace) still opens Discover. Android is unchanged.

### Previews & sound: master switches
- New **Everywhere** row at the top of Settings › Previews & sound: **All video previews** and **All preview sound**. Off stops (or mutes) every screen at once without touching each screen's own choice, so On brings them all back. Discover always plays its video; *All preview sound* mutes it too.

## build 41

### Settings, in the Xbox look
- **New layout:** a rail of pages with icons on the left; the page's title and a one-line summary on the right; every setting is a card — name on the left, value on the right between ‹ ›, On/Off in place of Yes/No — framed with the same focus ring as the tiles. Section names are small accent capitals.
- **Library** and **Previews & sound** are laid out as grids, as in the mockups: All Games beside Systems on Library; one row per screen with Preview, Sound, Grid: hide logo and List: hide columns on Previews & sound ("—" where a screen has no such setting). Move with the D-pad in any direction; A or RB changes a value, LB steps back, X shows More info, B or Left at the edge returns to the rail.
- Library lists the systems that have their own settings; X on one sends it back to following Systems.
- Right on the rail now enters the page, as A does.

### Banner
- **Background art** on Game details (and the launch screen) can be **Banner**; a game with no banner shows its fanart.
- **Media carousel › Banner** — banners used to be added to the carousel always; now it's a switch (on by default).

### Fixes found on the way
- A settings grid cell's value read through a function named `valueOf`, which every JavaScript object already has — QML called that instead and every value came back blank. Renamed.
- Scrolling a settings grid lagged one move behind (it read the focused cell before it was updated), so the bottom row could sit off-screen.

## build 40

### All Games and every system, set separately
- **All Games has its own View, tiles and titles; Systems is the default for every system** (Settings › Library). Changing All Games to list or grid no longer changes every system.
- **A system follows Systems or has its own settings.** Y on a system opens that system's panel: the top row says *Follow Systems* or *Its own*; while following, it shows what Systems uses, and changing any row gives the system its own settings, starting from what it showed. X in that panel sends it back to following Systems. The **Per-system overrides** switch and **Same as All view** are gone — Y on a system can no longer change every system.
- Y on All Games changes All Games only.

### Previews & sound, one page
- New **Settings › Previews & sound**: Preview, Sound and what hides while a preview plays, for each screen — Home rows, Library · All Games, Library · Systems (each system can have its own Preview and Sound), Game details background, Game details "More like this" rows, and Discover — plus menu sounds, volume and the startup chime. Replaces the rows spread over Tiles, Library, Game details and Audio.
- **Grids:** a tile's art always fades away under its preview; the choice is whether the logo goes too (**Hide logo while it plays**). The Library grid used to follow Home's row; it has its own now, for All Games and for Systems.
- **List view:** the screenshot always gives way to the preview; **hide while it plays** is None, Box art, Logo or Both (was two separate rows).
- Game details' "More like this" rows have their own Preview, Sound and Hide logo (they used to follow Home's, silently).

### Titles
- Home: **System row titles** (the system row, hero tile included) and **Collection row titles**, on Settings › Home.
- Library: **Tile titles** for All Games and for Systems, and per system.

### Settings pages
- New order: General, Appearance, Home, Home rows, Library, Game details (with the Media carousel items), Previews & sound, Retro Achievements, System (with Diagnostics), Tips & Tricks. Same look for now; the Xbox-style restyle is next.

### Sound
- Menu sounds and the startup chime re-mastered: +3 dB below ~150 Hz, −3 dB above ~5 kHz, same peak level.

### Updating
- Settings move over once (schema 2): every new setting starts from what the screen showed before — Systems takes the old View and System-view tiles (or the All view's, if "Same as All view" was on), the Library's titles take Home's, Systems and "More like this" previews take what they followed, and the two list hide rows become one choice. Per-system settings that were switched off by the old master switch stay off.

## Build 39

### Windows / Linux, part 1 (ported from the windows-wip branch, re-done on the refresh)
- **Mouse hover only follows the mouse.** Hover selects tiles, but a list scrolled by keys, wheel or a held D-pad moves tiles under a pointer that's sitting still, and Qt reports that as the pointer "entering" them — the selection jumped to whatever passed under the cursor, mid-scroll. Hover now counts only when the pointer itself moved in the last 300 ms (one watcher on the whole theme that doesn't take hover from anything). Applies to game tiles, Home system tiles, the Game details media strip and the RA lists.
- **Hover works in the Library grid.** The tiles played their nav sound on hover but the grid never moved the selection.
- **The wheel and hover stop at the screen you're on.** Every full-screen page now swallows the wheel as well as clicks, and overlays (app drawer and its menu, the Library's Y panel and filter panel, Settings' keyboard and info box, search) block hover and wheel for what's behind them. Hidden screens take no mouse input at all (`enabled: shown` on every screen), so tiles behind Settings stopped lighting up and playing sounds.
- **The wheel steps the Library's Y-panel rows.**
- **Desktop defaults** (only for settings you've never changed): video previews off on Windows and Linux (many PCs lack the codecs; a failed preview is a black box), mouse hover on, startup chime off; menu sounds off on Windows. Android keeps every default it had. The defaults live in one place now, so Settings and the theme can't disagree about them.
- Fixed: on a keyboard-only setup (no controller bound), help-bar prompts lost their icon and threw an error; they now show the default controller glyph. The help bar no longer swallows clicks over its whole strip, and its text no longer sits on a circular height binding.
- Fixed (Linux): system logos and backgrounds weren't found when a collection's shortname had capitals (Linux file names are case-sensitive).
- Already in place, so not ported: previews pause while Pegasus's own menu is open (the playback owner already follows the theme's focus).

## Build 38

### Less work before the theme appears
- Home's random rows (publisher, developer, two genres) were picked by four separate passes, each first copying the whole library into a JS array — four copies of ~4,400 games before the first frame. Now one pass, reading each game in place (`Utils.homePools`). Returning from a game restores the saved picks without any pass at all. The four old helpers are gone.
- The library search and its on-screen keyboard (about 1,500 lines of QML) are built 5 s after start, when their index warm-up began anyway, or the moment search is first opened — no longer before the first frame.
- The RA username / API-key keyboard in Settings is built only while it is open, not on every visit to Settings.
- Home rows: the genre rows normalised the wanted genre for every one of ~4,400 games on each re-filter; now once. Jump Back In and Most Played skip their per-game genre check when neither Hide option is on (the default).

### Home rows recycle their tiles
- The Home rows now recycle tiles that scroll off (as the Library grid's rows do) instead of destroying and rebuilding them, and while Left/Right is held tiles skip their animations and take their art once they've kept their game for 100 ms, like the Library grid.

## Build 37

### Images decoded at the size they're shown
- Game details media strip: each thumbnail was decoded at the file's full size (a 1080p–4K screenshot or fanart is 8–33 MB of texture) for a ~300 px tile. Now 1.5x the tile. The film-glyph images only load on video tiles.
- Home system strip: logos decoded at the grown tile's size instead of 512 px; the hero art and hero logo likewise. A custom `background.png` is decoded at screen size (a 4K one was a 33 MB texture).
- Home system strip: the hero tile's block (art, rounding shader, logo, title bar) is only built for the hero. Every system tile used to carry it invisibly.

### Effects drawn once, not every frame
- 16 blurs and drop shadows (Home nav buttons, row titles, Game details buttons and logo, the background blurs on Game details and the Library list, the launch screen, app-icon shadows) now cache their result. Without it they re-ran their blur passes on every frame the screen redrew — continuous on Home while the dynamic background, a marquee or a video is moving.
- Library list: the screenshot is rounded in one shader pass (as the tiles are) instead of an offscreen layer plus mask on every art change. The scanlines overlay no longer keeps an offscreen layer while scanlines are off.

On the test machine: Game details at rest 42 → 60 fps; leaving it 55 → 60 fps; memory at the end of the standard run 646 → 533 MB.

## Build 36

### One focus frame
- The Xbox-style frame is now the only tile frame, and its ring is 0.5 px thicker (3 px; 2.7 px on the box-art tiles, which grow 1.1x on focus, so they read the same). **Settings > Tiles > Tile frame** is gone, and with it the Classic accent border, the Classic halo image on selected tiles and system tiles, and `Global/ItemBorder.qml`.
- **Tile Halo** is now labelled **Frame glow** (same setting, same saved value): the soft glow outside the frame.
- **Highlight animation** is gone. It only ever pulsed the Classic frame.
- Favourite tiles keep their accent edge and soft glow.

### Featured box removed
- The large featured tile on Home (Favorites / Discover videos / fanart slideshow) and its three settings are gone, along with `Global/FavoritesHeader.qml`. Home rows are plain rows again: Left/Right wrap end to end, and moving between rows lands on the nearest column with no carousel slot in the way.
- Also removes what it cost at rest: a full-resolution fanart decode every 8 seconds for the slideshow, a video drawn through an offscreen mask for Discover mode, and the "row preview yields to the box" bookkeeping. Discover always starts on a random video now (it used to resume the box's).

### Cleanup
- Saved values for the removed rows, and two keys no row ever used (`Featured collection`, `AllGames Match Platform`), are cleared from the settings file once at startup.
- Game details and the launch screen read a "random background" option that never existed; they always showed the first screenshot/fanart, and still do, without the dead branch.
- Removed orphans: `Global/HeaderBar.qml` (unused since the Platform page went), `Global/GridSpacer.qml` and the details page's unused sizing box, and two images only HeaderBar used.
- Fixed: the mouse Back button on Discover threw an error instead of going back.
- Help texts no longer mention the Platform page or the Featured box.

## Build 35

### Fanart while fast-scrolling the grid
- Tiles no longer stay blank for the whole hold. A tile that keeps the same game for 100 ms while its row is on screen takes its art mid-race; the grid's rows only change game at the screen edges, so art fills in about a row behind the cursor. Tiles that flash past at the edge, and look-ahead rows off screen, never ask, so there is no request-then-cancel. Logos still wait for the release. (Test machine, 10 steps a second: 60 fps throughout, ~40 art loads a second.)

### Work nobody sees, removed
- **Game details no longer follows the Library cursor while hidden.** It stays loaded after the first visit, and was bound to the current game, so every step through the Library re-ran the hidden page: two 4,400-game walks, the media list, a full-screen fanart decode. It now follows only while it is the screen and catches up when shown. On the test machine the Library race after visiting details went from ~41 to ~55–58 fps. This is also most of why the list felt heavier after the refresh.
- The full-screen media viewer decodes nothing until it is opened (it was decoding 1–3 full-screen images per game change, unseen).
- A Home row set to None held the whole library: `max: 0` became `IndexFilter { maximumIndex: -1 }`, which means "up to the last row". The hidden row built tiles and decoded art over all 4,400 games. It now has no source at all.
- One Wi-Fi check for the whole theme, only while the theme is in front and the indicator is shown. Each status bar ran its own 30-second request, on hidden screens too and with the indicator off.
- The library and Home hide lists skip their 4,400-game walk when there is nothing to hide (always on desktop).

### Library list
- Held keys are frame-paced like the grid's, so the list stops when you let go instead of draining queued repeats.
- While racing, the preview art and the header system logo follow the cursor four times a second instead of freezing for the whole hold. The video still waits for the race to end.

## Build 34

### No video preview is warmed while scrolling (the Odin stall)
- Build 33's log from the Odin 2 showed the grid at 4–9 fps with 160–250 ms frames during a hold, and twice the UI thread froze for 2–3 s — with no tiles being built any more. The cause is the preview video. In HQ the highlight starts **warming** the preview after 300 ms on a tile (play at 1.5 s, decoder warm-up 1.2 s ahead). One slow step past 300 ms creates the Video for a tile the cursor is already leaving; the next step tears it down. On Android a MediaPlayer built and released on the UI thread — reading from the SD card — is a 100–300 ms stall, which trips the warm-up again on the next tile, and so on until the key is released. It also explains why turning video previews off made scrolling smooth.
- The highlight now has a `racing` flag from its host: no preview is warmed or created while a key is held (Library grid, Library list and the Home rows), and the normal rest-then-play resumes when the race ends. The list view's preview art (backdrop, screenshot, box, logo) likewise waits for the race to end instead of swapping on every slow step.

## Build 33

### Library grid rebuilt on recycled rows (the fast-scroll fix, properly)
- The grid was a Qt GridView, and in Pegasus's Qt (5.15) a GridView **never recycles its tiles** — `reuseItems` is accepted and ignored (its `removeItem()` releases every tile as NotReusable). So a held D-pad built a full row of tiles on every step and destroyed the row that left: each tile is several images, texts, loaders and a shader, and the destroyed ones piled up until the JavaScript engine paused to collect them. That is why scrolling got slower the longer the key was held (58 → 23 → 6 fps on the Odin 2 in the build 32 video) — and why build 32's art hold-off made it look worse: with nothing left to show, the per-step rebuild was all that remained.
- The grid is now a ListView of **rows** (`Global/RowGrid.qml`), which does recycle: a row that scrolls out comes back in at the other edge with a new index, and its tiles only rebind. During a 12-second race on the test machine, 69 tiles are built in total and none destroyed (build 32: ~125 built and destroyed per second), 60 fps throughout with a worst frame of 22–34 ms, and no art decoded until the scroll stops. The flat game index, Back, letter jumps, the wheel, the restore, the highlight video, per-system tiles and the box-art style are unchanged on the outside.
- A tile's art now follows a game it is **given** (`artGame`) rather than a binding on its model data, so a recycled tile can never request a decode that is cancelled a moment later.
- While the grid races, a passing tile is a dark card with its name bar instead of a blank, and the bar stays up until that tile's art has decoded. No extra text layout: the bar's title was always set.
- The imported-app treatment (blurred icon backdrop, two offscreen layers, three images) is only built for imported apps; every ROM tile used to carry it invisibly.

### Diagnostics
- With the frame-rate counter on, the counter also writes its once-a-second reading (`[perf] hh:mm:ss fps N worst M`) to `lastrun.log`, so a stutter in a report can be read against what the log says was happening.

## Build 32

### Fast scrolling with logos on
- Tiles created while the grid races are meant to hold off loading their art and logo until the scroll stops. That only ever worked for recycled tiles: a brand-new tile requested its images before the hold-off kicked in, then cancelled them. With logos on, a 6-second race requested about 700 logos it never showed. New tiles now hold off from their first instant. On the test machine the race went from about 42 fps / 90 ms stalls to about 56 fps / 55 ms, close to logos-off.
- The game title that a tile shows in place of a missing logo was being laid out for every passing tile even when invisible (outlined, wrapped text is the most expensive thing a tile draws). It now only exists when it's about to be shown, and never during a fast scroll.

## Build 31

### Smaller download
- Removed about 2.2 MB of files nothing used: four unused fonts, an unused 1.2 MB Xbox logo, three old scanline images, the keyboard key images (80 files), an unused CRT shader and two stray icons. Nothing on screen changes.

### Checks on every push
- The repo now runs its own checks on GitHub for every push and pull request (`.github/workflows/checks.yml`): bracket balance, duplicate properties, the scope check and an asset check that every image or font the code names exists. The scripts live in `tools/` so they can be run locally too.

## Build 30

### New: Settings → Diagnostics
- Shows the theme build, which Pegasus you're on (stock or Pegasus X, with its features), your display and UI scale, HQ mode, tile frame and library size. **A** on any row opens the full list.
- **Write diagnostics to log** writes those lines to `lastrun.log`, so a tester can send one file with a report.
- The **Frame rate counter** switch moved here from Tiles.

### Under the hood
- One `Platform` object answers "which OS, which Pegasus, which features" for the whole theme, in place of checks scattered through the code.

## Build 29

### Old Platform page removed
- The separate Platform page (and its **Library screen: Separate** option) is gone; the Library is the one screen for All Games and every system. About 1,600 lines of QML removed. Your Platform page settings live on as **Tiles – System view**, and per-system overrides are untouched.
- Settings help text and tips now talk about the Library instead of the Platform page.

## Build 28

### Fixed
- Back from Game details now returns to the system you were browsing, not to All. The Library screen is unloaded while hidden to save memory, and the rebuilt one forgot its system.
- Stepping between systems with different **Tiles per row** no longer leaves old-sized tiles overlapping the new grid. The grid now rebuilds its tiles on a system change, after the new system's games are sorted.
- Coming back from a game now restores the system too, even when the game was launched from Game details.

## Build 27

### Settings → Library
- The **Platform page** and **All Games menu** sections are now one **Library** section, grouped by what you see: **Layout** (Library screen, View, LB/RB on a system), **Video**, **Tiles – All view** and **Tiles – System view**. Same settings underneath, so nothing you've set changes.
- **Same as All view** (System view) makes systems use the All view's tile settings. It replaces the old **Match Platform page**, which pointed the other way.
- **View** can now be set per system: with **Per-system overrides** on, Y while viewing a system has a **View** row (List/Grid) alongside its tile rows. A system can be a list while All is a grid.
- Tips updated for the merged Library.

### Fixed
- Changing a system's View from its Y panel no longer drops focus out of the panel (Back then left the Library).
- LB/RB between a list-view system and a grid-view system no longer loses focus.

## Build 26

### One Library screen (All Games + Platform page)
- Opening a system from Home now lands on All Games scoped to that system: same screen, same filters, list and grid views and quick settings. **Settings → Platform page → Library screen** switches between **Merged** (new, default) and **Separate** (the old Platform page).
- Scoped to a system, the tiles follow the **Platform page** settings, with that system's own **per-system tile settings** on top when that option is on, exactly as before. The All view keeps the All Games settings.
- **Y** on a scoped view opens that system's own tile settings (or the Platform page's when per-system settings are off). Changes apply as you make them.
- **LB/RB** on a scoped view step to the previous/next system in Home's order (when LB/RB Function is Cycle Platforms). The **Library** button and nav icon always show All.
- **Discover** from a scoped view is scoped to that system, as on the Platform page.
- Coming back from a game returns to the same system and row.

### Fixed
- In grid view the button bar now reads **A Select** from the start; it used to show the list view's **A Launch** until something refreshed it.

## Build 25

### RetroAchievements: Back from a game's achievements
- Opened from **Game details** (the RA button): one Back now returns straight to the details page. Before, it went to the RA overview first.
- Opened from the RA overview (after entering RA from Home, the Platform page or the app drawer): Back returns to the overview, and a second Back leaves RA, as before. Picks from RA Search still return to the search results.

### Fixed
- Two errors the WiFi indicator could log when a screen closed while its connection check was still running.

## Build 24

### App drawer built on first open
- The drawer's screen (about 1,700 lines of QML) is now created the first time you open it, instead of at startup, and kept from then on. Memory after startup is about 90 MB lower on the test machine (about 490 MB → 400 MB).
- The drawer's data (the app list, categories, favourites, hidden apps) still loads at startup, in a new `Global/AppLibrary.qml`, because Home and the library use it to know what to hide. Everything you've favourited, hidden or re-categorised is unchanged.

## Build 23

### Under the hood: one place for screen changes
- Every screen change and the Back history now go through one component (`Global/Navigator.qml`). Before, a dozen functions in `theme.qml` each pushed, popped or rewrote two bare lists in slightly different ways, which is where most Back oddities came from. Nothing should look different; Back and returning from a game use the same code paths as before, just in one place. Saved return info from builds 2–22 still restores.

## Build 22

### Fixed
- **Tile Halo** works again. In Xbox mode it switches the frame's glow on or off (the ring stays). In Classic it switches the halo image. It now applies straight away instead of after a reload.

## Build 21

### Fixed
- **3D Box tiles:** the glow on the selected box no longer draws a blocky accent patch beside it. 3D renders often include nearly see-through pixels (a soft drop shadow, leftover transparency). The glow traced those too, and the tighter Xbox glow made them solid. The glow now follows only the box itself, and the box's own shadow is kept. This also fixes a faint version of the same patch in **Classic**.

## Build 20

### Xbox tile frame
- The ring is 0.5 px thicker everywhere.
- **Box Art tiles:** small corners and the same gap, ring and glow, sized for the box's 1.1x focus zoom so the ring matches the other tiles.
- **3D Box tiles:** the glow that traces the box's outline is thinner and tighter.
- The favorite outline follows the smaller corners.

## Build 19

### Xbox tile frame everywhere
- **Settings → Tiles → Tile frame** now applies to the whole theme: the Platform page, All Games, the Home rows, the "more like this" rows in Game details, and the system and hero tiles on the Home strip. It still switches live, and **Classic** is unchanged.
- In Xbox mode, the system and hero tiles use the same small corners, gap, ring and glow, in place of the thick accent border, the glow image and the animated highlight.
- The All Games video preview now stops at the bottom of the tile when titles are set to **Always**, like the Platform page.
- Box Art and 3D Box tiles keep their own look for now.
- Fixed an error the video preview could log when a row changed.

## Build 18

### Pegasus X: 3D boxes and manuals
- On Pegasus X (build 2124+), the theme uses Pegasus X's own list of a game's 3D box renders. Any folder spelling now counts ("3D Boxes", "3d_box", "box-3d" and so on), for the 3D Box tiles, the All Games box panel, the media carousel and its "3D Box" label. The flat cover is the first box art that isn't 3D. On stock Pegasus the file-name check works as before.
- Manuals: Pegasus X tells the theme which PDF belongs to each game (x-manual, media/manual(s) in any case, media/<game>/manual.pdf, ES-DE's manuals folder). The theme's own search is still the fallback.

## Build 17

### New: Xbox-style tile frame (Platform page, trial)
- **Settings → Tiles → Tile frame (Platform page)**: **Classic** (unchanged) or **Xbox**. It applies straight away, so you can switch back and forth to compare.
- **Xbox:** small rounded corners on the art, a thin see-through gap, a thin accent ring and a short soft glow, like the Xbox dashboard's focus frame. The video preview fills the art area and gets the same rounded corners.
- **Built to stay fast:** the frame is drawn in one step, and only on the selected tile. The art uses the same one-step rounding as before, and the video adds one extra layer only while a preview plays. It replaces the old glow image on that page.
- The video preview now fades in as the art fades out, so its edge no longer shows a moment before the transition. It also stops at the bottom of the tile when titles are set to **Always**.
- For now only the Platform page uses it. Home, All Games and the system tiles follow once the look is settled.

## Build 14

### Faster hand-off from Pegasus
- Pegasus's loading screen now disappears about 2 seconds sooner (about 5.2 s → 3.2 s on the test machine). Pegasus keeps its screen up until the theme has finished building, and the theme was building all of Home first, including its game rows, which sort and filter the whole library.
- With the startup intro on, Home now builds behind the intro, and the intro stays up until Home is ready (at least 1.5 seconds, never more than 15), then fades into it.
- With the intro off, or when coming back from a game, nothing changes: Home is ready before the theme appears.

## Build 13

### New: Startup intro
- When Pegasus starts with XboxOSv2, an Xbox intro covers the moment Pegasus hands over to the theme, then fades into Home. It never plays when you come back from a game.
- To use your own intro video, put it at `assets/video/intro.mp4` in the theme folder. Without one, the intro shows a still image (`assets/images/intro.jpg`) for a few seconds. The startup chime plays once, as the intro fades into Home.
- Turn it off in **Settings → Advanced → Startup intro**.

### Startup chime
- The chime now plays as the theme appears (or, with the intro on, as the intro fades into Home). Before, it started when the theme finished loading, while Pegasus's own loading screen was still showing.

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
