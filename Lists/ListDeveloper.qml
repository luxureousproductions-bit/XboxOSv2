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
    function currentGame(index) { return api.allGames.get(developerGames.mapToSource(index)) }
    property int max: developerGames.count

    property string developer: ""
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
    id: developerGames

        sourceModel: homeDataReady ? api.allGames : null   // theme.qml homeDataReady
        filters: [
            RegExpFilter { roleName: "developer"; pattern: Utils.escapeRegExp(developer); caseSensitivity: Qt.CaseInsensitive },
            ExpressionFilter {
                expression: {
                    if (root.hideRows[index] === true) return false;
                    if (root.hideTitles[model.title] === true) return false;
                    if (!root.omitApplication && !root.omitEmulator) return true;
                    var genres = model.genreList;
                    for (var i = 0; i < genres.length; i++) {
                        var g = genres[i].toLowerCase();
                        if (root.omitApplication && g === "application") return false;
                        if (root.omitEmulator && g === "emulator") return false;
                    }
                    return true;
                }
            }
        ]
        sorters: RoleSorter { roleName: "rating"; sortOrder: Qt.DescendingOrder }
    }

    SortFilterProxyModel {
    id: gamesFiltered

        sourceModel: developerGames
        filters: [
            IndexFilter { maximumIndex: max - 1 },
            ExpressionFilter { expression: developer !== "" }
        ]
    }

    property var collection: {
        return {
            name:       "Top Games by " + developer,
            shortName:  "developer",
            games:      gamesFiltered
        }
    }
}
