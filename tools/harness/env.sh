# Shared paths for the harness scripts. Source it; don't run it.
#   HARNESS  where the harness lives (Pegasus binary, config, fake library, results)
#   REPO     the theme checkout this harness tests
HARNESS=${HARNESS:-$HOME/xbx-harness}
REPO=${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
T=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)   # these scripts, even when REPO is another checkout
P=$HARNESS/pgrun
THEME=XboxOSv2-refresh
H=$P/config/themes/$THEME
