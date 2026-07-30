pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    /*
     * Resolves to ~/.config/matugen.json on a normal Linux setup,
     * while respecting XDG_CONFIG_HOME.
     */
    readonly property string colorsPath: Paths.strip(StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)) + "/wallpaper.matugen.json"

    property string resolvedColorsPath: ""
    property var colorsData: ({})

    Component.onCompleted: resolveColorsPath()

    readonly property string mode: {
        if (colorsData && typeof colorsData === "object") {
            const configuredMode = String(colorsData.mode || "").trim().toLowerCase();

            if (configuredMode === "light" || configuredMode === "dark") {
                return configuredMode;
            }

            if (typeof colorsData.is_dark_mode === "boolean") {
                return colorsData.is_dark_mode ? "dark" : "light";
            }
        }

        return "dark";
    }

    readonly property bool isLightMode: mode === "light"

    function readColor(role, fallback) {
        if (!colorsData || typeof colorsData !== "object" || !colorsData.colors || typeof colorsData.colors !== "object") {
            return fallback;
        }

        const roleData = colorsData.colors[role];

        if (!roleData || typeof roleData !== "object") {
            return fallback;
        }

        const modeData = roleData[root.mode];

        if (modeData && typeof modeData === "object" && typeof modeData.color === "string" && modeData.color.length > 0) {
            return modeData.color;
        }

        const defaultData = roleData.default;

        if (defaultData && typeof defaultData === "object" && typeof defaultData.color === "string" && defaultData.color.length > 0) {
            return defaultData.color;
        }

        return fallback;
    }

    function loadColors() {
        try {
            const contents = colorsFile.text();

            if (!contents || contents.trim().length === 0) {
                return;
            }

            const parsed = JSON.parse(contents);

            if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
                throw new Error("matugen.json root must be an object");
            }

            /*
             * Only replace the active data after successful parsing.
             * A partial or malformed write therefore leaves the
             * previous palette active.
             */
            colorsData = parsed;
        } catch (error) {
            console.warn("SkwigMatugenTheme: failed to parse " + colorsPath + ": " + error);
        }
    }

    function resolveColorsPath() {
        Proc.runCommand("skwigMatugenThemePath", ["readlink", "-f", colorsPath], (output, code) => {
            const resolvedPath = String(output || "").trim();
            resolvedColorsPath = code === 0 && resolvedPath.length > 0 ? resolvedPath : colorsPath;
        }, 0);
    }

    /*
     * Base colors used by the Theme compatibility singleton.
     */

    readonly property color primary: readColor("primary", "#d0bcff")

    readonly property color primaryText: readColor("on_primary", "#381e72")

    readonly property color primaryContainer: readColor("primary_container", "#4f378b")

    readonly property color secondary: readColor("secondary", "#ccc2dc")

    readonly property color surface: readColor("surface", "#141218")

    readonly property color surfaceText: readColor("on_surface", "#e6e0e9")

    readonly property color surfaceVariant: readColor("surface_variant", "#49454f")

    readonly property color surfaceVariantText: readColor("on_surface_variant", "#cac4d0")

    readonly property color background: readColor("background", surface)

    readonly property color outline: readColor("outline", "#938f99")

    readonly property color surfaceContainer: readColor("surface_container", "#211f26")

    readonly property color surfaceContainerHigh: readColor("surface_container_high", "#2b2930")

    readonly property color surfaceTint: readColor("surface_tint", primary)

    readonly property color error: readColor("error", "#f2b8b5")

    /*
     * Material does not define a standard warning role.
     * Use the generated tertiary accent.
     */
    readonly property color warning: readColor("tertiary", "#ff9800")

    readonly property color shadow: readColor("shadow", "#000000")

    FileView {
        id: colorsFile

        path: root.resolvedColorsPath

        blockLoading: true
        watchChanges: true
        printErrors: false

        onLoaded: {
            root.loadColors();
        }

        onFileChanged: {
            reload();
        }

        onLoadFailed: error => {
            console.warn("SkwigMatugenTheme: failed to load " + path + ": " + error);
        }
    }
}
