#!/bin/bash
# usage: compare.sh <reference commit> [rounds=2]
# A/B performance check: runs the standard scenario on the reference commit and
# on the working tree, interleaved (ref, current, ref, current ...), so both see
# the same machine state. Prints each run's race segments and the averages.
# Single runs swing by ±3 fps here; only interleaved averages mean anything.
. "$(dirname "$0")/env.sh"
REF=$1; N=${2:-2}
[ -n "$REF" ] || { echo "usage: compare.sh <reference commit> [rounds]"; exit 1; }
WT=$HARNESS/ref-checkout
git -C "$REPO" worktree remove --force "$WT" 2>/dev/null; rm -rf "$WT"
git -C "$REPO" worktree add --detach -q "$WT" "$REF" || exit 1
for i in $(seq 1 "$N"); do
    REPO=$WT bash "$T/sync.sh" >/dev/null || exit 1
    REPO=$WT bash "$T/scenario.sh" "cmp_ref_$i" >/dev/null 2>&1
    bash "$T/sync.sh" >/dev/null || exit 1
    bash "$T/scenario.sh" "cmp_cur_$i" >/dev/null 2>&1
done
git -C "$REPO" worktree remove --force "$WT"
python3 - "$P/results" "$N" "$REF" <<'PY'
import sys, re, os
res, n, ref = sys.argv[1], int(sys.argv[2]), sys.argv[3]
segs = ["home_race", "platform_race", "allgames_race", "open_details", "home_idle"]
def read(lbl):
    out = {}
    for line in open(os.path.join(res, lbl, "segments.txt")):
        m = re.match(r"(\S+)\s+secs=\s*\d+ min_fps=\s*(\d+) avg_fps=\s*([\d.]+) worst_ms=\s*(\d+)", line)
        if m: out[m.group(1)] = (float(m.group(3)), int(m.group(4)))
    return out
for side, tag in (("ref", ref), ("cur", "working tree")):
    runs = [read(f"cmp_{side}_{i}") for i in range(1, n + 1)]
    print(f"{tag}:")
    for s in segs:
        v = [r[s][0] for r in runs if s in r]
        w = [r[s][1] for r in runs if s in r]
        if v: print(f"  {s:14s} avg_fps {sum(v)/len(v):5.1f}  (runs {', '.join(f'{x:.1f}' for x in v)})  worst_ms max {max(w)}")
PY
