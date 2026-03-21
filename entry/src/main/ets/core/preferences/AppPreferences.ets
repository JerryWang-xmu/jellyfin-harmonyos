/**
 * Jellyfin HarmonyOS - AppPreferences
 * Migrated from jellyfin-android/app/AppPreferences.kt
 *
 * Manages application preferences using HarmonyOS preferences API.
 */

import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { Constants } from '../../common/constants/Constants';
import { Logger, PrefLog } from '../../common/utils/Logger';

// ==================== Enums ====================

/**
 * Video player type enumeration.
 */
export enum VideoPlayerType {
  WEB_PLAYER = 'web',
  EXO_PLAYER = 'native',  // HarmonyOS: AVPlayer
  EXTERNAL_PLAYER = 'external'
}

/**
 * External player package options.
 */
export enum ExternalPlayerPackage {
  SYSTEM_DEFAULT = 'system_default',
  MPV = 'is.xyz.mpv',
  MX_PLAYER = 'com.mxtech.videoplayer',
  VLC = 'org.videolan.vlc',
  MPVKT = 'live.mehiz.mpvkt'
}

/**
 * Media segment action types.
 */
export enum MediaSegmentAction {
  NONE = 'none',
  ASK_TO_SKIP = 'ask_to_skip',
  SKIP = 'skip'
}

/**
 * Media segment type enumeration.
 */
export enum MediaSegmentType {
  INTRO = 'intro',
  OUTRO = 'outro',
  PREVIEW = 'preview',
  RECAP = 'recap',
  COMMERCIAL = 'commercial'
}

// ==================== AppPreferences Class ====================

/**
 * App preferences class for storing and retrieving user settings.
 */
export class AppPreferences {
  private prefs: preferences.Preferences | null = null;
  private context: common.UIAbilityContext;
  private prefsName: string;

  constructor(context: common.UIAbilityContext, prefsName: string = 'jellyfin_prefs') {
    this.context = context;
    this.prefsName = prefsName;
  }

  /**
   * Initialize preferences. Must be called before using any preference methods.
   */
  async initialize(): Promise<void> {
    try {
      this.prefs = await preferences.getPreferences(this.context, this.prefsName);
      PrefLog.i('Preferences initialized successfully');
    } catch (error) {
      const err = error as Error;
      PrefLog.et('Failed to initialize preferences', err);
      throw new Error('Failed to initialize preferences: ' + (err?.message ?? 'unknown error'));
    }
  }

  /**
   * Save preferences to persistent storage.
   */
  async save(): Promise<void> {
    if (this.prefs) {
      await this.prefs.flush();
      PrefLog.d('Preferences saved');
    }
  }

  // ==================== Server/User IDs ====================

  /**
   * Current server ID.
   */
  get currentServerId(): number | null {
    const value = this.prefs?.getSync(Constants.PREF_SERVER_ID, -1) as number;
    return value >= 0 ? value : null;
  }

  set currentServerId(value: number | null) {
    if (value !== null) {
      this.prefs?.putSync(Constants.PREF_SERVER_ID, value);
    } else {
      this.prefs?.deleteSync(Constants.PREF_SERVER_ID);
    }
  }

  /**
   * Current user ID.
   */
  get currentUserId(): number | null {
    const value = this.prefs?.getSync(Constants.PREF_USER_ID, -1) as number;
    return value >= 0 ? value : null;
  }

  set currentUserId(value: number | null) {
    if (value !== null) {
      this.prefs?.putSync(Constants.PREF_USER_ID, value);
    } else {
      this.prefs?.deleteSync(Constants.PREF_USER_ID);
    }
  }

  /**
   * Instance URL.
   */
  get instanceUrl(): string | null {
    const value = this.prefs?.getSync(Constants.PREF_INSTANCE_URL, '') as string;
    return value.length > 0 ? value : null;
  }

