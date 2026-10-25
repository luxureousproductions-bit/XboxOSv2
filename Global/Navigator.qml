// XboxOSv2 – the one owner of "which screen is showing" and the Back history.
//
// theme.qml used to keep two bare arrays (lastState, lastGame) that a dozen
// functions pushed to, popped from, or replaced wholesale, and most of the
// bugs in Back came from one of them doing it slightly differently. Every
// screen change now goes through here:
//
//   go(screen)      open a screen; Back returns to the current one
//   jump(screen)    switch without adding to the history (the "FromX" cases)
//   home(screen)    clear the history and land on a screen (Home)
//   setStack(arr)   rewrite the history (launch from RA returns to Home)
//   back(apply)     return to the previous screen; false when there's none
//
// `current` is the screen name; theme.qml copies it into root.state, which
// every screen Loader keys on. Game details pages also keep the game they
// replaced (pushGame/popGame) so Back inside details chains works.
import QtQuick 2.15

QtObject {
id: nav

    property string current: ""
    // Screens behind `current`, oldest first. Arrays don't notify, so depth
    // is kept by hand for anything that needs to react.
    property var stack: []
    property int depth: 0
    // Games behind the current one, for details pages opened from details.
    property var games: []

    function go(screen) {
        if (current !== "") stack.push(current);
        depth = stack.length;
        current = screen;
    }

    function jump(screen) {
        current = screen;
    }

    function home(screen) {
        stack = [];
        depth = 0;
        current = screen;
    }

    function setStack(arr) {
        stack = arr.slice();
        depth = stack.length;
    }

    // Returns to the previous screen. `applyGame(game)` is called first when
    // a details page is returning to the details page it was opened from, so
    // the game swaps before the screen does (no flash of the wrong game).
    function back(applyGame) {
        if (stack.length === 0) return false;
        var top = stack.pop();
        depth = stack.length;
        if (top === current && games.length) {
            var g = games.pop();
            if (applyGame) applyGame(g);
        }
        current = top;
        return true;
    }

    function pushGame(g) { games.push(g); }
    function popGame() { return games.length ? games.pop() : null; }
    function clearGames() { games = []; }

    // For the Resume key: screens by name, games as whatever keyFn makes of them.
    function serialize(keyFn) {
        return { state: current, lastState: stack.slice(), lastGame: games.map(keyFn) };
    }
    function restore(current_, stack_, games_) {
        stack = (stack_ || []).slice();
        depth = stack.length;
        games = (games_ || []).slice();
        current = current_;
    }
}
