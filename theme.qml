import QtQuick
import QtQuick.Layouts
//import Qt5Compat.GraphicalEffects
import QtMultimedia
import Rift 1.0
import "Lists"
import "utils.js" as Utils

FocusScope {
	id: root

	// Hide the global Rift footer - this theme has its own navigation
	property bool footerVisible: false

	// Menu customization (SELECT, START, Settings) - PS3 XMB dark style
	property color menuBackgroundColor: "#1a1a1a"
	property color menuTextColor: "#ffffff"
	property color menuAccentColor: "#0070d1"
	property color menuSecondaryColor: "#252525"
	property color menuBorderColor: "#333333"
	property real menuBackgroundOpacity: 0.98
	property string menuFontFamily: generalFont.name

	FontLoader { id: generalFont; source: "assets/fonts/font.ttf" }

	// Theme settings from Rift
	property string backgroundSetting: Rift.themeSetting("background") ?? "1"
	property string iconSourceSetting: Rift.themeSetting("iconSource") ?? "0"

	// Listen for real-time setting changes
	Connections {
		target: Rift
		function onThemeSettingChanged(key, value) {
			if (key === "background") backgroundSetting = value
			if (key === "iconSource") iconSourceSetting = value
		}
	}

	property var settings: {
        return {
            background: "assets/background/xmb-wave-" + backgroundSetting + ".jpg",
            iconSource: iconSourceSetting
        }
    }
	
	// Background
    Item {
    id: background
        
        anchors.fill: parent

        property string bgImage1
        property string bgImage2
        property bool firstBG: true
        
        //property var bgData: itemBar.currentItem
        property var bgSource: {if (collectionBar.currentCollection.idx == -3 ) { settings.background } else if (itemBar.currentItem != null) return itemBar.currentItem.assets.background} //collectionBar.currentCollection.idx > -2 ? bgData.background : (collectionBar.currentCollection.background) //(bgData ? Utils.fanArt(bgData) || bgData.assets.screenshots[0] : "") : (collectionBar.currentCollection.background)
        onBgSourceChanged: { if (bgSource != "") swapImage(bgSource) }

        states: [
            State { // this will fade in gameBG2 and fade out gameBG1
                name: "fadeInRect2"
                PropertyChanges { target: gameBG1; opacity: 0}
                PropertyChanges { target: gameBG2; opacity: 1}
            },
            State   { // this will fade in gameBG1 and fade out gameBG2
                name:"fadeOutRect2"
                PropertyChanges { target: gameBG1; opacity: 1}
                PropertyChanges { target: gameBG2; opacity: 0}
            }
        ]

        transitions: [
            Transition {
                NumberAnimation { property: "opacity"; easing.type: Easing.InOutQuad; duration: 300  }
            }
        ]

        function swapImage(newSource) {
            if (firstBG) {
                // Go to second image
                if (newSource)
                    bgImage2 = newSource

                firstBG = false
                } else {
                // Go to first image
                if (newSource)
                    bgImage1 = newSource

                firstBG = true
            }
            background.state = background.state == "fadeInRect2" ? "fadeOutRect2" : "fadeInRect2"
        }

        Image {
        id: gameBG1

            anchors.fill: parent
            source: background.bgImage1
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(parent.width, parent.height)
            smooth: true
            asynchronous: true
            //visible: collectionAxis.currentIndex >= 2
        }

        Image {
        id: gameBG2

            anchors.fill: parent
            source: background.bgImage2
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(parent.width, parent.height)
            smooth: true
            asynchronous: true
            //visible: collectionAxis.currentIndex >= 2
        }

        Image {
        id: blurBG

            anchors.fill: parent
            source: "assets/background/blurbg.png"
            sourceSize: Qt.size(parent.width, parent.height)
            opacity: 0.9
        }
    }
	
	Text {
		id: currentCategory
		
		anchors {
            left: parent.left; leftMargin: vpx(40)
            //right: parent.right
			top: parent.top; topMargin: vpx(28)
			//bottom: parent.bottom
        }
		// will become a number between 0-19
		text: collectionBar.currentCollection != null ? collectionBar.currentCollection.name : ""
		//z:10
		
		color: "white"
		font.family: generalFont.name
		font.pointSize: 22
	}
	
	Text {
        id: sysTime

        function set() {
            sysTime.text = Qt.formatDateTime(new Date(), "d/MM/yyyy hh:mm")
        }
		
		anchors {
			right: parent.right; rightMargin: vpx(40)
            top: parent.top; topMargin: vpx(28)
        }
		
        Timer {
            id: textTimer
            interval: 60000 // Run the timer every minute
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: function() { sysTime.set() }
        }
		
		color: "white"
		font.family: generalFont.name
		font.pointSize: 22
    }

	CollectionBar {
		id: collectionBar
		anchors {
            left: parent.left
            right: parent.right
			top: parent.top; topMargin: vpx(156)
			//bottom: parent.bottom
        }
		
		active: itemBar.focus
		onCollectionChanged: {
		 if (collectionBar.currentCollection != null) itemBar.update(collectionBar.currentCollection.idx)
			
		}
	}
	
	ItemBar {
		id: itemBar
		anchors {
            left: parent.left//; leftMargin: vpx(320)
            //right: parent.right
			top: parent.top
			bottom: parent.bottom
        }
		focus: true //!gameDetails.focus //true
		collectionIdx: { if (collectionBar.currentCollection != null) return collectionBar.currentCollection.idx }
		
		//onSettings: {
		//	focus = false;
		//}
	}

	GameDetails {
		id: gameDetails
		//opacity: focus ? 1.0 : 0.0
		anchors {
            left: parent.left; leftMargin: vpx(250)
            right: parent.right; rightMargin: vpx(75)
			top: parent.top//; topMargin: vpx(75)
			bottom: parent.bottom//; bottomMargin: vpx(75)
        }
		focus: !itemBar.focus
		
		currentGame: itemBar.currentItem
		collectionIdx: { if (collectionBar.currentCollection != null) return collectionBar.currentCollection.idx }
		
		onExit: {
			itemBar.focus = true;
		}
	}
	
	Keys.onPressed: function(event) {
			// Details
		if (api.keys.isDetails(event) && !event.isAutoRepeat) {
			event.accepted = true;
			itemBar.focus ? itemBar.focus = false : itemBar.focus = true
		}
		if (api.keys.isNextPage(event)) {
			event.accepted = true;
			collectionBar.list.incrementCurrentIndex();
		}
		if (api.keys.isPrevPage(event)) {
			event.accepted = true;
			collectionBar.list.decrementCurrentIndex();
		}
	}
	
	SoundEffect {
        id: navSfx
        source: "assets/audio/nav.wav"
        volume: 0.25
    }
	SoundEffect {
        id: backSfx
        source: "assets/audio/back.wav"
        volume: 0.25
    }
}
