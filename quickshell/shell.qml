//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma UseQApplication
//@ pragma AppId dev.skwig.dms.bluetoothpoc

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.ControlCenter.Details

ShellRoot {
    id: root

    readonly property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    DankPopoutStandalone {
        id: bluetoothPopout

        screen: root.targetScreen
        layerNamespace: "skwig:bluetooth-poc"

        popupWidth: 520
        popupHeight: Math.min(620, Math.max(360, (screen?.height ?? 1080) - 96))

        positioning: ""
        fullHeightSurface: true

        onBackgroundClicked: close()

        Component.onCompleted: {
            PopoutService.controlCenterPopout = bluetoothPopout;
        }

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
        WlrLayershell.namespace: "skwig:bluetooth-poc-bar"

        function toggleBluetooth() {
            if (!screen)
                return;

            // The bar spans the full screen, so button.x is already
            // relative to the current screen.
            const triggerX = bluetoothButton.x;
            const triggerY = implicitHeight + 4;

            bluetoothPopout.setTriggerPosition(triggerX, triggerY, bluetoothButton.width, "right", screen, SettingsData.Position.Top, implicitHeight, 0, null);

            bluetoothPopout.toggle();
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.4)

            Rectangle {
                id: bluetoothButton

                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                }

                width: 40
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
                        barWindow.toggleBluetooth();
                    }
                }
            }
        }
    }
}
