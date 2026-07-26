//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma UseQApplication
//@ pragma AppId dev.skwig.dms.bluetoothpoc

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Common
import qs.Modals
import qs.Services
import qs.Widgets

import qs.Modules.ControlCenter.Details
import qs.Modules.DankBar.Widgets
import qs.Modules.DankDash.Overview
import qs.Modules.Notifications.Center
import qs.Modules.Notifications.Popup
import qs.Modules.OSD

ShellRoot {
    id: root

    readonly property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    property bool osdSurfacesLoaded: false
    property int pendingOsdResumeReloads: 0

    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    readonly property var activeDesktopEntry: activeWindow?.appId ? DesktopEntries.heuristicLookup(Paths.moddedAppId(activeWindow.appId)) : null

    readonly property string activeWindowIconSource: activeWindow?.appId ? Paths.getAppIcon(activeWindow.appId, activeDesktopEntry) : ""

    readonly property string activeWindowTitle: activeWindow?.title || activeWindow?.appId || "Desktop"

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

        osdStartupTimer.start();
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
     * Notification center
     */
    NotificationCenterPopout {
        id: notificationCenterPopout

        triggerScreen: root.targetScreen

        Component.onCompleted: {
            PopoutService.notificationCenterPopout = notificationCenterPopout;
        }

        Component.onDestruction: {
            if (PopoutService.notificationCenterPopout === notificationCenterPopout) {
                PopoutService.notificationCenterPopout = null;
            }
        }
    }

    /*
     * Incoming notification toast windows
     */
    Variants {
        model: Quickshell.screens

        delegate: NotificationPopupManager {
            topMargin: 44
        }
    }

    /*
     * DMS OSD surfaces
     */
    Loader {
        id: osdSurfacesLoader

        active: root.osdSurfacesLoaded
        asynchronous: false

        sourceComponent: Component {
            Item {
                /*
                 * Default PipeWire output volume
                 */
                Variants {
                    model: SettingsData.getFilteredScreens("osd")

                    delegate: VolumeOSD {}
                }

                /*
                 * Active MPRIS player's own volume
                 */
                Variants {
                    model: SettingsData.getFilteredScreens("osd")

                    delegate: MediaVolumeOSD {}
                }

                /*
                 * Active MPRIS track and playback state
                 */
                Variants {
                    model: SettingsData.getFilteredScreens("osd")

                    delegate: MediaPlaybackOSD {}
                }

                /*
                 * Microphone volume and mute
                 */
                Variants {
                    model: SettingsData.getFilteredScreens("osd")

                    delegate: MicVolumeOSD {}
                }

                /*
                 * Display brightness
                 */
                Variants {
                    model: SettingsData.getFilteredScreens("osd")

                    delegate: BrightnessOSD {}
                }

                /*
                 * Power-profile changes
                 */
                Variants {
                    model: SettingsData.osdPowerProfileEnabled ? SettingsData.getFilteredScreens("osd") : []

                    delegate: PowerProfileOSD {}
                }

                /*
                 * Current audio-output device
                 */
                Variants {
                    model: SettingsData.getFilteredScreens("osd")

                    delegate: AudioOutputOSD {}
                }
            }
        }
    }

    /*
     * Needed by NetworkDetail for password-protected Wi-Fi
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
     * Full-width bar
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

            if (notificationCenterPopout !== activePopup) {
                notificationCenterPopout.notificationHistoryVisible = false;
            }
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

            /* Active window title on the left side of the bar. */
            Item {
                id: windowTitleArea

                anchors {
                    top: parent.top
                    left: parent.left
                    right: workspaceSwitcher.visible ? workspaceSwitcher.left : rightButtons.left
                    bottom: parent.bottom

                    leftMargin: 12
                    rightMargin: 12
                }

                clip: true

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    spacing: 8

                    Item {
                        id: activeWindowIconContainer

                        width: 20
                        height: 20

                        IconImage {
                            id: activeWindowIcon

                            anchors.fill: parent

                            source: root.activeWindowIconSource

                            visible: root.activeWindow && status === Image.Ready

                            smooth: true
                            mipmap: true
                            asynchronous: true
                        }

                        DankIcon {
                            anchors.centerIn: parent

                            name: "desktop_windows"
                            size: 19
                            color: "#ffffff"

                            visible: !root.activeWindow
                        }

                        DankIcon {
                            anchors.centerIn: parent

                            name: "sports_esports"
                            size: 19
                            color: "#ffffff"

                            visible: root.activeWindow && root.activeWindow.appId && activeWindowIcon.status !== Image.Ready && Paths.isSteamApp(root.activeWindow.appId)
                        }

                        StyledText {
                            anchors.centerIn: parent

                            text: {
                                if (!root.activeWindow?.appId)
                                    return "?";

                                const appName = Paths.getAppName(root.activeWindow.appId, root.activeDesktopEntry);

                                return appName ? appName.charAt(0).toUpperCase() : "?";
                            }

                            color: "#ffffff"
                            font.pixelSize: 11
                            font.weight: Font.Bold

                            visible: root.activeWindow && root.activeWindow.appId && activeWindowIcon.status !== Image.Ready && !Paths.isSteamApp(root.activeWindow.appId)
                        }
                    }

                    StyledText {
                        width: Math.max(0, parent.width - activeWindowIconContainer.width - parent.spacing)

                        anchors.verticalCenter: parent.verticalCenter

                        text: root.activeWindowTitle

                        color: "#ffffff"
                        font.pixelSize: 15
                        font.weight: Font.Medium

                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                    }
                }
            }

            /*
             * Stock DMS workspace switcher, centered on the screen.
             *
             * It reads Hyprland's reactive workspace model, highlights
             * the active workspace, supports click-to-switch and wheel
             * navigation, and follows the DMS workspace appearance settings.
             */
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
                barThickness: barWindow.implicitHeight
                parentScreen: barWindow.screen
                blurBarWindow: barWindow
                barConfig: workspaceBarConfig
            }

            Row {
                id: rightButtons

                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                }

                spacing: 0

                /*
                 * Battery button
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
                            if (!NetworkService.networkAvailable) {
                                return "wifi_off";
                            }

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
                        if (bluetoothPopout.shouldBeVisible) {
                            return Qt.rgba(1, 1, 1, 0.16);
                        }

                        if (bluetoothMouseArea.containsMouse) {
                            return Qt.rgba(1, 1, 1, 0.10);
                        }

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
                 * Audio button
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
                 * Notification button
                 */
                Rectangle {
                    id: notificationButton

                    width: 40
                    height: rightButtons.height
                    radius: 4

                    readonly property bool centerVisible: notificationCenterPopout.notificationHistoryVisible || notificationCenterPopout.shouldBeVisible

                    readonly property bool hasNotifications: NotificationService.notifications.length > 0

                    color: {
                        if (centerVisible)
                            return Qt.rgba(1, 1, 1, 0.16);

                        if (notificationMouseArea.containsMouse) {
                            return Qt.rgba(1, 1, 1, 0.10);
                        }

                        return "transparent";
                    }

                    Item {
                        anchors.centerIn: parent

                        width: 24
                        height: 24

                        DankIcon {
                            id: notificationIcon

                            anchors.centerIn: parent

                            name: SessionData.doNotDisturb ? "notifications_off" : "notifications"

                            size: 22

                            color: SessionData.doNotDisturb ? Theme.primary : "#ffffff"
                        }

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3

                            anchors {
                                top: notificationIcon.top

                                right: notificationIcon.right
                            }

                            color: Theme.error

                            visible: notificationButton.hasNotifications
                        }
                    }

                    MouseArea {
                        id: notificationMouseArea

                        anchors.fill: parent
                        hoverEnabled: true

                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            barWindow.toggleNotificationCenter(notificationButton);
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
                        if (calendarPopout.shouldBeVisible) {
                            return Qt.rgba(1, 1, 1, 0.16);
                        }

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
