# String- and comment-aware brace/paren/bracket balance check for QML/JS.
import sys
def check(path):
    s=open(path,encoding='utf-8').read(); i=0; n=len(s)
    c={'{':0,'(':0,'[':0}; pair={'}':'{',')':'(',']':'['}
    while i<n:
        ch=s[i]
        if s.startswith('//',i): i=s.find('\n',i); i=n if i<0 else i; continue
        if s.startswith('/*',i): j=s.find('*/',i+2); i=n if j<0 else j+2; continue
        # Regex literal (/.../flags): follows an operator or an opening
        # bracket. Its parens/brackets are not code (e.g. /\s*\([^)]*\)/).
        if ch=='/' and not s.startswith('//',i) and not s.startswith('/*',i):
            k=i-1
            while k>=0 and s[k] in ' \t\n': k-=1     # previous real character, across lines
            if k<0 or s[k] in '(,=:[!&|?{};':
                j=i+1; incls=False
                while j<n and (s[j]!='/' or incls) and s[j]!='\n':
                    if s[j]=='\\': j+=2; continue
                    if s[j]=='[': incls=True
                    elif s[j]==']': incls=False
                    j+=1
                i=j+1; continue
        if ch in '"\'`':
            q=ch; i+=1
            while i<n and s[i]!=q:
                i+=2 if s[i]=='\\' else 1
            i+=1; continue
        if ch in c: c[ch]+=1
        elif ch in pair: c[pair[ch]]-=1
        i+=1
    return c
ok=True
for p in sys.argv[1:]:
    r=check(p); bad=any(r.values()); ok&=not bad
    print(('FAIL ' if bad else 'OK   ')+p+'  {}=%d ()=%d []=%d'%(r['{'],r['('],r['[']))
sys.exit(0 if ok else 1)
