//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma UseQApplication
//@ pragma AppId dev.skwig.dms.bluetoothpoc

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs.Common
import qs.Modules
import qs.Modules.Notifications.Center
import qs.Modules.Notifications.Popup
import qs.Services

ShellRoot {
    id: root

    readonly property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    property bool osdSurfacesLoaded: false
    property int pendingOsdResumeReloads: 0
    property string activeSubmap: ""

    function normalizeSubmap(value) {
        const submap = String(value ?? "").trim();

        if (submap === "" || submap === "reset" || submap === "default")
            return "";

        return submap;
    }

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

    function recreateOsdSurfaces() {
        OSDManager.currentOSDsByScreen = ({});
        osdSurfacesLoaded = false;
        osdSurfaceReloadTimer.restart();
    }

    Component.onCompleted: {
        SettingsData.osdPosition = SettingsData.Position.Left;
        SettingsData.osdMediaVolumeEnabled = true;
        SettingsData.osdMediaPlaybackEnabled = true;
        SettingsData.showWorkspaceIndex = true;
        SettingsData.showWorkspaceName = false;
        SettingsData.showWorkspaceApps = false;
        osdStartupTimer.start();
    }

    Process {
        command: ["hyprctl", "submap"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.activeSubmap = root.normalizeSubmap(text);
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "submap" || event.name === "keybinds.submap")
                root.activeSubmap = root.normalizeSubmap(event.data);
        }
    }

    SystemClock {
        id: barClock
        precision: SystemClock.Minutes
    }

    Timer {
        id: osdStartupTimer
        interval: 1000
        repeat: false

        onTriggered: {
            root.osdSurfacesLoaded = true;
        }
    }

    Timer {
        id: osdSurfaceReloadTimer
        interval: 120
        repeat: false

        onTriggered: {
            root.osdSurfacesLoaded = true;
        }
    }

    Timer {
        id: osdResumeRecreateTimer
        interval: 400
        repeat: false

        onTriggered: {
            root.recreateOsdSurfaces();
            root.pendingOsdResumeReloads--;

            if (root.pendingOsdResumeReloads <= 0) {
                root.pendingOsdResumeReloads = 0;
                interval = 400;
                return;
            }

            interval = 1400;
            restart();
        }
    }

    Connections {
        target: SessionService

        function onSessionResumed() {
            barClock.enabled = false;
            barClock.enabled = true;

            root.pendingOsdResumeReloads = 2;
            osdResumeRecreateTimer.interval = 400;
            osdResumeRecreateTimer.restart();
        }
    }

    SkwigBluetoothPopout {
        id: bluetoothPopoutRef
        screen: root.targetScreen
    }

    SkwigNetworkPopout {
        id: networkPopoutRef
        screen: root.targetScreen
    }

    SkwigAudioPopout {
        id: audioPopoutRef
        screen: root.targetScreen
    }

    SkwigBatteryPopout {
        id: batteryPopoutRef
        screen: root.targetScreen
    }

    SkwigCalendarPopout {
        id: calendarPopoutRef
        screen: root.targetScreen
    }

    SkwigTrayPopout {
        id: systemTrayPopoutRef
        screen: root.targetScreen
    }

    SkwigWifiPasswordModalHost {}

    NotificationCenterPopout {
        id: notificationCenterPopoutRef
        triggerScreen: root.targetScreen

        Component.onCompleted: {
            PopoutService.notificationCenterPopout = notificationCenterPopoutRef;
        }

        Component.onDestruction: {
            if (PopoutService.notificationCenterPopout === notificationCenterPopoutRef)
                PopoutService.notificationCenterPopout = null;
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: NotificationPopupManager {
            topMargin: 44
        }
    }

    Loader {
        active: root.osdSurfacesLoaded
        asynchronous: false

        sourceComponent: Component {
            SkwigOsdSurfaces {}
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: SkwigBar {
            modelData: modelData
            screen: modelData
            activeSubmap: root.activeSubmap
            clockText: root.formatBarTime(barClock.date)
            batteryPopout: batteryPopoutRef
            networkPopout: networkPopoutRef
            bluetoothPopout: bluetoothPopoutRef
            audioPopout: audioPopoutRef
            calendarPopout: calendarPopoutRef
            systemTrayPopout: systemTrayPopoutRef
            notificationCenterPopout: notificationCenterPopoutRef
        }
    }
}
