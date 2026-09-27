// gameOS theme
// Copyright (C) 2018-2020 Seth Powell 
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

import QtQuick 2.15
import "../utils.js" as Utils
import SortFilterProxyModel 0.2

Item {
id: root
    
    readonly property alias games: gamesFiltered
    function currentGame(index) { return api.allGames.get(genreGames.mapToSource(index)) }
    property int max: genreGames.count
    property string genre: ""
    // Canonical form for comparing genre strings: lower-case, and the
    // separators normalised so "Sports/Bowling", "Sports / Bowling" and
    // "Sports , Bowling" all compare equal.
    function normGenre(g) {
        if (!g) return "";
        return g.toLowerCase().split(/\s*[\/,]\s*/).map(function(p) { return p.trim(); }).join(" / ");
    }
    property bool omitApplication: true
    property bool omitEmulator: true
    // Titles of installed apps, supplied by the theme. Apps whose store lookup
    // failed carry no genre, so the genre test below can't catch them.
    property var appTitles: ({})

    SortFilterProxyModel {
    id: genreGames

        sourceModel: api.allGames
        filters: [
            ExpressionFilter {
                expression: {
                    if (root.omitApplication && root.appTitles[model.title] === true) return false;
                    var genres = model.genreList;
                    // root.genre, explicitly: inside an ExpressionFilter the model's
                    // roles are exposed as bare names, so a bare `genre` here is
                    // each GAME's own genre — every game then matched itself and
                    // the row filled with the library's top-rated titles.
                    var want = root.normGenre(root.genre);
                    var hit = false;
                    for (var i = 0; i < genres.length; i++) {
                        var raw = genres[i];
                        var g = raw.toLowerCase();
                        if (root.omitApplication && g === "application") return false;
                        if (root.omitEmulator && g === "emulator") return false;
                        if (!hit && want !== "") {
                            // Match with the SAME rule the picker uses to build its pool
                            // (utils.genrePools): the whole entry, or either half of a
                            // "Parent / Sub" entry. It used to be a regex on the "genre"
                            // role — a different field split a different way — so the
                            // picker could name "Bowling" (the sub half of
                            // "Sports / Bowling") while this filter found nothing.
                            if (root.normGenre(raw) === want) hit = true;
                            else {
                                var parts = raw.split(/\s*[\/,]\s*/);
                                for (var k = 0; k < parts.length; k++)
                                    if (parts[k].trim().toLowerCase() === want) { hit = true; break; }
                            }
                        }
                    }
                    return hit;
                }
            }
        ]
        sorters: RoleSorter { roleName: "rating"; sortOrder: Qt.DescendingOrder }
    }

    SortFilterProxyModel {
    id: gamesFiltered

        sourceModel: genreGames
        filters: [
            IndexFilter { maximumIndex: max - 1 },
            ExpressionFilter { expression: genre !== "" }
        ]
    }

    property var collection: {
        return {
            name:       "Top " + genre + " Games",
            shortName:  genre + "games",
            games:      gamesFiltered
        }
    }
}
