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

ShellRoot {
    id: root

    readonly property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

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
            if (PopoutService.controlCenterPopout === bluetoothPopout)
                PopoutService.controlCenterPopout = null;
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
     *
     * NetworkDetail is used directly from DMS. With no DMS_SOCKET,
     * NetworkService selects LegacyNetworkService automatically.
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
            if (PopoutService.controlCenterPopout === networkPopout)
                PopoutService.controlCenterPopout = null;
        }

        content: Component {
            NetworkDetail {
                anchors.fill: parent
            }
        }
    }

    /*
     * Required by NetworkDetail when connecting to a secured,
     * previously unsaved Wi-Fi network.
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
     * This is mainly useful when the DMS backend is retained.
     * It does no harm with LegacyNetworkService and keeps the
     * wiring compatible with DMS network credential prompts.
     */
    property string lastCredentialsToken: ""

    Connections {
        target: NetworkService

        function onCredentialsNeeded(token, ssid, setting, fields, hints, reason, connectionType, connectionName, vpnService, fieldsInfo) {
            const modal = wifiPasswordModalLoader.loadedModal;

            const alreadyShown = modal !== null && modal.shouldBeVisible;

            if (alreadyShown && token === root.lastCredentialsToken) {
                return;
            }

            wifiPasswordModalLoader.active = true;

            Qt.callLater(() => {
                const loadedModal = wifiPasswordModalLoader.loadedModal;

                if (!loadedModal)
                    return;

                if (alreadyShown && root.lastCredentialsToken !== "" && root.lastCredentialsToken !== token) {
                    NetworkService.cancelCredentials(root.lastCredentialsToken);
                }

                root.lastCredentialsToken = token;

                loadedModal.showFromPrompt(token, ssid, setting, fields, hints, reason, connectionType, connectionName, vpnService, fieldsInfo);
            });
        }
    }

    /*
     * Temporary full-width bar.
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

        /*
         * Both DMS detail components assume they are the current
         * control-center popout. Point PopoutService at whichever
         * standalone popup is currently being opened.
         */
        function toggleDetailPopup(popup, otherPopup, button) {
            if (!screen)
                return;

            const popupWasOpen = popup.shouldBeVisible;

            if (otherPopup.shouldBeVisible || otherPopup.isClosing) {
                otherPopup.close();
            }

            PopoutService.controlCenterPopout = popup;

            /*
             * button.x alone is relative to rightButtons, not the
             * screen. Map it into the full-width bar background.
             */
            const buttonPosition = button.mapToItem(barBackground, 0, 0);

            const triggerX = buttonPosition.x;
            const triggerY = implicitHeight + 4;

            popup.setTriggerPosition(triggerX, triggerY, button.width, "right", screen, SettingsData.Position.Top, implicitHeight, 0, null);

            if (popupWasOpen)
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
                            barWindow.toggleDetailPopup(networkPopout, bluetoothPopout, networkButton);
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
                            barWindow.toggleDetailPopup(bluetoothPopout, networkPopout, bluetoothButton);
                        }
                    }
                }
            }
        }
    }
}
