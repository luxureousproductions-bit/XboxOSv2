// Copyright (C) 2026 Esteban / XboxOSv2
//
// Turns mouse-wheel notches into SELECTION steps on a list or grid.
//
// Why this exists: every list and grid here drives its highlight from
// currentIndex with highlightRangeMode: ApplyRange. A raw wheel event scrolls
// the Flickable's content only, so the view drifts away from the highlighted
// item and snaps back on the next key press. Moving the index instead keeps
// the two in step, and works the same for keyboard, controller and wheel.
//
// Usage — declare as a SIBLING of the view, never a child (a MouseArea inside
// a Flickable is reparented into its contentItem and scrolls away with it):
//
//     GridView { id: grid; ... }
//     WheelNav { view: grid; columns: grid.columns; anchors.fill: grid }
//
// It takes no buttons and no hover, so clicks, taps, long-press and hover all
// still reach the delegates underneath.

import QtQuick 2.15

MouseArea {
id: root

    // The ListView / GridView whose currentIndex should move.
    property Item view: null
    // Indices per notch. A grid moves a whole row; a list moves one item.
    property int columns: 1
    // Off while an overlay covers the view (filters, a picker, a dialog).
    property bool active: true
    // Called after a successful move — usually a navigation sound.
    property var onStepped: null

    acceptedButtons: Qt.NoButton      // clicks pass straight through
    hoverEnabled: false               // hover passes through too
    propagateComposedEvents: true
    z: 5

    // Touchpads send many small deltas; a wheel sends 120 per notch. Both are
    // accumulated so a trackpad flick doesn't jump a page per pixel.
    property int accumulated: 0

    onWheel: {
        if (!active || !view || view.count <= 0) { wheel.accepted = false; return; }
        wheel.accepted = true;
        accumulated += wheel.angleDelta.y;
        var step = 0;
        while (accumulated >= 120)  { accumulated -= 120; step -= 1; }
        while (accumulated <= -120) { accumulated += 120; step += 1; }
        if (step === 0) return;

        var target = view.currentIndex + step * Math.max(1, columns);
        // Clamp rather than wrap: a wheel is a continuous gesture and wrapping
        // from the end to the start mid-flick is disorienting.
        if (target < 0) target = 0;
        if (target > view.count - 1) target = view.count - 1;
        if (target === view.currentIndex) return;
        view.currentIndex = target;
        if (onStepped) onStepped();
    }
}
