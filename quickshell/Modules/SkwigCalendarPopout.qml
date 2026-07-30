import QtQuick
import qs.Common
import qs.Modals
import qs.Modules.DankDash.Overview
import qs.Services
import qs.Widgets

DankPopoutStandalone {
    id: root

    popupWidth: 724
    popupHeight: 390
    positioning: ""
    fullHeightSurface: true

    onBackgroundClicked: close()

    Component.onDestruction: {
        if (PopoutService.controlCenterPopout === root)
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
                        root.close();
                    }
                }
            }
        }
    }
}
