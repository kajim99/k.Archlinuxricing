import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

// Glass dashboard shown when no left-sidebar tabs (AI, translator, anime) are enabled:
// clock header, notifications, and the calendar/to-do/timer card
Item {
    id: root
    property real padding: 10

    // Soft accent glows behind the glass, clipped to the rounded panel
    Item {
        id: glowLayer
        anchors.fill: parent
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: glowLayer.width
                height: glowLayer.height
                radius: GlassStyle.radiusPanel
            }
        }
        RadialGradient {
            x: -parent.width * 0.45
            y: -parent.width * 0.55
            width: parent.width * 1.2
            height: parent.width * 1.2
            gradient: Gradient {
                GradientStop { position: 0.0; color: GlassStyle.glowA }
                GradientStop { position: 0.5; color: "transparent" }
            }
        }
        RadialGradient {
            x: parent.width * 0.3
            y: parent.height - parent.width * 0.6
            width: parent.width * 1.2
            height: parent.width * 1.2
            gradient: Gradient {
                GradientStop { position: 0.0; color: GlassStyle.glowB }
                GradientStop { position: 0.5; color: "transparent" }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: root.padding

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.topMargin: 8
            Layout.bottomMargin: 4
            spacing: -3

            StyledText {
                text: {
                    const hour = DateTime.clock.date.getHours();
                    const greeting = hour < 5 ? Translation.tr("Good night") : hour < 12 ? Translation.tr("Good morning") : hour < 18 ? Translation.tr("Good afternoon") : Translation.tr("Good evening");
                    return `${greeting}, ${SystemInfo.username}`;
                }
                font.pixelSize: Appearance.font.pixelSize.small
                color: GlassStyle.textDim
            }
            StyledText {
                text: DateTime.time
                font.family: Appearance.font.family.expressive
                font.pixelSize: 40
                font.weight: 600
                color: Appearance.colors.colSecondary // theme blue
            }
            StyledText {
                Layout.topMargin: 2
                text: `${DateTime.collapsedCalendarFormat}  ·  ${Translation.tr("Up %1").arg(DateTime.uptime)}`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: GlassStyle.textDim
            }
        }

        CenterWidgetGroup {
            Layout.fillWidth: true
            color: GlassStyle.cardThin
            Layout.fillHeight: true
        }

        BottomWidgetGroup {
            Layout.fillWidth: true
            color: GlassStyle.cardThin
            Layout.preferredHeight: implicitHeight
        }
    }
}
