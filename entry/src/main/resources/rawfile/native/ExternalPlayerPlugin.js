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
