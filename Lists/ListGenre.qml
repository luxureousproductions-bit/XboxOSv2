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
    // The wanted genre, normalised ONCE: the filter below used to rebuild it
    // (a regex split, map and join) for every one of ~4,400 rows.
    readonly property string wantNorm: normGenre(genre)
    property bool omitApplication: true
    property bool omitEmulator: true
    // Titles Home should hide, already combined by the theme for the
    // current Hide apps / Hide emulators options (theme.qml homeHideTitles).
    // One property, so a change re-filters the row once; it only changes
    // when its contents do. Genre tags are still checked below.
    property var hideTitles: ({})
    // api.allGames rows to skip outright (theme.qml libraryHideRows):
    // duplicate Pegasus imports, plus anything hidden from the library.
    property var hideRows: ({})

    SortFilterProxyModel {
    id: genreGames

        sourceModel: homeDataReady ? api.allGames : null   // theme.qml homeDataReady
        filters: [
            ExpressionFilter {
                expression: {
                    // root.wantNorm, explicitly: inside an ExpressionFilter the
                    // model's roles are exposed as bare names, so a bare `genre`
                    // here is each GAME's own genre — every game then matched
                    // itself and the row filled with the library's top-rated titles.
                    var want = root.wantNorm;
                    if (want === "") return false;      // no genre picked: an empty row
                    if (root.hideRows[index] === true) return false;
                    if (root.hideTitles[model.title] === true) return false;
                    var genres = model.genreList;
                    var hit = false;
                    for (var i = 0; i < genres.length; i++) {
                        var raw = genres[i];
                        var g = raw.toLowerCase();
                        if (root.omitApplication && g === "application") return false;
                        if (root.omitEmulator && g === "emulator") return false;
                        if (!hit) {
                            // Match with the SAME rule the picker uses to build its pool
                            // (utils.homePools): the whole entry, or either half of a
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
