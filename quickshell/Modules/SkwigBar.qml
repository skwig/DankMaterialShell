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
    WlrLayershell.namespace: "skwig:bar"

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

        Row {
            id: leftSection

            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
                right: centerSection.left

                leftMargin: 12
            }

            SkwigWindowTitle {
                anchors {
                    fill: parent
                }
            }
        }

        QtObject {
            id: workspaceBarConfig

            property bool noBackground: true
        }

        Row {
            id: centerSection

            anchors {
                centerIn: parent
            }

            WorkspaceSwitcher {
                id: workspaceSwitcher

                widgetHeight: 30
                barThickness: root.implicitHeight
                parentScreen: root.screen
                blurBarWindow: root
                barConfig: workspaceBarConfig
            }
        }

        Row {
            id: rightSection

            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right

                rightMargin: 12
            }

            spacing: 0

            SkwigSubmapIndicator {
                anchors.verticalCenter: parent.verticalCenter
            }

            SkwigSystemTrayButton {
                height: parent.height
                barWindow: root
                barThickness: root.implicitHeight
                currentScreen: root.screen
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
