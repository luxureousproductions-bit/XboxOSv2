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

    function mapLayoutImage(layoutName) {
        // Original remaps
        if (layoutName === "Cyan")     return "Turquoise";
        if (layoutName === "Crimson")  return "Dark Red";
        if (layoutName === "Lime")     return "Light Green";
        if (layoutName === "Gold")     return "Yellow";
        if (layoutName === "Violet")   return "Purple";
        if (layoutName === "Teal")     return "Stone";
        // Greens → nearest existing green
        if (layoutName === "Olive")        return "Forest Green";
        if (layoutName === "Emerald")      return "Dark Green";
        if (layoutName === "Jade")         return "Mint";
        // Teals / Cyans → Turquoise
        if (layoutName === "Dark Teal")    return "Turquoise";
        if (layoutName === "Arctic")       return "Turquoise";
        if (layoutName === "Seafoam")      return "Turquoise";
        // Blues → nearest existing blue
        if (layoutName === "Royal Blue")   return "Dark Blue";
        if (layoutName === "Sky Blue")     return "Light Blue";
        if (layoutName === "Ice Blue")     return "Light Blue";
        if (layoutName === "Cobalt")       return "Navy Blue";
        if (layoutName === "Sapphire")     return "Navy Blue";
        // Reds / Pinks
        if (layoutName === "Maroon")       return "Burgundy";
        if (layoutName === "Brick Red")    return "Dark Red";
        if (layoutName === "Ruby")         return "Dark Red";
        if (layoutName === "Dark Pink")    return "Magenta";
        if (layoutName === "Light Pink")   return "Magenta";
        if (layoutName === "Hot Pink")     return "Magenta";
        if (layoutName === "Rose")         return "Magenta";
        if (layoutName === "Coral")        return "Orange";
        if (layoutName === "Salmon")       return "Orange";
        // Purples
        if (layoutName === "Dark Purple")  return "Purple";
        if (layoutName === "Lavender")     return "Purple";
        if (layoutName === "Indigo")       return "Purple";
        // Oranges / Yellows
        if (layoutName === "Amber")        return "Yellow";
        if (layoutName === "Dark Gold")    return "Yellow";
        if (layoutName === "Bronze")       return "Dark Orange";
        // Browns
        if (layoutName === "Light Brown")  return "Dark Brown";
        if (layoutName === "Copper")       return "Dark Brown";
        if (layoutName === "Rust")         return "Dark Brown";
        if (layoutName === "Sienna")       return "Dark Brown";
        if (layoutName === "Tan")          return "Dark Brown";
        // Grays / Neutrals
        if (layoutName === "Mid Gray")     return "Dark Gray";
        if (layoutName === "Steel")        return "Slate";
        if (layoutName === "Gunmetal")     return "Slate";
        if (layoutName === "Stone")        return "Stone";
        if (layoutName === "Onyx")         return "Dark Gray";
        if (layoutName === "White")        return "Silver";
        return layoutName;
    }

    Image {
    id: border

        anchors.fill: parent
        source: "../assets/images/" + mapLayoutImage(settings.ColorLayout) + ".png"
		asynchronous: true
        visible: false
        
        // Highlight animation (ColorOverlay causes graphical glitches on W10)
        Rectangle {
            anchors.fill: parent
            color: "#fff"
            visible: settings.AnimateHighlight === "Yes"
            SequentialAnimation on opacity {
            id: colorAnim

                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 1; duration: 200; }
                NumberAnimation { to: 0; duration: 500; }
                PauseAnimation { duration: 200 }
            }
        }
    }

    BorderImage {
    id: mask

        anchors.fill: parent
        source: "../assets/images/borderimage.gif"
        border { left: vpx(5); right: vpx(5); top: vpx(5); bottom: vpx(5);}
        smooth: false
        visible: false
        asynchronous: true
    }

    OpacityMask {
        anchors.fill: border
        source: border
        maskSource: mask
        visible: selected && border.status === Image.Ready
    }

    // Fallback: programmatic accent border shown when PNG doesn't exist
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: vpx(3)
        border.color: theme.accent
        opacity: (selected && border.status !== Image.Ready) ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
        visible: opacity > 0
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
