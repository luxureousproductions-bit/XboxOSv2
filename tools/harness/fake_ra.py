#!/usr/bin/env python3
"""Fake retroachievements.org web API for the harness (cloud sessions can't
reach the real one). Serves the endpoints the theme calls with made-up but
well-formed data: 620 played games (two pages of GetUserCompletionProgress),
awards with every kind (mastered, completed, beaten hardcore/softcore), each
game's achievements, and made-up badges/screenshots under /media/ (sync.sh
points media.retroachievements.org there).

    python3 tools/harness/fake_ra.py [port]      # default 8765

sync.sh points the theme's apiBase at http://127.0.0.1:8765/API/API_.
Sign in with any username and key (drawerrun.sh json:
{"RA Username":"Tester","RA API Key":"x"}).
"""
import json, random, sys, urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
R = random.Random(7)
CONSOLES = [(3, "SNES"), (1, "Genesis/Mega Drive"), (12, "PlayStation"), (5, "Game Boy Advance"),
            (7, "NES/Famicom"), (2, "Nintendo 64"), (25, "Atari 2600"), (4, "Game Boy")]
WORDS = ["Super", "Mega", "Castle", "Star", "Dragon", "Metal", "Turbo", "Crystal", "Shadow", "Neon",
         "Quest", "Racer", "Fighter", "Kingdom", "Legend", "Blade", "Galaxy", "Island", "Hunter", "Storm"]

