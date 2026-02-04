import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Services.Noctalia
import qs.Services.Compositor

Item {
    IpcHandler {
        target: "plugin:screenshot"

        function takeScreenshot(mode: string): bool {
            if (CompositorService.isHyprland) {
                Quickshell.execDetached([
                    "hyprshot",
                    "--freeze",
                    "--clipboard-only",
                    "--mode", mode,
                    "--silent"
                ])
            } else if (CompositorService.isNiri) {
                Quickshell.execDetached([
                    "niri", "msg", "action", "screenshot"
                ])
            }
            return true
        }
    }
}
