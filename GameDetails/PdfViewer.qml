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
import QtQuick.Pdf 5.15
import "../Global"

FocusScope {
id: root

    signal close
    property string pdfPath: ""

    // Only load the document while the viewer is visible
    PdfDocument {
    id: pdfDoc

        source: root.visible && pdfPath !== "" ? pdfPath : ""
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.97
    }

    // Loading state
    Text {
        anchors.centerIn: parent
        visible: pdfDoc.status === PdfDocument.Loading
        text: "Loading manual…"
        color: "white"
        font.family: subtitleFont.name
        font.pixelSize: vpx(20)
    }

    // Error / not found state
    Text {
        anchors.centerIn: parent
        visible: pdfDoc.status === PdfDocument.Error || (root.visible && pdfPath === "")
        text: "Manual not found"
        color: "white"
        font.family: subtitleFont.name
        font.pixelSize: vpx(20)
        opacity: 0.7
    }

    // Horizontal page list – one page per screen, swipe to navigate
    ListView {
    id: pageList

        focus: true
        currentIndex: 0
        anchors {
            fill: parent
            bottomMargin: vpx(40)
        }
        visible: pdfDoc.status === PdfDocument.Ready
        model: pdfDoc.pageCount
        orientation: ListView.Horizontal
        clip: true
        preferredHighlightBegin: 0
        preferredHighlightEnd: width
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 200
        snapMode: ListView.SnapOneItem
        keyNavigationWraps: true

        delegate: PdfPageImage {
            width: root.width
            height: root.height - vpx(40)
            document: pdfDoc
            pageNumber: index
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Keys.onLeftPressed:  { sfxNav.play(); decrementCurrentIndex() }
        Keys.onRightPressed: { sfxNav.play(); incrementCurrentIndex() }
    }

    // Page dots (shown when ≤ 20 pages)
    Row {
    id: blips

        anchors.horizontalCenter: parent.horizontalCenter
        anchors { bottom: parent.bottom; bottomMargin: vpx(10) }
        spacing: vpx(10)
        visible: pdfDoc.status === PdfDocument.Ready && pdfDoc.pageCount > 1 && pdfDoc.pageCount <= 20
        Repeater {
            model: pdfDoc.pageCount
            Rectangle {
                width: vpx(10)
                height: width
                color: (pageList.currentIndex === index) ? theme.accent : theme.text
                radius: width / 2
                opacity: (pageList.currentIndex === index) ? 1 : 0.5
            }
        }
    }

    // Page counter (shown when > 20 pages)
    Text {
        anchors { bottom: parent.bottom; bottomMargin: vpx(12); horizontalCenter: parent.horizontalCenter }
        visible: pdfDoc.status === PdfDocument.Ready && pdfDoc.pageCount > 20
        text: (pageList.currentIndex + 1) + " / " + pdfDoc.pageCount
        color: theme.text
        font.family: subtitleFont.name
        font.pixelSize: vpx(14)
        opacity: 0.7
    }

    // Reset to first page whenever a new document is loaded
    Connections {
        target: pdfDoc
        onStatusChanged: {
            if (pdfDoc.status === PdfDocument.Ready)
                pageList.currentIndex = 0;
        }
    }

    // Input handling
    Keys.onPressed: {
        // Back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            close();
        }
        // Accept also closes (mirrors MediaView behaviour)
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            close();
        }
    }

    // Helpbar buttons
    ListModel {
    id: pdfviewHelpModel

        ListElement { name: "Back"; button: "cancel" }
        ListElement { name: "Prev page"; button: "left" }
        ListElement { name: "Next page"; button: "right" }
    }

    onFocusChanged: {
        if (focus) {
            currentHelpbarModel = pdfviewHelpModel;
        }
    }
}
