import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    property Toplevel activeWindow: ToplevelManager.activeToplevel

    readonly property var activeDesktopEntry: activeWindow?.appId ? DesktopEntries.heuristicLookup(Paths.moddedAppId(activeWindow.appId)) : null
    readonly property string activeWindowIconSource: activeWindow?.appId ? Paths.getAppIcon(activeWindow.appId, activeDesktopEntry) : ""
    readonly property string activeWindowTitle: activeWindow?.title || activeWindow?.appId || "Desktop"

    clip: true

    Row {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        spacing: 8

        Item {
            id: activeWindowIconContainer

            width: 20
            height: 20

            IconImage {
                id: activeWindowIcon

                anchors.fill: parent

                source: root.activeWindowIconSource
                visible: root.activeWindow && status === Image.Ready
                smooth: true
                mipmap: true
                asynchronous: true
            }

            DankIcon {
                anchors.centerIn: parent
                name: "desktop_windows"
                size: 19
                color: "#ffffff"
                visible: !root.activeWindow
            }

            DankIcon {
                anchors.centerIn: parent
                name: "sports_esports"
                size: 19
                color: "#ffffff"
                visible: root.activeWindow && root.activeWindow.appId && activeWindowIcon.status !== Image.Ready && Paths.isSteamApp(root.activeWindow.appId)
            }

            StyledText {
                anchors.centerIn: parent
                text: {
                    if (!root.activeWindow?.appId)
                        return "?";

                    const appName = Paths.getAppName(root.activeWindow.appId, root.activeDesktopEntry);
                    return appName ? appName.charAt(0).toUpperCase() : "?";
                }
                color: "#ffffff"
                font.pixelSize: 11
                font.weight: Font.Bold
                visible: root.activeWindow && root.activeWindow.appId && activeWindowIcon.status !== Image.Ready && !Paths.isSteamApp(root.activeWindow.appId)
            }
        }

        StyledText {
            width: Math.max(0, parent.width - activeWindowIconContainer.width - parent.spacing)
            anchors.verticalCenter: parent.verticalCenter
            text: root.activeWindowTitle
            color: "#ffffff"
            font.pixelSize: 15
            font.weight: Font.Medium
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }
    }
}
