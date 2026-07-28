import QtQuick
import qs.Modules.DankBar.Widgets
import qs.Widgets

Rectangle {
    id: root

    required property var barWindow
    required property real barThickness
    required property var currentScreen
    required property var systemTrayPopout

    signal clicked(var button)

    width: 40
    radius: 4
    color: {
        if (systemTrayPopout?.shouldBeVisible)
            return Qt.rgba(1, 1, 1, 0.16);

        if (mouseArea.containsMouse)
            return Qt.rgba(1, 1, 1, 0.10);

        return "transparent";
    }

    DankIcon {
        anchors.centerIn: parent
        name: "apps"
        size: 22
        color: "#ffffff"
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
        barSpacing: 4
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
            root.systemTrayPopout.menuHost = root.trayMenuHost;
            root.systemTrayPopout.menuAnchorItem = root;
            root.systemTrayPopout.menuScreen = root.currentScreen;
            root.clicked(root);
        }
    }
}
