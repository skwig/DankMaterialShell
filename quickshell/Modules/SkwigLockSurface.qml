import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

WlSessionLockSurface {
    id: root

    required property string authMessage
    required property bool authInProgress

    signal passwordSubmitted(string password)

    color: "black"

    readonly property string wallpaperPath: Paths.strip(StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)) + "/wallpaper.jpg"

    component ClockDigitText: StyledText {
        font.pixelSize: 120
        font.weight: Font.Light
        color: "white"
        horizontalAlignment: Text.AlignHCenter
    }

    SystemClock {
        id: systemClock

        precision: SystemClock.Seconds
    }

    Item {
        anchors.fill: parent

        Image {
            anchors.fill: parent
            source: Paths.toFileUrl(root.wallpaperPath)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 0.8
                blurMax: 48
                blurMultiplier: 1
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.4
        }

        Item {
            id: clockContainer

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: 60
            width: parent.width
            height: clockText.implicitHeight

            Row {
                id: clockText

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                spacing: 0

                property string fullTimeStr: systemClock.date.toLocaleTimeString(Qt.locale(), SettingsData.getEffectiveTimeFormat())
                property var timeParts: fullTimeStr.split(':')
                property string hours: timeParts[0] || ""
                property string minutes: timeParts[1] || ""
                property string secondsWithAmPm: timeParts.length > 2 ? timeParts[2] : ""
                property string seconds: secondsWithAmPm.replace(/\s*(AM|PM|am|pm)$/i, '')
                property string ampm: {
                    const match = fullTimeStr.match(/\s*(AM|PM|am|pm)$/i);
                    return match ? match[0].trim() : "";
                }
                property bool hasSeconds: timeParts.length > 2

                ClockDigitText {
                    width: clockText.hours.length > 1 ? 75 : 0
                    text: clockText.hours.length > 1 ? clockText.hours[0] : ""
                }

                ClockDigitText {
                    width: 75
                    text: clockText.hours.length > 1 ? clockText.hours[1] : clockText.hours.length > 0 ? clockText.hours[0] : ""
                }

                ClockDigitText {
                    text: ":"
                }

                ClockDigitText {
                    width: 75
                    text: clockText.minutes.length > 0 ? clockText.minutes[0] : ""
                }

                ClockDigitText {
                    width: 75
                    text: clockText.minutes.length > 1 ? clockText.minutes[1] : ""
                }

                ClockDigitText {
                    text: clockText.hasSeconds ? ":" : ""
                    visible: clockText.hasSeconds
                }

                ClockDigitText {
                    width: 75
                    text: clockText.hasSeconds && clockText.seconds.length > 0 ? clockText.seconds[0] : ""
                    visible: clockText.hasSeconds
                }

                ClockDigitText {
                    width: 75
                    text: clockText.hasSeconds && clockText.seconds.length > 1 ? clockText.seconds[1] : ""
                    visible: clockText.hasSeconds
                }

                ClockDigitText {
                    width: 20
                    text: " "
                    visible: clockText.ampm !== ""
                }

                ClockDigitText {
                    text: clockText.ampm
                    visible: clockText.ampm !== ""
                }
            }
        }

        StyledText {
            id: dateText

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: clockContainer.bottom
            anchors.topMargin: 4
            text: SettingsData.lockDateFormat && SettingsData.lockDateFormat.length > 0 ? systemClock.date.toLocaleDateString(I18n.locale(), SettingsData.lockDateFormat) : systemClock.date.toLocaleDateString(I18n.locale(), Locale.LongFormat)
            font.pixelSize: Theme.fontSizeXLarge
            color: "white"
            opacity: 0.9
        }

        ColumnLayout {
            id: passwordLayout

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: dateText.bottom
            anchors.topMargin: Theme.spacingL
            spacing: Theme.spacingM
            width: 380

            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: Theme.cornerRadius
                    color: Theme.withAlpha(Theme.surfaceContainer, 0.9)
                    border.color: passwordField.activeFocus ? Theme.primary : Qt.rgba(1, 1, 1, 0.3)
                    border.width: passwordField.activeFocus ? 2 : 1

                    Item {
                        id: lockIconContainer

                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 20

                        DankIcon {
                            anchors.centerIn: parent
                            name: "lock"
                            size: 20
                            color: passwordField.activeFocus ? Theme.primary : Theme.surfaceVariantText
                        }
                    }

                    TextInput {
                        id: passwordField

                        anchors.fill: parent
                        anchors.leftMargin: lockIconContainer.width + Theme.spacingM * 2
                        anchors.rightMargin: enterButton.width + Theme.spacingM
                        opacity: 0
                        focus: true
                        enabled: !root.authInProgress
                        echoMode: TextInput.Password
                        onTextChanged: cursorPosition = text.length
                        onAccepted: submit()
                        Keys.onEscapePressed: clear()

                        function submit() {
                            if (text.length === 0 || root.authInProgress)
                                return;
                            root.passwordSubmitted(text);
                            text = "";
                        }

                        Component.onCompleted: forceActiveFocus()

                        onVisibleChanged: {
                            if (visible)
                                forceActiveFocus();
                        }

                        onActiveFocusChanged: {
                            if (!activeFocus)
                                Qt.callLater(() => forceActiveFocus());
                        }
                    }

                    StyledText {
                        anchors.left: lockIconContainer.right
                        anchors.leftMargin: Theme.spacingM
                        anchors.right: enterButton.left
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.authInProgress ? "Authenticating..." : "Password..."
                        color: root.authInProgress ? Theme.primary : Theme.outline
                        font.pixelSize: Theme.fontSizeMedium
                        opacity: passwordField.text.length === 0 ? 1 : 0
                    }

                    StyledText {
                        anchors.left: lockIconContainer.right
                        anchors.leftMargin: Theme.spacingM
                        anchors.right: enterButton.left
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: "•".repeat(passwordField.text.length)
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        opacity: passwordField.text.length > 0 ? 1 : 0
                    }

                    DankActionButton {
                        id: enterButton

                        anchors.right: parent.right
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "keyboard_return"
                        buttonSize: 36
                        visible: !root.authInProgress
                        onClicked: passwordField.submit()
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.preferredHeight: text.length > 0 ? Math.min(implicitHeight, Math.ceil(Theme.fontSizeSmall * 4.5)) : 0
                text: root.authMessage
                color: Theme.error
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                opacity: text.length > 0 ? 1 : 0
            }

            StyledText {
                Layout.fillWidth: true
                text: UserInfoService.fullName || UserInfoService.username || "User"
                font.pixelSize: Theme.fontSizeMedium
                color: "white"
                opacity: 0.85
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
