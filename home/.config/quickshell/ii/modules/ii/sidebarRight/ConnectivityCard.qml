import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

// Large glass card: click toggles, chevron (or right click) opens the device list
RippleButton {
    id: root
    required property string title
    required property string subtitle
    required property string iconName
    property bool active: false
    signal toggleRequested()
    signal menuRequested()

    implicitHeight: 58
    buttonRadius: GlassStyle.radiusCard
    colBackground: root.active ? GlassStyle.accent : GlassStyle.card
    colBackgroundHover: root.active ? GlassStyle.accentHover : GlassStyle.cardHover
    colRipple: root.active ? Appearance.colors.colPrimaryActive : GlassStyle.cardActive
    property color colContent: root.active ? GlassStyle.onAccent : Appearance.colors.colSecondary // off: theme blue

    onClicked: root.toggleRequested()
    altAction: () => root.menuRequested()

    Rectangle {
        anchors.fill: parent
        radius: root.buttonRadius
        color: "transparent"
        border.width: 1
        border.color: root.active ? ColorUtils.transparentize(GlassStyle.onAccent, 0.8) : GlassStyle.cardBorder
    }

    contentItem: RowLayout {
        anchors {
            fill: parent
            leftMargin: 8
            rightMargin: 2
        }
        spacing: 8

        Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: width / 2
            color: root.active ? ColorUtils.transparentize(GlassStyle.onAccent, 0.82) : GlassStyle.card
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 20
                fill: root.active ? 1 : 0
                text: root.iconName
                color: root.colContent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            MarqueeText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: 600
                color: root.colContent
            }
            MarqueeText {
                Layout.fillWidth: true
                text: root.subtitle
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: ColorUtils.transparentize(root.colContent, 0.25)
            }
        }

        RippleButton {
            implicitWidth: 28
            implicitHeight: 40
            buttonRadius: Appearance.rounding.full
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.transparentize(root.colContent, 0.88)
            colRipple: ColorUtils.transparentize(root.colContent, 0.8)
            onClicked: root.menuRequested()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "chevron_right"
                iconSize: 20
                color: root.colContent
            }
        }
    }
}
