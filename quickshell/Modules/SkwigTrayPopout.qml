import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Common
import qs.Modals
import qs.Services
import qs.Widgets

DankPopoutStandalone {
    id: root

    property var menuHost: null
    property var menuAnchorItem: null
    property var menuScreen: null

    readonly property var trayItems: SystemTray.items.values.filter(item => !SessionData.isHiddenTrayId(root.trayItemKey(item)))

    function trayItemKey(trayItem) {
        const id = trayItem?.id || "";
        const tooltipTitle = trayItem?.tooltipTitle || "";

        if (!tooltipTitle || tooltipTitle === id)
            return id;

        return id + "::" + tooltipTitle;
    }

    function trayIconSourceFor(trayItem) {
        const icon = trayItem?.icon;

        if (typeof icon !== "string" || icon.length === 0)
            return "";

        if (icon.includes("?path=")) {
            const separatorIndex = icon.indexOf("?path=");
            const iconName = icon.substring(0, separatorIndex);
            const iconPath = icon.substring(separatorIndex + 6);
            let fileName = iconName.substring(iconName.lastIndexOf("/") + 1);

            if (fileName.startsWith("dropboxstatus"))
                fileName = "hicolor/16x16/status/" + fileName;

            return "file://" + iconPath + "/" + fileName;
        }

        if (icon.startsWith("/") && !icon.startsWith("file://"))
            return "file://" + icon;

        return icon;
    }

    function trayItemFallbackText(trayItem) {
        const title = trayItem?.tooltipTitle || trayItem?.title || trayItem?.id || "?";
        return title.length > 0 ? title.charAt(0).toUpperCase() : "?";
    }

    function openThemedMenu(trayItem) {
        const host = menuHost;
        const anchor = menuAnchorItem;
        const targetScreen = menuScreen;

        close();

        if (!host || !anchor || !targetScreen || !trayItem?.hasMenu)
            return;

        Qt.callLater(() => {
            host.showForTrayItem(trayItem, anchor, targetScreen, false, false, host.axis);
        });
    }

    function openContextMenuFallback(trayItem, area, mouse) {
        const host = menuHost;

        if (!host || !trayItem || !area)
            return;

        const globalPosition = area.mapToGlobal(mouse.x, mouse.y);

        close();
        host.callContextMenuFallback(trayItem.id, Math.round(globalPosition.x), Math.round(globalPosition.y));
    }

    layerNamespace: "skwig:system-tray-poc"
    popupWidth: Math.min(420, Math.max(120, root.trayItems.length * 38 + 20))
    popupHeight: 56
    positioning: ""
    fullHeightSurface: true

    onBackgroundClicked: close()

    Component.onDestruction: {
        if (PopoutService.controlCenterPopout === root)
            PopoutService.controlCenterPopout = null;
    }

    content: Component {
        Item {
            StyledText {
                anchors.centerIn: parent
                visible: root.trayItems.length === 0
                text: I18n.tr("No tray items")
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            Flickable {
                id: systemTrayFlickable

                anchors.fill: parent
                anchors.margins: 8
                visible: root.trayItems.length > 0
                clip: true
                contentWidth: Math.max(width, trayItemsRow.implicitWidth)
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: trayItemsRow

                    x: Math.max(0, (systemTrayFlickable.width - implicitWidth) / 2)
                    y: Math.round((systemTrayFlickable.height - height) / 2)
                    height: 36
                    spacing: 2

                    Repeater {
                        model: root.trayItems

                        delegate: Rectangle {
                            id: trayItemButton

                            required property var modelData

                            width: 36
                            height: 36
                            radius: 6
                            color: trayItemMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

                            IconImage {
                                id: trayItemIcon

                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                source: root.trayIconSourceFor(trayItemButton.modelData)
                                visible: status === Image.Ready
                                asynchronous: true
                                smooth: true
                                mipmap: true
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: !trayItemIcon.visible
                                text: root.trayItemFallbackText(trayItemButton.modelData)
                                color: "#ffffff"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: trayItemMouseArea

                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor

                                onClicked: mouse => {
                                    const trayItem = trayItemButton.modelData;

                                    if (!trayItem)
                                        return;

                                    if (mouse.button === Qt.MiddleButton) {
                                        trayItem.secondaryActivate();
                                        return;
                                    }

                                    if (mouse.button === Qt.RightButton || trayItem.onlyMenu) {
                                        if (trayItem.hasMenu) {
                                            root.openThemedMenu(trayItem);
                                            return;
                                        }

                                        if (mouse.button === Qt.RightButton)
                                            root.openContextMenuFallback(trayItem, trayItemMouseArea, mouse);

                                        return;
                                    }

                                    trayItem.activate();
                                    root.close();
                                }

                                onWheel: wheel => {
                                    trayItemButton.modelData.scroll(wheel.angleDelta.y, false);
                                    wheel.accepted = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
