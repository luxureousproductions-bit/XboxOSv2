// XboxOSv2 – GameAchievementsView.qml
// Per-game achievements list with filter tabs and sort controls.
//
// Enhancements over v1:
//   • Filter tabs: All / Earned / Locked  (L1 / R1 or left bumper / right bumper)
//   • Sort toggle: Default / Points / Rarity / Date  (Y button)
//   • Rarity % label on each achievement row
//   • TrueRatio (RetroPoints) shown alongside regular points
//   • Animated progress bar already existed — kept and improved
//   • Shared RAStatusBar — no duplicate clock/battery timer
//   • cacheBuffer on ListView for smooth Android scrolling
//   • sourceSize on all network images

import QtQuick 2.15
import "../Global"

FocusScope {
id: root

    anchors.fill: parent

    property int currentIndex: 0

    // Resolved list used by the ListView (from CheevosData.filteredCheevos)
    property var displayList: cheevosData.filteredCheevos

    onDisplayListChanged: {
        // Clamp index when the filtered list shrinks
        if (currentIndex >= displayList.length && displayList.length > 0)
            currentIndex = displayList.length - 1;
    }

    // ── Relative time helpers ─────────────────────────────────────────────
    function earnedText(ts) {
        if (!ts || ts === 0) return "Locked";
        var s = Math.floor((Date.now() - ts) / 1000);
        if (s < 120)  return "Just now";
        var m = Math.floor(s / 60);
        if (m < 60)   return m + " min ago";
        var h = Math.floor(m / 60);
        if (h < 24)   return h === 1 ? "1 hr ago" : h + " hrs ago";
        var d = Math.floor(h / 24);
        if (d === 1)  return "Yesterday";
        if (d < 365)  return d + " days ago";
        return Qt.formatDate(new Date(ts), "MMM d, yyyy");
    }

    function rarityLabel(pct) {
        if (pct <= 0)   return "";
        if (pct < 5)    return "Ultra Rare  " + pct + "%";
        if (pct < 15)   return "Very Rare  "  + pct + "%";
        if (pct < 30)   return "Rare  "        + pct + "%";
        if (pct < 55)   return "Uncommon  "    + pct + "%";
        return "Common  " + pct + "%";
    }

    function rarityColor(pct) {
        if (pct <= 0)  return theme.text;
        if (pct < 5)   return "#FFD700";   // gold   — ultra rare
        if (pct < 15)  return "#E040FB";   // purple — very rare
        if (pct < 30)  return "#29B6F6";   // blue   — rare
        if (pct < 55)  return "#66BB6A";   // green  — uncommon
        return theme.text;                  // default — common
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────
    onActiveFocusChanged: {
        if (activeFocus) {
            currentHelpbarModel = null;
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
            sourceSize { width: 96; height: 96 }
        }

        Row {
            anchors {
                left: gaRaLogo.right; leftMargin: vpx(12)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(12)

            Image {
                width: vpx(56); height: vpx(56)
                source: cheevosData.avatarUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                sourceSize { width: 64; height: 64 }
                visible: cheevosData.avatarUrl !== ""
            }

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
                    font.pixelSize: vpx(15)
                    opacity: 0.65
                }
                Text {
                    text: cheevosData.memberText
                    color: theme.text
                    font.family: bodyFont.name
                    font.pixelSize: vpx(13)
                    opacity: 0.45
                    visible: cheevosData.memberText !== ""
                }
            }
        }

        RAStatusBar {
            anchors {
                right: parent.right; rightMargin: vpx(10)
                verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(1); color: theme.text; opacity: 0.1
        }
    }

    // ── Game summary bar ─────────────────────────────────────────────────
    Item {
    id: gameSummary

        anchors { top: brandHeader.bottom; left: parent.left; right: parent.right }
        height: vpx(110)

        Rectangle { anchors.fill: parent; color: theme.secondary; opacity: 0.10 }

        // Game icon — far right
        Item {
        id: summaryIcon
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: height

            Rectangle { anchors.fill: parent; color: theme.secondary; opacity: 0.4 }
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

        // Completion stats — right of icon area
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

            Text {
                text: statsCol.total > 0
                      ? Math.floor(statsCol.awarded * 100 / statsCol.total) + "%"
                      : ""
                color: {
                    if (statsCol.total === 0) return theme.accent;
                    var p = Math.floor(statsCol.awarded * 100 / statsCol.total);
                    return p >= 100 ? "#FFD700" : theme.accent;
                }
                font.family: titleFont.name
                font.pixelSize: vpx(40)
                font.bold: true
                horizontalAlignment: Text.AlignRight
                anchors.right: parent.right
            }
            Text {
                text: {
                    var s = statsCol.awarded + " of " + statsCol.total;
                    if (statsCol.hardcore > 0) s += "  ·  " + statsCol.hardcore + " HC";
                    return s;
                }
                color: theme.text
                font.family: subtitleFont.name
                font.pixelSize: vpx(17)
                font.bold: true
                opacity: 0.75
                horizontalAlignment: Text.AlignRight
                anchors.right: parent.right
            }
        }

        // Game title + platform — left side
        Column {
            anchors {
                left:  parent.left; leftMargin: globalMargin
                right: cheevosData.currentGameDetails.NumAchievements > 0
                       ? statsCol.left : summaryIcon.left
                rightMargin: vpx(12)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(5)

            Text {
                text: cheevosData.currentGameDetails.Title
                color: theme.text
                font.family: titleFont.name
                font.pixelSize: vpx(26)
                font.bold: true
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: cheevosData.currentGameDetails.ConsoleName
                color: theme.text
                font.family: subtitleFont.name
                font.pixelSize: vpx(17)
                font.bold: true
                opacity: 0.65
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Animated progress bar — bottom edge of summary bar
        Item {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(5)
            visible: cheevosData.currentGameDetails.NumAchievements > 0

            Rectangle { anchors.fill: parent; color: theme.text; opacity: 0.12 }
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: cheevosData.currentGameDetails.NumAchievements > 0
                       ? parent.width
                         * (cheevosData.currentGameDetails.NumAwardedToUser
                            / cheevosData.currentGameDetails.NumAchievements)
                       : 0
                color: {
                    if (cheevosData.currentGameDetails.NumAchievements === 0) return theme.accent;
                    var p = cheevosData.currentGameDetails.NumAwardedToUser
                            / cheevosData.currentGameDetails.NumAchievements;
                    return p >= 1.0 ? "#FFD700" : theme.accent;
                }
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ── Filter tabs + sort button ─────────────────────────────────────────
    Item {
    id: filterBar

        anchors { top: gameSummary.bottom; left: parent.left; right: parent.right }
        height: vpx(44)

        Rectangle { anchors.fill: parent; color: theme.secondary; opacity: 0.06 }

        Row {
            anchors { left: parent.left; leftMargin: globalMargin; verticalCenter: parent.verticalCenter }
            spacing: vpx(6)

            Repeater {
                model: [
                    { label: "All",    mode: "all",    count: cheevosData.raGameCheevos.count },
                    { label: "Earned", mode: "earned", count: cheevosData.countEarned },
                    { label: "Locked", mode: "locked", count: cheevosData.countLocked }
                ]

                delegate: Rectangle {
                    property bool active: cheevosData.filterMode === modelData.mode
                    width:  tabLabel.implicitWidth + vpx(20)
                    height: vpx(28)
                    radius: vpx(4)
                    color:  active ? theme.accent : theme.secondary
                    opacity: active ? 1.0 : 0.5

                    Behavior on color   { ColorAnimation  { duration: 150 } }
                    Behavior on opacity { NumberAnimation  { duration: 150 } }

                    Text {
                    id: tabLabel
                        anchors.centerIn: parent
                        text: modelData.label + " (" + modelData.count + ")"
                        color: theme.text
                        font.family: subtitleFont.name
                        font.pixelSize: vpx(14)
                        font.bold: active
                    }
                }
            }
        }

        // Sort toggle — right side
        Row {
            anchors { right: parent.right; rightMargin: globalMargin; verticalCenter: parent.verticalCenter }
            spacing: vpx(6)

            Text {
                text: "Sort:"
                color: theme.text
                font.family: subtitleFont.name
                font.pixelSize: vpx(14)
                opacity: 0.55
                anchors.verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: [
                    { label: "Default", mode: "default" },
                    { label: "Points",  mode: "points"  },
                    { label: "Rarity",  mode: "rarity"  },
                    { label: "Date",    mode: "date"     }
                ]

                delegate: Rectangle {
                    property bool active: cheevosData.sortMode === modelData.mode
                    width:  sortLbl.implicitWidth + vpx(14)
                    height: vpx(24)
                    radius: vpx(3)
                    color:  active ? theme.accent : "transparent"
                    opacity: active ? 1.0 : 0.45

                    Behavior on color   { ColorAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    Text {
                    id: sortLbl
                        anchors.centerIn: parent
                        text: modelData.label
                        color: theme.text
                        font.family: subtitleFont.name
                        font.pixelSize: vpx(13)
                        font.bold: active
                    }
                }
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(1); color: theme.text; opacity: 0.07
        }
    }

    // ── Achievement list ─────────────────────────────────────────────────
    ListView {
    id: achievementList

        anchors {
            top:    filterBar.bottom;  topMargin:    vpx(0)
            bottom: parent.bottom;     bottomMargin: vpx(56)
            left:   parent.left
            right:  parent.right
        }

        model:        root.displayList
        currentIndex: root.currentIndex
        clip:         true
        cacheBuffer:  vpx(300)

        highlightMoveDuration: 100
        preferredHighlightBegin: vpx(96)
        preferredHighlightEnd:   height - vpx(96)
        highlightRangeMode: ListView.ApplyRange

        highlight: Rectangle {
            color:   theme.accent
            opacity: 0.45
            width:   achievementList.width
        }

        // Empty / loading state
        Text {
            anchors.centerIn: parent
            visible: root.displayList.length === 0
            text:    cheevosData.statusText || "No achievements to show"
            color:   theme.text
            font.family: bodyFont.name
            font.pixelSize: vpx(18)
            opacity: 0.5
        }

        delegate: Item {
        id: achievementRow

            // JS array model — access via modelData
            property var  ach:        modelData
            property bool isSelected: ListView.isCurrentItem && achievementList.focus
            property bool isEarned:   ach.DateEarned > 0

            width:  achievementList.width
            height: vpx(100)

            Item {
                anchors { fill: parent; rightMargin: vpx(globalMargin) }

                // Badge — square, left edge
                Item {
                id: badge
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: height

                    Rectangle {
                        anchors.fill: parent
                        color:        theme.secondary
                        opacity:      isEarned ? 0.2 : 0.45
                    }
                    Image {
                        anchors.fill: parent
                        source: ach.BadgeName !== ""
                                ? "https://media.retroachievements.org/Badge/"
                                  + ach.BadgeName + (isEarned ? "" : "_lock") + ".png"
                                : ""
                        fillMode:    Image.PreserveAspectFit
                        smooth:      true
                        asynchronous: true
                        sourceSize { width: 64; height: 64 }
                        opacity: isEarned ? 1.0 : 0.28
                    }
                }

                // Points + rarity + earned status — right column
                Column {
                id: pointsCol
                    anchors {
                        right: parent.right; rightMargin: vpx(0)
                        verticalCenter: parent.verticalCenter
                    }
                    width: vpx(130)
                    spacing: vpx(4)

                    // Points (+ TrueRatio if different)
                    Text {
                        text: {
                            var s = ach.Points + " pts";
                            if (ach.TrueRatio && ach.TrueRatio !== ach.Points)
                                s += "  (" + ach.TrueRatio + ")";
                            return s;
                        }
                        color: isEarned ? theme.accent : theme.text
                        font.family:    subtitleFont.name
                        font.pixelSize: vpx(17)
                        font.bold:      true
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isEarned ? (isSelected ? 1.0 : 0.9) : 0.35
                    }

                    // Rarity label
                    Text {
                        text: root.rarityLabel(ach.Rarity)
                        color: root.rarityColor(ach.Rarity)
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(12)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isSelected ? 0.95 : 0.6
                        visible: ach.Rarity > 0
                    }

                    // Earned time or "Locked"
                    Text {
                        text: root.earnedText(ach.DateEarned)
                        color: theme.text
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(13)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        wrapMode: Text.WordWrap
                        opacity: isEarned ? (isSelected ? 0.75 : 0.5) : 0.28
                    }
                }

                // Title + description — centre
                Column {
                    anchors {
                        left:  badge.right;     leftMargin:  vpx(14)
                        right: pointsCol.left;  rightMargin: vpx(10)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: vpx(5)

                    // Title + optional HC pill
                    Row {
                        spacing: vpx(6)
                        width:   parent.width

                        Text {
                        id: achievTitle
                            text:  ach.Title
                            color: theme.text
                            font.family:    titleFont.name
                            font.pixelSize: vpx(19)
                            font.bold:      true
                            elide: Text.ElideRight
                            width: parent.width - (hcPill.visible ? hcPill.width + vpx(6) : 0)
                            opacity: isEarned
                                     ? (isSelected ? 1.0 : 0.9)
                                     : (isSelected ? 0.65 : 0.4)
                        }

                        Rectangle {
                        id: hcPill
                            visible: isEarned && ach.Hardcore
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
                        text:  ach.Description
                        color: theme.text
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(14)
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
                height:  vpx(1); color: theme.text; opacity: 0.08
            }

            // Touch
            MouseArea {
                anchors.fill: parent
                hoverEnabled: settings.MouseHover === "Yes"
                onEntered: { sfxNav.play(); root.currentIndex = index; }
                onClicked:  { sfxNav.play(); root.currentIndex = index; }
            }
        }
    }

    // ── Page counter ─────────────────────────────────────────────────────
    Text {
        visible: root.displayList.length > 0
        anchors {
            right:  parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: vpx(10)
        }
        text: (root.currentIndex + 1) + " of " + root.displayList.length
        color: theme.text
        font.family: bodyFont.name
        font.pixelSize: vpx(20)
        font.bold: true
        opacity: 0.75
    }

    // ── Local help bar ────────────────────────────────────────────────────
    Row {
        anchors {
            left: parent.left; leftMargin: globalMargin
            bottom: parent.bottom; bottomMargin: vpx(10)
        }
        spacing: vpx(16)

        Repeater {
            model: localHelpModel
            delegate: Row {
                spacing: vpx(6)
                Image {
                    source: "../assets/images/controller/"
                            + buttonbar.processButtonArt(button) + ".png"
                    width: vpx(32); height: vpx(32)
                    asynchronous: true
                    sourceSize { width: 48; height: 48 }
                }
                Text {
                    text: name
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(19)
                    color: theme.text
                    height: vpx(32)
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    ListModel {
    id: localHelpModel
        ListElement { name: "Overview";  button: "accept"  }
        ListElement { name: "Refresh";   button: "details" }
        ListElement { name: "Sort";      button: "filters" }
        ListElement { name: "Back";      button: "cancel"  }
    }

    // ── Key handling ─────────────────────────────────────────────────────

    // Cycle filter: all → earned → locked → all  (L1 / R1)
    function cycleFilterForward() {
        if      (cheevosData.filterMode === "all")    cheevosData.filterMode = "earned";
        else if (cheevosData.filterMode === "earned") cheevosData.filterMode = "locked";
        else                                          cheevosData.filterMode = "all";
        currentIndex = 0;
    }
    function cycleFilterBack() {
        if      (cheevosData.filterMode === "all")    cheevosData.filterMode = "locked";
        else if (cheevosData.filterMode === "locked") cheevosData.filterMode = "earned";
        else                                          cheevosData.filterMode = "all";
        currentIndex = 0;
    }

    // Cycle sort: default → points → rarity → date → default  (Y)
    function cycleSort() {
        if      (cheevosData.sortMode === "default") cheevosData.sortMode = "points";
        else if (cheevosData.sortMode === "points")  cheevosData.sortMode = "rarity";
        else if (cheevosData.sortMode === "rarity")  cheevosData.sortMode = "date";
        else                                         cheevosData.sortMode = "default";
        currentIndex = 0;
    }

    // Up/Down — scroll achievement list
    Keys.onUpPressed: {
        event.accepted = true;
        sfxNav.play();
        if (currentIndex > 0) currentIndex--;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        sfxNav.play();
        if (currentIndex < root.displayList.length - 1) currentIndex++;
    }

    // D-pad Left/Right — cycle filter tabs
    Keys.onLeftPressed: {
        event.accepted = true;
        sfxNav.play();
        cycleFilterBack();
        currentIndex = 0;
    }
    Keys.onRightPressed: {
        event.accepted = true;
        sfxNav.play();
        cycleFilterForward();
        currentIndex = 0;
    }

    Keys.onPressed: {
        // B — back to games list
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        // LB — cycle filter backward
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            sfxNav.play();
            cycleFilterBack();
            currentIndex = 0;
        }
        // RB — cycle filter forward
        if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            sfxNav.play();
            cycleFilterForward();
            currentIndex = 0;
        }
        // Y / Filters — cycle sort mode
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            sfxNav.play();
            cycleSort();
            currentIndex = 0;
        }
        // X / Details — refresh current game
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (cheevosData.currentGameDetails.Title !== "")
                cheevosData.loadGameAchievements(cheevosData.currentGameID);
        }
        // A — back to RA overview
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            achievementsScreen();
        }
    }
}
