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

import QtQuick 2.8
import QtQuick.Pdf 5.15
import "../Global"

FocusScope {
id: root

    signal close
    property string pdfPath: ""

    Rectangle {
        anchors.fill: parent
        color: theme.main
        opacity: 0.97
    }

    // Load PDF only while the overlay is open and a path is set
    PdfDocument {
    id: pdfDoc

        source: root.visible && pdfPath !== "" ? pdfPath : ""
    }

    // "Manual not found" state – shown when no path is set
    Text {
        anchors.centerIn: parent
        visible: pdfPath === ""
        text: "Manual not found"
        color: theme.text
        font.family: subtitleFont.name
        font.pixelSize: vpx(20)
        opacity: 0.7
    }

    // Load error message
    Text {
    id: errorText

        anchors.centerIn: parent
        visible: pdfPath !== "" && pdfDoc.status === PdfDocument.Error
        text: "Could not load manual"
        color: theme.text
        font.family: subtitleFont.name
        font.pixelSize: vpx(20)
        opacity: 0.7
    }

    // Scrollable multi-page PDF viewer
    Flickable {
    id: pdfFlickable

        anchors {
            fill: parent
            bottomMargin: vpx(50)
        }
        visible: pdfDoc.status === PdfDocument.Ready
        contentWidth: width
        contentHeight: pageColumn.height
        clip: true

        Column {
        id: pageColumn

            width: pdfFlickable.width

            Repeater {
                model: pdfDoc.status === PdfDocument.Ready ? pdfDoc.pageCount : 0

                PdfPageImage {
                    document: pdfDoc
                    currentPage: index
                    width: pageColumn.width
                    height: implicitWidth > 0 && implicitHeight > 0 ? Math.round(width * implicitHeight / implicitWidth) : 0
                    fillMode: Image.PreserveAspectFit
                }
            }
        }
    }

    // Bottom hint bar
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: vpx(50)
        color: theme.main
        opacity: 0.85

        Text {
            anchors.centerIn: parent
            text: "Scroll to navigate  •  Back to close"
            color: theme.text
            font.family: subtitleFont.name
            font.pixelSize: vpx(14)
            opacity: 0.7
        }
    }

    // Input handling
    Keys.onPressed: {
        // Back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            close();
        }
    }

    // Controller d-pad scrolling
    Keys.onUpPressed: {
        pdfFlickable.contentY = Math.max(0, pdfFlickable.contentY - vpx(100));
    }

    Keys.onDownPressed: {
        pdfFlickable.contentY = Math.min(
            Math.max(0, pdfFlickable.contentHeight - pdfFlickable.height),
            pdfFlickable.contentY + vpx(100)
        );
    }

    // Helpbar buttons
    ListModel {
    id: pdfviewHelpModel

        ListElement { name: "Back"; button: "cancel" }
        ListElement { name: "Scroll"; button: "up" }
    }

    onPdfPathChanged: {
        pdfFlickable.contentY = 0;
    }

    onFocusChanged: {
        if (focus) {
            currentHelpbarModel = pdfviewHelpModel;
        }
    }
}
