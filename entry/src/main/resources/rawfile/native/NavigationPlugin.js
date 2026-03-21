/**
 * Jellyfin HarmonyOS - Navigation Plugin
 * 导航插件，处理页面导航相关功能
 * 迁移自 jellyfin-android/assets/native/NavigationPlugin.js
 */

const NavigationPlugin = {
    name: 'Navigation',
    type: 'navigation',

    isSupported() {
        return window.NativeInterface !== undefined;
    },

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

    selectServer() {
        if (window.NativeInterface) {
            window.NativeInterface.openServerSelection();
        }
    },

    openSettings() {
        if (window.NativeInterface) {
            window.NativeInterface.openClientSettings();
        }
    },

    exit() {
        if (window.NativeInterface) {
            window.NativeInterface.exitApp();
        }
    }
};

// Export for plugin loader
if (typeof module !== 'undefined' && module.exports) {
    module.exports = NavigationPlugin;
}

window.NavigationPlugin = NavigationPlugin;
