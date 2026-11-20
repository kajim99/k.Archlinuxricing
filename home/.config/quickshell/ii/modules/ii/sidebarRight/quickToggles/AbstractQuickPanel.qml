import QtQuick
import qs.modules.common

Rectangle {
    id: root

    radius: GlassStyle.radiusCard
    color: GlassStyle.card

    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openNightLightDialog()
    signal openWifiDialog()
}