  set instanceUrl(value: string | null) {
    if (value && value.length > 0) {
      this.prefs?.putSync(Constants.PREF_INSTANCE_URL, value);
    } else {
      this.prefs?.deleteSync(Constants.PREF_INSTANCE_URL);
    }
  }

  // ==================== System Preferences ====================

  /**
   * Ignore battery optimizations.
   */
  get ignoreBatteryOptimizations(): boolean {
    return this.prefs?.getSync(Constants.PREF_IGNORE_BATTERY_OPTIMIZATIONS, false) as boolean;
  }

  set ignoreBatteryOptimizations(value: boolean) {
    this.prefs?.putSync(Constants.PREF_IGNORE_BATTERY_OPTIMIZATIONS, value);
  }

  /**
   * Ignore WebView checks.
   */
  get ignoreWebViewChecks(): boolean {
    return this.prefs?.getSync(Constants.PREF_IGNORE_WEBVIEW_CHECKS, false) as boolean;
  }

  set ignoreWebViewChecks(value: boolean) {
    this.prefs?.putSync(Constants.PREF_IGNORE_WEBVIEW_CHECKS, value);
  }

  /**
   * Ignore Bluetooth permission.
   */
  get ignoreBluetoothPermission(): boolean {
    return this.prefs?.getSync(Constants.PREF_IGNORE_BLUETOOTH_PERMISSION, false) as boolean;
  }

  set ignoreBluetoothPermission(value: boolean) {
    this.prefs?.putSync(Constants.PREF_IGNORE_BLUETOOTH_PERMISSION, value);
  }

  // ==================== Download Preferences ====================

  /**
   * Download method.
   */
  get downloadMethod(): number | null {
    const value = this.prefs?.getSync(Constants.PREF_DOWNLOAD_METHOD, -1) as number;
    return value >= 0 ? value : null;
  }

  set downloadMethod(value: number | null) {
    if (value !== null) {
      this.prefs?.putSync(Constants.PREF_DOWNLOAD_METHOD, value);
    } else {
      this.prefs?.deleteSync(Constants.PREF_DOWNLOAD_METHOD);
    }
  }

  /**
   * Download location path.
   */
  get downloadLocation(): string {
    return this.prefs?.getSync(Constants.PREF_DOWNLOAD_LOCATION, Constants.DOWNLOAD_PATH) as string;
  }

  set downloadLocation(value: string) {
    this.prefs?.putSync(Constants.PREF_DOWNLOAD_LOCATION, value);
  }

  /**
   * Download to internal storage.
   */
  get downloadToInternal(): boolean {
    return this.prefs?.getSync(Constants.PREF_DOWNLOAD_INTERNAL, true) as boolean;
  }

  set downloadToInternal(value: boolean) {
    this.prefs?.putSync(Constants.PREF_DOWNLOAD_INTERNAL, value);
  }

  // ==================== Music Player Preferences ====================

  /**
   * Music notification always dismissible.
   */
  get musicNotificationAlwaysDismissible(): boolean {
    return this.prefs?.getSync(Constants.PREF_MUSIC_NOTIFICATION_ALWAYS_DISMISSIBLE, false) as boolean;
  }

  // ==================== Video Player Preferences ====================

  /**
   * Video player type.
   */
  get videoPlayerType(): VideoPlayerType {
    const value = this.prefs?.getSync(Constants.PREF_VIDEO_PLAYER_TYPE, VideoPlayerType.WEB_PLAYER) as string;
    return value as VideoPlayerType;
  }

  /**
   * ExoPlayer (AVPlayer): Start landscape video in landscape.
   */
  get exoPlayerStartLandscapeVideoInLandscape(): boolean {
    return this.prefs?.getSync(Constants.PREF_EXOPLAYER_START_LANDSCAPE_VIDEO_IN_LANDSCAPE, false) as boolean;
  }

  /**
   * ExoPlayer (AVPlayer): Allow swipe gestures.
   */
  get exoPlayerAllowSwipeGestures(): boolean {
    return this.prefs?.getSync(Constants.PREF_EXOPLAYER_ALLOW_SWIPE_GESTURES, true) as boolean;
  }

