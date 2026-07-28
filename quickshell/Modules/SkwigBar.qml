import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Modules.DankBar.Widgets
import qs.Services

PanelWindow {
    id: root

    required property var batteryPopout
    required property var networkPopout
    required property var bluetoothPopout
    required property var audioPopout
    required property var systemTrayPopout
    required property var calendarPopout
    required property var notificationCenterPopout

    property var modelData

    visible: true
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 40
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "skwig:dms-poc-bar"

    function closeOtherPopouts(activePopup) {
        if (batteryPopout !== activePopup)
            batteryPopout.close();

        if (networkPopout !== activePopup)
            networkPopout.close();

        if (bluetoothPopout !== activePopup)
            bluetoothPopout.close();

        if (audioPopout !== activePopup)
            audioPopout.close();

        if (systemTrayPopout !== activePopup)
            systemTrayPopout.close();

        if (calendarPopout !== activePopup)
            calendarPopout.close();

        if (notificationCenterPopout !== activePopup)
            notificationCenterPopout.notificationHistoryVisible = false;
    }

    function toggleDetailPopup(popup, button) {
        if (!screen)
            return;

        const wasOpen = popup.shouldBeVisible;

        closeOtherPopouts(popup);
        PopoutService.controlCenterPopout = popup;

        const buttonPosition = button.mapToItem(barBackground, 0, 0);
        const triggerX = buttonPosition.x;
        const triggerY = implicitHeight + 4;

        popup.setTriggerPosition(triggerX, triggerY, button.width, "right", screen, SettingsData.Position.Top, implicitHeight, 0, null);

        if (wasOpen)
            popup.close();
        else
            popup.open();
    }

    function toggleNotificationCenter(button) {
        if (!screen)
            return;

        const wasOpen = notificationCenterPopout.notificationHistoryVisible || notificationCenterPopout.shouldBeVisible;

        closeOtherPopouts(notificationCenterPopout);

        const buttonPosition = button.mapToItem(barBackground, 0, 0);
        const triggerX = buttonPosition.x;
        const triggerY = implicitHeight + 4;

        notificationCenterPopout.triggerScreen = screen;
        notificationCenterPopout.setTriggerPosition(triggerX, triggerY, button.width, "right", screen, SettingsData.Position.Top, implicitHeight, 0, null);
        notificationCenterPopout.notificationHistoryVisible = !wasOpen;
    }

    Rectangle {
        id: barBackground

        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4)

        SkwigActiveWindow {
            anchors {
                top: parent.top
                left: parent.left
                right: workspaceSwitcher.visible ? workspaceSwitcher.left : rightButtons.left
                bottom: parent.bottom
                leftMargin: 12
                rightMargin: 12
            }
        }

        QtObject {
            id: workspaceBarConfig

            property bool noBackground: true
            property bool removeWidgetPadding: true
            property bool widgetOutlineEnabled: false
            property bool maximizeWidgetIcons: false
            property bool maximizeWidgetText: false
            property real fontScale: 1.0
            property real iconScale: 1.0
            property real widgetPadding: 0
            property real widgetTransparency: 0
        }

        WorkspaceSwitcher {
            id: workspaceSwitcher

            anchors.centerIn: parent
            widgetHeight: 30
            barThickness: root.implicitHeight
            parentScreen: root.screen
            blurBarWindow: root
            barConfig: workspaceBarConfig
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
            parentWindow: root
            parentScreen: root.screen
            widgetThickness: root.implicitHeight
            barThickness: root.implicitHeight
            barSpacing: 4
            axis: trayMenuAxis
            barConfig: null
            isAtBottom: false
            isAutoHideBar: false
            useAutomaticOverflow: false
            useOverflowPopup: false
        }

        Row {
            id: rightButtons

            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
            }

            spacing: 0

            SkwigSubmapIndicator {
                anchors.verticalCenter: parent.verticalCenter
            }

            SkwigSystemTrayButton {
                height: parent.height
                currentScreen: root.screen
                trayMenuHost: trayMenuHost
                systemTrayPopout: root.systemTrayPopout
                onClicked: button => root.toggleDetailPopup(root.systemTrayPopout, button)
            }

            SkwigBatteryButton {
                height: parent.height
                batteryPopout: root.batteryPopout
                onClicked: button => root.toggleDetailPopup(root.batteryPopout, button)
            }

            SkwigNetworkButton {
                height: parent.height
                networkPopout: root.networkPopout
                onClicked: button => root.toggleDetailPopup(root.networkPopout, button)
            }

            SkwigBluetoothButton {
                height: parent.height
                bluetoothPopout: root.bluetoothPopout
                onClicked: button => root.toggleDetailPopup(root.bluetoothPopout, button)
            }

            SkwigAudioButton {
                height: parent.height
                audioPopout: root.audioPopout
                onClicked: button => root.toggleDetailPopup(root.audioPopout, button)
            }

            SkwigNotificationButton {
                height: parent.height
                notificationCenterPopout: root.notificationCenterPopout
                onClicked: button => root.toggleNotificationCenter(button)
            }

            SkwigClockButton {
                height: parent.height
                calendarPopout: root.calendarPopout
                onClicked: button => root.toggleDetailPopup(root.calendarPopout, button)
            }
        }
    }
}
