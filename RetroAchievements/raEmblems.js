// XboxOSv2 – raEmblems.js
// The three RetroAchievements header emblems (points medallion, achievements
// hexagon, Mythic star), drawn as SVG text from your accent colour, so any
// preset or custom accent gets matching metal and gem shades. RAHeader.qml
// shows them through a data: URL; Qt renders each once at its size.
//
// Only what Qt's SVG renderer (SVG Tiny 1.2) draws: paths, polygons, linear
// and radial gradients, opacity. No filters or clipping, so glows and bevels
// are gradients and layered shapes. Original designs, not Xbox artwork.
// Gradient ids carry a prefix so two emblems never share one.
.pragma library

function rgb(h) { h = String(h).replace("#", ""); return [0, 2, 4].map(function(i) { return parseInt(h.substr(i, 2), 16); }); }
function hex(c) { return "#" + c.map(function(v) { v = Math.max(0, Math.min(255, Math.round(v))); return (v < 16 ? "0" : "") + v.toString(16); }).join(""); }
function mix(a, b, t) { a = rgb(a); b = rgb(b); return hex([0, 1, 2].map(function(i) { return a[i] + (b[i] - a[i]) * t; })); }
function L(a, t) { return mix(a, "#ffffff", t); }
function D(a, t) { return mix(a, "#000000", t); }
function n(v) { return (Math.round(v * 100) / 100).toString(); }
function pol(r, deg) { var a = deg * Math.PI / 180; return [r * Math.cos(a), r * Math.sin(a)]; }
function pt(p) { return n(p[0]) + "," + n(p[1]); }

function stops(list) {
    return list.map(function(s) { return '<stop offset="' + s[0] + '" stop-color="' + s[1] + '" stop-opacity="' + (s.length > 2 ? s[2] : 1) + '"/>'; }).join("");
}
function lin(id, list, x1, y1, x2, y2) {
    return '<linearGradient id="' + id + '" x1="' + x1 + '" y1="' + y1 + '" x2="' + x2 + '" y2="' + y2 + '">' + stops(list) + '</linearGradient>';
}
function rad(id, list, cx, cy, r) {
    return '<radialGradient id="' + id + '" cx="' + cx + '" cy="' + cy + '" r="' + r + '" gradientUnits="userSpaceOnUse">' + stops(list) + '</radialGradient>';
}
// Brushed metal in the accent: bright, dark, bright band, dark, bright edge.
function metal(id, a, x2, y2) {
    return lin(id, [[0, L(a, .85)], [.18, L(a, .45)], [.42, D(a, .1)], [.58, L(a, .3)], [.8, D(a, .35)], [1, L(a, .2)]], 0, 0, x2, y2);
}
function glow(id, a, r) { return rad(id, [[0, L(a, .5), .55], [.55, L(a, .35), .18], [1, L(a, .3), 0]], 0, 0, r); }
function svg(view, defs, body) {
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="' + view + '"><defs>' + defs + '</defs>' + body + '</svg>';
}

