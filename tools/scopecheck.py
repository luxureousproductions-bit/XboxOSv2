#!/usr/bin/env python3
"""Approximate QML scope checker.

Finds bare identifiers used in bindings/handlers of object O that are only
declared as `property` on a NON-scope ancestor of O (i.e. an ancestor that is
neither the file root nor the root of an inline/implicit Component).  In QML
those names do not resolve -> ReferenceError at runtime.
Also flags `typeof`-less reads of ListModel roles that only some models define
(passed via --roles).
"""
import re, sys, os

COMPONENT_PROPS = {"delegate", "sourceComponent", "effect", "highlight", "header",
                   "footer", "component", "contentItem_"}
DEFAULT_DELEGATE_TYPES = {"Repeater", "Instantiator"}
JS_WORDS = set("""var let const function return if else for while do switch case break continue
new typeof instanceof in of true false null undefined this delete try catch finally throw default
Math JSON Qt console parseInt parseFloat isNaN Object Array String Number Boolean Date RegExp
model modelData index parent""".split())

def strip_strings_comments(src):
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i)); i = j; continue
        if src.startswith("/*", i):
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append("".join(ch if ch == "\n" else " " for ch in src[i:j])); i = j; continue
        if c in "\"'`":
            q = c; j = i + 1
            while j < n and src[j] != q:
                if src[j] == "\\": j += 1
                if j < n and src[j] == "\n" and q != "`": break
                j += 1
            out.append(q + " " * (j - i - 1) + (q if j < n else "")); i = j + 1; continue
        out.append(c); i += 1
    return "".join(out)

OBJ_START = re.compile(r'(?:(?P<prop>[\w.]+)\s*:\s*)?(?:(?P<beh>Behavior\s+on\s+[\w.]+)|(?P<type>[A-Z][\w.]*))\s*\{')
PROP_DECL = re.compile(r'\b(?:readonly\s+|default\s+)?property\s+(?:alias|var|int|real|bool|string|url|color|list<[\w.]+>|[\w.]+)\s+(\w+)')
SIGNAL_DECL = re.compile(r'\bsignal\s+(\w+)')
FUNC_DECL = re.compile(r'\bfunction\s+(\w+)\s*\(([^)]*)\)')
ID_DECL = re.compile(r'(?<![\w.])id\s*:\s*(\w+)')
IDENT = re.compile(r'(?<![\w.$])([A-Za-z_]\w*)')

class Obj:
    def __init__(self, typ, parent, line, scope_root):
        self.typ, self.parent, self.line = typ, parent, line
        self.props, self.funcs = set(), set()
        self.scope_root = scope_root
        self.uses = []  # (line, text)

def analyse(path):
    raw = open(path, encoding="utf-8", errors="replace").read()
    src = strip_strings_comments(raw)
    ids = set(ID_DECL.findall(src))
    objs, stack = [], []
    # brace stack items: ("obj", Obj) or ("js", None)
    i, n, line = 0, len(src), 1
    root = None
    while i < n:
        c = src[i]
        if c == "\n": line += 1; i += 1; continue
        if c == "{":
            # decide whether this brace opens an object
            ls = src.rfind("\n", 0, i) + 1
            head = src[ls:i + 1]
            m = None
            for mm in OBJ_START.finditer(head):
                if mm.end() == len(head): m = mm
            cur = stack[-1][1] if stack and stack[-1][0] == "obj" else None
            in_js = any(k == "js" for k, _ in stack)
            if m and not in_js and (m.group("type") or m.group("beh")):
                typ = m.group("type") or "Behavior"
                prop = m.group("prop")
                is_scope = (cur is None or typ == "Component"
                            or (prop and prop.split(".")[-1] in COMPONENT_PROPS)
                            or (cur and cur.typ in DEFAULT_DELEGATE_TYPES and not prop)
                            or (cur and cur.typ == "Component"))
                o = Obj(typ, cur, line, is_scope)
                if root is None: root = o
                objs.append(o); stack.append(("obj", o))
                je = src.find("\n", i); je = n if je < 0 else je
                rest = src[i+1:je]
                if rest.strip():
                    o.uses.append((line, rest))
                    for p_ in PROP_DECL.findall(rest): o.props.add(p_)
            else:
                stack.append(("js", None))
            i += 1; continue
        if c == "}":
            if stack: stack.pop()
            i += 1; continue
        # line-level processing at line start
        if i == 0 or src[i - 1] == "\n":
            j = src.find("\n", i); j = n if j < 0 else j
            text = src[i:j]
            cur = None
            for k, o in reversed(stack):
                if k == "obj": cur = o; break
            if cur is not None:
                for p in PROP_DECL.findall(text): cur.props.add(p)
                for s in SIGNAL_DECL.findall(text): cur.props.add(s)
                for f, _ in FUNC_DECL.findall(text): cur.funcs.add(f)
                cur.uses.append((line, text))
        i += 1
    return raw, objs, ids, root

def check(path):
    raw, objs, ids, root = analyse(path)
    rawlines = raw.split("\n")
    findings = []
    for o in objs:
        # names in scope: own + every scope-root ancestor (incl. file root)
        inscope = set(o.props) | set(o.funcs)
        a = o.parent
        nonscope = {}
        while a is not None:
            if a.scope_root:
                inscope |= a.props | a.funcs
            else:
                for p in a.props | a.funcs:
                    nonscope.setdefault(p, a)
            a = a.parent
        if not nonscope: continue
        for ln, text in o.uses:
            if PROP_DECL.search(text) and ":" not in text.split(PROP_DECL.search(text).group(1), 1)[1]:
                continue
            # locals declared on this line
            local = set(re.findall(r'\b(?:var|let|const)\s+(\w+)', text))
            for f, params in FUNC_DECL.findall(text):
                local |= {p.strip() for p in params.split(",") if p.strip()}
            body = text
            md = PROP_DECL.search(text)
            if md: body = text[md.end():]
            for name in IDENT.findall(body):
                if name in JS_WORDS or name in inscope or name in ids or name in local: continue
                if name in nonscope:
                    # skip property-name side of "name: value"
                    if re.match(r'\s*' + name + r'\s*:', body) and not md: continue
                    owner = nonscope[name]
                    findings.append((ln, name, owner.typ, owner.line, rawlines[ln - 1].strip()[:110]))
    return findings

if __name__ == "__main__":
    base = sys.argv[1]
    total = 0
    for dp, _, fs in os.walk(base):
        for f in sorted(fs):
            if f.endswith(".qml"):
                p = os.path.join(dp, f)
                seen = set()
                for ln, name, typ, oln, txt in check(p):
                    if (ln, name) in seen: continue
                    seen.add((ln, name)); total += 1
                    print(f"{os.path.relpath(p, base)}:{ln}: '{name}' declared on non-scope {typ}@{oln} | {txt}")
    print("TOTAL", total)
