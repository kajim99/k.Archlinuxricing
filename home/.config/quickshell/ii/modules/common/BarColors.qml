import QtQuick
import Quickshell
pragma Singleton

// Fixed dark-violet palette for the top bar (icons/rings violet, text blue) (modules/ii/bar). Replaces Appearance colors there only.
Singleton {
    // Backgrounds, darkest to lightest
    readonly property color colLayer0: "#731e0c3d"   // ~45% opaque: glass bar, blurred by Hyprland
    readonly property color colLayer0Border: "#330083"
    readonly property color m3surfaceContainer: "#99200e3e"
    readonly property color colLayer1: "#99270070"
    readonly property color colSurfaceContainerHigh: "#99300087"
    readonly property color colLayer1Hover: "#a63c009e"
    readonly property color colLayer1Active: "#664900be"
    readonly property color colOutlineVariant: "#3c00af"
    readonly property color m3outlineVariant: "#3c00af"

    // Highlight containers (toggled buttons, tray, workspace bg)
    readonly property color colSecondaryContainer: "#b345009e"
    readonly property color m3secondaryContainer: "#b345009e"
    readonly property color colSecondaryContainerHover: "#bf5200c0"
    readonly property color colSecondaryContainerActive: "#666200df"

    // Bar popups (battery, CPU/RAM, clock, tray menus): glass sheet like the panels
    readonly property color colPopup: "#73200e3e"

    // Thin glowing edge around the bar's widget pills (glass tile look)
    readonly property color colGroupBorder: "#738703ff"

    // Accents
    readonly property color colPrimary: "#8703ff"
    readonly property color colOnPrimary: "#ffffff"
    readonly property color colSecondary: "#8703ff"
    readonly property color colTertiary: "#8703ff"
    readonly property color colError: "#ff5c8a"
    readonly property color m3error: "#ff5c8a"

    // Text
    readonly property color colOnLayer0: "#0059e7"
    readonly property color colOnLayer1: "#0059e7"
    readonly property color colOnLayer2: "#8703ff"  // util-button + tray icons
    readonly property color colOnLayer1Inactive: "#6d5a96"
    readonly property color colSubtext: "#004ac9"
    readonly property color colOnSurfaceVariant: "#8703ff"
    readonly property color colOnSecondaryContainer: "#8703ff"
    readonly property color m3onSecondaryContainer: "#0059e7"

    readonly property bool darkmode: true
}
