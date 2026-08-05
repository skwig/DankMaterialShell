import QtQuick
import QtCore
import Quickshell
import Quickshell.Wayland
import qs.Common

PanelWindow {
    id: root

    visible: true
    color: "black"

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "skwig-dms-wallpaper"
    WlrLayershell.exclusiveZone: -1

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    readonly property string wallpaperPath: Paths.strip(StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)) + "/wallpaper.jpg"

    Image {
        anchors.fill: parent
        source: Paths.toFileUrl(root.wallpaperPath)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }
}
