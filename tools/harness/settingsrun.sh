#!/bin/bash
# usage: settingsrun.sh <label> <xkeys tokens...> — boots, opens Settings (F), runs the tokens
. "$(dirname "$0")/env.sh"
L=$1; shift
mkdir -p $P/results/$L; cd $P; ./stop.sh >/dev/null 2>&1
sed -i "s#general.theme: .*#general.theme: themes/$THEME/#" config/settings.txt
rm -f config/theme_settings/*.json; cp $T/clean_settings.json config/theme_settings/$THEME.json
RES=${RES:-1280x720} ./start.sh >/dev/null
for i in $(seq 1 120); do grep -aq "\[perf\]" run.out 2>/dev/null && break; sleep 0.25; done
DISPLAY=:99 SHOTS=$P/results/$L python3 -I $T/xkeys.py wait:3000 f wait:2500 "$@" > results/$L/actions.log
cp run.out results/$L/run.out; ./stop.sh >/dev/null
grep -aiE 'qml|error|warn|TypeError|ReferenceError' results/$L/run.out | grep -v perf | sort | uniq -c | sort -rn | head -25
