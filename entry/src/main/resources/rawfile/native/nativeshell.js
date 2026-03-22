/*
 * Copyright (C) 2020-2026 Jellyfin Contributors
 * Copyright (C) 2026 WangRuijie
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * ---
 *
 * Based on jellyfin-android by Jellyfin Contributors
 * Original repository: https://github.com/jellyfin/jellyfin-android
 * Rewritten in 'ArkTS' with modifications by WangRuijie on 2026-03-22
 */

/**
 * Jellyfin HarmonyOS - NativeShell JavaScript
 * WebView 与原生桥接的 JavaScript 端实现
 * 迁移自 jellyfin-android/assets/native/nativeshell.js
 */

const features = [
    "castmenuhashchange",
    "clientsettings",
    "displaylanguage",
    "downloadmanagement",
    "exit",
    "externallinks",
    "filedownload",
    "fileinput",
    "htmlaudioautoplay",
    "htmlvideoautoplay",
    "multiserver",
    "physicalvolumecontrol",
    "remotecontrol",
    "subtitleappearancesettings",
    "subtitleburnsettings"
];

const plugins = [
    'NavigationPlugin',
    'ExoPlayerPlugin',
    'ExternalPlayerPlugin',
    'MediaSegmentsPlugin'
];

// Add plugin loaders
for (const plugin of plugins) {
    window[plugin] = async () => {
        const pluginDefinition = await import(`/native/${plugin}.js`);
        return pluginDefinition[plugin];
    };
}

let deviceId;
let deviceName;
let appName;
let appVersion;

window.NativeShell = {
    enableFullscreen() {
        if (window.NativeInterface) {
            window.NativeInterface.enableFullscreen();
        }
    },

    disableFullscreen() {
        if (window.NativeInterface) {
            window.NativeInterface.disableFullscreen();
        }
    },

    openUrl(url, target) {
        if (window.NativeInterface) {
            window.NativeInterface.openUrl(url);
        }
    },

    updateMediaSession(mediaInfo) {
        if (window.NativeInterface) {
            window.NativeInterface.updateMediaSession(JSON.stringify(mediaInfo));
        }
    },

    hideMediaSession() {
        if (window.NativeInterface) {
            window.NativeInterface.hideMediaSession();
        }
    },

    updateVolumeLevel(value) {
        if (window.NativeInterface) {
            window.NativeInterface.updateVolumeLevel(value);
        }
    },

    downloadFile(downloadInfo) {
        if (window.NativeInterface) {
            window.NativeInterface.downloadFiles(JSON.stringify([downloadInfo]));
        }
    },

    downloadFiles(downloadInfo) {
        if (window.NativeInterface) {
            window.NativeInterface.downloadFiles(JSON.stringify(downloadInfo));
        }
    },

    openDownloadManager() {
        if (window.NativeInterface) {
            window.NativeInterface.openDownloadManager();
        }
    },

    openClientSettings() {
        if (window.NativeInterface) {
            window.NativeInterface.openClientSettings();
        }
    },

    openDownloads() {
        if (window.NativeInterface) {
            window.NativeInterface.openDownloads();
        }
    },

    selectServer() {
        if (window.NativeInterface) {
            window.NativeInterface.openServerSelection();
        }
    },

    getPlugins() {
        return plugins;
    },

    async execCast(action, args, callback) {
        this.castCallbacks = this.castCallbacks || {};
        this.castCallbacks[action] = callback;
        if (window.NativeInterface) {
            window.NativeInterface.execCast(action, JSON.stringify(args));
        }
    },

    async castCallback(action, keep, err, result) {
        const callbacks = this.castCallbacks || {};
        const callback = callbacks[action];
        callback && callback(err || null, result);
        if (!keep) {
            delete callbacks[action];
        }
    }
};

function getDeviceProfile(profileBuilder, item) {
    const profile = profileBuilder({
        enableMkvProgressive: false
    });

    profile.CodecProfiles = profile.CodecProfiles.filter(function (i) {
        return i.Type === "Audio";
    });

    profile.CodecProfiles.push({
        Type: "Video",
        Container: "avi",
        Conditions: [
            {
                Condition: "NotEquals",
                Property: "VideoCodecTag",
                Value: "xvid"
            }
        ]
    });

    profile.CodecProfiles.push({
        Type: "Video",
        Codec: "h264",
        Conditions: [
            {
                Condition: "EqualsAny",
                Property: "VideoProfile",
                Value: "high|main|baseline|constrained baseline"
            },
            {
                Condition: "LessThanEqual",
                Property: "VideoLevel",
                Value: "41"
            }]
    });

    profile.TranscodingProfiles.reduce(function (profiles, p) {
        if (p.Type === "Video" && p.CopyTimestamps === true && p.VideoCodec === "h264") {
            p.AudioCodec += ",ac3";
            profiles.push(p);
        }
        return profiles;
    }, []);

    return profile;
}

window.NativeShell.AppHost = {
    init() {
        if (window.NativeInterface) {
            const result = JSON.parse(window.NativeInterface.getDeviceInformation());
            // set globally so they can be used elsewhere
            deviceId = result.deviceId;
            deviceName = result.deviceName;
            appName = result.appName;
            appVersion = result.appVersion;
        }
    },
    getDefaultLayout() {
        return "mobile";
    },
    supports(command) {
        return features.includes(command.toLowerCase());
    },
    getDeviceProfile,
    getSyncProfile: getDeviceProfile,
    deviceName() {
        return deviceName;
    },
    deviceId() {
        return deviceId;
    },
    appName() {
        return appName;
    },
    appVersion() {
        return appVersion;
    },
    exit() {
        if (window.NativeInterface) {
            window.NativeInterface.exitApp();
        }
    }
};

// External Player support
window.ExtPlayer = {
    notifyCANCELED(parameters) {
        console.log('ExtPlayer.notifyCANCELED');
    },

    notifyENDED(parameters) {
        console.log('ExtPlayer.notifyENDED');
    },

    notifyTIME_UPDATE(parameters) {
        console.log('ExtPlayer.notifyTIME_UPDATE: ' + parameters);
    }
};
