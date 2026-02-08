pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

import qs.Commons
import qs.Services.UI

import "../common"

Item {
    id: root
    required property var pluginApi


    /***************************
    * PROPERTIES
    ***************************/
    required property bool enabled
    required property bool thumbCacheReady
    required property string wallpapersFolder
    required property FolderModel folderModel

    readonly property alias thumbFolderModel: thumbFolderModel

    readonly property string thumbCacheFolderPath: ImageCacheService.wpThumbDir + "video-wallpaper"
    property int _thumbGenIndex: 0

    // Local copy of the current wallpaper for only the startColorGen
    property string _currentWallpaper

    /***************************
    * FUNCTIONS
    ***************************/
    function clearThumbCacheReady() {
        if(pluginApi != null && thumbCacheReady) {
            pluginApi.pluginSettings.thumbCacheReady = false;
            pluginApi.saveSettings();
        }
    }

    function setThumbCacheReady() {
        if(pluginApi != null && !thumbCacheReady) {
            pluginApi.pluginSettings.thumbCacheReady = true;
            pluginApi.saveSettings();
        }
    }

    function getThumbPath(videoPath: string): string {
        const file = videoPath.split('/').pop();

        return `${thumbCacheFolderPath}/${file}.bmp`
    }

    function startColorGen(currentWallpaper: string) {
        _currentWallpaper = currentWallpaper;
        // If the folder model isn't ready, or we are still regenerating a thumbnail, try in a bit
        if(!thumbFolderModel.ready || startColorGenProc.running){
            startColorGenTimer.restart();
            return;
        }

        Logger.d("video-wallpaper", currentWallpaper);

        const thumbPath = root.getThumbPath(currentWallpaper);
        if (thumbFolderModel.indexOf(thumbPath) !== -1) {
            Logger.d("video-wallpaper", "Generating color scheme based on video wallpaper!");
            WallpaperService.changeWallpaper(thumbPath);
        } else {
            // Try to create the thumbnail again
            // just a fail safe if the current wallpaper isn't included in the wallpapers folder
            Logger.d("video-wallpaper", "Thumbnail not found:", thumbPath);
            startColorGenProc.command = ["sh", "-c", `ffmpeg -y -i ${currentWallpaper} -vframes:v 1 ${thumbPath}`]
            startColorGenProc.running = true;
        }
    }

    function thumbGeneration() {
        if(pluginApi == null) return;

        // Try to start in a bit since the folder models aren't ready yet
        if (!folderModel.ready || !thumbFolderModel.ready) {
            thumbGenerationTimer.restart();
            return;
        }

        // Reset the state of thumbCacheReady
        clearThumbCacheReady();

        while(root._thumbGenIndex < folderModel.count) {
            const videoPath = folderModel.get(root._thumbGenIndex);
            const thumbPath = root.getThumbPath(videoPath);
            root._thumbGenIndex++;
            // Check if file already exists, otherwise create it with ffmpeg
            if (thumbFolderModel.indexOf(thumbPath) === -1) {
                Logger.d("video-wallpaper", `Creating thumbnail for video: ${videoPath}`);

                // With scale
                //thumbProc.command = ["sh", "-c", `ffmpeg -y -i ${videoUrl} -vf "scale=1080:-1" -vframes:v 1 ${thumbUrl}`]
                thumbGenerationProc.command = ["sh", "-c", `ffmpeg -y -i ${videoPath} -vframes:v 1 ${thumbPath}`]
                thumbGenerationProc.running = true;
                return;
            }
        }

        // The thumbnail generation has looped over every video and finished the generation
        // Update the thumbnail folder
        thumbFolderModel.forceReload();

        root._thumbGenIndex = 0;
        setThumbCacheReady();
    }

    function thumbRegenerate() {
        if(pluginApi == null) return;

        clearThumbCacheReady();

        thumbRegenerationProc.command = ["sh", "-c", `rm -rf ${thumbCacheFolderPath} && mkdir -p ${thumbCacheFolderPath}`]
        thumbRegenerationProc.running = true;
    }


    /***************************
    * EVENTS
    ***************************/
    onWallpapersFolderChanged: {
        root.thumbGeneration();
    }

    /***************************
    * COMPONENTS
    ***************************/
    FolderModel {
        id: thumbFolderModel
        folder: root.thumbCacheFolderPath
        filters: ["*.bmp"]
    }

    Process {
        // Process to create the thumbnail folder
        id: thumbInit
        command: ["sh", "-c", `mkdir -p ${root.thumbCacheFolderPath}`]
        running: true
    }

    Process {
        id: thumbGenerationProc

        // When exiting run the thumbGenerate
        onExited: root.thumbGeneration();
    }

    Process {
        id: thumbRegenerationProc
        onExited: {
            // Reload the thumbFolder first
            thumbFolderModel.forceReload();
            root.thumbGeneration();
        }
    }
    
    Timer {
        id: thumbGenerationTimer
        interval: 10
        repeat: false
        running: false
        triggeredOnStart: false
        onTriggered: root.thumbGeneration();
    }


    Process {
        id: startColorGenProc
        onExited: {
            // When finished recreating the thumbnail, try to apply the colors again
            root.startColorGen(root._currentWallpaper);
        }
    }

    Timer {
        id: startColorGenTimer
        interval: 10
        repeat: false
        running: false
        triggeredOnStart: false
        onTriggered: root.startColorGen(root._currentWallpaper);
    }
}
