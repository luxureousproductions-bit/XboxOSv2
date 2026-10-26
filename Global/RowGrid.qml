// XboxOSv2 – a grid of game tiles built as a ListView of ROWS.
//
// Why not a GridView: in Qt 5.15 GridView never recycles its delegates.
// Its removeItem() releases every tile that scrolls out with NotReusable
// (qquickgridview.cpp), whatever `reuseItems` says, so a held D-pad builds
// and destroys a full row of tiles on every step — a tile is several
// Images, Texts, Loaders and a shader, and the destroyed ones pile up as
// garbage until the JS engine stops to collect it. That is the scrolling
// that got slower the longer the key was held. ListView DOES recycle: a
// row that scrolls out is handed back in at the other edge with a new
// index, and its tiles only rebind.
//
// The host sees a flat grid: `currentIndex` and `count` are GAME indices,
// exactly as GridView gave them, so the letter jumps, the wheel, the
// restore and the key handlers are unchanged. The host supplies:
//   model      the games model (its count is used; `0` for none)
//   resolve    function(i) -> game, for the tile at flat index i
//   tile       the tile Component. It is created inside a row by a
//              Repeater, so `index` is its COLUMN and `parent` the row
//              (parent.rowIndex). The host binds gameData from
//              gameAt(flatIndex) and `selected` from currentIndex.
//   highlightItem  the ItemHighlight Component; this positions it over the
//              current cell (y by the ListView, x by the column).
import QtQuick 2.15

Item {
id: grid

    property var model: null
    property var resolve: null
    property Component tile: null
    property Component highlightItem: null
    property int columns: 4
    property real cellWidth: columns > 0 ? width / columns : width
    property real cellHeight: cellWidth
    // Space under the art inside each cell (box-art titles); the highlight
    // and the tiles are cellHeight minus this.
    property real titleMargin: 0
    property int highlightMoveDuration: 200
    property real cacheBuffer: 0
    property int populateDuration: 200
    property int populateEasing: Easing.Linear

    // Flat game index, as a GridView's currentIndex. Plain (not readonly):
    // the host both binds it and assigns it, as it did with the GridView.
    property int currentIndex: -1
    readonly property int count: (model && model.count !== undefined) ? model.count : 0
    readonly property int rows: columns > 0 ? Math.ceil(count / columns) : 0
    readonly property int currentRow: currentIndex < 0 ? -1 : Math.floor(currentIndex / columns)
    readonly property int currentColumn: currentIndex < 0 ? 0 : currentIndex % columns

    // Bumped whenever the model's ORDER may have changed without its count
    // (a re-sort, a filter, a scope swap to a same-sized system). Every
    // tile's gameAt() reads it, so they all re-resolve.
    property int epoch: 0
    function gameAt(i) {
        var e = epoch;   // dependency
        if (!resolve || i < 0 || i >= count) return null;
        return resolve(i);
    }
    onModelChanged: { epoch++; syncRows(); }
    onResolveChanged: epoch++
    Connections {
        target: (grid.model && typeof grid.model === "object") ? grid.model : null
        ignoreUnknownSignals: true
        onLayoutChanged: grid.epoch++
        onModelReset:    grid.epoch++
        onRowsInserted:  grid.epoch++
        onRowsRemoved:   grid.epoch++
        onRowsMoved:     grid.epoch++
    }

    // The rows themselves: a ListModel kept at `rows` entries, grown and
    // shrunk in place. An integer model would do, but every change to an
    // integer model is a NEW model to the view: it tears every row down,
    // rebuilds, resets its current index and scroll position and replays the
    // populate fade — on every keystroke of a name filter. A ListModel's
    // inserts and removals are incremental, and rows that leave go to the
    // recycle pool and come straight back.
    ListModel { id: rowModel }
    function syncRows() {
        var want = model ? rows : 0;
        var have = rowModel.count;
        if (want > have) { for (var i = have; i < want; i++) rowModel.append({ r: i }); }
        else if (want < have) rowModel.remove(want, have - want);
        // The view may have moved its own current index while rows came and
        // went (or reset it); put it back on the current game's row.
        syncCurrent();
    }
    onRowsChanged: syncRows()
    Component.onCompleted: syncRows()
    // Imperative, not a binding: the view writes its own currentIndex from
    // C++ on resets and removals, which leaves a binding stale.
    function syncCurrent() { if (list.currentIndex !== currentRow) list.currentIndex = currentRow; }
    onCurrentRowChanged: syncCurrent()

    function forceLayout() { list.forceLayout(); }
    // Scrolls so the current row sits at the top of the view (used after a
    // restore, where the range mode alone can leave it anywhere in range).
    function positionAtCurrent(mode) {
        if (currentRow >= 0) list.positionViewAtIndex(currentRow, mode === undefined ? ListView.Contain : mode);
    }

    ListView {
    id: list
        anchors.fill: parent
        model: rowModel
        orientation: ListView.Vertical
        interactive: false
        keyNavigationEnabled: false
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: grid.cacheBuffer
        reuseItems: true

        highlightFollowsCurrentItem: true
        highlightMoveDuration: grid.highlightMoveDuration
        highlightMoveVelocity: -1
        highlightResizeDuration: 0
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: 0
        preferredHighlightEnd: height

        populate: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1.0
                              duration: grid.populateDuration; easing.type: grid.populateEasing }
        }

        // The highlight spans the row; the host's item sits at the column.
        // Under the tiles, as the GridView's was: the tile fades its own art
        // to reveal the preview playing in the highlight beneath it.
        highlight: Item {
            width: list.width
            height: grid.cellHeight
            z: 0
            Loader {
                sourceComponent: grid.highlightItem
                x: grid.currentColumn * grid.cellWidth
                Behavior on x { NumberAnimation { duration: grid.highlightMoveDuration } }
            }
        }

        delegate: Item {
        id: row
            readonly property int rowIndex: index
            width: list.width
            height: grid.cellHeight
            // A selected tile pops above its row-mates by its own z, but its
            // frame and glow also reach into the rows above and below, so
            // the current row sits above the others.
            z: rowIndex === grid.currentRow ? 2 : 1
            // Recycled: the tiles already follow their new games through
            // gameData; this is for whatever else a tile resets (its art's
            // opacity after a preview, say).
            ListView.onReused: {
                for (var i = 0; i < row.children.length; i++) {
                    var c = row.children[i];
                    if (c && typeof c.resetForReuse === "function") c.resetForReuse();
                }
            }
            Repeater {
                model: grid.columns
                delegate: grid.tile
            }
        }
    }
}
