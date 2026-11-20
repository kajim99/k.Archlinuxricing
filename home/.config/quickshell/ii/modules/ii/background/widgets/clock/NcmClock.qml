pragma ComponentBehavior: Bound

import QtQuick

// N-CM clock (2026-11-16): same look as the Windows N-CM wallpaper clock.
// Weekday in Anurati with the normal A (violet, blue shadow; "Anurati Arch" = Arch-logo A, still installed), date + 12h time in JetBrains Mono bold (blue, violet shadow; was Quicksand on Windows).
Column {
    id: root
    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    component ShadowText: Item {
        id: st
        property string text
        property string family
        property int size
        property bool bold: false
        property real spacing: 0
        property color color
        property color shadow
        property bool upper: false
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: main.implicitWidth + 2
        implicitHeight: main.implicitHeight + 2
        Text {
            x: 2; y: 2
            text: st.text; color: st.shadow
            font { family: st.family; pixelSize: st.size; bold: st.bold; letterSpacing: st.spacing; kerning: false
                   capitalization: st.upper ? Font.AllUppercase : Font.MixedCase }
        }
        Text {
            id: main
            text: st.text; color: st.color
            font { family: st.family; pixelSize: st.size; bold: st.bold; letterSpacing: st.spacing; kerning: false
                   capitalization: st.upper ? Font.AllUppercase : Font.MixedCase }
        }
    }

    ShadowText {
        text: Qt.formatDateTime(root.now, "dddd")
        family: "Anurati"; size: 72; spacing: 40; upper: true
        color: "#8703ff"; shadow: "#0059e7"
    }
    Item { width: 1; height: 48 - 16 }
    ShadowText {
        text: Qt.formatDateTime(root.now, "d MMMM yyyy")
        family: "JetBrainsMono Nerd Font"; size: 26; bold: true; spacing: 4
        color: "#0059e7"; shadow: "#8703ff"
    }
    Item { width: 1; height: 32 - 6 }
    ShadowText {
        text: Qt.formatDateTime(root.now, "h:mm AP")
        family: "JetBrainsMono Nerd Font"; size: 26; bold: true; spacing: 4
        color: "#0059e7"; shadow: "#8703ff"
    }
}
