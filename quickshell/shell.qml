//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma UseQApplication
//@ pragma AppId dev.skwig.dms.bluetoothpoc

import QtQuick
import Quickshell

import qs.Common
import qs.Modules
import qs.Modules.Notifications.Popup
import qs.Modules.OSD
import qs.Services

ShellRoot {
    id: root

    readonly property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    Component.onCompleted: {
        SettingsData.osdPosition = SettingsData.Position.Left;
        SettingsData.osdMediaVolumeEnabled = true;
        SettingsData.osdMediaPlaybackEnabled = true;
        SettingsData.showWorkspaceIndex = true;
        SettingsData.showWorkspaceName = false;
        SettingsData.showWorkspaceApps = false;
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

    SkwigSystemTrayPopout {
        id: systemTrayPopoutRef
        screen: root.targetScreen
    }

    SkwigBatteryPopout {
        id: batteryPopoutRef
        screen: root.targetScreen
    }

    SkwigNetworkPopout {
        id: networkPopoutRef
        screen: root.targetScreen
    }

    SkwigBluetoothPopout {
        id: bluetoothPopoutRef
        screen: root.targetScreen
    }

    SkwigAudioPopout {
        id: audioPopoutRef
        screen: root.targetScreen
    }

    SkwigNotificationCenterPopout {
        id: notificationCenterPopoutRef
        triggerScreen: root.targetScreen
    }

    SkwigCalendarPopout {
        id: calendarPopoutRef
        screen: root.targetScreen
    }

    SkwigWifiPasswordModalHost {}

    Variants {
        model: Quickshell.screens

        delegate: NotificationPopupManager {
            topMargin: 44
        }
    }

    SkwigOsdHost {
        surfaces: Component {
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
                    model: SettingsData.getFilteredScreens("osd")
                    delegate: PowerProfileOSD {}
                }

                Variants {
                    model: SettingsData.getFilteredScreens("osd")
                    delegate: AudioOutputOSD {}
                }
            }
        }
    }
}
