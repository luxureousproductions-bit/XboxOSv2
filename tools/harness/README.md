# XboxOSv2 test harness

Runs the theme in stock Pegasus on a virtual screen (Xvfb, 1280x720, software
rendering), drives it like a controller, takes screenshots and logs frame
rates. It's how every refresh build was checked before it was pushed. Use it
so the redesign doesn't lose the performance work in builds 1–63.

It is **not** a handheld. Numbers here are slower than any real device (two
CPU cores, no GPU) and only mean something compared with each other, on
the same machine, in the same session.

## Setup (once per session, ~1 minute)

```bash
bash tools/harness/setup.sh          # builds ~/xbx-harness (HARNESS=... to change)
```

- Installs Xvfb, ImageMagick, XTest, GStreamer and ffmpeg if missing.
- Pegasus: **alpha16-107-g5d58223e**, x11 static. It comes from this repo's
  `harness-pegasus` branch. Claude cloud sessions can't download GitHub release
  files, and every baseline below was measured on this exact build.
- Fake library from `gen.py`: 4,392 games across 24 systems. Each game has
  box art and a screenshot, and every third one has a video (an 8 s test
  clip with sound).
- PC drawer fixtures: the Linux PC Apps starter file, plus a fake "Steam"
  collection with 3 games.

## Every build

```bash
bash tools/harness/sync.sh           # copy the working tree in (+ instrumentation)
bash tools/harness/run.sh mytest wait:2000 shot:home down enter wait:3000 shot:page
```

`sync.sh` copies every git-tracked file except `tools/` and `extras/`, then
patches the copy. The frame counter is always on, logs
`[perf] hh:mm:ss fps N worst MS` each second, and grid tiles are counted.
Never commit the patched copy. If sync stops with "harness patch no longer
applies", FrameCounter.qml, DynamicGridItem.qml or theme.qml's frame-counter
line changed; update the patch in `sync.sh`.

| Script | Does |
|---|---|
| `run.sh <label> <tokens>` | Boots at Home with clean settings, runs the tokens, lists QML errors |
| `settingsrun.sh <label> <tokens>` | Same, opening Settings (F) first |
| `drawerrun.sh <label> '<json>' <tokens>` | Adds the PC Apps starter + fake Steam; `<json>` = theme settings (e.g. `{"PC games in App Drawer":"Yes"}`) |
| `scenario.sh <label>` | The standard performance run (below) |
| `compare.sh <commit> [rounds]` | A/B: that commit vs the working tree, interleaved |

Results land in `$HARNESS/pgrun/results/<label>/`: screenshots, `run.out`
(Pegasus log), `actions.log`, and for scenarios `segments.txt` and
`summary.txt`.

**Key tokens** (`xkeys.py`): `up down left right enter esc tab bksp f i q e
pgup pgdn f1`; `hold:<key>:<ms>`; `wait:<ms>`; `shot:<name>`; `mark:<label>`;
`move:x,y`; `click`; `click:right`; `wheel:down:<n>`. Keyboard map: Enter = A,
Esc/Backspace = B, I = X, F = Y, Q/E = LB/RB, Tab = App Drawer. Pegasus
settings files write keys as `<name>` plus `<name>Index`. The json in
`drawerrun.sh` writes only the value, so a Settings row can show its default
there while the theme uses your value.

## The standard scenario

`scenario.sh` boots, rests on Home, opens a system and holds Down for 5 s.
It opens a game's details and goes back. It opens All Games and holds Down
for 5 s. Back on Home, it holds Right for 4 s. Each step is a segment in
`segments.txt`: seconds, min/avg fps, worst frame in ms. `summary.txt` adds
startup time and memory.

## Baseline: build 63 (3589cdf), Oct 28 2026

Fresh harness from `setup.sh`, 2 CPUs. Averages of interleaved runs. Build 57
was measured alongside it and comes out the same within noise.

| Segment | Build 63 avg fps (runs) | Build 57 avg fps (runs) | Worst frame |
|---|---|---|---|
| home_race (hold Right on Home) | 23.9 (21.9, 22.0, 24.0, 25.7, 24.9) | 24.8 (24.1, 25.3, 24.4, 25.3) | 80–180 ms |
| platform_race (hold Down in a system) | 46.7 (46.7, 47.1, 46.4) | 46.8 (46.2, 47.4) | 70–90 ms |
| allgames_race (hold Down in All Games) | 31.4 (30.2, 28.6, 33.7, 33.3, 31.3) | 32.7 (32.1, 32.0, 33.8, 32.7) | 80–145 ms |
| details_idle | 51–60 | | |
| startup (warm) | 4.7 s | | |
| memory after start / at end | ~314 MB / ~459 MB | | |

A first run after `setup.sh` is cold. Pegasus builds its caches and startup
takes ~10 s; ignore that run. home_idle often shows one 3–4 s "worst frame"
in any run: that's the theme loading, not a stutter, so ignore home_idle's
worst_ms. One round of `compare.sh` isn't enough either: builds 62 and 63
(which differ only in the nav pills) were 6 fps apart on platform_race in
a single round.

**What counts as a regression:** run `compare.sh <previous build> 2`.
- A race segment's interleaved average down more than ~10% (single runs swing
  ±3 fps).
- Worst frames routinely past ~150 ms.
- Warm startup past ~6 s.
- Memory at the end well past ~460 MB.

Two separate runs on their own prove nothing. In this session, build 63 once
looked 4 fps slower than 57 until the runs were interleaved.

## Things the speed work depends on (don't undo without measuring)

- **Android draws exactly as before:** `hiResScale` is exactly 1 on
  Android. `decodePxFor()`, `hrpx()` and the blur sizes only grow on big
  desktop screens; `animMs()` halves animations on desktop only.
- **Image caches only work when the keys match:** a pre-decoder must use the
  same `source`, `sourceSize` **and `fillMode`** as the items that show the
  image. The App Drawer's icon warmer missed on PC for this reason until
  build 62.
- **App Drawer delegates stay alive while it's closed** (emptying the model
  made every open re-decode and pop). Its icons load async; the warm cache
  makes them land the same frame.
- **Home's hide lists are built once per change:** `libraryHideRows`,
  `homeHideRows` and `rebuildHomeHide()` in theme.qml. They're published only
  when their contents change (a signature check), and wait while the drawer
  is open. Don't make Home rows filter per game per row again: that was ~10 s
  frozen per "Move to…".
- **The hero re-reads with `Qt.callLater`** (refreshResume), not a function
  binding.
- **Drawer blur is a snapshot, not live:** one blur pass per open, off by
  default, half size outside High Quality.
- **Every `DropShadow` that doesn't change is `cached: true`.**
- **Videos stop on destruction.** Two failed videos turn previews off
  (desktop), and preview masters gate everything through
  `gatePreview()`/`gateSound()`.
- **Settings and per-screen values that change at runtime are read through
  `settingsEpoch`**. The plain `settings` object only refreshes on reload.
- **`theme.accent` is a string**, so use `accentA(alpha)` or a `color`
  property for its r/g/b.

## Also check visually

Take a screenshot (`shot:`) of what you changed, at 1280x720 and with the
`RES=1920x1080` start variable for desktop. Before pushing, also run
`balance.py` and `dupprops.py` on changed QML, `scopecheck.py .` and
`assetcheck.py`. CI runs the same checks.
