import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    required property var calendarPopout

    signal clicked(var button)

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

    width: Math.max(68, timeText.implicitWidth + Theme.spacingL + Theme.spacingXS)
    radius: Theme.cornerRadius / 3
    color: {
        if (calendarPopout?.shouldBeVisible)
            return Theme.surfacePressed;

        if (mouseArea.containsMouse)
            return Theme.surfaceHover;

        return "transparent";
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

    StyledText {
        id: timeText

        anchors.centerIn: parent
        text: root.formatBarTime(barClock.date)
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked(root)
    }
}
