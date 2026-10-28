#!/bin/bash
# usage: run.sh <label> <xkeys tokens...> — boots at Home with clean settings, runs the tokens, lists QML errors
. "$(dirname "$0")/env.sh"
L=$1; shift
mkdir -p $P/results/$L; cd $P; ./stop.sh >/dev/null 2>&1
sed -i "s#general.theme: .*#general.theme: themes/$THEME/#" config/settings.txt
rm -f config/theme_settings/*.json; cp $T/clean_settings.json config/theme_settings/$THEME.json
RES=${RES:-1280x720} ./start.sh >/dev/null
for i in $(seq 1 120); do grep -aq "\[perf\]" run.out 2>/dev/null && break; sleep 0.25; done
DISPLAY=:99 SHOTS=$P/results/$L python3 -I $T/xkeys.py wait:3000 "$@" > results/$L/actions.log
cp run.out results/$L/run.out; ./stop.sh >/dev/null
grep -aE 'TypeError|ReferenceError|is not a type|unavailable|not a function|Cannot' results/$L/run.out | sort | uniq -c | sort -rn | head -15
