import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtMultimedia
import qs
import qs.modules.common
import qs.modules.common.panels.lock
import Quickshell

// Lock screen styled after the SDDM login screen (sddm-astronaut-theme + Themes/astronaut.conf.user):
// same baked matrix video, blurred middle strip, Orbitron clock, username/password boxes and Login button.
// Unlocking still goes through end-4's LockContext (PAM). Original: ~/Backups/Configs/config-backup-2026-10-28/LockSurface.qml.end4-original
MouseArea {
    id: root
    required property LockContext context
    property bool active: false

    // Values copied from the login theme
    readonly property string videoPath: "file://" + Quickshell.env("HOME") + "/Videos/Wallpapers/deep-space-matrix-login.mp4"
    readonly property real fontPt: 13                 // FontSize
    readonly property real corner: 20                 // RoundCorners
    readonly property string uiFont: "Space Grotesk"  // Font
    readonly property color violet: "#8703ff"         // TimeTextColor (numbers)
    readonly property color blue: "#0059e7"           // DateTextColor, field text (letters)
    readonly property color formBg: "#17122e"         // FormBackgroundColor
    readonly property color fieldBg: "#1f0b3a"        // Login/PasswordFieldBackgroundColor
    readonly property color iconColor: "#8703ff"      // User/PasswordIconColor
    readonly property color placeholder: "#6215ff"    // PlaceholderTextColor
    readonly property color warning: "#ff5c8a"       // WarningColor
    readonly property real formWidth: width / 2.5

    function paint(str) {
        return str.replace(/([0-9]+)|([A-Za-z]+)/g, (m, num, word) =>
            `<font color="${num ? root.violet : root.blue}">${m}</font>`);
    }

    // Focus handling (same behaviour as end-4's lock)
    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }
    Connections {
        target: context
        function onShouldReFocus() {
            forceFieldFocus();
        }
    }
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: mouse => forceFieldFocus()
    onPositionChanged: mouse => forceFieldFocus()
    Component.onCompleted: forceFieldFocus()

    property bool ctrlHeld: false
    Keys.onPressed: event => {
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Control)
            root.ctrlHeld = true;
        if (event.key === Qt.Key_Escape)
            root.context.currentText = "";
        forceFieldFocus();
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control)
            root.ctrlHeld = false;
        forceFieldFocus();
    }

    // Background: the login video
    Rectangle {
        anchors.fill: parent
        color: "#0d0a1a"
    }
    MediaPlayer {
        id: player
        source: root.videoPath
        loops: MediaPlayer.Infinite
        videoOutput: video
        Component.onCompleted: play()
    }
    VideoOutput {
        id: video
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    // Middle strip: blurred video + 30% form tint (PartialBlur)
    ShaderEffectSource {
        id: stripSource
        width: root.formWidth
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        sourceItem: video
        sourceRect: Qt.rect(x, y, width, height)
        visible: false
    }
    MultiEffect {
        anchors.fill: stripSource
        source: stripSource
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        autoPaddingEnabled: false
    }
    Rectangle {
        anchors.fill: stripSource
        color: root.formBg
        opacity: 0.3
    }

    // Form column: clock (top third), inputs, login button
    ColumnLayout {
        width: root.formWidth
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.height / 3

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                spacing: 0

                Text {
                    id: timeLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Orbitron"
                    font.pointSize: root.fontPt * 9
                    font.bold: true
                    textFormat: Text.StyledText
                    color: root.blue
                }
                Text {
                    id: dateLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: root.uiFont
                    font.pointSize: root.fontPt * 2
                    font.bold: true
                    textFormat: Text.StyledText
                    color: root.blue
                }
                Timer {
                    interval: 1000
                    repeat: true
                    running: true
                    triggeredOnStart: true
                    onTriggered: {
                        const now = new Date();
                        timeLabel.text = root.paint(Qt.formatTime(now, "h:mm AP"));
                        dateLabel.text = root.paint(now.toLocaleDateString(Qt.locale(), Locale.LongFormat));
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.height / 10
        }

        Column {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.formWidth / 2
            spacing: 0

            // Warning line (login failed)
            Text {
                width: parent.width
                height: root.fontPt * 2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: root.uiFont
                font.pointSize: root.fontPt * 0.8
                font.italic: true
                color: root.warning
                text: GlobalStates.screenUnlockFailed ? "Login failed!" : ""
            }

            // Username (read-only, like a remembered user)
            Item {
                width: parent.width
                height: root.fontPt * 4.5
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: root.fontPt * 3
                    radius: root.corner
                    color: root.fieldBg
                    opacity: 0.2
                }
                Text {
                    anchors.centerIn: parent
                    font.family: root.uiFont
                    font.pointSize: root.fontPt
                    font.bold: true
                    color: root.blue
                    text: Quickshell.env("USER")
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.fontPt
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: root.fontPt * 1.4
                    color: root.iconColor
                    text: "person"
                }
            }

            // Password
            Item {
                width: parent.width
                height: root.fontPt * 4.5
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: root.fontPt * 3
                    radius: root.corner
                    color: root.fieldBg
                    opacity: 0.2
                    border.color: root.violet
                    border.width: passwordBox.activeFocus ? 2 : 0
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.fontPt
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: root.fontPt * 1.4
                    color: root.iconColor
                    text: "lock"
                }
                TextField {
                    id: passwordBox
                    anchors.centerIn: parent
                    width: parent.width - root.fontPt * 6
                    height: root.fontPt * 3
                    background: null
                    horizontalAlignment: TextInput.AlignHCenter
                    font.family: root.uiFont
                    font.pointSize: root.fontPt
                    font.bold: true
                    color: root.blue
                    placeholderText: "Password"
                    placeholderTextColor: root.placeholder
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    inputMethodHints: Qt.ImhSensitiveData
                    enabled: !root.context.unlockInProgress
                    selectionColor: root.fieldBg
                    selectedTextColor: root.blue

                    // Synchronizing (across monitors) and unlocking
                    onTextChanged: root.context.currentText = text
                    onAccepted: root.context.tryUnlock(root.ctrlHeld)
                    Connections {
                        target: root.context
                        function onCurrentTextChanged() {
                            passwordBox.text = root.context.currentText;
                        }
                    }
                    Keys.onPressed: event => root.context.resetClearTimer()
                }
            }

            // Login button
            Item {
                width: parent.width
                height: root.fontPt * 9
                Rectangle {
                    id: loginBg
                    anchors.top: parent.top
                    width: parent.width
                    height: root.fontPt * 3
                    radius: root.corner
                    color: loginArea.containsPress ? Qt.darker(root.fieldBg, 1.1) : root.fieldBg
                    opacity: loginArea.containsMouse && loginArea.enabled ? 1 : 0.2
                }
                Text {
                    anchors.centerIn: loginBg
                    font.family: root.uiFont
                    font.pointSize: root.fontPt
                    font.bold: true
                    color: root.blue
                    opacity: loginArea.enabled ? 1 : 0.5
                    text: "Login"
                }
                MouseArea {
                    id: loginArea
                    anchors.fill: loginBg
                    hoverEnabled: true
                    enabled: passwordBox.text.length > 0 && !root.context.unlockInProgress
                    onClicked: root.context.tryUnlock()
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
