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
import QtQuick.Layouts 1.15

Item {
id: root

    Component {
        id: buttonhelpDelegate
        Row {
            spacing: 10
            Image {
                // An entry may supply its own icon instead of a controller
                // glyph — used for buttons Pegasus has no mapping for, like
                // Select. Only the taken branch of the ternary evaluates, so
                // processButtonArt() isn't called for custom-icon entries.
                source: (typeof icon !== 'undefined' && icon !== "")
                        ? icon
                        : "../assets/images/controller/" + processButtonArt(button) + ".png"
                width: vpx(30)
                height: vpx(30)
                sourceSize { width: Math.round(vpx(30) * 2); height: Math.round(vpx(30) * 2) }
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
            }
            Text { 
                text: name
                font.family: subtitleFont.name
                font.pixelSize: fpx(16)
                color: (root.state === "settingsscreen") ? "#ebebeb" : theme.text
                height: parent.height
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    ListView {
        anchors.fill: parent
        model: currentHelpbarModel
        delegate: buttonhelpDelegate
        orientation: ListView.Horizontal
        layoutDirection: Qt.RightToLeft
        spacing: vpx(20)
    }

    // Standalone prompt pinned to the far left, clear of the right-aligned
    // group above. Set leftPromptText to show it; empty hides it entirely.
    property string leftPromptText: ""
    property string leftPromptIcon: ""

    // Mirrors buttonhelpDelegate exactly: same spacing, same sizes, and the
    // same vertical treatment. The ListView above anchors.fill and lays its
    // rows out from the TOP of the bar, so centring this one instead is what
    // made "Apps" sit lower than everything else.
    Row {
        anchors {
            left: parent.left
            top: parent.top
        }
        spacing: 10
        visible: leftPromptText !== ""

        Image {
            source: leftPromptIcon
            width: vpx(30); height: vpx(30)
            sourceSize { width: Math.round(vpx(30) * 2); height: Math.round(vpx(30) * 2) }
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            visible: leftPromptIcon !== ""
        }
        Text {
            text: leftPromptText
            font.family: subtitleFont.name
            font.pixelSize: fpx(16)
            color: (root.state === "settingsscreen") ? "#ebebeb" : theme.text
            height: parent.height
            verticalAlignment: Text.AlignVCenter
        }
    }

    visible: currentHelpbarModel ? true : false

    // Processes the button and will display the correct art based on the button mappings set in Pegasus
    // Necessary as we can't use script in the ListModel
    function processButtonArt(button) {
        var buttonModel;
        switch (button) {
            case "accept":
            buttonModel = api.keys.accept;
            break;
            case "cancel":
            buttonModel = api.keys.cancel;
            break;
            case "filters":
            buttonModel = api.keys.filters;
            break;
            case "details":
            buttonModel = api.keys.details;
            break;
            case "nextPage":
            buttonModel = api.keys.nextPage;
            break;
            case "prevPage":
            buttonModel = api.keys.prevPage;
            break;
            case "pageUp":
            buttonModel = api.keys.pageUp;
            break;
            case "pageDown":
                buttonModel = api.keys.pageDown;
                break;
            default:
            buttonModel = api.keys.accept;
        }

        var i;
        for (i = 0; buttonModel.length; i++) {
            if (buttonModel[i].name().includes("Gamepad")) {
            var buttonValue = buttonModel[i].key.toString(16)
            return buttonValue.substring(buttonValue.length-1, buttonValue.length);
            }
        }
    }
    
}