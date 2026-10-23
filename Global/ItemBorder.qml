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
import QtGraphicalEffects 1.15

Item {
id: root

    // Thick rounded accent frame — matches the hero box / game tiles in the
    // showcase. This component is loaded only while the item is selected
    // (the grid/collection delegates use `active: selected` on their Loader),
    // so the frame appears on selection. Replaces the old borderimage.gif
    // OpacityMask approach.
    Rectangle {
    id: border

        anchors.fill: parent
        anchors.margins: -vpx(3)   // overhang so the tile's antialiased corner
                                   // can't peek outside the frame
        color: "transparent"
        radius: vpx(15)
        border.color: theme.accent
        // 6, not 5: one unit thicker on the INSIDE only (the outer edge, -3,
        // and its curve are unchanged), so its inner edge sits at +3. The
        // preview video (ItemHighlight) is inset +3 to meet it; at +2 its
        // square corners sat under the frame's outer curve by less than a
        // pixel and faintly showed through on light backgrounds.
        border.width: vpx(6)
        antialiasing: true
    }

    // Animated highlight — flashes the frame white when the setting is on
    Rectangle {
    id: highlightPulse

        anchors.fill: parent
        anchors.margins: -vpx(3)
        visible: settings.AnimateHighlight === "Yes"
        color: "transparent"
        radius: vpx(15)
        border.color: "#ffffff"
        border.width: vpx(6)   // matches the frame above
        antialiasing: true
        opacity: 0   // start invisible so it can't pop in at peak brightness
        SequentialAnimation on opacity {
            running: highlightPulse.visible
            loops: Animation.Infinite
            PropertyAction { target: highlightPulse; property: "opacity"; value: 0 }
            NumberAnimation { to: 1; duration: 200 }
            NumberAnimation { to: 0; duration: 500 }
            PauseAnimation  { duration: 200 }
        }
    }

}
