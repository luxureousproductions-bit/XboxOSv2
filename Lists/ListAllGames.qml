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
    // Two models deep now, so map back through both to reach api.allGames.
    function currentGame(index) {
        return api.allGames.get(dedupedGames.mapToSource(gamesFiltered.mapToSource(index)));
    }
    property int max: gamesFiltered.count

    // api.allGames rows to leave out (theme.qml libraryHideRows): duplicate
    // Pegasus imports, plus anything hidden from the library. Filtered in their own
    // model BEFORE the length limit below — IndexFilter counts against its
    // source, so filtering in the same model would leave a short row a game
    // or two short.
    property var hideRows: ({})
    readonly property bool hasHideRows: Object.keys(hideRows).length > 0

    SortFilterProxyModel {
    id: dedupedGames

        // max 0 (a Home row set to None) must mean NO games: IndexFilter
        // reads maximumIndex -1 as "the last row", so it passed all 4,400,
        // and the hidden row built tiles and decoded art over the library.
        sourceModel: (homeDataReady && root.max > 0) ? api.allGames : null   // theme.qml homeDataReady
        // Off (no per-row JS at all) when there's nothing to hide.
        filters: ExpressionFilter {
            enabled: root.hasHideRows
            expression: root.hideRows[index] !== true
        }
    }

    SortFilterProxyModel {
    id: gamesFiltered

        sourceModel: dedupedGames
        filters: IndexFilter { maximumIndex: max - 1 }
    }

    property var collection: {
        return {
            name:       "All games",
            shortName:  "allgames",
            games:      gamesFiltered
        }
    }
}
