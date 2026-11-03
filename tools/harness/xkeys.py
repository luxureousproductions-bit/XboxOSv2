"""Drive the X server like a controller: python3 -I xkeys.py <seq>
seq tokens (space separated):
  right/left/up/down/enter/esc/i/f/q/e/pgup/pgdn/f1/tab  -> tap
  hold:<key>:<ms>   -> hold (server autorepeat produces repeats)
  wait:<ms>  shot:<name>  mark:<label>
Each action is logged with a wall-clock timestamp to stdout."""
import ctypes, sys, time, subprocess, os
X=ctypes.CDLL("libX11.so.6"); XT=ctypes.CDLL("libXtst.so.6")
X.XOpenDisplay.restype=ctypes.c_void_p; X.XOpenDisplay.argtypes=[ctypes.c_char_p]
X.XKeysymToKeycode.argtypes=[ctypes.c_void_p, ctypes.c_ulong]; X.XKeysymToKeycode.restype=ctypes.c_ubyte
X.XStringToKeysym.argtypes=[ctypes.c_char_p]; X.XStringToKeysym.restype=ctypes.c_ulong
XT.XTestFakeKeyEvent.argtypes=[ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
X.XFlush.argtypes=[ctypes.c_void_p]
d=X.XOpenDisplay(os.environ.get("DISPLAY",":99").encode())
assert d, "no display"
XT.XTestFakeButtonEvent.argtypes=[ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
XT.XTestFakeMotionEvent.argtypes=[ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ulong]
X.XSetInputFocus.argtypes=[ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int, ctypes.c_ulong]
# No window manager: park the pointer on the window and let focus follow it.
XT.XTestFakeMotionEvent(d, -1, 300, 300, 0)
# Qt ignores pointer-root focus, so focus the biggest top-level window directly.
W=ctypes.c_ulong
X.XDefaultRootWindow.argtypes=[ctypes.c_void_p]; X.XDefaultRootWindow.restype=W
X.XQueryTree.argtypes=[ctypes.c_void_p, W, ctypes.POINTER(W), ctypes.POINTER(W), ctypes.POINTER(ctypes.POINTER(W)), ctypes.POINTER(ctypes.c_uint)]
X.XGetGeometry.argtypes=[ctypes.c_void_p, W, ctypes.POINTER(W)]+[ctypes.POINTER(ctypes.c_int)]*2+[ctypes.POINTER(ctypes.c_uint)]*4
root=X.XDefaultRootWindow(d); r=W(); par=W(); ch=ctypes.POINTER(W)(); n=ctypes.c_uint()
X.XQueryTree(d, root, ctypes.byref(r), ctypes.byref(par), ctypes.byref(ch), ctypes.byref(n))
best=(0,None)
for i in range(n.value):
    w=ch[i]; rr=W(); x=ctypes.c_int(); y=ctypes.c_int(); ww=ctypes.c_uint(); hh=ctypes.c_uint(); bw=ctypes.c_uint(); dep=ctypes.c_uint()
    if X.XGetGeometry(d, w, ctypes.byref(rr), ctypes.byref(x), ctypes.byref(y), ctypes.byref(ww), ctypes.byref(hh), ctypes.byref(bw), ctypes.byref(dep)):
        if ww.value*hh.value > best[0]: best=(ww.value*hh.value, w)
if best[1]: X.XSetInputFocus(d, best[1], 2, 0)
X.XFlush(d)
NAMES={"right":"Right","left":"Left","up":"Up","down":"Down","enter":"Return","esc":"Escape","i":"i","f":"f","q":"q","e":"e","pgup":"Prior","pgdn":"Next","f1":"F1","tab":"Tab","bksp":"BackSpace"}
def kc(name): return X.XKeysymToKeycode(d, X.XStringToKeysym(NAMES.get(name,name).encode()))
def ev(code,down): XT.XTestFakeKeyEvent(d, code, 1 if down else 0, 0); X.XFlush(d)
def log(*a): print(time.strftime("%H:%M:%S"), f"{time.time():.3f}", *a, flush=True)
outdir=os.environ.get("SHOTS",".")
for tok in " ".join(sys.argv[1:]).split():
    if tok.startswith("wait:"): time.sleep(int(tok[5:])/1000); continue
    if tok.startswith("shot:"):
        p=os.path.join(outdir,tok[5:]+".png"); subprocess.run(["import","-window","root",p]); log("shot",p); continue
    if tok.startswith("mark:"): log("mark",tok[5:]); continue
    if tok.startswith("move:"):
        x,y=map(int,tok[5:].split(",")); XT.XTestFakeMotionEvent(d,-1,x,y,0); X.XFlush(d); log("move",x,y); time.sleep(0.15); continue
    if tok.startswith("wheel:"):
        _,dirn,cnt=tok.split(":"); b=5 if dirn=="down" else 4
        for _i in range(int(cnt)):
            XT.XTestFakeButtonEvent(d,b,1,0); XT.XTestFakeButtonEvent(d,b,0,0); X.XFlush(d); time.sleep(0.12)
        log("wheel",dirn,cnt); continue
    if tok.startswith("click"):
        b=3 if tok=="click:right" else 1
        XT.XTestFakeButtonEvent(d,b,1,0); X.XFlush(d); time.sleep(0.05); XT.XTestFakeButtonEvent(d,b,0,0); X.XFlush(d); log("click",b); time.sleep(0.3); continue
    if tok.startswith("hold:"):
        # hold:<key>:<ms>[:<shotname>@<ms>]  — optional screenshot during the hold
        parts=tok.split(":"); k=parts[1]; ms=int(parts[2]); c=kc(k); log("hold",k,ms); ev(c,True)
        if len(parts)>3 and "@" in parts[3]:
            nm,at=parts[3].split("@"); at=int(at); time.sleep(at/1000)
            p=os.path.join(outdir,nm+".png"); subprocess.run(["import","-window","root",p]); log("shot",p)
            time.sleep(max(0,(ms-at)/1000))
        else: time.sleep(ms/1000)
        ev(c,False); log("release",k); time.sleep(0.05); continue
    c=kc(tok); ev(c,True); time.sleep(0.04); ev(c,False); log("tap",tok); time.sleep(0.25)