  /**
   * ExoPlayer (AVPlayer): Allow press to speed up.
   */
  get exoPlayerAllowPressSpeedUp(): boolean {
    return this.prefs?.getSync(Constants.PREF_EXOPLAYER_ALLOW_PRESS_SPEED_UP, true) as boolean;
  }

  /**
   * ExoPlayer (AVPlayer): Remember brightness.
   */
  get exoPlayerRememberBrightness(): boolean {
    return this.prefs?.getSync(Constants.PREF_EXOPLAYER_REMEMBER_BRIGHTNESS, false) as boolean;
  }

  /**
   * ExoPlayer (AVPlayer): Brightness value.
   */
  get exoPlayerBrightness(): number {
    return this.prefs?.getSync(Constants.PREF_EXOPLAYER_BRIGHTNESS, -1.0) as number;
  }

  set exoPlayerBrightness(value: number) {
    this.prefs?.putSync(Constants.PREF_EXOPLAYER_BRIGHTNESS, value);
  }

  /**
   * ExoPlayer (AVPlayer): Allow background audio.
   */
  get exoPlayerAllowBackgroundAudio(): boolean {
    return this.prefs?.getSync(Constants.PREF_EXOPLAYER_ALLOW_BACKGROUND_AUDIO, false) as boolean;
  }

  /**
   * ExoPlayer (AVPlayer): Direct play ASS subtitles.
   */
  get exoPlayerDirectPlayAss(): boolean {
    return this.prefs?.getSync(Constants.PREF_EXOPLAYER_DIRECT_PLAY_ASS, false) as boolean;
  }

  set exoPlayerDirectPlayAss(value: boolean) {
    this.prefs?.putSync(Constants.PREF_EXOPLAYER_DIRECT_PLAY_ASS, value);
  }

  /**
   * External player app selection.
   */
  get externalPlayerApp(): ExternalPlayerPackage {
    return this.prefs?.getSync(Constants.PREF_EXTERNAL_PLAYER_APP, ExternalPlayerPackage.SYSTEM_DEFAULT) as ExternalPlayerPackage;
  }

  set externalPlayerApp(value: ExternalPlayerPackage) {
    this.prefs?.putSync(Constants.PREF_EXTERNAL_PLAYER_APP, value);
  }

  // ==================== Media Segment Actions ====================

  /**
   * Media segment actions configuration.
   */
  get mediaSegmentActions(): string {
    const defaultActions = JSON.stringify({
      [MediaSegmentType.INTRO]: MediaSegmentAction.ASK_TO_SKIP,
      [MediaSegmentType.OUTRO]: MediaSegmentAction.ASK_TO_SKIP
    });
    return this.prefs?.getSync(Constants.PREF_MEDIA_SEGMENT_ACTIONS, defaultActions) as string;
  }

  set mediaSegmentActions(value: string) {
    this.prefs?.putSync(Constants.PREF_MEDIA_SEGMENT_ACTIONS, value);
  }

  // ==================== Subtitle Style ====================

  /**
   * Subtitle style configuration.
   */
  get subtitleStyle(): string {
    return this.prefs?.getSync(Constants.PREF_SUBTITLE_STYLE, '') as string;
  }

  set subtitleStyle(value: string) {
    this.prefs?.putSync(Constants.PREF_SUBTITLE_STYLE, value);
  }

  // ==================== Utility Methods ====================

  /**
   * Clear all preferences.
   */
  async clear(): Promise<void> {
    if (this.prefs) {
      await this.prefs.clear();
      await this.prefs.flush();
      PrefLog.i('All preferences cleared');
    }
  }

  /**
   * Check if preferences are initialized.
   */
  isInitialized(): boolean {
    return this.prefs !== null;
  }

  /**
   * Get raw preferences object for advanced usage.
   */
  getRawPreferences(): preferences.Preferences | null {
    return this.prefs;
  }
}
