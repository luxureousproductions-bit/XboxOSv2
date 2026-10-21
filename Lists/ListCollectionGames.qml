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
    property var collection: api.collections.get(currentCollectionIndex)
    function currentGame(index) { return collection.games.get(gamesFiltered.mapToSource(index)) }
    property int max
    // On an Android platform page, leave out duplicate Pegasus imports and
    // anything hidden from the library (theme.qml androidHideRows, numbered in
    // that collection's own list — this proxy's source). Off for every other
    // system, so they run no per-row JS for it.
    readonly property var  hideRowsHere: hideRowsForCollection(currentCollectionIndex)
    readonly property bool hideAndroidDupes: Object.keys(hideRowsHere).length > 0

    SortFilterProxyModel {
    id: gamesFiltered

        sourceModel: collection.games
        filters: [
            ValueFilter { roleName: "favorite"; value: true; enabled: showFavs },
            RegExpFilter { roleName: "title"; pattern: searchTerm; caseSensitivity: Qt.CaseInsensitive; enabled: searchTerm != "" && searchMode === "Title" },
            RegExpFilter { roleName: "genre"; pattern: searchTerm; caseSensitivity: Qt.CaseInsensitive; enabled: searchTerm != "" && searchMode === "Genre" },
            RegExpFilter { roleName: "genre"; pattern: genresToPattern(genreSelected); caseSensitivity: Qt.CaseInsensitive; enabled: genreSelected.length > 0 },
            ExpressionFilter { enabled: root.hideAndroidDupes; expression: root.hideRowsHere[index] !== true },
            IndexFilter { maximumIndex: max - 1; enabled: max }
        ]
        // By title: A to Z ignoring upper/lower case (RoleSorter compares
        // case-sensitively, so "abc" landed after "Zelda")
        sorters: [
            StringSorter { roleName: "title"; caseSensitivity: Qt.CaseInsensitive; sortOrder: orderBy
                           enabled: sortByFilter[sortByIndex] === "title" },
            RoleSorter { roleName: sortByFilter[sortByIndex]; sortOrder: orderBy
                         enabled: sortByFilter[sortByIndex] !== "title" }
        ]
    }
}
