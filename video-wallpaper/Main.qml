import Qt.labs.folderlistmodel
import QtQuick
import Quickshell.Io
import qs.Commons

import "./common"
import "./main"

Item {
    id: root

    property var pluginApi: null


    readonly property bool automation:
        pluginApi.pluginSettings.automation ||
        false

    readonly property string automationMode:
        pluginApi.pluginSettings.automationMode ||
        "random"

    readonly property real automationTime:
        pluginApi.pluginSettings.automationTime ||
        5 * 60

    readonly property string currentWallpaper: 
        pluginApi.pluginSettings.currentWallpaper || 
        ""

    readonly property bool enabled: 
        pluginApi.pluginSettings.enabled || 
        false

    readonly property int fillMode:
        pluginApi.pluginSettings.fillMode ||
        0

    readonly property bool isMuted:
        pluginApi.pluginSettings.isMuted ||
        false

    readonly property bool isPlaying:
        pluginApi.pluginSettings.isPlaying ||
        false

    readonly property var oldWallpapers:
        pluginApi.pluginSettings.oldWallpapers || 
        ({})

    readonly property int orientation:
        pluginApi.pluginSettings.orientation ||
        0

    readonly property bool thumbCacheReady:
        pluginApi.pluginSettings.thumbCacheReady ||
        false

    readonly property double volume:
        pluginApi.pluginSettings.volume ||
        1.0

    readonly property string wallpapersFolder: 
        pluginApi.pluginSettings.wallpapersFolder || 
        pluginApi.manifest.metadata.defaultSettings.wallpapersFolder || 
        "~/Pictures/Wallpapers"


    /***************************
    * WALLPAPER FUNCTIONALITY
    ***************************/
    function random() {
        if (wallpapersFolder === "") {
            Logger.e("video-wallpaper", "Wallpapers folder is empty!");
            return;
        }
        if (folderModel.count === 0) {
            Logger.e("video-wallpaper", "No valid video files found!");
            return;
        }

        const rand = Math.floor(Math.random() * folderModel.count);
        const url = folderModel.get(rand, "filePath");
        setWallpaper(url);
    }

    function clear() {
        setWallpaper("");
    }

    function nextWallpaper() {
        if (wallpapersFolder === "") {
            Logger.e("video-wallpaper", "Wallpapers folder is empty!");
            return;
        }
        if (folderModel.count === 0) {
            Logger.e("video-wallpaper", "No valid video files found!");
            return;
        }

        Logger.d("video-wallpaper", "Choosing next wallpaper...");

        // Even if the file is not in wallpapers folder, aka -1, it sets the nextIndex to 0 then
        const currentIndex = folderModel.indexOf(root.currentWallpaper);
        const nextIndex = (currentIndex + 1) % folderModel.count;
        const url = folderModel.get(nextIndex, "filePath");
        setWallpaper(url);
    }

    function setWallpaper(path) {
        if (root.pluginApi == null) {
            Logger.e("video-wallpaper", "Can't set the wallpaper because pluginApi is null.");
            return;
        }

        pluginApi.pluginSettings.currentWallpaper = path;
        pluginApi.saveSettings();
    }

    /***************************
    * HELPER FUNCTIONALITY
    ***************************/
    function getThumbPath(videoPath: string): string {
        return thumbnails.getThumbPath(videoPath);
    }

    function thumbRegenerate() {
        thumbnails.thumbRegenerate();
    }

    /***************************
    * EVENTS
    ***************************/
    onCurrentWallpaperChanged: {
        if (root.enabled && root.currentWallpaper != "") {
            innerService.saveOldWallpapers();

            Logger.d("video-wallpaper", root.currentWallpaper);

            // Only after saving the old wallpapers should we start the color gen since it uses the same WallpaperService
            thumbnails.startColorGen(root.currentWallpaper);

            // Set the isPlaying flag to true.
            pluginApi.pluginSettings.isPlaying = true;
            pluginApi.saveSettings();
        } else {
            innerService.applyOldWallpapers();
        }
    }

    onEnabledChanged: {
        if (root.enabled && root.currentWallpaper != "") {
            innerService.saveOldWallpapers();

            // Only after saving the old wallpapers should we start the color gen since it uses the same WallpaperService
            thumbnails.startColorGen(root.currentWallpaper);

            // Set the isPlaying flag to true.
            pluginApi.pluginSettings.isPlaying = true;
            pluginApi.saveSettings();
        } else {
            innerService.applyOldWallpapers();
        }
    }

    /***************************
    * COMPONENTS
    ***************************/
    VideoWallpaper {
        id: wallpaper
        pluginApi: root.pluginApi
        currentWallpaper: root.currentWallpaper
        enabled: root.enabled
        fillMode: root.fillMode
        isPlaying: root.isPlaying
        isMuted: root.isMuted
        orientation: root.orientation
        volume: root.volume
    }

    Thumbnails {
        id: thumbnails
        pluginApi: root.pluginApi
        enabled: root.enabled
        thumbCacheReady: root.thumbCacheReady
        wallpapersFolder: root.wallpapersFolder
        folderModel: folderModel
    }

    InnerService {
        id: innerService
        pluginApi: root.pluginApi
        currentWallpaper: root.currentWallpaper
        enabled: root.enabled
        oldWallpapers: root.oldWallpapers

        thumbnails: thumbnails
    }

    Automation {
        id: automation
        pluginApi: root.pluginApi
        automation: root.automation
        automationMode: root.automationMode
        automationTime: root.automationTime

        random: root.random
        nextWallpaper: root.nextWallpaper
    }

    FolderModel {
        id: folderModel
        folder: root.wallpapersFolder
        filters: ["*.mp4", "*.avi", "*.mov"]
    }

    // IPC Handler
    IpcHandler {
        target: "plugin:videowallpaper"

        function random() {
            root.random();
        }

        function clear() {
            root.clear();
        }

        // Current wallpaper
        function setWallpaper(path: string) {
            root.setWallpaper(path);
        }

        function getWallpaper(): string {
            return root.currentWallpaper;
        }

        // Enabled
        function setEnabled(enabled: bool) {
            if (root.pluginApi == null) return;

            root.pluginApi.pluginSettings.enabled = enabled;
            root.pluginApi.saveSettings();
        }

        function getEnabled(): bool {
            return root.enabled;
        }

        function toggleActive() {
            setEnabled(!root.enabled);
        }

        // Is playing
        function resume() {
            if (root.pluginApi == null) return;

            root.pluginApi.pluginSettings.isPlaying = true;
            root.pluginApi.saveSettings();
        }

        function pause() {
            if (root.pluginApi == null) return;

            root.pluginApi.pluginSettings.isPlaying = false;
            root.pluginApi.saveSettings();
        }

        function togglePlaying() {
            if (root.pluginApi == null) return;

            root.pluginApi.pluginSettings.isPlaying = !root.isPlaying;
            root.pluginApi.saveSettings();
        }

        // Mute / unmute
        function mute() {
            if (root.pluginApi == null) return;

            root.pluginApi.pluginSettings.isMuted = true;
            root.pluginApi.saveSettings();
        }

        function unmute() {
            if (root.pluginApi == null) return;

            root.pluginApi.pluginSettings.isMuted = false;
            root.pluginApi.saveSettings();
        }

        function toggleMute() {
            if (root.pluginApi == null) return;

            root.pluginApi.pluginSettings.isMuted = !root.isMuted;
            root.pluginApi.saveSettings();
        }

        // Volume
        function setVolume(volume: real) {
            if (root.pluginApi == null) return;

            root.pluginApi.pluginSettings.volume = volume;
            root.pluginApi.saveSettings();
        }

        function increaseVolume() {
            setVolume(root.volume + Settings.data.audio.volumeStep);
        }

        function decreaseVolume() {
            setVolume(root.volume - Settings.data.audio.volumeStep);
        }

        // Panel
        function openPanel() {
            pluginApi.withCurrentScreen(screen => {
                pluginApi.openPanel(screen);
            });
        }
    }
}
