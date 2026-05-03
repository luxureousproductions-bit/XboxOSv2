// XboxOSv2 – Per-game achievements list
// Layout matches retromega-sleipnir with XboxOSv2 colour scheme.
//
// ─ Header (72 px): avatar + name + points (left)
// ─ Game summary bar (110 px):
//     LEFT  – game title (very large) + platform (bold, smaller)
//     CENTER-RIGHT – large "%" in accent + "N of M" below
//     FAR RIGHT – game icon (square, fills bar height)
// ─ Achievement list rows (84 px):
//     LEFT  – badge (square, fills row height)
//     CENTER – title + HC pill + description
//     RIGHT – "N points" (accent) + "Locked"/"Earned N ago"

import QtQuick 2.0
import "../Global"

FocusScope {
id: root

    anchors.fill: parent

    property int currentIndex: 0

    // Returns a human-readable string for when an achievement was earned.
    function earnedText(ts) {
        if (!ts) return "Locked";
        var s = Math.floor((Date.now() - ts) / 1000);
        if (s < 120)  return "Earned just now";
        var m = Math.floor(s / 60);
        if (m < 60)   return "Earned " + m + " min ago";
        var h = Math.floor(m / 60);
        if (h < 24)   return h === 1 ? "Earned 1 hr ago" : "Earned " + h + " hrs ago";
        var d = Math.floor(h / 24);
        if (d === 1)  return "Earned yesterday";
        if (d < 365)  return "Earned " + d + " days ago";
        return Qt.formatDate(new Date(ts), "MMM d, yyyy");
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            currentHelpbarModel = null;   // hide global bar; we draw our own bottom-left bar
            currentIndex = 0;
        }
    }

    // ── Background ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: theme.main
    }

    // ── Header: RA logo + avatar + name + points ─────────────────────────
    Item {
    id: brandHeader

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(110)

        // RetroAchievements logo – anchored directly to fill the full header height
        Image {
        id: gaRaLogo

            anchors {
                left: parent.left; leftMargin: vpx(5)
                top: parent.top; bottom: parent.bottom
                topMargin: vpx(4); bottomMargin: vpx(4)
            }
            width: height
            source: "../assets/images/icon_ra.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
        }

        Row {
            anchors {
                left: gaRaLogo.right; leftMargin: vpx(12)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(12)

            // User avatar (hidden until logged in)
            Image {
                width: vpx(48); height: vpx(48)
                source: cheevosData.avatarUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                visible: cheevosData.avatarUrl !== ""
            }

            // Username + points
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(2)
                visible: cheevosData.raUserName !== ""

                Text {
                    text: cheevosData.raUserName
                    color: theme.text
                    font.family: titleFont.name
                    font.pixelSize: vpx(24)
                    font.bold: true
                }
                Text {
                    text: cheevosData.pointsText
                    color: theme.text
                    font.family: bodyFont.name
                    font.pixelSize: vpx(16)
                    opacity: 0.65
                    visible: cheevosData.raUserName !== ""
                }
            }
        }

        // ── Top-right: 12hr clock + battery icon ─────────────────────────
        Row {
            anchors {
                right: parent.right; rightMargin: vpx(10)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(14)

            // 12-hour clock
            Text {
                id: gaClockText
                function set() { gaClockText.text = Qt.formatTime(new Date(), "h:mm AP") }
                Timer {
                    interval: 60000; repeat: true; running: true; triggeredOnStart: true
                    onTriggered: gaClockText.set()
                }
                color: theme.text
                font.family: subtitleFont.name
                font.pixelSize: vpx(22)
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            // Battery icon (drawn in QML)
            Item {
                width: vpx(32); height: vpx(16)
                anchors.verticalCenter: parent.verticalCenter
                // Battery body
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: parent.width - vpx(4)
                    color: "transparent"
                    border.color: theme.text
                    border.width: vpx(2)
                    radius: vpx(2)
                    opacity: 0.8
                    // Battery fill (real device percentage)
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: vpx(3) }
                        width: parent.width * Math.max(0, Math.min(1, api.device.batteryPercent))
                        color: theme.text
                        radius: vpx(1)
                        opacity: 0.9
                    }
                }
                // Battery nub
                Rectangle {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: vpx(4); height: vpx(8)
                    color: theme.text
                    radius: vpx(1)
                    opacity: 0.8
                }
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(1)
            color: theme.text
            opacity: 0.1
        }
    }

    // ── Game summary bar ─────────────────────────────────────────────────
    // Title + platform left; completion % + count center-right; icon far right.
    Item {
    id: gameSummary

        anchors {
            top: brandHeader.bottom
            left: parent.left; right: parent.right
        }
        height: vpx(110)

        // Subtle background tint
        Rectangle {
            anchors.fill: parent
            color:   theme.secondary
            opacity: 0.10
        }

        // ── Game icon – far RIGHT, square, fills bar height ───────────────
        Item {
        id: summaryIcon

            anchors {
                right: parent.right
                top: parent.top; bottom: parent.bottom
            }
            width: height // square

            Rectangle {
                anchors.fill: parent
                color:   theme.secondary
                opacity: 0.4
            }
            Image {
                anchors.fill: parent
                source: cheevosData.currentGameDetails.ImageIcon
                        ? "https://media.retroachievements.org"
                          + cheevosData.currentGameDetails.ImageIcon
                        : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                sourceSize { width: 120; height: 120 }
            }
        }

        // ── Completion stats – right side, left of icon ───────────────────
        Column {
        id: statsCol

            visible: cheevosData.currentGameDetails.NumAchievements > 0
            anchors {
                right: summaryIcon.left; rightMargin: vpx(20)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(4)

            property int awarded:  cheevosData.currentGameDetails.NumAwardedToUser
            property int total:    cheevosData.currentGameDetails.NumAchievements
            property int hardcore: cheevosData.currentGameDetails.NumAwardedToUserHardcore

            // Large completion percentage
            Text {
                text: statsCol.total > 0
                      ? Math.floor(statsCol.awarded * 100 / statsCol.total) + "%"
                      : ""
                color: theme.accent
                font.family: titleFont.name
                font.pixelSize: vpx(42)
                font.bold: true
                horizontalAlignment: Text.AlignRight
                anchors.right: parent.right
            }
            // "12 of 16" or "12 of 16  ·  4 HC"
            Text {
                text: {
                    var s = statsCol.awarded + " of " + statsCol.total;
                    if (statsCol.hardcore > 0) s += "  ·  " + statsCol.hardcore + " HC";
                    return s;
                }
                color: theme.text
                font.family: subtitleFont.name
                font.pixelSize: vpx(18)
                font.bold: true
                opacity: 0.75
                horizontalAlignment: Text.AlignRight
                anchors.right: parent.right
            }
        }

        // ── Game title + platform – left side ─────────────────────────────
        Column {
            anchors {
                left:  parent.left; leftMargin: globalMargin
                right: cheevosData.currentGameDetails.NumAchievements > 0
                       ? statsCol.left : summaryIcon.left
                rightMargin: vpx(12)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(6)

            Text {
                text: cheevosData.currentGameDetails.Title
                color: theme.text
                font.family: titleFont.name
                font.pixelSize: vpx(28)
                font.bold: true
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: cheevosData.currentGameDetails.ConsoleName
                color: theme.text
                font.family: subtitleFont.name
                font.pixelSize: vpx(18)
                font.bold: true
                opacity: 0.65
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Thin progress bar along the bottom edge
        Item {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(4)
            visible: cheevosData.currentGameDetails.NumAchievements > 0

            Rectangle {
                anchors.fill: parent
                color:   theme.text
                opacity: 0.12
            }
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: cheevosData.currentGameDetails.NumAchievements > 0
                       ? parent.width
                         * (cheevosData.currentGameDetails.NumAwardedToUser
                            / cheevosData.currentGameDetails.NumAchievements)
                       : 0
                color: theme.accent
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }
    }

    // ── Achievement list ─────────────────────────────────────────────────
    ListView {
    id: achievementList

        anchors {
            top:    gameSummary.bottom;  topMargin:    vpx(0)
            bottom: parent.bottom;       bottomMargin: vpx(56)
            left:   parent.left
            right:  parent.right
        }

        model: cheevosData.raGameCheevos
        currentIndex: root.currentIndex
        clip: true

        highlightMoveDuration: 100
        preferredHighlightBegin: vpx(96)
        preferredHighlightEnd:   height - vpx(96)
        highlightRangeMode: ListView.ApplyRange

        // Solid-ish accent highlight matching the sleipnir style
        highlight: Rectangle {
            color:   theme.accent
            opacity: 0.55
            radius:  vpx(0)
            width:   achievementList.width
        }

        // Status / empty-state message
        Text {
            anchors.centerIn: parent
            visible: cheevosData.raGameCheevos.count === 0
            text:    cheevosData.statusText || "No achievements found"
            color:   theme.text
            font.family: bodyFont.name
            font.pixelSize: vpx(18)
            opacity: 0.5
        }

        delegate: Item {
        id: achievementRow

            width:  achievementList.width
            height: vpx(96)

            property bool isSelected: ListView.isCurrentItem && achievementList.focus
            property bool isEarned:   DateEarned > 0

            // ── Row inner layout ─────────────────────────────────────────
            Item {
                anchors {
                    fill:         parent
                    leftMargin:   vpx(0)
                    rightMargin:  vpx(globalMargin)
                }

                // Badge – square, fills full row height (left edge)
                Item {
                id: badge

                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: height // square

                    Rectangle {
                        anchors.fill: parent
                        color:   theme.secondary
                        opacity: isEarned ? 0.2 : 0.45
                    }
                    Image {
                        anchors.fill: parent
                        source: BadgeName !== ""
                                ? "https://media.retroachievements.org/Badge/"
                                  + BadgeName + ".png"
                                : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        sourceSize { width: 64; height: 64 }
                        opacity: isEarned ? 1.0 : 0.25
                    }
                }

                // Points + earned/locked (right column, fixed width)
                Column {
                id: pointsCol

                    anchors { right: parent.right; rightMargin: vpx(0); verticalCenter: parent.verticalCenter }
                    width: vpx(120)
                    spacing: vpx(6)

                    Text {
                        text: Points + " points"
                        color: isEarned ? theme.accent : theme.text
                        font.family:    subtitleFont.name
                        font.pixelSize: vpx(18)
                        font.bold:      true
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isEarned ? (isSelected ? 1.0 : 0.9) : 0.35
                    }
                    Text {
                        text: root.earnedText(DateEarned)
                        color: theme.text
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(14)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        wrapMode: Text.WordWrap
                        opacity: isEarned ? (isSelected ? 0.75 : 0.5) : 0.3
                    }
                }

                // Title + description (centre)
                Column {
                    anchors {
                        left:  badge.right;     leftMargin:  vpx(14)
                        right: pointsCol.left;  rightMargin: vpx(10)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: vpx(6)

                    // Title row: name + optional "HC" pill
                    Row {
                        spacing: vpx(6)
                        width:   parent.width

                        Text {
                        id: achievTitle

                            text:  Title
                            color: theme.text
                            font.family:    titleFont.name
                            font.pixelSize: vpx(20)
                            font.bold:      true
                            elide: Text.ElideRight
                            width: parent.width
                                   - (hcPill.visible ? hcPill.width + vpx(6) : 0)
                            opacity: isEarned
                                     ? (isSelected ? 1.0 : 0.9)
                                     : (isSelected ? 0.65 : 0.4)
                        }

                        Rectangle {
                        id: hcPill

                            visible: isEarned && Hardcore
                            width:   vpx(26); height: vpx(16)
                            radius:  vpx(3)
                            color:   theme.accent
                            anchors.verticalCenter: achievTitle.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text:  "HC"
                                color: theme.text
                                font.family:    bodyFont.name
                                font.pixelSize: vpx(9)
                                font.bold:      true
                            }
                        }
                    }

                    Text {
                        text:  Description
                        color: theme.text
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(15)
                        elide: Text.ElideRight
                        width: parent.width
                        opacity: isEarned
                                 ? (isSelected ? 0.75 : 0.55)
                                 : (isSelected ? 0.45 : 0.28)
                    }
                }
            }

            // Row divider
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height:  vpx(1)
                color:   theme.text
                opacity: 0.08
            }

            // Mouse / touch
            MouseArea {
                anchors.fill: parent
                hoverEnabled: settings.MouseHover === "Yes"
                onEntered: { sfxNav.play(); root.currentIndex = index; }
                onClicked: { sfxNav.play(); root.currentIndex = index; }
            }
        }
    }

    // ── Page counter (bottom-right) ───────────────────────────────────────
    Text {
        visible: cheevosData.raGameCheevos.count > 0
        anchors {
            right:  parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: vpx(10)
        }
        text: (root.currentIndex + 1) + " of " + cheevosData.raGameCheevos.count
        color: theme.text
        font.family: bodyFont.name
        font.pixelSize: vpx(22)
        font.bold: true
        opacity: 0.75
    }

    // ── Local help bar (bottom-left) ─────────────────────────────────────
    Row {
        anchors {
            left: parent.left; leftMargin: globalMargin
            bottom: parent.bottom; bottomMargin: vpx(10)
        }
        spacing: vpx(20)

        Repeater {
            model: localHelpModel
            delegate: Row {
                spacing: vpx(8)
                Image {
                    source: "../assets/images/controller/"
                            + buttonbar.processButtonArt(button) + ".png"
                    width: vpx(36); height: vpx(36)
                    asynchronous: true
                }
                Text {
                    text: name
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(22)
                    color: theme.text
                    height: vpx(36)
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    ListModel {
    id: localHelpModel
        ListElement { name: "Back";     button: "cancel"  }
        ListElement { name: "Refresh";  button: "details" }
        ListElement { name: "Overview"; button: "filters" }
    }

    // ── Key handling ─────────────────────────────────────────────────────

    Keys.onUpPressed: {
        event.accepted = true;
        sfxNav.play();
        if (currentIndex > 0) currentIndex--;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        sfxNav.play();
        if (currentIndex < cheevosData.raGameCheevos.count - 1) currentIndex++;
    }
    Keys.onPressed: {
        // Cancel → back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        // Filters → open the full RA overview (recently-played list)
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            achievementsScreen();
        }
        // Details → refresh current game
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (cheevosData.currentGameDetails.Title !== "")
                cheevosData.loadGameAchievements(cheevosData.currentGameID);
        }
    }

    // ── Help bar ─────────────────────────────────────────────────────────
    // (local left-aligned bar is drawn above; no global model needed)
}
