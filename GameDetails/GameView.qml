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
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0
import SortFilterProxyModel 0.2
import QtQml.Models 2.10
import QtMultimedia 5.9
import "../Global"
import "../GridView"
import "../Lists"
import "../utils.js" as Utils

FocusScope {
id: root

    property var game: api.allGames.get(0)
    property string favIcon: game && game.favorite ? "../assets/images/icon_unheart.svg" : "../assets/images/icon_heart.svg"
    property string collectionName: game ? game.collections.get(0).name : ""
    property string collectionShortName: game ? game.collections.get(0).shortName : ""
    property bool iamsteam: game ? (collectionShortName == "steam") : false
    property bool canPlayVideo: settings.VideoPreview === "Yes"
    property real detailsOpacity: (settings.DetailsDefault === "Yes") ? 1 : 0
    property bool blurBG: settings.GameBlurBackground === "Yes"
    property string publisherName: {
        if (game !== null && game.publisher !== null) {
            var str = game.publisher;
            var result = str.split(" ");
            return result[0]
        } else {
            return ""
        }
    }
    
    // --- BEGIN: More section – merged Publisher/Developer list (Option 5) ---
    // publisher/developer/currentTitle are set imperatively in the debounce timer
    // (filterDebounce), followed by an explicit rebuild() call.
    ListPublisherDeveloper {
        id: publisherCollection
        max: 20
    }
    // --- END: More section – merged Publisher/Developer list (Option 5) ---

    // --- BEGIN: More section – Recommended Games fallback ---
    // Shown in place of the Publisher/Developer list when that list is empty.
    // Only affects the "More" section of the Game Details page.
    ListRecommended {
        id: recommendedCollection
        max: 20
        omitApplication: settings.OmitApplicationFromShowcase === "Enable"
        omitEmulator: settings.OmitEmulatorFromShowcase === "Enable"
    }
    // --- END: More section – Recommended Games fallback ---

    // --- BEGIN: More section – main-genre list (Option B: JS array) ---
    // genre/currentTitle are set imperatively in the debounce timer, then
    // rebuild() fires a single JS pass matching only the main genre (left of "/").
    ListGenreExpanded {
        id: genreCollection
        max: 20
    }
    // --- END: More section – main-genre list (Option B: JS array) ---

    // Combine the video and the screenshot arrays into one
    function mediaArray() {
        let mediaList = [];
        if (game && game.assets.video && settings.CarouselVideo === "On")
            game.assets.videoList.forEach(v => mediaList.push(v));

        if (game) {
            if (settings.CarouselScreenshots === "On")
                game.assets.screenshotList.forEach(v => mediaList.push(v));
            if (settings.CarouselTitleScreen === "On" && game.assets.titlescreen)
                mediaList.push(game.assets.titlescreen);
            if (settings.CarouselFanart === "On")
                game.assets.backgroundList.forEach(v => mediaList.push(v));
            var art3d = Utils.get3dBoxArt(game);
            if (settings.Carousel3DBox === "On" && art3d)
                mediaList.push(art3d);
            // In Pegasus, ALL box images (box3d, box2dFront, etc.) are stored in boxFrontList.
            // Push every 2D entry that wasn't already added as the 3D art above.
            if (settings.Carousel2DBox === "On" && game.assets.boxFrontList) {
                game.assets.boxFrontList.forEach(function(url) {
                    if (url && url !== art3d) mediaList.push(url);
                });
            }
            if (settings.CarouselBackBox === "On" && game.assets.boxBack)
                mediaList.push(game.assets.boxBack);
            if (settings.CarouselCartridge === "On" && game.assets.cartridge)
                mediaList.push(game.assets.cartridge);
            // steamList contains all steamgrid/miximage images (UI_STEAMGRID slot in Pegasus).
            // Push all entries so they appear in the media viewer for browsing.
            // getMiximage() separately picks the best one for the box art thumbnail.
            if (settings.CarouselMiximage === "On" && game.assets.steamList) {
                game.assets.steamList.forEach(function(url) {
                    if (url) mediaList.push(url);
                });
            }
            if (game.assets.poster)     mediaList.push(game.assets.poster);
            if (game.assets.banner)     mediaList.push(game.assets.banner);
            if (game.assets.tile)       mediaList.push(game.assets.tile);
            if (settings.CarouselWheel === "On" && game.assets.logo)
                mediaList.push(game.assets.logo);
        }

        return mediaList;
    }

    // Reset the screen to default state
    function reset() {
        content.currentIndex = 0;
        menu.currentIndex = 0;
        media.savedIndex = 0;
        list1.savedIndex = 0;
        list2.savedIndex = 0;
        screenshot.opacity = 1;
        mediaScreen.opacity = 0;
        toggleVideo(true);
        // Defer the "More" list filter updates (Options 1 & 2) so the expensive
        // ExpressionFilter scans don't block the navigation transition.
        filterDebounce.restart();
    }

    // Show/hide the details overlay
    function showDetails() {
        if (detailsOpacity === 1) {
            toggleVideo(true);
            detailsOpacity = 0;
        }
        else {
            detailsOpacity = 1;
            toggleVideo(false);
        }
    }

    // Show/hide the media view
    function showMedia(index) {
        sfxAccept.play();
        mediaScreen.mediaIndex = index;
        mediaScreen.focus = true;
        mediaScreen.opacity = 1;
    }

    function closeMedia() {
        sfxBack.play();
        mediaScreen.opacity = 0;
        content.focus = true;
        currentHelpbarModel = gameviewHelpModel;
    }

    onGameChanged: reset();

    // Pre-computed media list for this game; used by both the strip and the full-screen viewer.
    // Binding to `game` means it is computed once per game change instead of twice.
    readonly property var mediaList: game ? mediaArray() : []

    anchors.fill: parent

    GridSpacer {
    id: fakebox
        
        width: vpx(100); height: vpx(100)
    }

    // Video
    // Show/hide the video
    function toggleVideo(toggle) {
      if (!toggle)
      {
        // Turn off video
        screenshot.opacity = 1;
        stopvideo.restart();
      } else {
        stopvideo.stop();
        // Turn on video
        if (canPlayVideo)
            videoDelay.restart();
      }
    }

    // Timer to show the video
    Timer {
    id: videoDelay

        interval: 2000
        onTriggered: {
            if (game && game.assets.videos.length && canPlayVideo) {
                videoPreviewLoader.sourceComponent = videoPreviewWrapper;
                fadescreenshot.restart();
            }
        }
    }

    // NOTE: Next fade out the bg so there is a smooth transition into the video
    Timer {
    id: fadescreenshot

        interval: 1000
        onTriggered: {
            screenshot.opacity = 0;
            if (blurBG)
                bgBlur.opacity = 0;
        }
    }

    Timer {
    id: stopvideo

        interval: 1000
        onTriggered: {
            videoPreviewLoader.sourceComponent = undefined;
            videoDelay.stop();
            fadescreenshot.stop();
        }
    }

    // Options B & 5: Debounce timer for the "More" list filter inputs.
    // Fires 200 ms after a game change so all scans run after the navigation
    // transition has rendered.
    // Both genre and publisher/developer lists are rebuilt via a single JS pass
    // each (rebuild()) instead of reactive ExpressionFilters.
    // Option 2: recommendedCollection.refresh() is only called when the
    // publisher/developer list comes up empty (avoiding the scan entirely
    // when it's not needed).
    Timer {
    id: filterDebounce

        interval: 200
        onTriggered: {
            var title = game ? game.title : "";

            // Option 5: publisher/developer
            publisherCollection.publisher    = game && game.publisher ? game.publisher : "";
            publisherCollection.developer    = game && game.developer ? game.developer : "";
            publisherCollection.currentTitle = title;
            publisherCollection.rebuild();
            // Refresh the recommended fallback only when the publisher/developer
            // list has no results (Option 2: skip the scan when not needed).
            if (publisherCollection.games.length === 0)
                recommendedCollection.refresh();

            // Option B: genre – extract the correct genre token based on the
            // "More by Genre Display" setting, then trigger a rebuild.
            var genreStr  = game && game.genreList.length > 0 ? game.genreList[0] : "";
            var sepMatch  = genreStr.match(/^(.*?)\s*[\/,]\s*(.+)$/);
            var mainGenre = sepMatch ? sepMatch[1].trim() : genreStr;
            var subGenre  = sepMatch ? sepMatch[2].trim() : mainGenre;
            var modeStr   = settings.MoreByGenreDisplay || "Main Genre";
            var genreTarget, genreMatchMode;
            if (modeStr === "Sub Genre") {
                genreTarget    = subGenre;
                genreMatchMode = "sub";
            } else if (modeStr === "Full") {
                genreTarget    = genreStr;
                genreMatchMode = "full";
            } else {
                genreTarget    = mainGenre;
                genreMatchMode = "main";
            }
            genreCollection.genre        = genreTarget;
            genreCollection.matchMode    = genreMatchMode;
            genreCollection.currentTitle = title;
            genreCollection.rebuild();
        }
    }

    // NOTE: Video Preview
    Component {
    id: videoPreviewWrapper

        Video {
        id: videocomponent

            property bool videoExists: game ? game.assets.videos.length : false
            source: videoExists ? game.assets.videos[0] : ""
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            muted: settings.AllowVideoPreviewAudio === "No"
            loops: MediaPlayer.Infinite
            autoPlay: true
            //onPlaying: videocomponent.seek(5000)
        }

    }

    // Video
    Loader {
    id: videoPreviewLoader

        asynchronous: true
        anchors { fill: parent }
    }

    // Background
    Image {
    id: screenshot

        anchors.fill: parent
        asynchronous: true
        property int randoScreenshotNumber: {
            if (game && settings.GameRandomBackground === "Yes")
                return Math.floor(Math.random() * game.assets.screenshotList.length);
            else
                return 0;
        }
        property int randoFanartNumber: {
            if (game && settings.GameRandomBackground === "Yes")
                return Math.floor(Math.random() * game.assets.backgroundList.length);
            else
                return 0;
        }

        property var randoScreenshot: game ? game.assets.screenshotList[randoScreenshotNumber] : ""
        property var randoFanart: game ? game.assets.backgroundList[randoFanartNumber] : ""
        property var actualBackground: (settings.GameBackground === "Screenshot") ? randoScreenshot : Utils.fanArt(game) || randoFanart;
        source: actualBackground || ""
        sourceSize: Qt.size(root.width, root.height)
        fillMode: Image.PreserveAspectCrop
        smooth: false
        Behavior on opacity { NumberAnimation { duration: 500 } }
        visible: !blurBG
    }

    FastBlur {
        anchors.fill: screenshot
        source: screenshot
        radius: 64
        opacity: screenshot.opacity
        Behavior on opacity { NumberAnimation { duration: 500 } }
        visible: blurBG
    }

    // Scanlines
    Image {
    id: scanlines

        anchors.fill: parent
        source: "../assets/images/scanlines_v3.png"
        asynchronous: true
        opacity: 0.2
        visible: !iamsteam && (settings.ShowScanlines == "Yes")
    }

    // Clear logo
    Image {
    id: logo

        anchors { 
            top: parent.top; //topMargin: vpx(70)
            left: parent.left; leftMargin: vpx(70)
        }
        width: vpx(500)
        height: vpx(450) + header.height
        source: game ? Utils.logo(game) : ""
        sourceSize { width: 512; height: 512 }
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        opacity: (content.currentIndex !== 0 || detailsScreen.opacity !== 0) ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 200 } }
        z: (content.currentIndex == 0) ? 10 : -10
        visible: settings.GameLogo === "Show"
    }

    DropShadow {
    id: logoshadow

        anchors.fill: logo
        horizontalOffset: 0
        verticalOffset: 0
        radius: 8.0
        samples: 9
        color: "#000000"
        source: logo
        opacity: (content.currentIndex !== 0 || detailsScreen.opacity !== 0) ? 0 : 0.4
        Behavior on opacity { NumberAnimation { duration: 200 } }
        visible: settings.GameLogo === "Show"
    }

    // Platform title
    Text {
    id: gametitle
        
        text: game.title
        
        anchors {
            top:    logo.top;
            left:   logo.left;//    leftMargin: globalMargin
            right:  parent.right;
            bottom: logo.bottom
        }
        
        color: theme.text
        font.family: titleFont.name
        font.pixelSize: vpx(80)
        font.bold: true
        horizontalAlignment: Text.AlignHLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        lineHeight: 0.8
        visible: logo.source === "" || settings.GameLogo === "Text only"
        opacity: (content.currentIndex !== 0 || detailsScreen.opacity !== 0) ? 0 : 1
    }

    // Gradient
    LinearGradient {
    id: bggradient

        width: parent.width
        height: parent.height/2
        start: Qt.point(0, 0)
        end: Qt.point(0, height)
        gradient: Gradient {
            GradientStop { position: 0.0; color: theme.gradientstart }
            GradientStop { position: 0.7; color: theme.gradientend }
        }
        y: (content.currentIndex == 0) ? height : -height
        Behavior on y { NumberAnimation { duration: 200 } }
    }

    Rectangle {
    id: overlay

        color: theme.gradientend
        anchors {
            left: parent.left; right: parent.right
            top: bggradient.bottom; bottom: parent.bottom
        }
    }

    

    // Details screen
    Item {
    id: detailsScreen
        
        anchors.fill: parent
        visible: opacity !== 0
        opacity: (content.currentIndex !== 0) ? 0 : detailsOpacity
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        Rectangle {
            anchors.fill: parent
            color: theme.main
            opacity: 0.7
        }

        Item {
        id: details 

            anchors { 
                top: parent.top; topMargin: vpx(100)
                left: parent.left; leftMargin: vpx(70)
                right: parent.right; rightMargin: vpx(70)
            }
            height: vpx(450) - header.height

            Image {
            id: boxart

                source: Utils.boxArt(game, settings.BoxArtStyle)
                width: vpx(350)
                height: parent.height
                sourceSize { width: 512; height: 512 }
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
            }

            GameInfo {
            id: info

                anchors {
                    left: boxart.right; leftMargin: vpx(30)
                    top: parent.top; bottom: parent.bottom; right: parent.right
                }
            }
        }
    }

    // Header
    Item {
    id: header

        anchors {
            left: parent.left; 
            right: parent.right
        }
        height: vpx(75)

        // Platform logo
        Image {
        id: logobg

            anchors.fill: platformlogo
            source: "../assets/images/blank.png"
            asynchronous: true
            visible: false
        }

        Image {
        id: platformlogo

            anchors {
                top: parent.top; topMargin: vpx(20)
                bottom: parent.bottom; bottomMargin: vpx(20)
                left: parent.left; leftMargin: globalMargin
            }
            fillMode: Image.PreserveAspectFit
            source: "../assets/images/logospng/" + Utils.processPlatformName(game.collections.get(0).shortName) + ".png"
            sourceSize { width: 256; height: 256 }
            smooth: true
            visible: false
            asynchronous: true           
        }

        OpacityMask {
            anchors.fill: platformlogo
            source: platformlogo
            maskSource: logobg
            
            // Mouse/touch functionality
            MouseArea {
                anchors.fill: parent
                hoverEnabled: settings.MouseHover == "Yes"
                onClicked: previousScreen();
            }
        }

        // Platform title
        Text {
        id: softwareplatformtitle
            
            text: game.collections.get(0).name
            
            anchors {
                top:    parent.top;
                left:   parent.left;    leftMargin: globalMargin
                right:  parent.right
                bottom: parent.bottom
            }
            
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: vpx(30)
            font.bold: true
            horizontalAlignment: Text.AlignHLeft
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            visible: platformlogo.status == Image.Error

            // Mouse/touch functionality
            MouseArea {
                anchors.fill: parent
                hoverEnabled: settings.MouseHover == "Yes"
                onClicked: previousScreen();
            }
        }
        z: 10
    }


    // Game menu
    ObjectModel {
    id: menuModel

        Button { 
        id: button1 

            text: {
                if (!game || game.genreList.length === 0) return "Play game";
                var g = game.genreList[0];
                var sepM = g.match(/^(.*?)\s*[\/,]\s*(.+)$/);
                var lower = (sepM ? sepM[1] : g).trim().toLowerCase();
                return (lower === "application" || lower === "emulator") ? "Open" : "Play game";
            }
            height: parent.height
            selected: ListView.isCurrentItem && menu.focus
            onHighlighted: { menu.currentIndex = ObjectModel.index; content.currentIndex = 0; }
            onActivated: 
                if (selected) {
                    sfxAccept.play();
                    launchGame(game);
                } else {
                    sfxNav.play();
                    menu.currentIndex = ObjectModel.index;
                }
        }

        Button {
        id: button5

            icon: "../assets/images/icon_ra.svg"
            iconPadding: vpx(16)
            height: parent.height
            selected: ListView.isCurrentItem && menu.focus
            onHighlighted: { menu.currentIndex = ObjectModel.index; content.currentIndex = 0; }
            onActivated:
                if (selected) {
                    sfxAccept.play();
                    achievementsScreen();
                } else {
                    sfxNav.play();
                    menu.currentIndex = ObjectModel.index;
                }
        }

        Button { 
        id: button2 

            icon: "../assets/images/icon_details.svg"
            height: parent.height
            selected: ListView.isCurrentItem && menu.focus
            onHighlighted: { menu.currentIndex = ObjectModel.index; content.currentIndex = 0; }
            onActivated: 
                if (selected) {
                    sfxToggle.play();
                    showDetails();
                } else {
                    sfxNav.play();
                    menu.currentIndex = ObjectModel.index;
                }
        }

        Button { 
        id: button3 

            property string buttonText: game && game.favorite ? "Unfavorite" : "Add favorite"
            //text: buttonText
            icon: favIcon
            height: parent.height
            selected: ListView.isCurrentItem && menu.focus
            onHighlighted: { menu.currentIndex = ObjectModel.index; content.currentIndex = 0; }
            onActivated: 
                if (selected) {
                    sfxToggle.play();
                    game.favorite = !game.favorite;
                } else {
                    sfxNav.play();
                    menu.currentIndex = ObjectModel.index;
                }
        }
        
        Button { 
        id: button4

            //text: "Back"
            icon: "../assets/images/icon_back.svg"
            height: parent.height
            selected: ListView.isCurrentItem && menu.focus
            onHighlighted: { menu.currentIndex = ObjectModel.index; content.currentIndex = 0; }
            onActivated: 
                if (selected) 
                    previousScreen();
                else {
                    sfxNav.play(); 
                    menu.currentIndex = ObjectModel.index;
                }
        }
    }

    // Full list
    ObjectModel {
    id: extrasModel

        // Game menu
        ListView {
        id: menu

            property bool selected: parent.focus
            focus: selected
            width: parent.width
            height: vpx(50)
            model: menuModel
            orientation: ListView.Horizontal
            spacing: vpx(10)
            keyNavigationWraps: true
            Keys.onLeftPressed: { sfxNav.play(); decrementCurrentIndex() }
            Keys.onRightPressed: { sfxNav.play(); incrementCurrentIndex() }
        }

        HorizontalCollection {
        id: media

            width: root.width - vpx(70) - globalMargin
            height: ((root.width - globalMargin * 2) / 6.0) + vpx(60)
            title: "Media"
            model: mediaList
            delegate: MediaItem {
            id: mediadelegate

                width: (root.width - globalMargin * 2) / 6.0
                height: width
                selected: ListView.isCurrentItem && media.ListView.isCurrentItem
                mediaItem: modelData

                onHighlighted: {
                    sfxNav.play(); 
                    media.currentIndex = index;
                    content.currentIndex = media.ObjectModel.index;
                }

                onActivated: {
                if (selected)
                    showMedia(index);
                else
                {
                    sfxNav.play(); 
                    media.currentIndex = index;
                    content.currentIndex = media.ObjectModel.index;
                }
            }
            }
            
        }

        // --- BEGIN: More by Publisher/Developer (More section only) ---
        // Falls back to "More Recommended Games" when no publisher/developer results exist.
        HorizontalCollection {
        id: list1

            property bool selected: ListView.isCurrentItem
            focus: selected
            width: root.width - vpx(70) - globalMargin
            height: itemHeight + vpx(60)
            itemWidth: (root.width - globalMargin * 2) / 4.0
            itemHeight: itemWidth * settings.WideRatio

            // Show recommended games when there are no publisher/developer results
            title: {
                if (!game) return "";
                if (publisherCollection.games.length === 0)
                    return "More Recommended Games";
                var pub = game.publisher || "";
                var dev = game.developer || "";
                var g = game.genreList.length > 0 ? game.genreList[0] : "";
                var sepM = g.match(/^(.*?)\s*[\/,]\s*(.+)$/);
                var lower = (sepM ? sepM[1] : g).trim().toLowerCase();
                var prefix = (lower === "application" || lower === "emulator") ? "More by " : "More games by ";
                if (pub && dev && pub.toLowerCase() !== dev.toLowerCase())
                    return prefix + pub + " / " + dev;
                return prefix + (pub || dev);
            }
            // Switch to the recommended fallback when publisher/developer list is empty
            search: publisherCollection.games.length > 0 ? publisherCollection : recommendedCollection
            onListHighlighted: { sfxNav.play(); content.currentIndex = list1.ObjectModel.index; }
        }
        // --- END: More by Publisher/Developer (More section only) ---

        // --- BEGIN: More by Genre (Option B: genre token controlled by setting) ---
        HorizontalCollection {
        id: list2

            property bool selected: ListView.isCurrentItem
            focus: selected
            width: root.width - vpx(70) - globalMargin
            height: itemHeight + vpx(60)
            itemWidth: (root.width - globalMargin * 2) / 8.0
            itemHeight: itemWidth / settings.TallRatio

            title: {
                if (!game || game.genreList.length === 0) return "              ";
                var g  = game.genreList[0];
                var sepM = g.match(/^(.*?)\s*[\/,]\s*(.+)$/);
                var mainGenre = sepM ? sepM[1].trim() : g;
                var lower = mainGenre.toLowerCase();
                // Special labels are always based on the main genre.
                if (lower === "application") return "More Applications";
                if (lower === "emulator") return "More Emulators";
                var modeStr = settings.MoreByGenreDisplay || "Main Genre";
                if (modeStr === "Sub Genre") {
                    var displayGenre = sepM ? sepM[2].trim() : mainGenre;
                    return "More " + displayGenre + " Games";
                }
                if (modeStr === "Full") return "More " + g + " Games";
                return "More " + mainGenre + " Games";
            }
            search: genreCollection
            onListHighlighted: { sfxNav.play(); content.currentIndex = list2.ObjectModel.index; }
        }
        // --- END: More by Genre (Option B: genre token controlled by setting) ---
        
    }

    ListView {
    id: content

        anchors {
            left: parent.left; leftMargin: vpx(70)
            right: parent.right
            top: parent.top; topMargin: header.height
            bottom: parent.bottom; bottomMargin: vpx(150)
        }
        model: extrasModel
        focus: true
        spacing: vpx(30)
        header: Item { height: vpx(450) }
        
        snapMode: ListView.SnapToItem
        highlightMoveDuration: 100
        displayMarginEnd: 150
        cacheBuffer: 0
        onCurrentIndexChanged: { 
            if (content.currentIndex === 0) {
                toggleVideo(true); 
            } else {
                toggleVideo(false);
            }
        }
        keyNavigationWraps: true
        Keys.onUpPressed: { sfxNav.play(); decrementCurrentIndex() }
        Keys.onDownPressed: { sfxNav.play(); incrementCurrentIndex() }
    }

    MediaView {
    id: mediaScreen
        
        anchors.fill: parent
        Behavior on opacity { NumberAnimation { duration: 100 } }
        visible: opacity != 0

        mediaModel: mediaList;
        mediaIndex: media.currentIndex != -1 ? media.currentIndex : 0
        onClose: closeMedia();
    }

    // Input handling
    Keys.onPressed: {
        // Back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (mediaScreen.visible)
                closeMedia();
            else
                previousScreen();
        }
        // Toggle Favorite
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            sfxAccept.play();
            game.favorite = !game.favorite;
        }
        // Settings
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            settingsScreen();
        }
    }

    // Helpbar buttons
    ListModel {
        id: gameviewHelpModel

        ListElement {
            name: "Back"
            button: "cancel"
        }
        ListElement {
            name: "Settings"
            button: "filters"
        }
        ListElement {
            name: "Toggle Favorite"
            button: "details"
        }
        ListElement {
            name: "Launch"
            button: "accept"
        }
    }
    
    onActiveFocusChanged: {
        if (activeFocus) {
            currentHelpbarModel = gameviewHelpModel;
            menu.focus = true;
            menu.currentIndex = 0;
        } else {
            screenshot.opacity = 1;
            toggleVideo(false);
        }
    }

}
