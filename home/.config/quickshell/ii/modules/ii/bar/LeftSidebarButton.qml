import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root

    property bool showPing: false

    property bool aiChatEnabled: Config.options.policies.ai !== 0
    property bool translatorEnabled: Config.options.sidebar.translator.enable
    property bool animeEnabled: Config.options.policies.weeb !== 0
    visible: true // Glass dashboard is shown when no tabs are enabled

    readonly property bool customLogo: Config.options.bar.topLeftIcon === 'fetchlogo'
    property real buttonPadding: customLogo ? 2 : 5
    implicitWidth: distroIcon.width + buttonPadding * 2
    implicitHeight: distroIcon.height + buttonPadding * 2
    buttonRadius: Appearance.rounding.full
    colBackgroundHover: BarColors.colLayer1Hover
    colRipple: BarColors.colLayer1Active
    colBackgroundToggled: BarColors.colSecondaryContainer
    colBackgroundToggledHover: BarColors.colSecondaryContainerHover
    colRippleToggled: BarColors.colSecondaryContainerActive
    toggled: GlobalStates.sidebarLeftOpen

    onPressed: {
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
    }

    Connections {
        target: Ai
        function onResponseFinished() {
            if (GlobalStates.sidebarLeftOpen) return;
            root.showPing = true;
        }
    }

    Connections {
        target: Booru
        function onResponseFinished() {
            if (GlobalStates.sidebarLeftOpen) return;
            root.showPing = true;
        }
    }

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            root.showPing = false;
        }
    }

    CustomIcon {
        id: distroIcon
        anchors.centerIn: parent
        width: root.customLogo ? 36 : 24   // biggest that fits the 40 px bar (2026-11-14); custom logo big enough to show its cracks/glitch
        height: root.customLogo ? 36 : 24
        source: Config.options.bar.topLeftIcon == 'distro' ? SystemInfo.distroIcon : `${Config.options.bar.topLeftIcon}-symbolic`
        colorize: Config.options.bar.topLeftIcon !== 'fetchlogo' // fetchlogo keeps its purple/blue
        color: BarColors.colOnLayer0
        layer.enabled: true   // brighter + more saturated (2026-11-14)
        layer.effect: MultiEffect { brightness: 0.25; saturation: 0.3 }

        Rectangle {
            opacity: root.showPing ? 1 : 0
            visible: opacity > 0
            anchors {
                bottom: parent.bottom
                right: parent.right
                bottomMargin: -2
                rightMargin: -2
            }
            implicitWidth: 8
            implicitHeight: 8
            radius: Appearance.rounding.full
            color: BarColors.colTertiary

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }
}
