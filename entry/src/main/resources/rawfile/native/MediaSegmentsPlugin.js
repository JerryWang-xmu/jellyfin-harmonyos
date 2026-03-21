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