// ── Points medallion ─────────────────────────────────────────────────────
var P_PATH = "M-9,-15 h11 a8.5,8.5 0 0 1 0,17 h-5.2 v13 h-5.8 Z M-3.2,-10 v7.2 h4.6 a3.6,3.6 0 0 0 0,-7.2 Z";
function medallion(a, k) {
    k = k || "m";
    var defs = glow(k + "g", a, 64) + metal(k + "rim", a, .35, 1) + metal(k + "band", a, 1, 1)
        + rad(k + "well", [[0, D(a, .35)], [.7, D(a, .7)], [1, D(a, .85)]], 0, -6, 40)
        + rad(k + "gem", [[0, L(a, .75)], [.35, L(a, .15)], [.8, D(a, .25)], [1, D(a, .5)]], -8, -10, 34)
        + lin(k + "pip", [[0, "#ffffff"], [.5, L(a, .6)], [1, D(a, .2)]], 0, 0, 1, 1)
        + lin(k + "P", [[0, "#ffffff"], [1, L(a, .55)]], 0, 0, 0, 1);
    var i, b = '<circle r="68" fill="url(#' + k + 'g)"/>';
    var lobes = [];
    for (i = 0; i < 48; i++) lobes.push(pt(pol(i % 2 === 0 ? 56 : 52.5, i * 7.5 - 90)));
    b += '<polygon points="' + lobes.join(" ") + '" fill="url(#' + k + 'rim)"/>';
    b += '<polygon points="' + lobes.join(" ") + '" fill="none" stroke="' + D(a, .55) + '" stroke-width=".8" stroke-opacity=".7"/>';
    b += '<circle r="48.5" fill="url(#' + k + 'band)" stroke="' + L(a, .85) + '" stroke-width=".8"/>';
    b += '<circle r="46.5" fill="none" stroke="' + D(a, .6) + '" stroke-width="1"/>';
    b += '<circle r="40.5" fill="url(#' + k + 'well)"/>';
    for (i = 0; i < 48; i++) {
        var p1 = pol(41, i * 7.5), p2 = pol(i % 4 ? 44.5 : 46, i * 7.5);
        b += '<line x1="' + n(p1[0]) + '" y1="' + n(p1[1]) + '" x2="' + n(p2[0]) + '" y2="' + n(p2[1]) + '" stroke="' + D(a, .6) + '" stroke-width="' + (i % 4 ? .8 : 1.4) + '"/>';
    }
    b += '<circle r="38.5" fill="none" stroke="' + L(a, .5) + '" stroke-width=".7" stroke-opacity=".6"/>';
    for (i = 0; i < 12; i++) { var d = pol(35, i * 30 + 15); b += '<circle cx="' + n(d[0]) + '" cy="' + n(d[1]) + '" r="1.3" fill="' + L(a, .6) + '" fill-opacity=".85"/>'; }
    b += '<circle r="29.5" fill="' + D(a, .75) + '"/><circle r="28" fill="url(#' + k + 'band)"/><circle r="25.5" fill="url(#' + k + 'gem)"/>';
    for (i = 0; i < 8; i++)
        b += '<polygon points="0,0 ' + pt(pol(26, i * 45 - 90)) + ' ' + pt(pol(26, i * 45 - 45)) + '" fill="' + (i % 2 ? "#ffffff" : "#000000") + '" fill-opacity=".1"/>';
    b += '<path d="M-17,-12 A21,21 0 0 1 9,-21" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round" stroke-opacity=".55"/>';
    b += '<ellipse cx="-9" cy="-13" rx="5" ry="2.6" fill="#ffffff" fill-opacity=".45" transform="rotate(-35 -9 -13)"/>';
    b += '<path d="' + P_PATH + '" transform="translate(1.6,2)" fill="' + D(a, .8) + '" fill-opacity=".85"/>';
    b += '<path d="' + P_PATH + '" fill="url(#' + k + 'P)" stroke="' + D(a, .3) + '" stroke-width=".6"/>';
    [-90, 0, 90, 180].forEach(function(g) {
        b += '<polygon points="' + pt(pol(64, g)) + ' ' + pt(pol(55, g - 6)) + ' ' + pt(pol(48, g)) + ' ' + pt(pol(55, g + 6)) + '" fill="url(#' + k + 'pip)" stroke="' + D(a, .45) + '" stroke-width=".7"/>';
    });
    return svg("-70 -70 140 140", defs, b);
}

