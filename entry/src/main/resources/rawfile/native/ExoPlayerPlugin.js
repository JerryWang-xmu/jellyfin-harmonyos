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
