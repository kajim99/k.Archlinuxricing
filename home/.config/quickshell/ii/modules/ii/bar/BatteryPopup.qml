import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

StyledPopup {
    id: root
    // Charge mode (2026-11-24): read from sysfs each time the popup opens; click the battery icon to cycle it
    property string chargeMode: (chargeFile.text().match(/\[([^\]]+)\]/) || ["", ""])[1]
    property FileView chargeFile: FileView { path: "/sys/class/power_supply/BAT1/charge_types"; blockLoading: true }
    onActiveChanged: if (active) { chargeFile.reload(); drainFile.reload(); seedFile.reload() }  // sysfs can't be watched: re-read on every hover
    // Real time on a full charge per power mode, from YOUR measured drain (~/.local/bin/battery-log, 2026-11-24)
    property FileView drainFile: FileView { path: Quickshell.env("HOME") + "/.local/state/battery-drain.json"; blockLoading: true }
    // Past drain from upower's own history (copied once 2026-11-24): typical (median) and light (lowest 10%) use
    property FileView seedFile: FileView { path: Quickshell.env("HOME") + "/.local/state/battery-history-seed.json"; blockLoading: true }
    function seedTime(key) {
        let d, s; try { d = JSON.parse(drainFile.text()); s = JSON.parse(seedFile.text()); } catch (e) { return ""; }
        const w = s[key]; if (!(w > 0)) return "";
        const hours = d.full_wh * (root.chargeMode === "Long_Life" ? 0.8 : 1.0) / w;
        const h = Math.floor(hours), min = Math.round((hours - h) * 60);
        return (h > 0 ? `${h}h ` : "") + `${min}m (${w} W)`;
    }
    function measured(mode) { try { const m = JSON.parse(drainFile.text()).modes[mode]; return m && m.minutes >= 10; } catch (e) { return false; } }
    function fullTime(mode) {
        let d; try { d = JSON.parse(drainFile.text()); } catch (e) { return Translation.tr("measuring…"); }
        const m = d.modes && d.modes[mode];
        if (!m || m.minutes < 10 || !(m.watts > 0)) return Translation.tr("measuring…");
        const hours = d.full_wh * (root.chargeMode === "Long_Life" ? 0.8 : 1.0) / m.watts;
        const h = Math.floor(hours), min = Math.round((hours - h) * 60);
        return (h > 0 ? `${h}h ` : "") + `${min}m`;
    }
    property var modeText: ({ "Long_Life": "Long Life (stops ~80%)", "Standard": "Standard (to 100%)", "Fast": "Fast (to 100%)" })
    
    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        // Header
        StyledPopupHeaderRow {
            icon: "battery_android_full"
            label: Translation.tr("Battery")
        }

        StyledPopupValueRow {
            visible: {
                let timeValue = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                let power = Battery.energyRate;
                return !(Battery.chargeState == 4 || timeValue <= 0 || power <= 0.01);
            }
            icon: "schedule"
            label: Battery.isCharging ? Translation.tr("Time to full:") : Translation.tr("Time to empty:")
            value: {
                function formatTime(seconds) {
                    var h = Math.floor(seconds / 3600);
                    var m = Math.floor((seconds % 3600) / 60);
                    if (h > 0)
                        return `${h}h, ${m}m`;
                    else
                        return `${m}m`;
                }
                if (Battery.isCharging)
                    return formatTime(Battery.timeToFull);
                else
                    return formatTime(Battery.timeToEmpty);
            }
        }

        StyledPopupValueRow {
            visible:  !(Battery.chargeState != 4 && Battery.energyRate == 0)
            icon: "bolt"
            label: {
                if (Battery.chargeState == 4) {
                    return Translation.tr("Fully charged");
                } else if (Battery.chargeState == 1) {
                    return Translation.tr("Charging:");
                } else {
                    return Translation.tr("Discharging:");
                }
            }
            value: {
                if (Battery.chargeState == 4) {
                    return "";
                } else {
                    return `${Battery.energyRate.toFixed(2)}W`;
                }
            }
        }

        StyledPopupValueRow {
            icon: "battery_charging_full"
            label: Translation.tr("Charge mode:")
            value: root.modeText[root.chargeMode] || root.chargeMode
        }

        StyledPopupValueRow {
            icon: "battery_full"
            label: root.chargeMode === "Long_Life" ? Translation.tr("On a full charge (80%):") : Translation.tr("On a full charge:")
            value: ""
        }
        StyledPopupValueRow { visible: value !== ""; icon: "history"; label: Translation.tr("  your typical use"); value: root.seedTime("typical_w") }
        StyledPopupValueRow { visible: value !== ""; icon: "eco"; label: Translation.tr("  your lightest use"); value: root.seedTime("light_w") }
        StyledPopupValueRow { visible: root.measured("saver"); icon: "eco"; label: Translation.tr("  saver"); value: root.fullTime("saver") }
        StyledPopupValueRow { visible: root.measured("balanced"); icon: "balance"; label: Translation.tr("  balanced"); value: root.fullTime("balanced") }
        StyledPopupValueRow { visible: root.measured("max"); icon: "rocket_launch"; label: Translation.tr("  max"); value: root.fullTime("max") }

        StyledText {
            text: Translation.tr("Click: 100% (Standard/Fast) · Right-click: 80%")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: BarColors.colOnSurfaceVariant
            opacity: 0.7
        }

        StyledPopupValueRow {
            icon: "heart_check"
            label: Translation.tr("Health:")
            value: `${(Battery.health).toFixed(1)}%`
        }
    }
}
