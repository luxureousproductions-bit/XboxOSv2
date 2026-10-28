#!/bin/bash
# One-time setup of the test harness in a fresh Linux session (Ubuntu 24.04).
#   bash tools/harness/setup.sh
# Builds $HARNESS (default ~/xbx-harness): stock Pegasus (the same nightly the
# baselines were measured on), a 4,400-game fake library across 24 systems, a
# PC Apps starter + fake Steam collection, and the start/stop scripts.
set -e
. "$(dirname "$0")/env.sh"

# Packages: virtual X server, screenshots (ImageMagick `import`), XTest for the
# key/mouse driver, GStreamer for video, ffmpeg for the test clip.
if ! command -v Xvfb >/dev/null || ! command -v import >/dev/null; then
    apt-get update -qq
    apt-get install -y -qq xvfb imagemagick libxtst6 ffmpeg \
        gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libav >/dev/null
fi
pip install --break-system-packages -q pillow 2>/dev/null || true

mkdir -p "$P/config/themes" "$P/results" "$HARNESS/testenv/media"

# Pegasus: alpha16-107-g5d58223e, x11 static build, from the project's
# continuous release. Baselines below were measured on exactly this build.
if [ ! -x "$P/pegasus-fe" ]; then
    cd "$HARNESS"
    # Kept on this repo's `harness-pegasus` branch: Claude cloud sessions can
    # clone/fetch but can't download GitHub release files.
    # PEGASUS_ZIP=/path/to/zip skips the fetch.
    if [ -z "$PEGASUS_ZIP" ]; then
        ZIP=pegasus-fe_alpha16-107-g5d58223e_x11-static.zip
        git -C "$REPO" fetch -q origin harness-pegasus
        git -C "$REPO" show "FETCH_HEAD:$ZIP" > "$HARNESS/$ZIP"
        PEGASUS_ZIP=$HARNESS/$ZIP
    fi
    unzip -o -q "$PEGASUS_ZIP" -d pgrun
    chmod +x pgrun/pegasus-fe
fi

cat > "$P/start.sh" <<'EOF'
#!/bin/bash
P=$(cd "$(dirname "$0")" && pwd); cd "$P"
pkill -x pegasus-fe; pkill -x Xvfb; sleep 0.5
Xvfb :99 -screen 0 ${RES:-1280x720}x24 -nolisten tcp -ardelay 300 -arinterval ${ARINT:-40} >/dev/null 2>&1 &
sleep 1
export DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 QT_QPA_PLATFORM=xcb GST_PLUGIN_FEATURE_RANK=kmssink:NONE ${EXTRA_ENV}
nohup ./pegasus-fe --portable > run.out 2>&1 &
echo started
EOF
cat > "$P/stop.sh" <<'EOF'
#!/bin/bash
pkill -x pegasus-fe; sleep 1; pkill -9 -x pegasus-fe 2>/dev/null; pkill -x Xvfb; echo stopped
EOF
chmod +x "$P/start.sh" "$P/stop.sh"

printf "general.theme: themes/%s/\ngeneral.fullscreen: false\ngeneral.verify-files: false\n" "$THEME" > "$P/config/settings.txt"
mkdir -p "$P/config/theme_settings"

# Theme copy first (gen.py reads its system logos).
bash "$T/sync.sh"

# Fake library: 4,400 games, box art + screenshot each, every 3rd has a video.
TE=$HARNESS/testenv
[ -f "$TE/media/preview.mp4" ] || ffmpeg -loglevel error -f lavfi -i testsrc=size=640x360:rate=30 \
    -f lavfi -i sine=frequency=440 -t 8 -c:v libx264 -pix_fmt yuv420p -c:a aac "$TE/media/preview.mp4"
[ -d "$TE/lib/snes" ] || python3 "$T/gen.py" "$TE" "$H" 4400
ls -d "$TE"/lib/*/ | sed 's#/$##' > "$P/config/game_dirs.txt"

# PC drawer fixtures (used by drawerrun.sh only): the Linux starter + fake Steam.
rm -rf "$TE/pcstarter"; cp -r "$REPO/extras/pc-apps/linux" "$TE/pcstarter"
mkdir -p "$TE/steamfake"
cat > "$TE/steamfake/metadata.pegasus.txt" <<'EOF'
collection: Steam

game: Hollow Knight
file: steam:367520
genre: Action

game: Celeste
file: steam:504230
genre: Platformer

game: Hades
file: steam:1145360
genre: Action, Roguelike
EOF
echo "harness ready in $HARNESS — run: bash tools/harness/scenario.sh base"
