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
import SortFilterProxyModel 0.2

Item {
id: root

    readonly property alias games: gamesFiltered
    function currentGame(index) { return api.allGames.get(mostPlayedGames.mapToSource(index)) }
    property int max: mostPlayedGames.count

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
    id: mostPlayedGames

        sourceModel: homeDataReady ? api.allGames : null   // theme.qml homeDataReady
        // Primary: total time played (seconds), most first.
        // Tie-break: number of launches, most first (covers games with equal or
        // zero playTime so they still order sensibly).
        // "Most played" means most OFTEN: launches first, hours only to break
        // ties. It used to be the other way round, so one long session beat a
        // game you kept coming back to — and play time is fragile anyway (an
        // emulator left open counts as play).
        sorters: [
            RoleSorter { roleName: "playCount"; sortOrder: Qt.DescendingOrder },
            RoleSorter { roleName: "playTime";  sortOrder: Qt.DescendingOrder }
        ]
        filters: ExpressionFilter {
            expression: {
                // Only games actually played. Without this every unplayed game
                // passed too and padded the row with titles sorted by nothing.
                if (!(model.playCount > 0)) return false;
                if (root.hideRows[index] === true) return false;
                if (root.hideTitles[model.title] === true) return false;
                if (!root.omitApplication && !root.omitEmulator) return true;   // no genre walk needed
                var genres = model.genreList;
                for (var i = 0; i < genres.length; i++) {
                    var g = genres[i].toLowerCase();
                    if (root.omitApplication && g === "application") return false;
                    if (root.omitEmulator && g === "emulator") return false;
                }
                return true;
            }
        }
    }

    SortFilterProxyModel {
    id: gamesFiltered

        sourceModel: mostPlayedGames
        filters: IndexFilter { maximumIndex: max - 1 }
    }

    property var collection: {
        return {
            name:       "Most Popular",
            shortName:  "mostplayed",
            games:      gamesFiltered
        }
    }
}
