import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100

    implicitWidth: batteryProgress.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ClippedProgressBar {
        id: batteryProgress
        anchors.centerIn: parent
        value: percentage
        // Plugged in (charging, conservation-mode hold, or full): violet. On battery: blue. Low on battery: red
        highlightColor: (isLow && !isCharging) ? BarColors.m3error
            : (Battery.isPluggedIn || Battery.chargeState == UPowerDeviceState.FullyCharged) ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.30)
            : ColorUtils.transparentize(Appearance.colors.colSecondary, 0.30)

        Item {
            anchors.centerIn: parent
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight

            RowLayout {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: (parent.height - height) / 2
                }
                spacing: 0

                MaterialSymbol {
                    id: boltIcon
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: -2
                    Layout.rightMargin: -2
                    fill: 1
                    text: "bolt"
                    iconSize: Appearance.font.pixelSize.smaller
                    visible: isCharging && percentage < 1 // TODO: animation
                }
                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    font: batteryProgress.font
                    text: batteryProgress.text
                }
            }
        }
    }

    BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
