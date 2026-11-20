pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common.functions

// Frosted-glass palette for the right sidebar.
// Everything derives from the Material You tokens, so it follows wallpaper changes.
Singleton {
    id: root

    readonly property color base: Appearance.m3colors.m3background
    readonly property color onBase: Appearance.m3colors.m3onBackground
    readonly property color accent: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.30)  // active/toggled: violet glass ~70%
    readonly property color accentHover: ColorUtils.transparentize(Appearance.colors.colPrimaryHover, 0.22)
    readonly property color accentActive: ColorUtils.transparentize(Appearance.colors.colPrimaryActive, 0.15)
    readonly property color onAccent: Appearance.colors.colOnPrimary

    // Panel: tinted see-through sheet; Hyprland blurs what's behind it
    readonly property color panel: ColorUtils.transparentize(base, 0.72)  // ~45% solid, matches the bar
    readonly property color panelBorder: ColorUtils.transparentize(onBase, 0.84)
    readonly property color glowA: ColorUtils.transparentize(Appearance.m3colors.m3primary, 0.72)
    readonly property color glowB: ColorUtils.transparentize(Appearance.m3colors.m3tertiary, 0.80)

    // Cards sitting on the panel: violet glass tiles (~60% solid) with a thin glowing violet edge
    readonly property color tile: Appearance.m3colors.m3primaryContainer
    readonly property color card: ColorUtils.transparentize(tile, 0.58)
    readonly property color cardThin: ColorUtils.transparentize(tile, 0.85)  // left sidebar: big cards ~25% so the blur shows through
    readonly property color cardHover: ColorUtils.transparentize(tile, 0.45)
    readonly property color cardActive: ColorUtils.transparentize(tile, 0.35)
    readonly property color cardPressed: ColorUtils.transparentize(tile, 0.28)
    readonly property color cardBorder: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.50)

    // Popups over the sidebar need to stay readable
    readonly property color dialog: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHigh, 0.30)

    readonly property color textDim: "#004ac9"  // labels: dark blue
    readonly property color textSoft: "#0059e7"  // text: theme blue

    readonly property real radiusPanel: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
    readonly property real radiusCard: Appearance.rounding.large
}
