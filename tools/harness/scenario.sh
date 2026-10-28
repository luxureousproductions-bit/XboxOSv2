#!/bin/bash
# usage: scenario.sh <label> — the standard performance run; compare results/<label>/segments.txt with the baseline in README.md
. "$(dirname "$0")/env.sh"
L=$1
mkdir -p $P/results/$L; cd $P; ./stop.sh >/dev/null 2>&1
sed -i "s#general.theme: .*#general.theme: themes/$THEME/#" config/settings.txt
rm -f config/theme_settings/*.json; cp $T/clean_settings.json config/theme_settings/$THEME.json
T0=$(date +%s.%N); RES=${RES:-1280x720} ./start.sh >/dev/null
# wait for first perf line = theme up
for i in $(seq 1 120); do grep -aq "\[perf\]" run.out 2>/dev/null && break; sleep 0.25; done
T1=$(date +%s.%N); echo "startup_s $(echo "$T1 - $T0" | bc)" > results/$L/summary.txt
rss(){ ps -o rss= -C pegasus-fe | head -1; }
echo "rss_after_start_kb $(rss)" >> results/$L/summary.txt
DISPLAY=:99 SHOTS=$P/results/$L python3 -I $T/xkeys.py \
  wait:4000 mark:home_idle wait:4000 shot:01_home down wait:1500 right wait:1500 shot:02_home_sel \
  mark:open_platform enter wait:4000 shot:03_platform \
  mark:platform_idle wait:3000 mark:platform_race hold:down:5000 wait:1500 shot:04_platform_raced \
  wait:2500 down wait:1200 mark:open_details enter wait:4000 shot:05_details mark:details_idle wait:3000 \
  mark:details_back esc wait:3000 esc wait:3000 shot:05b_home_again \
  mark:open_allgames up left left left left left wait:500 enter wait:4000 shot:06_allgames \
  mark:allgames_idle wait:3000 mark:allgames_race hold:down:5000 wait:1500 shot:07_allgames_raced \
  mark:allgames_back esc wait:3000 down wait:1000 \
  mark:home_race hold:right:4000 wait:1500 shot:08_home_raced mark:home_drain wait:4000 mark:end > results/$L/actions.log
echo "rss_end_kb $(rss)" >> results/$L/summary.txt
cp run.out results/$L/run.out; ./stop.sh >/dev/null
# per-second perf with timestamps (from the theme's own log lines in run.out)
python3 - $P/results/$L <<'PY'
import sys,re,os
d=sys.argv[1]
txt=open(os.path.join(d,'run.out'),errors='ignore').read()
perf=[(m.group(1),int(m.group(2)),int(m.group(3))) for m in re.finditer(r'\[perf\] (\d\d:\d\d:\d\d) fps (\d+) worst (\d+)',txt)]
marks=[(a.split()[0],a.split()[3]) for a in open(os.path.join(d,'actions.log')) if ' mark ' in a]
out=[]
for i,(t,lab) in enumerate(marks):
    t_end=marks[i+1][0] if i+1<len(marks) else '99:99:99'
    seg=[p for p in perf if t<=p[0]<t_end]
    if seg: out.append(f"{lab:16s} secs={len(seg):2d} min_fps={min(s[1] for s in seg):3d} avg_fps={sum(s[1] for s in seg)/len(seg):5.1f} worst_ms={max(s[2] for s in seg):4d}")
open(os.path.join(d,'segments.txt'),'w').write("\n".join(out)+"\n")
print("\n".join(out))
PY
cat results/$L/summary.txt
cd $P/results/$L && python3 -c "
from PIL import Image
ns=['01_home','02_home_sel','03_platform','04_platform_raced','05_details','05b_home_again','06_allgames','07_allgames_raced']
ims=[Image.open(n+'.png').resize((640,360)) for n in ns]
s=Image.new('RGB',(1280,1440))
for i,im in enumerate(ims): s.paste(im,((i%2)*640,(i//2)*360))
s.save('sheet.png')"
