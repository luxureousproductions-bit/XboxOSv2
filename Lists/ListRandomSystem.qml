// Copyright (C) 2026 Esteban / XboxOSv2
//
// "Play Something New For <System>": picks one system at random, then a
// handful of its games at random — Recommended, but scoped to a single
// collection. Built the same way as ListRecommended: refresh() hands over a
// plain array of the picked games, so there is never a library-wide pass.
//
// Two rows set to this are given different systems (the Showcase passes the
// first pick's shortName as `avoid` when refreshing the second).

import QtQuick 2.15

Item {
id: root

    property int max: 15
    property bool active: false

    // Skipped when picking: the drawer's app collection, and anything with
    // fewer games than this (a two-game system makes a poor "something new").
    property string skipShortName: "android"
    property int minGames: 10

    property var  games: []
    property var  system: null          // the picked collection
    property string avoid: ""           // shortName of a system to not pick

    function currentGame(index) {
        return (index >= 0 && index < games.length) ? games[index] : null;
    }

    function refresh() {
        var eligible = [];
        for (var c = 0; c < api.collections.count; c++) {
            var col = api.collections.get(c);
            if (!col) continue;
            var sn = (col.shortName || "").toLowerCase();
            if (sn === skipShortName || sn === avoid.toLowerCase()) continue;
            if (col.games.count < minGames) continue;
            eligible.push(col);
        }
        if (eligible.length === 0) { games = []; system = null; return; }
        var picked = eligible[Math.floor(Math.random() * eligible.length)];

        // A few random games from it, no repeats, best-rated first.
        var total = picked.games.count, seen = {}, out = [], tries = 0;
        while (out.length < max && tries < max * 20) {
            tries++;
            var i = Math.floor(Math.random() * total);
            if (seen[i]) continue;
            seen[i] = true;
            var g = picked.games.get(i);
            if (g) out.push(g);
        }
        out.sort(function(a, b) { return (b.rating || 0) - (a.rating || 0); });
        system = picked;
        games = out;
    }

    // First pick at load, like Recommended. The Showcase declares the
    // second instance after the first, so its `avoid` is already set here.
    Component.onCompleted: if (active) refresh()

    property var collection: {
        return {
            name:       system ? ("Play Something New For " + system.name) : "Play Something New",
            shortName:  system ? system.shortName : "randomsystem",
            games:      games
        }
    }
}
