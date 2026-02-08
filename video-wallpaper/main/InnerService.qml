import QtQuick

import qs.Commons
import qs.Services.UI

Item {
    id: root
    required property var pluginApi


    /***************************
    * PROPERTIES
    ***************************/
    required property string currentWallpaper
    required property bool enabled
    required property var oldWallpapers

    required property Thumbnails thumbnails


    /***************************
    * FUNCTIONS
    ***************************/
    function saveOldWallpapers() {
        Logger.d("video-wallpaper", "Saving old wallpapers.");

        let changed = false;
        let wallpapers = {};
        const oldWallpapers = WallpaperService.currentWallpapers;
        for(let screenName in oldWallpapers) {
            const thumbPath = thumbnails.getThumbPath(root.currentWallpaper);
            const oldWallpaper = oldWallpapers[screenName];
            // Only save the old wallpapers if it isn't the current video wallpaper, and if the thumbnail folder doesn't know of it.
            if(oldWallpaper != thumbPath && thumbnails.thumbFolderModel.indexOf(oldWallpaper) === -1) {
                wallpapers[screenName] = oldWallpapers[screenName];
            }
        }

        if(Object.keys(wallpapers).length != 0) {
            pluginApi.pluginSettings.oldWallpapers = wallpapers;
            pluginApi.saveSettings();
        }
    }

    function applyOldWallpapers() {
        Logger.d("video-wallpaper", "Applying the old wallpapers.");

        for (let screenName in oldWallpapers) {
            WallpaperService.changeWallpaper(oldWallpapers[screenName], screenName);
        }
    }

    Component.onDestruction: {
        applyOldWallpapers();
    }
}
