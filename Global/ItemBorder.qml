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
        color: "transparent"
        radius: vpx(6)
        border.color: theme.accent
        border.width: vpx(5)
        antialiasing: true
    }

    // Animated highlight — flashes the frame white when the setting is on
    Rectangle {
    id: highlightPulse

        anchors.fill: parent
        visible: settings.AnimateHighlight === "Yes"
        color: "transparent"
        radius: vpx(6)
        border.color: "#ffffff"
        border.width: vpx(5)
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

    Rectangle {
    id: titlecontainer

        width: bubbletitle.contentWidth + vpx(20)
        height: bubbletitle.contentHeight + vpx(8)
        color: theme.secondary
        anchors {
            top: border.bottom; topMargin: vpx(7)
        }
        anchors.horizontalCenter: parent.horizontalCenter
        radius: height/2
        opacity: selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
        visible: opacity !== 0

        Text {
        id: bubbletitle

            text: modelData.title
            color: theme.text
            font {
                family: subtitleFont.name
                pixelSize: vpx(14)
                bold: true
            }
            elide: Text.ElideRight
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
