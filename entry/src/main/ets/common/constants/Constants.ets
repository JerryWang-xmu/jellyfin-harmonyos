/**
 * Jellyfin HarmonyOS - Constants
 * Migrated from jellyfin-android/utils/Constants.kt
 */
export class Constants {
  // ==================== App Info ====================
  static readonly APP_INFO_NAME: string = 'Jellyfin HarmonyOS';
  static readonly APP_INFO_VERSION: string = '1.0.0';

  // ==================== Webapp Constants ====================
  static readonly MINIMUM_WEB_VIEW_VERSION: number = 80;
  static readonly SHOW_PROGRESS_BAR_DELAY: number = 1000;
  static readonly INITIAL_CONNECTION_TIMEOUT: number = 10000; // 10 seconds
  static readonly CAST_SDK_PATH: string = 'cast_sender.js';
  static readonly SESSION_CAPABILITIES_PATH: string = 'sessions/capabilities/full';

  // Regex for main bundle path (using string pattern for ArkTS compatibility)
  static readonly MAIN_BUNDLE_PATH_PATTERN: string = 'main\\.[^.]+\\.bundle\\.js$';

  // ==================== Fragment Extras ====================
  static readonly FRAGMENT_CONNECT_EXTRA_ERROR: string = 'org.jellyfin.mobile.intent.extra.ERROR';
  static readonly FRAGMENT_WEB_VIEW_EXTRA_SERVER: string = 'org.jellyfin.mobile.intent.extra.SERVER';

  // ==================== Preference Keys ====================
  static readonly PREF_SERVER_ID: string = 'pref_server_id';
  static readonly PREF_USER_ID: string = 'pref_user_id';
  static readonly PREF_INSTANCE_URL: string = 'pref_instance_url';
  static readonly PREF_IGNORE_BATTERY_OPTIMIZATIONS: string = 'pref_ignore_battery_optimizations';
  static readonly PREF_IGNORE_WEBVIEW_CHECKS: string = 'pref_ignore_webview_checks';
  static readonly PREF_IGNORE_BLUETOOTH_PERMISSION: string = 'pref_ignore_bluetooth_permission';
  static readonly PREF_DOWNLOAD_METHOD: string = 'pref_download_method';
  static readonly PREF_MUSIC_NOTIFICATION_ALWAYS_DISMISSIBLE: string = 'pref_music_notification_always_dismissible';
  static readonly PREF_VIDEO_PLAYER_TYPE: string = 'pref_video_player_type';
  static readonly PREF_EXOPLAYER_START_LANDSCAPE_VIDEO_IN_LANDSCAPE: string = 'pref_exoplayer_start_landscape_video_in_landscape';
  static readonly PREF_EXOPLAYER_ALLOW_SWIPE_GESTURES: string = 'pref_exoplayer_allow_swipe_gestures';
  static readonly PREF_EXOPLAYER_ALLOW_PRESS_SPEED_UP: string = 'pref_exoplayer_allow_press_speed_up';
  static readonly PREF_EXOPLAYER_REMEMBER_BRIGHTNESS: string = 'pref_exoplayer_remember_brightness';
  static readonly PREF_EXOPLAYER_BRIGHTNESS: string = 'pref_exoplayer_brightness';
  static readonly PREF_EXOPLAYER_ALLOW_BACKGROUND_AUDIO: string = 'pref_exoplayer_allow_background_audio';
  static readonly PREF_EXOPLAYER_DIRECT_PLAY_ASS: string = 'pref_exoplayer_direct_play_ass';
  static readonly PREF_EXTERNAL_PLAYER_APP: string = 'pref_external_player_app';
  static readonly PREF_SUBTITLE_STYLE: string = 'pref_subtitle_style';
  static readonly PREF_DOWNLOAD_LOCATION: string = 'pref_download_location';
  static readonly PREF_DOWNLOAD_INTERNAL: string = 'pref_download_internal';
  static readonly PREF_MEDIA_SEGMENT_ACTIONS: string = 'pref_media_segment_actions';

  // ==================== InputManager Commands ====================
  static readonly PLAYBACK_MANAGER_COMMAND_PLAY: string = 'unpause';
  static readonly PLAYBACK_MANAGER_COMMAND_PAUSE: string = 'pause';
  static readonly PLAYBACK_MANAGER_COMMAND_PREVIOUS: string = 'previousTrack';
  static readonly PLAYBACK_MANAGER_COMMAND_NEXT: string = 'nextTrack';
  static readonly PLAYBACK_MANAGER_COMMAND_REWIND: string = 'rewind';
  static readonly PLAYBACK_MANAGER_COMMAND_FAST_FORWARD: string = 'fastForward';
  static readonly PLAYBACK_MANAGER_COMMAND_STOP: string = 'stop';
  static readonly PLAYBACK_MANAGER_COMMAND_VOL_UP: string = 'volumeUp';
  static readonly PLAYBACK_MANAGER_COMMAND_VOL_DOWN: string = 'volumeDown';

  // ==================== Notification ====================
  static readonly MEDIA_NOTIFICATION_CHANNEL_ID: string = 'org.jellyfin.harmony.media.NOW_PLAYING';
  static readonly DOWNLOAD_NOTIFICATION_CHANNEL_ID: string = 'org.jellyfin.harmony.download.DOWNLOAD_PROGRESS';
  static readonly MEDIA_PLAYER_NOTIFICATION_ID: number = 42;
  static readonly VIDEO_PLAYER_NOTIFICATION_ID: number = 99;
  static readonly DOWNLOAD_NOTIFICATION_ID: number = 80;
  static readonly REMOTE_PLAYER_CONTENT_INTENT_REQUEST_CODE: number = 100;

