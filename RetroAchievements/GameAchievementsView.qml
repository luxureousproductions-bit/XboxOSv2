// XboxOSv2 – Per-game achievements list
// Redesigned in the style of retromega-sleipnir with the XboxOSv2 colour scheme.
// Layout:
//   ─ brand header (60 px): "Retro Achievements" title + user avatar / name / pts
//   ─ game summary bar (100 px): game icon, title, platform, completion %, progress bar
//   ─ scrollable achievement list (fills remaining space)
//
// Each achievement row:  [badge] [title + HC pill + description] [pts + relative date]
// Unearned achievements are dimmed; the badge is shown at 25 % opacity instead
// of a separate dark lock overlay.

import QtQuick 2.0
import "../Global"

FocusScope {
id: root

    anchors.fill: parent

    property int currentIndex: 0

    // Returns a human-readable string for when an achievement was earned.
    // ts is the Unix-millisecond timestamp stored in DateEarned (0 = locked).
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
            currentHelpbarModel = gameAchievementsHelpModel;
            currentIndex = 0;
        }
    }

    // ── Background ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: theme.main
    }

    // ── Brand header ─────────────────────────────────────────────────────
    // Mirrors the header of AchievementsView: "Retro Achievements" on the left,
    // the logged-in user's avatar / name / points on the right.
    Item {
    id: brandHeader

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(60)

        Text {
            anchors {
                left: parent.left; leftMargin: globalMargin
                verticalCenter: parent.verticalCenter
            }
            text: "Retro Achievements"
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: vpx(24)
            font.bold: true
        }

        // User avatar + name + points (top-right)
        Row {
            anchors {
                right: parent.right; rightMargin: globalMargin
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(10)
            visible: cheevosData.raUserName !== ""

            Image {
                width: vpx(38); height: vpx(38)
                source: cheevosData.avatarUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                visible: cheevosData.avatarUrl !== ""
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(1)

                Text {
                    text: cheevosData.raUserName
                    color: theme.text
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(14)
                    font.bold: true
                }
                Text {
                    text: cheevosData.pointsText
                    color: theme.text
                    font.family: bodyFont.name
                    font.pixelSize: vpx(11)
                    opacity: 0.65
                    visible: cheevosData.pointsText !== ""
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
    // Prominently displays the game icon, title, platform, completion percentage
    // and a thin progress bar along the bottom edge.
    Item {
    id: gameSummary

        anchors {
            top: brandHeader.bottom
            left: parent.left; right: parent.right
        }
        height: vpx(100)

        // Subtle tint to distinguish this section from the list
        Rectangle {
            anchors.fill: parent
            color:   theme.secondary
            opacity: 0.10
        }

        // Game icon (left edge)
        Item {
        id: summaryIcon

            anchors {
                left: parent.left; leftMargin: globalMargin
                verticalCenter: parent.verticalCenter
            }
            width: vpx(70); height: vpx(70)

            Rectangle {
                anchors.fill: parent
                color:   theme.secondary
                radius:  vpx(6)
                opacity: 0.5
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
                sourceSize { width: 80; height: 80 }
            }
        }

        // Completion stats column (right-aligned)
        Column {
        id: statsCol

            visible: cheevosData.currentGameDetails.NumAchievements > 0
            anchors {
                right: parent.right; rightMargin: globalMargin
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(3)

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
                font.pixelSize: vpx(30)
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
                font.family: bodyFont.name
                font.pixelSize: vpx(12)
                opacity: 0.6
                horizontalAlignment: Text.AlignRight
                anchors.right: parent.right
            }
        }

        // Game title + platform name (fills the space between icon and stats)
        Column {
            anchors {
                left:  summaryIcon.right; leftMargin:  vpx(14)
                right: cheevosData.currentGameDetails.NumAchievements > 0
                       ? statsCol.left : parent.right
                rightMargin: vpx(12)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(5)

            Text {
                text: cheevosData.currentGameDetails.Title
                color: theme.text
                font.family: titleFont.name
                font.pixelSize: vpx(20)
                font.bold: true
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: cheevosData.currentGameDetails.ConsoleName
                color: theme.text
                font.family: bodyFont.name
                font.pixelSize: vpx(13)
                opacity: 0.55
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Thin progress bar along the bottom edge of the summary bar
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
            top:    gameSummary.bottom;  topMargin:    vpx(6)
            bottom: parent.bottom;       bottomMargin: helpMargin + vpx(6)
            left:   parent.left;         leftMargin:   globalMargin
            right:  parent.right;        rightMargin:  globalMargin
        }

        model: cheevosData.raGameCheevos
        currentIndex: root.currentIndex
        clip: true

        highlightMoveDuration: 120
        preferredHighlightBegin: height / 2 - vpx(42)
        preferredHighlightEnd:   height / 2 + vpx(42)
        highlightRangeMode: ListView.ApplyRange

        highlight: Rectangle {
            color:   theme.accent
            opacity: 0.18
            radius:  vpx(6)
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
            height: vpx(84)

            property bool isSelected: ListView.isCurrentItem && achievementList.focus
            property bool isEarned:   DateEarned > 0

            // ── Row content ──────────────────────────────────────────────
            // Uses Item+anchors (rather than Row) so the badge can take its
            // full natural height without manual width arithmetic.
            Item {
                anchors {
                    fill:         parent
                    leftMargin:   vpx(6)
                    rightMargin:  vpx(6)
                    topMargin:    vpx(8)
                    bottomMargin: vpx(8)
                }

                // Badge image – square, fills the content area height
                Item {
                id: badge

                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: height // square

                    Rectangle {
                        anchors.fill: parent
                        color:   theme.secondary
                        radius:  vpx(6)
                        opacity: isEarned ? 0.25 : 0.5
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
                        // Unearned: shown at 25 % opacity (no separate lock overlay needed)
                        opacity: isEarned ? 1.0 : 0.25
                    }
                }

                // Points + earned date (right column, fixed width)
                Column {
                id: pointsCol

                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width:   vpx(90)
                    spacing: vpx(6)

                    // Point value, e.g. "25 pts"
                    Text {
                        text: Points + " pts"
                        color: isEarned ? theme.accent : theme.text
                        font.family:    subtitleFont.name
                        font.pixelSize: vpx(15)
                        font.bold:      true
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isEarned ? (isSelected ? 1.0 : 0.85) : 0.3
                    }
                    // "Earned 3 days ago" / "Earned yesterday" / "Locked"
                    Text {
                        text: root.earnedText(DateEarned)
                        color: theme.text
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(10)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        wrapMode: Text.WordWrap
                        opacity: isEarned ? (isSelected ? 0.7 : 0.45) : 0.25
                    }
                }

                // Title + description (fills remaining centre space)
                Column {
                    anchors {
                        left:  badge.right;     leftMargin:  vpx(12)
                        right: pointsCol.left;  rightMargin: vpx(8)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: vpx(5)

                    // Title row: name + optional "HC" pill
                    Row {
                        spacing: vpx(6)
                        width:   parent.width

                        Text {
                        id: achievTitle

                            text:  Title
                            color: isSelected ? theme.accent : theme.text
                            font.family:    subtitleFont.name
                            font.pixelSize: vpx(15)
                            font.bold:      true
                            elide: Text.ElideRight
                            width: parent.width
                                   - (hcPill.visible ? hcPill.width + vpx(6) : 0)
                            opacity: isEarned
                                     ? (isSelected ? 1.0 : 0.9)
                                     : (isSelected ? 0.65 : 0.38)
                        }

                        // "HC" badge for hardcore-earned achievements
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
                        font.pixelSize: vpx(12)
                        elide: Text.ElideRight
                        width: parent.width
                        opacity: isEarned
                                 ? (isSelected ? 0.7 : 0.5)
                                 : (isSelected ? 0.42 : 0.26)
                    }
                }
            }

            // Row divider
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height:  vpx(1)
                color:   theme.text
                opacity: 0.06
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
        // Details → open the full RA overview (recently-played list)
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            achievementsScreen();
        }
        // Filters → refresh current game
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (cheevosData.currentGameDetails.Title !== "")
                cheevosData.loadGameAchievements(cheevosData.currentGameID);
        }
    }

    // ── Help bar ─────────────────────────────────────────────────────────
    ListModel {
    id: gameAchievementsHelpModel
        ListElement { name: "Back";     button: "cancel"  }
        ListElement { name: "Overview"; button: "details" }
        ListElement { name: "Refresh";  button: "filters" }
    }
}
