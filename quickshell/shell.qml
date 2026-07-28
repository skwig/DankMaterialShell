//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma UseQApplication
//@ pragma AppId dev.skwig.dms.bluetoothpoc

import QtQuick
import Quickshell

import qs.Common
import qs.Modules
import qs.Modules.Notifications.Center
import qs.Modules.Notifications.Popup
import qs.Modules.OSD
import qs.Services

ShellRoot {
    id: root

    readonly property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    property bool osdSurfacesLoaded: false
    property int pendingOsdResumeReloads: 0

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
            Item {
                Variants {
                    model: SettingsData.getFilteredScreens("osd")
                    delegate: VolumeOSD {}
                }

                Variants {
                    model: SettingsData.getFilteredScreens("osd")
                    delegate: MediaVolumeOSD {}
                }

                Variants {
                    model: SettingsData.getFilteredScreens("osd")
                    delegate: MediaPlaybackOSD {}
                }

                Variants {
                    model: SettingsData.getFilteredScreens("osd")
                    delegate: MicVolumeOSD {}
                }

                Variants {
                    model: SettingsData.getFilteredScreens("osd")
                    delegate: BrightnessOSD {}
                }

                Variants {
                    model: SettingsData.osdPowerProfileEnabled ? SettingsData.getFilteredScreens("osd") : []
                    delegate: PowerProfileOSD {}
                }

                Variants {
                    model: SettingsData.getFilteredScreens("osd")
                    delegate: AudioOutputOSD {}
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: SkwigBar {
            modelData: modelData
            screen: modelData
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