GAMES = []
for i in range(620):
    cid, cname = CONSOLES[i % len(CONSOLES)]
    mx = R.choice([12, 24, 30, 45, 48, 64, 72, 88])
    roll = R.random()
    if roll < 0.06:   kind, n, hc = "mastered", mx, mx
    elif roll < 0.09: kind, n, hc = "completed", mx, 0
    elif roll < 0.17: kind, n = "beaten-hardcore", R.randint(mx // 2, mx - 1); hc = n
    elif roll < 0.21: kind, n = "beaten-softcore", R.randint(mx // 2, mx - 1); hc = 0
    else:             kind, n = None, R.randint(1, mx - 1); hc = R.choice([0, n])
    day = 28 - (i % 28)
    GAMES.append({
        "GameID": 1000 + i, "Title": f"{R.choice(WORDS)} {R.choice(WORDS)} {i}",
        "ImageIcon": f"/Images/{100000 + i:06d}.png", "ConsoleID": cid, "ConsoleName": cname,
        "MaxPossible": mx, "NumAwarded": n, "NumAwardedHardcore": hc,
        "MostRecentAwardedDate": f"2026-10-{day:02d}T12:00:00+00:00",
        "HighestAwardKind": kind, "HighestAwardDate": (f"2026-09-{day:02d}T12:00:00+00:00" if kind else None)})

def awards():
    vis = []
    for g in GAMES:
        k = g["HighestAwardKind"]
        if not k: continue
        typ = "Mastery/Completion" if k in ("mastered", "completed") else "Game Beaten"
        vis.append({"AwardedAt": g["HighestAwardDate"], "AwardType": typ, "AwardData": g["GameID"],
                    "AwardDataExtra": 1 if k in ("mastered", "beaten-hardcore") else 0, "DisplayOrder": 0,
                    "Title": g["Title"], "ConsoleID": g["ConsoleID"], "ConsoleName": g["ConsoleName"],
                    "Flags": None, "ImageIcon": g["ImageIcon"]})
    c = lambda k: sum(1 for g in GAMES if g["HighestAwardKind"] == k)
    return {"TotalAwardsCount": len(vis) + 3, "HiddenAwardsCount": 0, "MasteryAwardsCount": c("mastered"),
            "CompletionAwardsCount": c("completed"), "BeatenHardcoreAwardsCount": c("beaten-hardcore"),
            "BeatenSoftcoreAwardsCount": c("beaten-softcore"), "EventAwardsCount": 2, "SiteAwardsCount": 1,
            "VisibleUserAwards": vis}

def media_png(path):
    # Stand-in for media.retroachievements.org: a made-up picture per path.
    # /Badge/*  64x64 badge (grey when it ends in _lock); anything else a
    # 320x240 "screenshot".
    import io, zlib
    from PIL import Image, ImageDraw
    r = random.Random(zlib.crc32(path.replace("_lock", "").encode()))
    badge = "/Badge/" in path
    w, h = (64, 64) if badge else (320, 240)
    a = (r.randint(40, 230), r.randint(40, 230), r.randint(40, 230))
    im = Image.new("RGB", (w, h), tuple(v // 3 for v in a)); d = ImageDraw.Draw(im)
    for _ in range(4 if badge else 9):
        cx, cy, rr = r.randint(0, w), r.randint(0, h), r.randint(w // 6, w // 2)
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=tuple(min(255, v + r.randint(0, 60)) for v in a))
    if badge: d.rectangle([0, 0, w - 1, h - 1], outline=(255, 255, 255), width=2)
    if "_lock" in path: im = im.convert("L").convert("RGB")
    b = io.BytesIO(); im.save(b, "PNG"); return b.getvalue()

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        u = urllib.parse.urlparse(self.path); q = dict(urllib.parse.parse_qsl(u.query))
        if u.path.startswith("/media/"):
            data = media_png(u.path)
            self.send_response(200); self.send_header("Content-Type", "image/png")
            self.send_header("Content-Length", str(len(data))); self.end_headers(); self.wfile.write(data); return
        name = u.path.rsplit("/API_", 1)[-1].replace(".php", "")
        user = q.get("u") or q.get("z") or "Tester"
        if name == "GetUserProfile":
            body = {"User": user, "UserPic": "/UserPic/Tester.png", "TotalPoints": 24615}
        elif name == "GetUserSummary":
            body = {"User": user, "TotalPoints": 24615, "TotalSoftcorePoints": 1320, "TotalTruePoints": 61203,
                    "Rank": 4812, "MemberSince": "2019-03-02 10:00:00", "UserPic": "/UserPic/Tester.png"}
        elif name == "GetUserRankAndScore":
            body = {"Score": 24615, "SoftcoreScore": 1320, "Rank": 4812, "TotalRanked": 90000}
        elif name == "GetUserRecentlyPlayedGames":
            body = [{"GameID": g["GameID"], "ConsoleName": g["ConsoleName"], "Title": g["Title"],
                     "ImageIcon": g["ImageIcon"], "LastPlayed": "2026-10-28 18:00:00",
                     "NumPossibleAchievements": g["MaxPossible"], "PossibleScore": g["MaxPossible"] * 10,
                     "NumAchieved": g["NumAwarded"], "ScoreAchieved": g["NumAwarded"] * 10} for g in GAMES[:20]]
        elif name == "GetUserCompletionProgress":
            c = min(int(q.get("c", 100)), 500); o = int(q.get("o", 0))
            body = {"Count": len(GAMES[o:o + c]), "Total": len(GAMES), "Results": GAMES[o:o + c]}
        elif name == "GetUserAwards":
            body = awards()
        elif name == "GetUserGameRankAndScore":
            body = [{"User": user, "TotalScore": 315, "LastAward": "2026-10-22 12:00:00", "UserRank": 412}]
        elif name == "GetGameInfoAndUserProgress":
            g = next((x for x in GAMES if str(x["GameID"]) == q.get("g")), GAMES[0])
            rr = random.Random(g["GameID"]); ach = {}
            for i in range(g["MaxPossible"]):
                aid = g["GameID"] * 100 + i; earned = i < g["NumAwarded"]
                hc = earned and i < g["NumAwardedHardcore"]
                when = f"2026-{rr.randint(7,10):02d}-{rr.randint(1,28):02d} 12:00:00"
                ach[str(aid)] = {"ID": aid, "Title": f"{rr.choice(WORDS)} {rr.choice(WORDS)}", "Description": "Do the thing in the level without getting hit.",
                                 "Points": rr.choice([1, 2, 3, 5, 10, 25, 50]), "TrueRatio": rr.randint(2, 200), "BadgeName": str(100000 + aid % 900000),
                                 "DisplayOrder": i, "NumAwarded": rr.randint(20, 5000), "NumAwardedHardcore": rr.randint(5, 2000),
                                 "Type": rr.choice(["", "", "progression", "win_condition", "missable"]),
                                 **({"DateEarned": when} if earned else {}), **({"DateEarnedHardcore": when} if hc else {})}
            body = {"Title": g["Title"], "ImageIcon": g["ImageIcon"], "ImageIngame": "/Images/000002.png", "ConsoleName": g["ConsoleName"],
                    "NumAchievements": g["MaxPossible"], "NumAwardedToUser": g["NumAwarded"],
                    "NumAwardedToUserHardcore": g["NumAwardedHardcore"], "NumDistinctPlayersCasual": 5000, "NumDistinctPlayersHardcore": 1800,
                    "HighestAwardKind": g["HighestAwardKind"], "HighestAwardDate": g["HighestAwardDate"], "Achievements": ach}
        else:
            body = {}
        data = json.dumps(body).encode()
        self.send_response(200); self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data))); self.end_headers(); self.wfile.write(data)

ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
