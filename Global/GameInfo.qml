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

import QtQuick 2.0
import QtQuick.Layouts 1.11
import "qrc:/qmlutils" as PegasusUtils

Item {
id: infocontainer

    property var gameData: currentGame

    // Game title
    Text {
    id: gametitle
        
        text: gameData ? gameData.title : ""
        
        anchors {
            top:    parent.top;
            left:   parent.left;
            right:  parent.right
        }
        
        color: theme.text
        font.family: titleFont.name
        font.pixelSize: vpx(44)
        font.bold: true
        horizontalAlignment: Text.AlignHLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    // Meta data
    RowLayout {
    id: metarow

        height: vpx(50)
        anchors {
            top: gametitle.bottom;
            left: parent.left
            right: parent.right
        }
        spacing: 0

        // Publisher
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
            id: publisherlabel
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Publisher: "
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                font.bold: true
                color: theme.accent
            }
            Text {
                anchors { left: publisherlabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                text: gameData ? (gameData.publisher || "") : ""
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                color: theme.text
                elide: Text.ElideRight
            }
        }

        Rectangle {
            width: vpx(2); height: vpx(30)
            Layout.alignment: Qt.AlignVCenter
            opacity: 0.2
        }

        // Developer
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
            id: developerlabel
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Developer: "
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                font.bold: true
                color: theme.accent
            }
            Text {
                anchors { left: developerlabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                text: gameData ? (gameData.developer || "") : ""
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                color: theme.text
                elide: Text.ElideRight
            }
        }

        Rectangle {
            width: vpx(2); height: vpx(30)
            Layout.alignment: Qt.AlignVCenter
            opacity: 0.2
        }

        // Release Date
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
            id: releaselabel
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Released: "
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                font.bold: true
                color: theme.accent
            }
            Text {
                anchors { left: releaselabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                text: gameData && gameData.releaseDate ? Qt.formatDate(gameData.releaseDate, "MM-dd-yyyy") : ""
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                color: theme.text
                elide: Text.ElideRight
            }
        }

        Rectangle {
            width: vpx(2); height: vpx(30)
            Layout.alignment: Qt.AlignVCenter
            opacity: 0.2
        }

        // Genre
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
            id: genrelabel
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Genre: "
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                font.bold: true
                color: theme.accent
            }
            Text {
                anchors { left: genrelabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                text: gameData ? gameData.genre : ""
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                color: theme.text
                elide: Text.ElideRight
            }
        }

        Rectangle {
            width: vpx(2); height: vpx(30)
            Layout.alignment: Qt.AlignVCenter
            opacity: 0.2
        }

        // Players
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
            id: playerslabel
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Players: "
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                font.bold: true
                color: theme.accent
            }
            Text {
                anchors { left: playerslabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                text: gameData ? gameData.players : ""
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                color: theme.text
                elide: Text.ElideRight
            }
        }

        Rectangle {
            width: vpx(2); height: vpx(30)
            Layout.alignment: Qt.AlignVCenter
            opacity: 0.2
        }

        // Rating
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
            id: ratinglabel
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Rating: "
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                font.bold: true
                color: theme.accent
            }
            Text {
                property real processedRating: gameData ? Math.round(gameData.rating * 100) / 10 : 0
                anchors { left: ratinglabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                text: steam ? processedRating * 5 : processedRating
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                color: theme.text
                elide: Text.ElideRight
            }
        }
    }

    // Description
    PegasusUtils.AutoScroll
    {
    id: gameDescription
    
        anchors {
            left: parent.left; 
            right: parent.right;
            top: metarow.bottom
            bottom: parent.bottom;
        }

        Text {
            width: parent.width
            text: gameData && (gameData.summary || gameData.description) ? gameData.description || gameData.summary : "No description available"
            font.pixelSize: vpx(16)
            font.family: bodyFont.name
            color: theme.text
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
        }
    }
    
}