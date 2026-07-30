import QtQuick
import qs.Common
import qs.Modules.DankBar.Widgets
import qs.Widgets

Rectangle {
    id: root

    required property var barWindow
    required property real barThickness
    required property var currentScreen
    required property var systemTrayPopout

    signal clicked(var button)

    width: Theme.barHeight - Theme.spacingS
    radius: Theme.cornerRadius / 3
    color: {
        if (systemTrayPopout?.shouldBeVisible)
            return Theme.surfacePressed;

        if (mouseArea.containsMouse)
            return Theme.surfaceHover;

        return "transparent";
    }

    DankIcon {
        anchors.centerIn: parent
        name: "apps"
        size: Theme.iconSize - Theme.spacingXXS
        color: Theme.surfaceText
    }

    QtObject {
        id: trayMenuAxis

        property bool isVertical: false
        property bool isHorizontal: true
        property string edge: "top"
    }

    SystemTrayBar {
        id: trayMenuHost

        visible: false
        parentWindow: root.barWindow
        parentScreen: root.currentScreen
        widgetThickness: root.barThickness
        barThickness: root.barThickness
        barSpacing: Theme.spacingXS
        axis: trayMenuAxis
        barConfig: null
        isAtBottom: false
        isAutoHideBar: false
        useAutomaticOverflow: false
        useOverflowPopup: false
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.systemTrayPopout.menuHost = trayMenuHost;
            root.systemTrayPopout.menuAnchorItem = root;
            root.systemTrayPopout.menuScreen = root.currentScreen;
            root.clicked(root);
        }
    }
}
