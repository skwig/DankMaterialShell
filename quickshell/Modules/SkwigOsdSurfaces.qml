import QtQuick
import Quickshell
import qs.Common
import qs.Modules.OSD

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