// ── Achievements hexagon ─────────────────────────────────────────────────
function hexp(r) { var out = []; for (var i = 0; i < 6; i++) out.push(pol(r, -90 + 60 * i)); return out; }
function pts(list) { return list.map(pt).join(" "); }
function hexgem(a, k) {
    k = k || "h";
    var o2 = hexp(60), o = hexp(54), m = hexp(42), t = hexp(31), i;
    var tones = [[L(a, .8), L(a, .35)], [L(a, .45), D(a, .05)], [D(a, .05), D(a, .45)], [D(a, .3), D(a, .65)], [D(a, .1), D(a, .45)], [L(a, .55), L(a, .1)]];
    var defs = glow(k + "g", a, 66) + metal(k + "frame", a, .35, 1)
        + rad(k + "tbl", [[0, D(a, .25)], [.75, D(a, .65)], [1, D(a, .82)]], 0, -12, 36)
        + lin(k + "tro", [[0, "#ffffff"], [.45, L(a, .65)], [1, L(a, .25)]], 0, 0, .4, 1)
        + lin(k + "leaf", [[0, L(a, .7)], [1, L(a, .2)]], 0, 0, 0, 1);
    for (i = 0; i < 6; i++) defs += lin(k + "f" + i, [[0, tones[i][0]], [1, tones[i][1]]], 0, 0, 0, 1);
    var b = '<circle r="68" fill="url(#' + k + 'g)"/>';
    b += '<polygon points="' + pts(o2) + '" fill="url(#' + k + 'frame)" stroke="' + D(a, .6) + '" stroke-width="1"/>';
    b += '<polygon points="' + pts(hexp(57.5)) + '" fill="none" stroke="' + L(a, .9) + '" stroke-width=".8" stroke-opacity=".8"/>';
    for (i = 0; i < 6; i++)
        b += '<polygon points="' + pt(o[i]) + ' ' + pt(o[(i + 1) % 6]) + ' ' + pt(m[(i + 1) % 6]) + ' ' + pt(m[i]) + '" fill="url(#' + k + 'f' + i + ')" stroke="' + D(a, .6) + '" stroke-width=".6" stroke-opacity=".6"/>';
    b += '<polygon points="' + pts(o) + '" fill="none" stroke="' + L(a, .85) + '" stroke-width="1.1"/>';
    for (i = 0; i < 6; i++)
        b += '<polygon points="' + pt(m[i]) + ' ' + pt(m[(i + 1) % 6]) + ' ' + pt(t[(i + 1) % 6]) + ' ' + pt(t[i]) + '" fill="' + (i === 0 || i === 5 ? "#ffffff" : "#000000") + '" fill-opacity="' + (i === 0 || i === 5 ? .12 : .22) + '"/>';
    b += '<polygon points="' + pts(t) + '" fill="url(#' + k + 'tbl)" stroke="' + D(a, .8) + '" stroke-width="1.2"/>';
    b += '<polygon points="' + pts(hexp(28.5)) + '" fill="none" stroke="' + L(a, .45) + '" stroke-width=".6" stroke-opacity=".6"/>';
    b += '<polyline points="' + pt(t[5]) + ' ' + pt(t[0]) + ' ' + pt(t[1]) + '" fill="none" stroke="#ffffff" stroke-width="1.3" stroke-opacity=".35"/>';
    [-1, 1].forEach(function(side) {
        for (var j = 0; j < 5; j++) {
            var ang = 110 + j * 22, c = pol(22, side < 0 ? ang : 180 - ang), rot = side < 0 ? ang + 90 : 90 - ang;
            b += '<ellipse cx="' + n(c[0]) + '" cy="' + n(c[1]) + '" rx="3.6" ry="1.6" fill="url(#' + k + 'leaf)" transform="rotate(' + n(rot) + ' ' + n(c[0]) + ' ' + n(c[1]) + ')"/>';
        }
    });
    b += '<g transform="translate(0,-1) scale(1.35)">'
       + '<path d="M-8.5,-12 H8.5 V-4 A8.5,8.5 0 0 1 -8.5,-4 Z" fill="url(#' + k + 'tro)" stroke="' + D(a, .4) + '" stroke-width=".5"/>'
       + '<path d="M-8.5,-10 H-12.5 V-7.5 A5.2,5.2 0 0 0 -7.4,-2.6" fill="none" stroke="' + L(a, .7) + '" stroke-width="1.9"/>'
       + '<path d="M8.5,-10 H12.5 V-7.5 A5.2,5.2 0 0 1 7.4,-2.6" fill="none" stroke="' + L(a, .7) + '" stroke-width="1.9"/>'
       + '<path d="M-5,-10.5 V-5 A4.5,4.5 0 0 0 -1,-0.8" fill="none" stroke="#ffffff" stroke-width="1.2" stroke-opacity=".8"/>'
       + '<rect x="-1.5" y="4.2" width="3" height="4.6" fill="' + L(a, .5) + '"/>'
       + '<path d="M-6.5,13.5 H6.5 V11 A2.2,2.2 0 0 0 4.3,8.8 H-4.3 A2.2,2.2 0 0 0 -6.5,11 Z" fill="url(#' + k + 'tro)" stroke="' + D(a, .4) + '" stroke-width=".5"/></g>';
    hexp(57).forEach(function(p) { b += '<circle cx="' + n(p[0]) + '" cy="' + n(p[1]) + '" r="2.2" fill="' + L(a, .85) + '" stroke="' + D(a, .5) + '" stroke-width=".6"/>'; });
    b += '<polyline points="' + pt(o2[5]) + ' ' + pt(o2[0]) + ' ' + pt(o2[1]) + '" fill="none" stroke="#ffffff" stroke-width="1.6" stroke-opacity=".55"/>';
    return svg("-70 -70 140 140", defs, b);
}

