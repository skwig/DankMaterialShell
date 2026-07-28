//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma UseQApplication
//@ pragma AppId dev.skwig.dms.bluetoothpoc

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
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

    readonly property var trayItems: SystemTray.items.values.filter(item => !SessionData.isHiddenTrayId(root.trayItemKey(item)))

    property bool osdSurfacesLoaded: false
    property int pendingOsdResumeReloads: 0
    property string activeSubmap: ""

    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    readonly property var activeDesktopEntry: activeWindow?.appId ? DesktopEntries.heuristicLookup(Paths.moddedAppId(activeWindow.appId)) : null

    readonly property string activeWindowIconSource: activeWindow?.appId ? Paths.getAppIcon(activeWindow.appId, activeDesktopEntry) : ""

    readonly property string activeWindowTitle: activeWindow?.title || activeWindow?.appId || "Desktop"

    function normalizeSubmap(value) {
        const submap = String(value ?? "").trim();

        if (submap === "" || submap === "reset" || submap === "default")
            return "";

        return submap;
    }

    function trayItemKey(trayItem) {
        const id = trayItem?.id || "";
        const tooltipTitle = trayItem?.tooltipTitle || "";

        if (!tooltipTitle || tooltipTitle === id)
            return id;

        return id + "::" + tooltipTitle;
    }

    function trayIconSourceFor(trayItem) {
        const icon = trayItem?.icon;

        if (typeof icon !== "string" || icon.length === 0)
            return "";

        if (icon.includes("?path=")) {
            const separatorIndex = icon.indexOf("?path=");
            const iconName = icon.substring(0, separatorIndex);
            const iconPath = icon.substring(separatorIndex + 6);

            let fileName = iconName.substring(iconName.lastIndexOf("/") + 1);

            if (fileName.startsWith("dropboxstatus"))
                fileName = "hicolor/16x16/status/" + fileName;

            return "file://" + iconPath + "/" + fileName;
        }

        if (icon.startsWith("/") && !icon.startsWith("file://"))
            return "file://" + icon;

        return icon;
    }

    function trayItemFallbackText(trayItem) {
        const title = trayItem?.tooltipTitle || trayItem?.title || trayItem?.id || "?";

        return title.length > 0 ? title.charAt(0).toUpperCase() : "?";
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
        id: initialSubmapProcess

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
            if (!shouldBeVisible && BluetoothService.adapter?.discovering)
                BluetoothService.adapter.discovering = false;
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
            if (PopoutService.controlCenterPopout === audioPopout)
                PopoutService.controlCenterPopout = null;
        }

        content: Component {
            AudioOutputDetail {
                anchors.fill: parent
                hasVolumeSliderInCC: false
            }
        }
    }

    /*
     * System tray popup
     */
    DankPopoutStandalone {
        id: systemTrayPopout

        property var menuHost: null
        property var menuAnchorItem: null
        property var menuScreen: null

        function openThemedMenu(trayItem) {
            const host = menuHost;
            const anchor = menuAnchorItem;
            const targetScreen = menuScreen;

            close();

            if (!host || !anchor || !targetScreen || !trayItem?.hasMenu)
                return;

            Qt.callLater(() => {
                host.showForTrayItem(trayItem, anchor, targetScreen, false, false, host.axis);
            });
        }

        function openContextMenuFallback(trayItem, area, mouse) {
            const host = menuHost;

            if (!host || !trayItem || !area)
                return;

            const globalPosition = area.mapToGlobal(mouse.x, mouse.y);

            close();

            host.callContextMenuFallback(trayItem.id, Math.round(globalPosition.x), Math.round(globalPosition.y));
        }

        screen: root.targetScreen
        layerNamespace: "skwig:system-tray-poc"

        popupWidth: Math.min(420, Math.max(120, root.trayItems.length * 38 + 20))
        popupHeight: 56

        positioning: ""
        fullHeightSurface: true

        onBackgroundClicked: close()

        Component.onDestruction: {
            if (PopoutService.controlCenterPopout === systemTrayPopout)
                PopoutService.controlCenterPopout = null;
        }

        content: Component {
            Item {
                StyledText {
                    anchors.centerIn: parent

                    visible: root.trayItems.length === 0
                    text: I18n.tr("No tray items")

                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                Flickable {
                    id: systemTrayFlickable

                    anchors.fill: parent
                    anchors.margins: 8

                    visible: root.trayItems.length > 0
                    clip: true

                    contentWidth: Math.max(width, trayItemsRow.implicitWidth)
                    contentHeight: height

                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: trayItemsRow

                        x: Math.max(0, (systemTrayFlickable.width - implicitWidth) / 2)

                        y: Math.round((systemTrayFlickable.height - height) / 2)

                        height: 36
                        spacing: 2

                        Repeater {
                            model: root.trayItems

                            delegate: Rectangle {
                                id: trayItemButton

                                required property var modelData

                                width: 36
                                height: 36
                                radius: 6

                                color: trayItemMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

                                IconImage {
                                    id: trayItemIcon

                                    anchors.centerIn: parent

                                    width: 18
                                    height: 18

                                    source: root.trayIconSourceFor(trayItemButton.modelData)

                                    visible: status === Image.Ready

                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                }

                                StyledText {
                                    anchors.centerIn: parent

                                    visible: !trayItemIcon.visible

                                    text: root.trayItemFallbackText(trayItemButton.modelData)

                                    color: "#ffffff"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    id: trayItemMouseArea

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: mouse => {
                                        const trayItem = trayItemButton.modelData;

                                        if (!trayItem)
                                            return;

                                        if (mouse.button === Qt.MiddleButton) {
                                            trayItem.secondaryActivate();
                                            return;
                                        }

                                        if (mouse.button === Qt.RightButton || trayItem.onlyMenu) {
                                            if (trayItem.hasMenu) {
                                                systemTrayPopout.openThemedMenu(trayItem);

                                                return;
                                            }

                                            if (mouse.button === Qt.RightButton) {
                                                systemTrayPopout.openContextMenuFallback(trayItem, trayItemMouseArea, mouse);
                                            }

                                            return;
                                        }

                                        trayItem.activate();
                                        systemTrayPopout.close();
                                    }

                                    onWheel: wheel => {
                                        trayItemButton.modelData.scroll(wheel.angleDelta.y, false);

                                        wheel.accepted = true;
                                    }
                                }
                            }
                        }
                    }
                }
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
            if (PopoutService.controlCenterPopout === batteryPopout)
                PopoutService.controlCenterPopout = null;
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
            if (PopoutService.controlCenterPopout === calendarPopout)
                PopoutService.controlCenterPopout = null;
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
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow

                property var modelData

                screen: modelData
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

                    /*
                     * Active window title on the left.
                     */
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
                     * Stock DMS workspace switcher.
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

                    QtObject {
                        id: trayMenuAxis

                        property bool isVertical: false
                        property bool isHorizontal: true
                        property string edge: "top"
                    }

                    /*
                     * Hidden stock tray widget used for themed menus.
                     */
                    SystemTrayBar {
                        id: trayMenuHost

                        visible: false

                        parentWindow: barWindow
                        parentScreen: barWindow.screen

                        widgetThickness: barWindow.implicitHeight
                        barThickness: barWindow.implicitHeight
                        barSpacing: 4

                        axis: trayMenuAxis
                        barConfig: null

                        isAtBottom: false
                        isAutoHideBar: false

                        useAutomaticOverflow: false
                        useOverflowPopup: false
                    }

                    Rectangle {
                        id: submapIndicator

                        anchors {
                            right: rightButtons.left
                            rightMargin: 6
                            verticalCenter: parent.verticalCenter
                        }

                        visible: root.activeSubmap !== ""

                        width: submapText.implicitWidth + 20
                        height: 28
                        radius: 4

                        color: Qt.rgba(1, 1, 1, 0.14)

                        StyledText {
                            id: submapText

                            anchors.centerIn: parent

                            text: root.activeSubmap

                            color: Theme.primary
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
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
                         * System tray button
                         */
                        Rectangle {
                            id: systemTrayButton

                            width: 40
                            height: rightButtons.height
                            radius: 4

                            color: {
                                if (systemTrayPopout.shouldBeVisible)
                                    return Qt.rgba(1, 1, 1, 0.16);

                                if (systemTrayMouseArea.containsMouse)
                                    return Qt.rgba(1, 1, 1, 0.10);

                                return "transparent";
                            }

                            DankIcon {
                                anchors.centerIn: parent

                                name: "apps"
                                size: 22
                                color: "#ffffff"
                            }

                            MouseArea {
                                id: systemTrayMouseArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    systemTrayPopout.menuHost = trayMenuHost;
                                    systemTrayPopout.menuAnchorItem = systemTrayButton;

                                    systemTrayPopout.menuScreen = barWindow.screen;

                                    barWindow.toggleDetailPopup(systemTrayPopout, systemTrayButton);
                                }
                            }
                        }

                        /*
                         * Battery button
                         */
                        Rectangle {
                            id: batteryButton

                            visible: BatteryService.batteryAvailable

                            width: Math.max(40, batteryButtonContent.implicitWidth + 16)

                            height: rightButtons.height
                            radius: 4

                            color: {
                                if (batteryPopout.shouldBeVisible)
                                    return Qt.rgba(1, 1, 1, 0.16);

                                if (batteryMouseArea.containsMouse)
                                    return Qt.rgba(1, 1, 1, 0.10);

                                return "transparent";
                            }

                            Row {
                                id: batteryButtonContent

                                anchors.centerIn: parent
                                spacing: 4

                                DankIcon {
                                    anchors.verticalCenter: parent.verticalCenter

                                    name: BatteryService.getBatteryIcon()
                                    size: 22

                                    color: {
                                        if (BatteryService.isLowBattery && !BatteryService.isCharging) {
                                            return Theme.error;
                                        }

                                        return "#ffffff";
                                    }
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter

                                    text: Math.round(BatteryService.batteryLevel) + "%"

                                    color: {
                                        if (BatteryService.isLowBattery && !BatteryService.isCharging) {
                                            return Theme.error;
                                        }

                                        return "#ffffff";
                                    }

                                    font.pixelSize: 14
                                    font.weight: Font.Medium
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
                                    if (!NetworkService.networkAvailable || NetworkService.networkStatus === "disconnected") {
                                        return "wifi_off";
                                    }

                                    if (NetworkService.networkStatus === "ethernet") {
                                        return "lan";
                                    }

                                    return NetworkService.wifiSignalIcon || "wifi_off";
                                }

                                size: 22
                                color: "#ffffff"
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

                                name: {
                                    if (!BluetoothService.available || !BluetoothService.enabled) {
                                        return "bluetooth_disabled";
                                    }

                                    if (BluetoothService.connected)
                                        return "bluetooth_connected";

                                    return "bluetooth";
                                }

                                size: 22
                                color: "#ffffff"
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

                                    if (!audio || audio.muted || audio.volume <= 0) {
                                        return "volume_off";
                                    }

                                    if (audio.volume <= 0.33)
                                        return "volume_down";

                                    return "volume_up";
                                }

                                size: 22
                                color: "#ffffff"
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

                                if (notificationMouseArea.containsMouse)
                                    return Qt.rgba(1, 1, 1, 0.10);

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
    }
}
