#!/usr/bin/env python3
"""Bump the theme build number in buildinfo.js: build + 1, today's date.
Usage: python3 tools/bump_build.py [branch]"""
import datetime, pathlib, re, sys
p = pathlib.Path(__file__).resolve().parent.parent / "buildinfo.js"
s = p.read_text()
n = int(re.search(r"var build\s*=\s*(\d+);", s).group(1)) + 1
s = re.sub(r"var build\s*=\s*\d+;", f"var build  = {n};", s)
s = re.sub(r'var date\s*=\s*"[^"]*";', f'var date   = "{datetime.date.today().isoformat()}";', s)
if len(sys.argv) > 1:
    s = re.sub(r'var branch\s*=\s*"[^"]*";', f'var branch = "{sys.argv[1]}";', s)
p.write_text(s)
print(f"build {n}")
