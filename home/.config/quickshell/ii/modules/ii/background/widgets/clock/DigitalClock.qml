pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: clockColumn
    spacing: 4

    property bool isVertical: Config.options.background.widgets.clock.digital.vertical
    property color colText: Appearance.colors.colOnSecondaryContainer
    property var textHorizontalAlignment: Text.AlignHCenter

    // Numbers in violet (primary), letters in blue (secondary)
    function paint(str) {
        return str.replace(/([0-9]+)|([A-Za-z]+)/g, (m, num, word) =>
            `<font color="${num ? Appearance.colors.colPrimary : Appearance.colors.colSecondary}">${m}</font>`);
    }

    // Time
    ClockText {
        id: timeTextTop
        textFormat: Text.StyledText
        text: clockColumn.paint(clockColumn.isVertical ? DateTime.time.split(":")[0].padStart(2, "0") : DateTime.time)
        color: Appearance.colors.colSecondary
        horizontalAlignment: Text.AlignHCenter
        font {
            pixelSize: Config.options.background.widgets.clock.digital.font.size
            weight: Config.options.background.widgets.clock.digital.font.weight
            family: Config.options.background.widgets.clock.digital.font.family
            variableAxes: ({
                    "wdth": Config.options.background.widgets.clock.digital.font.width,
                    "ROND": Config.options.background.widgets.clock.digital.font.roundness
                })
        }
    }

    Loader {
        Layout.topMargin: -40
        Layout.fillWidth: true
        active: clockColumn.isVertical
        visible: active
        sourceComponent: ClockText {
            id: timeTextBottom
            textFormat: Text.StyledText
            text: clockColumn.paint(DateTime.time.split(":")[1].split(" ")[0].padStart(2, "0"))
            color: Appearance.colors.colSecondary
            horizontalAlignment: clockColumn.textHorizontalAlignment
            font {
                pixelSize: timeTextTop.font.pixelSize
                weight: timeTextTop.font.weight
                family: timeTextTop.font.family
                variableAxes: timeTextTop.font.variableAxes
            }
        }
    }

    // Date
    ClockText {
        visible: Config.options.background.widgets.clock.digital.showDate
        Layout.topMargin: -20
        Layout.fillWidth: true
        textFormat: Text.StyledText
        text: clockColumn.paint(DateTime.longDate)
        color: Appearance.colors.colSecondary
        horizontalAlignment: clockColumn.textHorizontalAlignment
    }

    // Quote
    ClockText {
        visible: Config.options.background.widgets.clock.quote.enable && Config.options.background.widgets.clock.quote.text.length > 0
        font.pixelSize: Appearance.font.pixelSize.normal
        text: Config.options.background.widgets.clock.quote.text
        animateChange: false
        color: clockColumn.colText
        horizontalAlignment: clockColumn.textHorizontalAlignment
    }
}
