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
 * Jellyfin HarmonyOS - External Player Plugin
 * 外部播放器插件
 * 迁移自 jellyfin-android/assets/native/ExternalPlayerPlugin.js
 */

const ExternalPlayerPlugin = {
    name: 'ExternalPlayer',
    type: 'mediaplayer',

    isSupported() {
        return window.ExternalPlayer && window.ExternalPlayer.isEnabled();
    },

    async load(options) {
        if (!window.ExternalPlayer) {
            throw new Error('ExternalPlayer not available');
        }

        const playOptions = {
            ids: options.ids || [],
            mediaSourceId: options.mediaSourceId,
            startIndex: options.startIndex || 0,
            startPosition: options.startPosition,
            audioStreamIndex: options.audioStreamIndex,
            subtitleStreamIndex: options.subtitleStreamIndex
        };

        window.ExternalPlayer.initPlayer(JSON.stringify(playOptions));
    },

    async pause() {
        // External players handle their own state
        console.log('ExternalPlayer.pause - not supported');
    },

    async unpause() {
        // External players handle their own state
        console.log('ExternalPlayer.unpause - not supported');
    },

    async stop() {
        // External players handle their own state
        console.log('ExternalPlayer.stop - not supported');
    },

    async destroy() {
        // External players handle their own lifecycle
        console.log('ExternalPlayer.destroy - not supported');
    },

    async seek(ticks) {
        // External players handle their own seeking
        console.log('ExternalPlayer.seek - not supported');
    },

    async seekMs(ms) {
        // External players handle their own seeking
        console.log('ExternalPlayer.seekMs - not supported');
    },

    async setVolume(volume) {
        // External players handle their own volume
        console.log('ExternalPlayer.setVolume - not supported');
    },

    getDeviceProfile(profileBuilder) {
        const profile = profileBuilder({
            enableMkvProgressive: true,
            enableSsaRender: false,
            enableAc3Encoding: false
        });

        // External players typically support direct play
        profile.DirectPlayProfiles.push({
            Container: '',
            Type: 'Video',
            VideoCodec: '',
            AudioCodec: ''
        });

        return profile;
    }
};

// Export for plugin loader
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ExternalPlayerPlugin;
}

window.ExternalPlayerPlugin = ExternalPlayerPlugin;
