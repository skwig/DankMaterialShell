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

    // Use the standalone backend directly so this POC does not depend on
    // DMS frame/bar surfaces or the saved DMS frame mode.
    DankPopoutStandalone {
        id: bluetoothPopout

        screen: root.targetScreen
        layerNamespace: "skwig:bluetooth-poc"
        popupWidth: 520
        popupHeight: Math.min(620, Math.max(360, (screen?.height ?? 1080) - 96))
        positioning: ""
        fullHeightSurface: true
        onBackgroundClicked: close()

        Component.onCompleted: PopoutService.controlCenterPopout = bluetoothPopout
        Component.onDestruction: {
            if (PopoutService.controlCenterPopout === bluetoothPopout)
                PopoutService.controlCenterPopout = null;
        }

        onShouldBeVisibleChanged: {
            if (!shouldBeVisible && BluetoothService.adapter?.discovering)
                BluetoothService.adapter.discovering = false;
        }

        content: Component {
            Item {
                BluetoothDetail {
                    id: bluetoothDetail

                    anchors.fill: parent
                    bluetoothCodecModalRef: codecSelector
                    onShowCodecSelector: device => codecSelector.show(device)
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

    // Temporary button for the POC. Replace this PanelWindow with your own bar
    // and keep the setTriggerPosition(...); bluetoothPopout.toggle(); calls.
    PanelWindow {
        id: triggerWindow

        screen: root.targetScreen
        visible: true
        anchors.top: true
        anchors.right: true
        implicitWidth: 56
        implicitHeight: 56
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "skwig:bluetooth-poc-trigger"

        function toggleBluetooth() {
            if (!screen)
                return;

            // The trigger window is anchored to the screen's right edge, so
            // convert the button's window-local x coordinate to screen-local x.
            const triggerX = screen.width - implicitWidth + button.x;
            const triggerY = implicitHeight + 4;

            bluetoothPopout.setTriggerPosition(triggerX, triggerY, button.width, "right", screen, SettingsData.Position.Top, implicitHeight, 0, null);
            bluetoothPopout.toggle();
        }

        Rectangle {
            id: button

            anchors.fill: parent
            anchors.margins: 8
            radius: Theme.cornerRadius
            color: buttonMouse.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer
            border.width: Theme.layerOutlineWidth
            border.color: bluetoothPopout.shouldBeVisible ? Theme.primary : Theme.outlineMedium

            DankIcon {
                anchors.centerIn: parent
                name: !BluetoothService.available ? "bluetooth_disabled" : (BluetoothService.connected ? "bluetooth_connected" : "bluetooth")
                size: 22
                color: BluetoothService.enabled ? Theme.primary : Theme.surfaceVariantText
            }

            MouseArea {
                id: buttonMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: triggerWindow.toggleBluetooth()
            }
        }
    }
}
