# Duplicate-property sweep: within each QML object (and grouped property block),
# the same property name may only be assigned/declared once.
import sys,re
OBJ=re.compile(r'^\s*([A-Za-z_][\w.]*)\s*\{\s*(//.*)?$')
KEY=re.compile(r'^\s*([A-Za-z_][\w.]*)\s*:(?!:)')
DECL=re.compile(r'^\s*(?:readonly\s+|default\s+|required\s+)*property\s+[\w<>.]+\s+(\w+)')
def strip(line):
    out=[];q=None;i=0
    while i<len(line):
        ch=line[i]
        if q:
            if ch=='\\': i+=2; continue
            if ch==q: q=None
            i+=1; continue
        if ch in '"\'`': q=ch; i+=1; continue
        if line.startswith('//',i): break
        out.append(ch); i+=1
    return ''.join(out)
def sweep(path):
    stack=[('root',{},True)]; probs=[]; incomment=False
    for ln,raw in enumerate(open(path,encoding='utf-8'),1):
        line=raw
        if incomment:
            if '*/' in line: line=line.split('*/',1)[1]; incomment=False
            else: continue
        if '/*' in line and '*/' not in line.split('/*',1)[1]:
            line=line.split('/*',1)[0]; incomment=True
        line=strip(line)
        top=stack[-1]
        if top[2]:   # inside a QML object scope: record keys
            m=DECL.match(line) or KEY.match(line)
            if m and not OBJ.match(line):
                k=m.group(1)
                if k in top[1]: probs.append('%s:%d duplicate `%s` (first at line %d)'%(path,ln,k,top[1][k]))
                else: top[1][k]=ln
        for ch in line:
            pass
        opens=line.count('{'); closes=line.count('}')
        is_obj = top[2] and OBJ.match(line) is not None
        # push scopes: first '{' on an object line is a QML scope, others are JS
        for i in range(opens):
            stack.append(('obj' if (is_obj and i==0) else 'js',{}, is_obj and i==0))
        for i in range(closes):
            if len(stack)>1: stack.pop()
    return probs
allp=[]
for p in sys.argv[1:]:
    pr=sweep(p); allp+=pr
    print(('OK   ' if not pr else 'FAIL ')+p+'  (%d duplicate%s)'%(len(pr),'' if len(pr)==1 else 's'))
for x in allp: print('  '+x)
sys.exit(1 if allp else 0)
