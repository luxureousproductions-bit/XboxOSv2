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

    // Clicking (or tapping) a prompt does what pressing its button does.
    // The bar only reports which one; theme.qml routes it down the focus
    // chain, the same path the key itself takes.
    signal promptClicked(string button)
    signal leftPromptClicked()

    Component {
        id: buttonhelpDelegate
        Item {
        width: promptRow.width
        height: promptRow.height
        opacity: promptMouse.pressed ? 0.6 : 1
        MouseArea {
        id: promptMouse
            anchors.fill: parent
            anchors.margins: -vpx(6)          // a little easier to hit
            cursorShape: Qt.PointingHandCursor
            onClicked: root.promptClicked(button)
        }
        Row {
        id: promptRow
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
                color: promptColor
                height: vpx(30)   // the icon's height: parent.height was circular (the Row takes its height from this)
                verticalAlignment: Text.AlignVCenter
            }
        }
        }
    }

    ListView {
        anchors.fill: parent
        // Never scrolls. An interactive ListView grabs every press over its
        // whole area, which ate clicks meant for prompts drawn in this strip.
        interactive: false
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
    property real   leftPromptNudge: 0
    // Prompt text colour, set by theme.qml (see helpPromptColor there).
    property color  promptColor: theme.text

    // Mirrors buttonhelpDelegate exactly: same spacing, same sizes, and the
    // same vertical treatment. The ListView above anchors.fill and lays its
    // rows out from the TOP of the bar, so centring this one instead is what
    // made "Apps" sit lower than everything else.
    Row {
    id: leftPrompt
        opacity: leftMouse.pressed ? 0.6 : 1
        anchors {
            left: parent.left
            top: parent.top
            // Level with the right-hand prompts everywhere except the three
            // RetroAchievements pages, where those prompts sit lower and the
            // Apps prompt has to follow them.
            // Set by theme.qml per screen (this file's own id is `root`, so
            // the theme's state isn't reachable from here).
            topMargin: leftPromptNudge
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
            color: promptColor
            height: vpx(30)   // the icon's height (see above)
            verticalAlignment: Text.AlignVCenter
        }
    }
    // Click area for Apps: a sibling over the Row, so the Row doesn't lay
    // it out as one more item.
    MouseArea {
    id: leftMouse
        anchors.fill: leftPrompt
        anchors.margins: -vpx(6)
        enabled: leftPrompt.visible
        cursorShape: Qt.PointingHandCursor
        onClicked: root.leftPromptClicked()
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
            case "menu":   // Start (controller/11.png)
                buttonModel = api.keys.menu;
                break;
            default:
            buttonModel = api.keys.accept;
        }

        // `i < length`: the loop used to test `buttonModel.length` alone, so a
        // key with no controller binding ran past the end and threw.
        for (var i = 0; i < buttonModel.length; i++) {
            if (buttonModel[i].name().includes("Gamepad")) {
            var buttonValue = buttonModel[i].key.toString(16)
            // Last hex digit of the gamepad key = button index (A 0 ... Select a,
            // Start b); the glyph files are named in decimal (10.png, 11.png)
            return String(parseInt(buttonValue.substring(buttonValue.length-1, buttonValue.length), 16));
            }
        }
        // A key with no controller binding (keyboard-only on PC) gets the
        // default controller glyph instead of no icon.
        return defaultButtonArt[button] || "0";
    }
    // Default glyph per action (Pegasus's default controller layout).
    readonly property var defaultButtonArt: ({ accept: "0", cancel: "1", details: "2", filters: "3",
                                               prevPage: "4", nextPage: "5", pageUp: "6", pageDown: "7", menu: "11" })
    
}