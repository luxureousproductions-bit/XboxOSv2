#!/usr/bin/env python3
"""Asset check: every assets/ path written literally in the theme's QML/JS must
exist, and lists asset files nothing references (information only).
Usage: python3 tools/assetcheck.py [theme dir]    exit 1 on a missing asset."""
import os, re, subprocess, sys
root = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def ls(*pats):
    out = subprocess.check_output(['git', '-C', root, 'ls-files', '-z', *pats]).decode().split('\0')
    return [f for f in out if f]
code = ""
for f in ls('*.qml', '*.js', 'theme.cfg'):
    code += open(os.path.join(root, f), errors='ignore').read() + "\n"
# Comments don't load files
code = re.sub(r'^\s*//.*$', '', code, flags=re.M)
# Optional: the startup intro video is the user's own, never shipped
OPTIONAL = {'assets/video/intro.mp4'}
missing = []
for ref in sorted(set(re.findall(r'["\'](?:\.\./)*(assets/[A-Za-z0-9_\-./ ]+\.[a-z0-9]{2,4})["\']', code))):
    if ref not in OPTIONAL and not os.path.exists(os.path.join(root, ref)):
        missing.append(ref)
dyn = set(re.findall(r'assets/images/([A-Za-z0-9_\-]+)/["\']\s*\+', code))
unused = []
for f in ls('assets'):
    parts = f.split('/')
    if len(parts) > 3 and parts[2] in dyn: continue
    base = os.path.basename(f); stem = os.path.splitext(base)[0]
    if base in code or '"' + stem + '"' in code or "'" + stem + "'" in code or '/' + stem + '"' in code: continue
    unused.append(f)
for m in missing: print("MISSING", m)
for u in unused: print("unused ", u)
print(f"{len(missing)} missing, {len(unused)} unreferenced")
sys.exit(1 if missing else 0)
