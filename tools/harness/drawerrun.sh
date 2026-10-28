#!/bin/bash
# usage: drawerrun.sh <label> '<settings json>' <xkeys tokens...> — adds the PC starter + fake Steam collection
. "$(dirname "$0")/env.sh"
L=$1; J=$2; shift 2
mkdir -p $P/results/$L; cd $P; ./stop.sh >/dev/null 2>&1
sed -i "s#general.theme: .*#general.theme: themes/$THEME/#" config/settings.txt
cp config/game_dirs.txt $HARNESS/game_dirs.keep; printf "%s\n%s\n" $HARNESS/testenv/pcstarter $HARNESS/testenv/steamfake >> config/game_dirs.txt
rm -f config/theme_settings/*.json; echo "$J" > config/theme_settings/$THEME.json
RES=${RES:-1280x720} ./start.sh >/dev/null
for i in $(seq 1 120); do grep -aq "\[perf\]" run.out 2>/dev/null && break; sleep 0.25; done
DISPLAY=:99 SHOTS=$P/results/$L python3 -I $T/xkeys.py wait:3500 "$@" > results/$L/actions.log
cp run.out results/$L/run.out; ./stop.sh >/dev/null; cp $HARNESS/game_dirs.keep config/game_dirs.txt
grep -aiE 'qml|error|warn|TypeError|ReferenceError' results/$L/run.out | grep -v perf | sort | uniq -c | sort -rn | head -15
