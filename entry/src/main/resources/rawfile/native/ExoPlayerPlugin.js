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
 * Jellyfin HarmonyOS - ExoPlayer Plugin
 * 原生播放器插件 (对应 HarmonyOS AVPlayer)
 * 迁移自 jellyfin-android/assets/native/ExoPlayerPlugin.js
 */

const ExoPlayerPlugin = {
    name: 'ExoPlayer',
    type: 'mediaplayer',

    isSupported() {
        return window.NativePlayer && window.NativePlayer.isEnabled();
    },

    async load(options) {
        if (!window.NativePlayer) {
            throw new Error('NativePlayer not available');
        }

        const playOptions = {
            ids: options.ids || [],
            mediaSourceId: options.mediaSourceId,
            startIndex: options.startIndex || 0,
            startPosition: options.startPosition,
            audioStreamIndex: options.audioStreamIndex,
            subtitleStreamIndex: options.subtitleStreamIndex
        };

        window.NativePlayer.loadPlayer(JSON.stringify(playOptions));
    },

    async pause() {
        if (window.NativePlayer) {
            window.NativePlayer.pausePlayer();
        }
    },

    async unpause() {
        if (window.NativePlayer) {
            window.NativePlayer.resumePlayer();
        }
    },

    async stop() {
        if (window.NativePlayer) {
            window.NativePlayer.stopPlayer();
        }
    },

    async destroy() {
        if (window.NativePlayer) {
            window.NativePlayer.destroyPlayer();
        }
    },

    async seek(ticks) {
        if (window.NativePlayer) {
            window.NativePlayer.seekTicks(ticks);
        }
    },

    async seekMs(ms) {
        if (window.NativePlayer) {
            window.NativePlayer.seekMs(ms);
        }
    },

    async setVolume(volume) {
        if (window.NativePlayer) {
            window.NativePlayer.setVolume(volume);
        }
    },

    getDeviceProfile(profileBuilder) {
        const profile = profileBuilder({
            enableMkvProgressive: true,
            enableSsaRender: true,
            enableAc3Encoding: true
        });

        return profile;
    }
};

// Export for plugin loader
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ExoPlayerPlugin;
}

window.ExoPlayerPlugin = ExoPlayerPlugin;
