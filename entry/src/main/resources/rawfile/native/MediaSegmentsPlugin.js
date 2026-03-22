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
 * Jellyfin HarmonyOS - Media Segments Plugin
 * 媒体段插件，用于跳过片头片尾等
 * 迁移自 jellyfin-android/assets/native/MediaSegmentsPlugin.js
 */

const MediaSegmentsPlugin = {
    name: 'MediaSegments',
    type: 'mediasegments',

    isSupported() {
        return window.MediaSegments !== undefined;
    },

    async setSegmentTypeAction(type, action) {
        if (window.MediaSegments) {
            window.MediaSegments.setSegmentTypeAction(type, action);
        }
    },

    async getSupportedSegmentTypes() {
        if (window.MediaSegments) {
            const types = window.MediaSegments.getSupportedSegmentTypes();
            return JSON.parse(types);
        }
        return [];
    }
};

// Export for plugin loader
if (typeof module !== 'undefined' && module.exports) {
    module.exports = MediaSegmentsPlugin;
}

window.MediaSegmentsPlugin = MediaSegmentsPlugin;
