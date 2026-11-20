import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

import qs.modules.ii.sidebarRight.quickToggles
import qs.modules.ii.sidebarRight.quickToggles.classicStyle

import qs.modules.ii.sidebarRight.bluetoothDevices
import qs.modules.ii.sidebarRight.nightLight
import qs.modules.ii.sidebarRight.volumeMixer
import qs.modules.ii.sidebarRight.wifiNetworks

Item {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 10
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false
    property bool showBluetoothDialog: false
    property bool showNightLightDialog: false
    property bool showWifiDialog: false
    property bool editMode: false

    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            if (!GlobalStates.sidebarRightOpen) {
                root.showWifiDialog = false;
                root.showBluetoothDialog = false;
                root.showAudioOutputDialog = false;
                root.showAudioInputDialog = false;
            }
        }
    }

    // Popover height follows the content; dialogs (Wi-Fi/Bluetooth lists) need more room
    readonly property bool anyDialogShown: showAudioOutputDialog || showAudioInputDialog || showBluetoothDialog || showNightLightDialog || showWifiDialog
    implicitHeight: Math.max(contentColumn.implicitHeight + sidebarPadding * 2, anyDialogShown ? 660 : 0)
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    StyledRectangularShadow {
        target: sidebarRightBackground
    }
    Rectangle {
        id: sidebarRightBackground

        anchors.fill: parent
        color: GlassStyle.panel
        radius: GlassStyle.radiusPanel

        // Soft accent glows behind the glass, clipped to the rounded panel
        Item {
            id: glowLayer
            anchors.fill: parent
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: glowLayer.width
                    height: glowLayer.height
                    radius: sidebarRightBackground.radius
                }
            }
            RadialGradient {
                x: parent.width * 0.25
                y: -parent.width * 0.55
                width: parent.width * 1.2
                height: parent.width * 1.2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: GlassStyle.glowA }
                    GradientStop { position: 0.5; color: "transparent" }
                }
            }
            RadialGradient {
                x: -parent.width * 0.5
                y: parent.height - parent.width * 0.6
                width: parent.width * 1.2
                height: parent.width * 1.2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: GlassStyle.glowB }
                    GradientStop { position: 0.5; color: "transparent" }
                }
            }
        }

        // Hairline edge that catches the light
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: GlassStyle.panelBorder
        }

        ColumnLayout {
            id: contentColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: sidebarPadding
            }
            spacing: sidebarPadding

            RowLayout {
                Layout.fillWidth: true
                spacing: sidebarPadding

                ConnectivityCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: Network.ethernet ? Translation.tr("Ethernet") : Translation.tr("Wi-Fi")
                    iconName: Network.materialSymbol
                    active: Network.ethernet || Network.wifiEnabled
                    subtitle: Network.ethernet ? Translation.tr("Connected")
                        : !Network.wifiEnabled ? Translation.tr("Off")
                        : Network.wifiStatus === "connected" ? Network.networkName
                        : Network.wifiStatus === "connecting" ? Translation.tr("Connecting…")
                        : Translation.tr("Not connected")
                    onToggleRequested: Network.toggleWifi()
                    onMenuRequested: root.showWifiDialog = true
                }

                ConnectivityCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    enabled: BluetoothStatus.available
                    title: Translation.tr("Bluetooth")
                    iconName: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                    active: BluetoothStatus.enabled
                    subtitle: !BluetoothStatus.available ? Translation.tr("Unavailable")
                        : !BluetoothStatus.enabled ? Translation.tr("Off")
                        : BluetoothStatus.activeDeviceCount > 1 ? Translation.tr("%1 +%2").arg(BluetoothStatus.firstActiveDevice?.name ?? "").arg(BluetoothStatus.activeDeviceCount - 1)
                        : BluetoothStatus.connected ? (BluetoothStatus.firstActiveDevice?.name ?? Translation.tr("Connected"))
                        : Translation.tr("No devices")
                    onToggleRequested: {
                        if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                    }
                    onMenuRequested: root.showBluetoothDialog = true
                }
            }

            Loader {
                id: slidersLoader
                Layout.fillWidth: true
                visible: active
                active: {
                    const configQuickSliders = Config.options.sidebar.quickSliders
                    return configQuickSliders.showMic || configQuickSliders.showVolume || configQuickSliders.showBrightness;
                }
                sourceComponent: QuickSliders {}
            }

            LoaderedQuickPanelImplementation {
                styleName: "classic"
                sourceComponent: ClassicQuickPanel {}
            }

            LoaderedQuickPanelImplementation {
                styleName: "android"
                sourceComponent: AndroidQuickPanel {
                    editMode: root.editMode
                }
            }

            GlassFooter {
                Layout.fillWidth: true
                Layout.leftMargin: 4
            }
        }
    }

    ToggleDialog {
        shownPropertyString: "showAudioOutputDialog"
        dialog: VolumeDialog {
            isSink: true
        }
    }

    ToggleDialog {
        shownPropertyString: "showAudioInputDialog"
        dialog: VolumeDialog {
            isSink: false
        }
    }

    ToggleDialog {
        shownPropertyString: "showBluetoothDialog"
        dialog: BluetoothDialog {}
        onShownChanged: {
            if (!shown) {
                Bluetooth.defaultAdapter.discovering = false;
            } else {
                Bluetooth.defaultAdapter.enabled = true;
                Bluetooth.defaultAdapter.discovering = true;
            }
        }
    }

    ToggleDialog {
        shownPropertyString: "showNightLightDialog"
        dialog: NightLightDialog {}
    }

    ToggleDialog {
        shownPropertyString: "showWifiDialog"
        dialog: WifiDialog {}
        onShownChanged: {
            if (!shown) return;
            Network.enableWifi();
            Network.rescanWifi();
        }
    }

    component ToggleDialog: Loader {
        id: toggleDialogLoader
        required property string shownPropertyString
        property alias dialog: toggleDialogLoader.sourceComponent
        readonly property bool shown: root[shownPropertyString]
        anchors.fill: parent

        onShownChanged: if (shown) toggleDialogLoader.active = true;
        active: shown
        onLoaded: item.backgroundWidth = Qt.binding(() => root.width - 24)
        onActiveChanged: {
            if (active) {
                item.show = true;
                item.forceActiveFocus();
            }
        }
        Connections {
            target: toggleDialogLoader.item
            function onDismiss() {
                toggleDialogLoader.item.show = false
                root[toggleDialogLoader.shownPropertyString] = false;
            }
            function onVisibleChanged() {
                if (!toggleDialogLoader.item.visible && !root[toggleDialogLoader.shownPropertyString]) toggleDialogLoader.active = false;
            }
        }
    }

    component LoaderedQuickPanelImplementation: Loader {
        id: quickPanelImplLoader
        required property string styleName
        Layout.alignment: item?.Layout.alignment ?? Qt.AlignHCenter
        Layout.fillWidth: item?.Layout.fillWidth ?? false
        visible: active
        active: Config.options.sidebar.quickToggles.style === styleName
        Connections {
            target: quickPanelImplLoader.item
            function onOpenAudioOutputDialog() {
                root.showAudioOutputDialog = true;
            }
            function onOpenAudioInputDialog() {
                root.showAudioInputDialog = true;
            }
            function onOpenBluetoothDialog() {
                root.showBluetoothDialog = true;
            }
            function onOpenNightLightDialog() {
                root.showNightLightDialog = true;
            }
            function onOpenWifiDialog() {
                root.showWifiDialog = true;
            }
        }
    }

    component GlassIconButton: RippleButton {
        id: glassIconButton
        property string buttonIcon
        implicitWidth: 32
        implicitHeight: 32
        buttonRadius: toggled ? Appearance.rounding.normal : Appearance.rounding.full
        colBackground: GlassStyle.card
        colBackgroundHover: GlassStyle.cardHover
        colRipple: GlassStyle.cardActive
        Rectangle {
            anchors.fill: parent
            radius: glassIconButton.buttonRadius
            color: "transparent"
            border.width: 1
            border.color: GlassStyle.cardBorder
        }
        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 17
            fill: glassIconButton.toggled ? 1 : 0
            text: glassIconButton.buttonIcon
            color: glassIconButton.toggled ? GlassStyle.onAccent : Appearance.colors.colSecondary // footer icons: theme blue
        }
    }

    component GlassFooter: RowLayout {
        spacing: 6

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Up %1").arg(DateTime.uptime)
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: GlassStyle.textDim
            elide: Text.ElideRight
        }
        GlassIconButton {
            toggled: root.editMode
            visible: Config.options.sidebar.quickToggles.style === "android"
            buttonIcon: "edit"
            onClicked: root.editMode = !root.editMode
            StyledToolTip {
                text: Translation.tr("Edit quick toggles") + (root.editMode ? Translation.tr("\nLMB to enable/disable\nRMB to toggle size\nScroll to swap position") : "")
            }
        }
        GlassIconButton {
            buttonIcon: "restart_alt"
            onClicked: {
                Quickshell.execDetached(["hyprctl", "reload"])
                Quickshell.reload(true);
            }
            StyledToolTip {
                text: Translation.tr("Reload Hyprland & Quickshell")
            }
        }
        GlassIconButton {
            buttonIcon: "settings"
            onClicked: {
                GlobalStates.sidebarRightOpen = false;
                Quickshell.execDetached(["qs", "-p", root.settingsQmlPath]);
            }
            StyledToolTip {
                text: Translation.tr("Settings")
            }
        }
        GlassIconButton {
            buttonIcon: "power_settings_new"
            onClicked: {
                GlobalStates.sessionOpen = true;
            }
            StyledToolTip {
                text: Translation.tr("Session")
            }
        }
    }
}
