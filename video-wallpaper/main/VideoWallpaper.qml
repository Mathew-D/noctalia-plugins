
import Qt.labs.folderlistmodel
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import QtMultimedia

import qs.Commons
import qs.Services.UI

Variants {
    id: root
    required property var pluginApi


    /***************************
    * PROPERTIES
    ***************************/
    required property string currentWallpaper
    required property bool enabled
    required property int fillMode
    required property bool isPlaying
    required property bool isMuted
    required property int orientation
    required property real volume


    model: Quickshell.screens
    PanelWindow {
        required property var modelData
        screen: modelData
        exclusionMode: ExclusionMode.Ignore

        implicitWidth: modelData.width
        implicitHeight: modelData.height
        visible: root.enabled && root.currentWallpaper != ""

        WlrLayershell.namespace: `noctalia-video-wallpaper-${modelData.name}`
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            right: true
            left: true
        }

        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "black"

            Video {
                id: videoWallpaper
                anchors.fill: parent
                autoPlay: true
                fillMode: {
                    if(root.fillMode == 1) return VideoOutput.PreserveAspectFit
                    else if (root.fillMode == 2) return VideoOutput.PreserveAspectCrop
                    else return VideoOutput.Stretch
                }
                loops: MediaPlayer.Infinite
                muted: root.isMuted
                orientation: root.orientation
                playbackRate: {
                    if(root.isPlaying) return 1.0
                    // Pausing is the same as putting the speed to veryyyyyyy tiny amount
                    else return 0.00000001
                }
                source: {
                    if(root.currentWallpaper == "") return ""
                    else if (root.currentWallpaper.startsWith("file://")) return root.currentWallpaper
                    else return `file://${root.currentWallpaper}`
                }
                volume: root.volume

                onErrorOccurred: (error, errorString) => {
                    Logger.e("video-wallpaper", errorString);
                }
            }
        }
    }
}
