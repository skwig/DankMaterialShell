//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma UseQApplication
//@ pragma AppId dev.skwig.dms.bluetoothpoc

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Common
import qs.Modals
import qs.Services
import qs.Widgets
import qs.Modules.ControlCenter.Details
import qs.Modules.DankDash.Overview

ShellRoot {
    id: root

    readonly property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    function formatBarTime(date) {
        if (!date)
            return "--:--";

        const minutes = String(date.getMinutes()).padStart(2, "0");
        const hours = date.getHours();

        if (SettingsData.use24HourClock)
            return String(hours).padStart(2, "0") + ":" + minutes;

        const displayHours = hours === 0 ? 12 : hours > 12 ? hours - 12 : hours;

        const suffix = hours >= 12 ? " PM" : " AM";

        return String(displayHours) + ":" + minutes + suffix;
    }

    SystemClock {
        id: barClock

        precision: SystemClock.Minutes
    }

    Connections {
        target: SessionService

        function onSessionResumed() {
            barClock.enabled = false;
            barClock.enabled = true;
        }
    }

    /*
     * Bluetooth popup
     */
    DankPopoutStandalone {
        id: bluetoothPopout

        screen: root.targetScreen
        layerNamespace: "skwig:bluetooth-poc"

        popupWidth: 520
        popupHeight: Math.min(620, Math.max(360, (screen?.height ?? 1080) - 96))

        positioning: ""
        fullHeightSurface: true

        onBackgroundClicked: close()

        Component.onDestruction: {
            if (PopoutService.controlCenterPopout === bluetoothPopout) {
                PopoutService.controlCenterPopout = null;
            }
        }

        onShouldBeVisibleChanged: {
            if (!shouldBeVisible && BluetoothService.adapter?.discovering) {
                BluetoothService.adapter.discovering = false;
            }
        }

        content: Component {
            Item {
                BluetoothDetail {
                    id: bluetoothDetail

                    anchors.fill: parent
                    bluetoothCodecModalRef: codecSelector

                    onShowCodecSelector: device => {
                        codecSelector.show(device);
                    }
                }

                BluetoothCodecSelector {
                    id: codecSelector

                    anchors.fill: parent
                    z: 10000

                    onCodecSelected: (deviceAddress, codecName) => {
                        bluetoothDetail.updateDeviceCodecDisplay(deviceAddress, codecName);
                    }
                }
            }
        }
    }

    /*
     * Network popup
     */
    DankPopoutStandalone {
        id: networkPopout

        screen: root.targetScreen
        layerNamespace: "skwig:network-poc"

        popupWidth: 520
        popupHeight: Math.min(620, Math.max(360, (screen?.height ?? 1080) - 96))

        positioning: ""
        fullHeightSurface: true

        onBackgroundClicked: close()

        Component.onDestruction: {
            if (PopoutService.controlCenterPopout === networkPopout) {
                PopoutService.controlCenterPopout = null;
            }
        }

        content: Component {
            NetworkDetail {
                anchors.fill: parent
            }
        }
    }

    /*
     * Audio output popup
     */
    DankPopoutStandalone {
        id: audioPopout

        screen: root.targetScreen
        layerNamespace: "skwig:audio-poc"

        popupWidth: 520
        popupHeight: Math.min(620, Math.max(360, (screen?.height ?? 1080) - 96))

        positioning: ""
        fullHeightSurface: true

        onBackgroundClicked: close()

        Component.onDestruction: {
            if (PopoutService.controlCenterPopout === audioPopout) {
                PopoutService.controlCenterPopout = null;
            }
        }

        content: Component {
            AudioOutputDetail {
                anchors.fill: parent

                /*
                 * Show the master output volume slider inside this
                 * standalone detail popup.
                 */
                hasVolumeSliderInCC: false
            }
        }
    }

    /*
     * Battery and power-profile popup
     */
    DankPopoutStandalone {
        id: batteryPopout

        property real desiredContentHeight: 360

        screen: root.targetScreen
        layerNamespace: "skwig:battery-poc"

        popupWidth: 520

        popupHeight: Math.min(Math.max(320, desiredContentHeight), Math.max(320, (screen?.height ?? 1080) - 96))

        positioning: ""
        fullHeightSurface: true

        onBackgroundClicked: close()

        Component.onDestruction: {
            if (PopoutService.controlCenterPopout === batteryPopout) {
                PopoutService.controlCenterPopout = null;
            }
        }

        content: Component {
            BatteryDetail {
                anchors.fill: parent

                Component.onCompleted: {
                    batteryPopout.desiredContentHeight = implicitHeight;
                }

                onImplicitHeightChanged: {
                    batteryPopout.desiredContentHeight = implicitHeight;
                }
            }
        }
    }

    /*
     * Clock and calendar popup
     */
    DankPopoutStandalone {
        id: calendarPopout

        screen: root.targetScreen
        layerNamespace: "skwig:calendar-poc"

        popupWidth: SettingsData.showWeekNumber ? 760 : 724

        popupHeight: 390

        positioning: ""
        fullHeightSurface: true

        onBackgroundClicked: close()

        Component.onDestruction: {
            if (PopoutService.controlCenterPopout === calendarPopout) {
                PopoutService.controlCenterPopout = null;
            }
        }

        content: Component {
            Item {
                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM

                    spacing: Theme.spacingM

                    ClockCard {
                        id: popupClockCard

                        width: 148
                        height: parent.height
                    }

                    CalendarOverviewCard {
                        width: parent.width - popupClockCard.width - parent.spacing

                        height: parent.height

                        onCloseDash: {
                            calendarPopout.close();
                        }
                    }
                }
            }
        }
    }

    /*
     * Needed by NetworkDetail for password-protected Wi-Fi.
     */
    LazyLoader {
        id: wifiPasswordModalLoader

        active: false

        readonly property WifiPasswordModal loadedModal: item as WifiPasswordModal

        Component.onCompleted: {
            PopoutService.wifiPasswordModalLoader = wifiPasswordModalLoader;
        }

        Component.onDestruction: {
            if (PopoutService.wifiPasswordModalLoader === wifiPasswordModalLoader) {
                PopoutService.wifiPasswordModalLoader = null;
            }

            if (PopoutService.wifiPasswordModal === wifiPasswordModalLoader.loadedModal) {
                PopoutService.wifiPasswordModal = null;
            }
        }

        WifiPasswordModal {
            id: wifiPasswordModal

            Component.onCompleted: {
                PopoutService.wifiPasswordModal = wifiPasswordModal;
            }
        }
    }

    /*
     * Full-width temporary bar
     */
    PanelWindow {
        id: barWindow

        screen: root.targetScreen
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

            if (calendarPopout !== activePopup)
                calendarPopout.close();
        }

        function toggleDetailPopup(popup, button) {
            if (!screen)
                return;

            const wasOpen = popup.shouldBeVisible;

            closeOtherPopouts(popup);

            /*
             * Reused DMS components may call
             * PopoutService.closeControlCenter().
             */
            PopoutService.controlCenterPopout = popup;

            /*
             * Convert the button's position from the Row into
             * full-screen bar coordinates.
             */
            const buttonPosition = button.mapToItem(barBackground, 0, 0);

            const triggerX = buttonPosition.x;
            const triggerY = implicitHeight + 4;

            popup.setTriggerPosition(triggerX, triggerY, button.width, "right", screen, SettingsData.Position.Top, implicitHeight, 0, null);

            if (wasOpen)
                popup.close();
            else
                popup.open();
        }

        Rectangle {
            id: barBackground

            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.4)

            Row {
                id: rightButtons

                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                }

                spacing: 0

                /*
                 * Battery and power-profile button
                 */
                Rectangle {
                    id: batteryButton

                    width: 40
                    height: rightButtons.height
                    radius: 4

                    color: {
                        if (batteryPopout.shouldBeVisible)
                            return Qt.rgba(1, 1, 1, 0.16);

                        if (batteryMouseArea.containsMouse)
                            return Qt.rgba(1, 1, 1, 0.10);

                        return "transparent";
                    }

                    DankIcon {
                        anchors.centerIn: parent

                        name: BatteryService.getBatteryIcon()

                        size: 22

                        color: {
                            if (BatteryService.isLowBattery && !BatteryService.isCharging) {
                                return Theme.error;
                            }

                            return "#ffffff";
                        }
                    }

                    MouseArea {
                        id: batteryMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            barWindow.toggleDetailPopup(batteryPopout, batteryButton);
                        }
                    }
                }

                /*
                 * Network button
                 */
                Rectangle {
                    id: networkButton

                    width: 40
                    height: rightButtons.height
                    radius: 4

                    color: {
                        if (networkPopout.shouldBeVisible)
                            return Qt.rgba(1, 1, 1, 0.16);

                        if (networkMouseArea.containsMouse)
                            return Qt.rgba(1, 1, 1, 0.10);

                        return "transparent";
                    }

                    DankIcon {
                        anchors.centerIn: parent

                        name: {
                            if (!NetworkService.networkAvailable)
                                return "wifi_off";

                            if (NetworkService.networkStatus === "ethernet") {
                                return "lan";
                            }

                            return NetworkService.wifiSignalIcon || "wifi_off";
                        }

                        size: 22

                        color: NetworkService.networkStatus !== "disconnected" ? "#ffffff" : Qt.rgba(1, 1, 1, 0.5)
                    }

                    MouseArea {
                        id: networkMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            barWindow.toggleDetailPopup(networkPopout, networkButton);
                        }
                    }
                }

                /*
                 * Bluetooth button
                 */
                Rectangle {
                    id: bluetoothButton

                    width: 40
                    height: rightButtons.height
                    radius: 4

                    color: {
                        if (bluetoothPopout.shouldBeVisible)
                            return Qt.rgba(1, 1, 1, 0.16);

                        if (bluetoothMouseArea.containsMouse)
                            return Qt.rgba(1, 1, 1, 0.10);

                        return "transparent";
                    }

                    DankIcon {
                        anchors.centerIn: parent

                        name: !BluetoothService.available ? "bluetooth_disabled" : BluetoothService.connected ? "bluetooth_connected" : "bluetooth"

                        size: 22

                        color: BluetoothService.enabled ? "#ffffff" : Qt.rgba(1, 1, 1, 0.5)
                    }

                    MouseArea {
                        id: bluetoothMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            barWindow.toggleDetailPopup(bluetoothPopout, bluetoothButton);
                        }
                    }
                }

                /*
                 * Audio output button
                 */
                Rectangle {
                    id: audioButton

                    width: 40
                    height: rightButtons.height
                    radius: 4

                    color: {
                        if (audioPopout.shouldBeVisible)
                            return Qt.rgba(1, 1, 1, 0.16);

                        if (audioMouseArea.containsMouse)
                            return Qt.rgba(1, 1, 1, 0.10);

                        return "transparent";
                    }

                    DankIcon {
                        anchors.centerIn: parent

                        name: {
                            const audio = AudioService.sink?.audio;

                            if (!audio)
                                return "volume_off";

                            if (audio.muted)
                                return "volume_off";

                            if (audio.volume <= 0)
                                return "volume_mute";

                            if (audio.volume <= 0.33)
                                return "volume_down";

                            return "volume_up";
                        }

                        size: 22

                        color: {
                            const audio = AudioService.sink?.audio;

                            if (!audio || audio.muted || audio.volume <= 0) {
                                return Qt.rgba(1, 1, 1, 0.5);
                            }

                            return "#ffffff";
                        }
                    }

                    MouseArea {
                        id: audioMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            barWindow.toggleDetailPopup(audioPopout, audioButton);
                        }
                    }
                }

                /*
                 * Clock button
                 */
                Rectangle {
                    id: clockButton

                    width: Math.max(68, timeText.implicitWidth + 20)

                    height: rightButtons.height
                    radius: 4

                    color: {
                        if (calendarPopout.shouldBeVisible)
                            return Qt.rgba(1, 1, 1, 0.16);

                        if (clockMouseArea.containsMouse)
                            return Qt.rgba(1, 1, 1, 0.10);

                        return "transparent";
                    }

                    StyledText {
                        id: timeText

                        anchors.centerIn: parent

                        text: root.formatBarTime(barClock.date)
                        color: "#ffffff"

                        font.pixelSize: 16
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: clockMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            barWindow.toggleDetailPopup(calendarPopout, clockButton);
                        }
                    }
                }
            }
        }
    }
}