// ── Mythic star ──────────────────────────────────────────────────────────
// A thick four-point star (concave sides), each arm cut into a lit and a
// shaded half; an inset star gives the bevelled rim; a cut diamond in the
// middle; a slimmer star behind at 45°, soft rays, sparkles and a glow.
function star(R, w, rot) {   // 8 points: tips at R, waists at w
    var out = [];
    for (var i = 0; i < 8; i++) out.push(pol(i % 2 === 0 ? R : w, rot + i * 45));
    return out;
}
function armHalves(k, tag, R, w, rot, lit, shade, defsOut) {
    var b = "";
    for (var i = 0; i < 4; i++) {
        var ang = rot + i * 90, tip = pol(R, ang), l = pol(w, ang - 45), r = pol(w, ang + 45);
        var g1 = k + tag + i + "l", g2 = k + tag + i + "r";
        defsOut.push(lin(g1, [[0, lit[0]], [1, lit[1]]], 0, 0, 1, 1) + lin(g2, [[0, shade[0]], [1, shade[1]]], 1, 0, 0, 1));
        b += '<polygon points="0,0 ' + pt(l) + ' ' + pt(tip) + '" fill="url(#' + g1 + ')"/>';
        b += '<polygon points="0,0 ' + pt(tip) + ' ' + pt(r) + '" fill="url(#' + g2 + ')"/>';
    }
    return b;
}
function mythic(a, k) {
    k = k || "y";
    var d = [];
    d.push(rad(k + "aura", [[0, L(a, .6), .6], [.4, L(a, .45), .22], [1, L(a, .3), 0]], 0, 0, 70));
    d.push(lin(k + "ray", [[0, L(a, .8), 0], [.5, L(a, .85), .45], [1, L(a, .8), 0]], 0, 0, 0, 1));
    d.push(rad(k + "gem", [[0, "#ffffff"], [.45, L(a, .9)], [1, L(a, .55)]], -3, -4, 16));
    var b = '<circle r="70" fill="url(#' + k + 'aura)"/>';
    for (var r = -90 + 22.5; r < 270; r += 45)
        b += '<polygon points="' + pt(pol(16, r - 2.5)) + ' ' + pt(pol(68, r)) + ' ' + pt(pol(16, r + 2.5)) + '" fill="url(#' + k + 'ray)"/>';
    // Back star at 45°, darker and slimmer.
    b += armHalves(k, "b", 46, 15, -45, [L(a, .45), L(a, .1)], [D(a, .1), D(a, .45)], d);
    b += '<polygon points="' + pts(star(46, 15, -45)) + '" fill="none" stroke="' + D(a, .55) + '" stroke-width=".8" stroke-opacity=".8"/>';
    // Main star: thick arms (waist 25 for tips at 62), lit/shaded halves.
    b += armHalves(k, "f", 62, 25, -90, ["#ffffff", L(a, .5)], [L(a, .35), D(a, .25)], d);
    b += '<polygon points="' + pts(star(62, 25, -90)) + '" fill="none" stroke="' + D(a, .5) + '" stroke-width="1.2"/>';
    b += '<polygon points="' + pts(star(60.5, 24, -90)) + '" fill="none" stroke="' + L(a, .9) + '" stroke-width=".9" stroke-opacity=".9"/>';
    // Inset star: the bevel's inner face, then its dark groove.
    b += armHalves(k, "i", 44, 17.5, -90, [L(a, .8), L(a, .3)], [L(a, .2), D(a, .3)], d);
    b += '<polygon points="' + pts(star(44, 17.5, -90)) + '" fill="none" stroke="' + D(a, .55) + '" stroke-width="1.4"/>';
    b += '<polygon points="' + pts(star(42.5, 16.5, -90)) + '" fill="none" stroke="' + L(a, .85) + '" stroke-width=".6" stroke-opacity=".8"/>';
    // Centre: a cut diamond with a bright table.
    var dia = [pol(17, -90), pol(17, 0), pol(17, 90), pol(17, 180)];
    b += '<polygon points="' + pts(dia) + '" fill="' + D(a, .45) + '"/>';
    b += '<polygon points="' + pts([pol(15, -90), pol(15, 0), pol(15, 90), pol(15, 180)]) + '" fill="url(#' + k + 'gem)" stroke="' + L(a, .6) + '" stroke-width=".8"/>';
    b += '<polygon points="' + pts([pol(7.5, -90), pol(7.5, 0), pol(7.5, 90), pol(7.5, 180)]) + '" fill="#ffffff" fill-opacity=".9"/>';
    b += '<polygon points="0,-15 0,15 -15,0" fill="#ffffff" fill-opacity=".15"/>';
    // Highlight along the top-left edges of the upper arm.
    b += '<polyline points="' + pt(pol(25, -135)) + ' ' + pt(pol(62, -90)) + '" fill="none" stroke="#ffffff" stroke-width="1.4" stroke-opacity=".7"/>';
    function spark(x, y, s, o) {
        return '<polygon points="' + [[x, y - s], [x + s * .22, y - s * .22], [x + s, y], [x + s * .22, y + s * .22], [x, y + s], [x - s * .22, y + s * .22], [x - s, y], [x - s * .22, y - s * .22]].map(pt).join(" ") + '" fill="#ffffff" fill-opacity="' + o + '"/>';
    }
    b += spark(40, -44, 5, .95) + spark(-46, 34, 3.5, .8) + spark(50, 38, 2.6, .7) + spark(-36, -50, 2.4, .6);
    return svg("-72 -72 144 144", d.join(""), b);
}

function dataUrl(svgText) { return "data:image/svg+xml;utf8," + encodeURIComponent(svgText); }