  // ==================== Player Intent Actions ====================
  static readonly ACTION_SHOW_PLAYER: string = 'org.jellyfin.mobile.intent.action.SHOW_PLAYER';
  static readonly ACTION_PLAY: string = 'org.jellyfin.mobile.intent.action.PLAY';
  static readonly ACTION_PAUSE: string = 'org.jellyfin.mobile.intent.action.PAUSE';
  static readonly ACTION_REWIND: string = 'org.jellyfin.mobile.intent.action.REWIND';
  static readonly ACTION_FAST_FORWARD: string = 'org.jellyfin.mobile.intent.action.FAST_FORWARD';
  static readonly ACTION_PREVIOUS: string = 'org.jellyfin.mobile.intent.action.PREVIOUS';
  static readonly ACTION_NEXT: string = 'org.jellyfin.mobile.intent.action.NEXT';
  static readonly ACTION_STOP: string = 'org.jellyfin.mobile.intent.action.STOP';
  static readonly ACTION_REPORT: string = 'org.jellyfin.mobile.intent.action.REPORT';

  // ==================== Player Intent Extras ====================
  static readonly EXTRA_PLAYER_ACTION: string = 'action';
  static readonly EXTRA_ITEM_ID: string = 'itemId';
  static readonly EXTRA_TITLE: string = 'title';
  static readonly EXTRA_ARTIST: string = 'artist';
  static readonly EXTRA_ALBUM: string = 'album';
  static readonly EXTRA_IMAGE_URL: string = 'imageUrl';
  static readonly EXTRA_POSITION: string = 'position';
  static readonly EXTRA_DURATION: string = 'duration';
  static readonly EXTRA_CAN_SEEK: string = 'canSeek';
  static readonly EXTRA_IS_LOCAL_PLAYER: string = 'isLocalPlayer';
  static readonly EXTRA_IS_PAUSED: string = 'isPaused';
  static readonly EXTRA_MEDIA_PLAY_OPTIONS: string = 'org.jellyfin.mobile.MEDIA_PLAY_OPTIONS';

  // ==================== Video Player Constants ====================
  static readonly LANGUAGE_UNDEFINED: string = 'und';
  static readonly PLAYER_TIME_UPDATE_RATE: number = 10000;
  static readonly CHAPTER_MARKING_UPDATE_DELAY: number = 1000;
  static readonly SKIP_MEDIA_SEGMENT_UPDATE_DELAY: number = 1000;
  static readonly DEFAULT_CONTROLS_TIMEOUT_MS: number = 2500;
  static readonly SWIPE_GESTURE_EXCLUSION_SIZE_VERTICAL: number = 64;
  static readonly DEFAULT_CENTER_OVERLAY_TIMEOUT_MS: number = 250;
  static readonly DISPLAY_PREFERENCES_ID_USER_SETTINGS: string = 'usersettings';
  static readonly DISPLAY_PREFERENCES_CLIENT_EMBY: string = 'emby';
  static readonly DISPLAY_PREFERENCES_SKIP_BACK_LENGTH: string = 'skipBackLength';
  static readonly DISPLAY_PREFERENCES_SKIP_FORWARD_LENGTH: string = 'skipForwardLength';
  static readonly DEFAULT_SEEK_TIME_MS: number = 10000;
  static readonly MAX_SKIP_TO_PREV_MS: number = 3000;
  static readonly DOUBLE_TAP_RIPPLE_DURATION_MS: number = 100;
  static readonly FULL_SWIPE_RANGE_SCREEN_RATIO: number = 0.66;
  static readonly SCREEN_BRIGHTNESS_MAX: number = 255;
  static readonly HOLD_SPEEDUP_MULTIPLIER: number = 3.0;
  static readonly ZOOM_SCALE_BASE: number = 1.0;
  static readonly ZOOM_SCALE_THRESHOLD: number = 0.01;
  static readonly MAX_SKIP_TO_PREV_CHAPTER_MS: number = 10000;

  // ==================== External Player ====================
  static readonly MPV_PLAYER_RESULT_ACTION: string = 'is.xyz.mpv.MPVActivity.result';
  static readonly MX_PLAYER_RESULT_ACTION: string = 'com.mxtech.intent.result.VIEW';
  static readonly VLC_PLAYER_RESULT_ACTION: string = 'org.videolan.vlc.player.result';
  static readonly MPVKT_PLAYER_RESULT_ACTION: string = 'live.mehiz.mpvkt.ui.player.PlayerActivity.result';

  // ==================== External Player Webapp Events ====================
  static readonly EVENT_ENDED: string = 'Ended';
  static readonly EVENT_TIME_UPDATE: string = 'TimeUpdate';
  static readonly EVENT_CANCELED: string = 'Canceled';

  // ==================== HarmonyOS Specific ====================
  static readonly PLAYER_EVENT_CHANNEL: string = 'player_event_channel';
  static readonly VOLUME_STEPS: number = 100;
  static readonly DEFAULT_PLAYBACK_SPEED: number = 1.0;
  static readonly PERCENT_MAX: number = 100;

  // ==================== Download ====================
  static readonly DOWNLOAD_PATH: string = '/MediaCache/';
  static readonly DOWNLOAD_THUMBNAIL_FILENAME: string = 'thumbnail.jpg';
}
