/**
 * Jellyfin HarmonyOS - ActivityEvent
 * Migrated from jellyfin-android/events/ActivityEvent.kt
 *
 * Defines activity events for communication between WebView and native code.
 */

// ==================== Activity Event Type ====================

/**
 * Activity event type enumeration.
 * Each type represents a specific action or command from the web app.
 */
export enum ActivityEventType {
  CHANGE_FULLSCREEN = 'ChangeFullscreen',
  LAUNCH_NATIVE_PLAYER = 'LaunchNativePlayer',
  OPEN_URL = 'OpenUrl',
  DOWNLOAD_FILE = 'DownloadFile',
  REMOVE_DOWNLOAD = 'RemoveDownload',
  CAST_MESSAGE = 'CastMessage',
  REQUEST_BLUETOOTH_PERMISSION = 'RequestBluetoothPermission',
  OPEN_SETTINGS = 'OpenSettings',
  SELECT_SERVER = 'SelectServer',
  EXIT_APP = 'ExitApp',
  OPEN_DOWNLOADS = 'OpenDownloads',
  UPDATE_MEDIA_SESSION = 'UpdateMediaSession',
  HIDE_MEDIA_SESSION = 'HideMediaSession',
  UPDATE_VOLUME = 'UpdateVolume'
}

// ==================== Activity Event Interface ====================

/**
 * Base interface for all activity events.
 */
export interface ActivityEvent {
  type: ActivityEventType;
  payload?: Object;
}

// ==================== Payload Interfaces ====================

/**
 * Payload for ChangeFullscreen event.
 */
export interface ChangeFullscreenPayload {
  isFullscreen: boolean;
}

/**
 * Play options for native player.
 * Migrated from PlayOptions.kt
 */
export interface PlayOptions {
  /** List of media item IDs to play */
  ids: string[];
  /** Media source ID */
  mediaSourceId?: string;
  /** Starting index in the playlist */
  startIndex: number;
  /** Starting position in ticks (1 tick = 100ns) */
  startPosition?: number;
  /** Audio stream index */
  audioStreamIndex?: number;
  /** Subtitle stream index */
  subtitleStreamIndex?: number;
  /** Whether playing from local downloads */
  playFromDownloads?: boolean;
  /** Player options */
  playerOptions?: PlayerOptions;
}

/**
 * Additional player options.
 */
export interface PlayerOptions {
  /** Enable media segments */
  enableMediaSegments?: boolean;
  /** Auto play next item */
  autoPlay?: boolean;
}

/**
 * Payload for LaunchNativePlayer event.
 */
export interface LaunchNativePlayerPayload extends PlayOptions {
}

/**
 * Payload for OpenUrl event.
 */
export interface OpenUrlPayload {
  uri: string;
}

/**
 * Payload for DownloadFile event.
 */
export interface DownloadFilePayload {
  uri: string;
  title: string;
  filename: string;
}

/**
 * Payload for RemoveDownload event.
 */
export interface RemoveDownloadPayload {
  downloadId: string;
  downloadPath: string;
  force: boolean;
}

/**
 * Payload for CastMessage event.
 */
export interface CastMessagePayload {
  action: string;
  args: string[]; // JSON array as string array
}

/**
 * Media session information.
 */
export interface MediaSessionInfo {
  itemId: string;
  title: string;
  artist?: string;
  album?: string;
  imageUrl?: string;
  duration: number;
  position: number;
  isPaused: boolean;
  canSeek: boolean;
}

/**
 * Payload for UpdateMediaSession event.
 */
export interface UpdateMediaSessionPayload extends MediaSessionInfo {
}

/**
 * Payload for UpdateVolume event.
 */
export interface UpdateVolumePayload {
  volume: number;
  muted: boolean;
}

/**
 * Download information.
 */
export interface DownloadInfo {
  uri: string;
  title: string;
  filename: string;
}

// ==================== Activity Events Factory ====================

/**
 * Factory class for creating activity events.
 * Provides type-safe event creation methods.
 */
export class ActivityEvents {
  /**
   * Create a change fullscreen event.
   */
  static changeFullscreen(isFullscreen: boolean): ActivityEvent {
    return {
      type: ActivityEventType.CHANGE_FULLSCREEN,
      payload: { isFullscreen } as ChangeFullscreenPayload
    };
  }

  /**
   * Create a launch native player event.
   */
  static launchNativePlayer(playOptions: PlayOptions): ActivityEvent {
    return {
      type: ActivityEventType.LAUNCH_NATIVE_PLAYER,
      payload: playOptions as LaunchNativePlayerPayload
    };
  }

  /**
   * Create an open URL event.
   */
  static openUrl(uri: string): ActivityEvent {
    return {
      type: ActivityEventType.OPEN_URL,
      payload: { uri } as OpenUrlPayload
    };
  }

  /**
   * Create a download file event.
   */
  static downloadFile(uri: string, title: string, filename: string): ActivityEvent {
    return {
      type: ActivityEventType.DOWNLOAD_FILE,
      payload: { uri, title, filename } as DownloadFilePayload
    };
  }

  /**
   * Create a remove download event.
   */
  static removeDownload(downloadId: string, downloadPath: string, force: boolean = false): ActivityEvent {
    return {
      type: ActivityEventType.REMOVE_DOWNLOAD,
      payload: { downloadId, downloadPath, force } as RemoveDownloadPayload
    };
  }

  /**
   * Create a cast message event.
   */
  static castMessage(action: string, args: string[]): ActivityEvent {
    return {
      type: ActivityEventType.CAST_MESSAGE,
      payload: { action, args } as CastMessagePayload
    };
  }

  /**
   * Create a request Bluetooth permission event.
   */
  static requestBluetoothPermission(): ActivityEvent {
    return {
      type: ActivityEventType.REQUEST_BLUETOOTH_PERMISSION
    };
  }

  /**
   * Create an open settings event.
   */
  static openSettings(): ActivityEvent {
    return {
      type: ActivityEventType.OPEN_SETTINGS
    };
  }

  /**
   * Create a select server event.
   */
  static selectServer(): ActivityEvent {
    return {
      type: ActivityEventType.SELECT_SERVER
    };
  }

  /**
   * Create an exit app event.
   */
  static exitApp(): ActivityEvent {
    return {
      type: ActivityEventType.EXIT_APP
    };
  }

  /**
   * Create an open downloads event.
   */
  static openDownloads(): ActivityEvent {
    return {
      type: ActivityEventType.OPEN_DOWNLOADS
    };
  }

  /**
   * Create an update media session event.
   */
  static updateMediaSession(mediaInfo: MediaSessionInfo): ActivityEvent {
    return {
      type: ActivityEventType.UPDATE_MEDIA_SESSION,
      payload: mediaInfo as UpdateMediaSessionPayload
    };
  }

  /**
   * Create a hide media session event.
   */
  static hideMediaSession(): ActivityEvent {
    return {
      type: ActivityEventType.HIDE_MEDIA_SESSION
    };
  }

  /**
   * Create an update volume event.
   */
  static updateVolume(volume: number, muted: boolean = false): ActivityEvent {
    return {
      type: ActivityEventType.UPDATE_VOLUME,
      payload: { volume, muted } as UpdateVolumePayload
    };
  }
}

// ==================== Event Helper ====================

/**
 * Helper functions for event handling.
 */
export class ActivityEventHelper {
  /**
   * Parse an activity event from JSON string.
   */
  static fromJson(jsonString: string): ActivityEvent | null {
    try {
      const obj: Record<string, Object> = JSON.parse(jsonString);
      const event: ActivityEvent = {
        type: obj.type as ActivityEventType,
        payload: obj.payload
      };
      return event;
    } catch (e) {
      return null;
    }
  }

  /**
   * Convert an activity event to JSON string.
   */
  static toJson(event: ActivityEvent): string {
    return JSON.stringify(event);
  }

  /**
   * Check if payload is ChangeFullscreenPayload.
   */
  static isChangeFullscreenPayload(payload: Object | undefined): boolean {
    if (payload === undefined) {
      return false;
    }
    const p = payload as ChangeFullscreenPayload;
    return typeof p.isFullscreen === 'boolean';
  }

  /**
   * Check if payload is PlayOptions/LaunchNativePlayerPayload.
   */
  static isPlayOptions(payload: Object | undefined): boolean {
    if (payload === undefined) {
      return false;
    }
    const p = payload as PlayOptions;
    return Array.isArray(p.ids);
  }

  /**
   * Check if payload is OpenUrlPayload.
   */
  static isOpenUrlPayload(payload: Object | undefined): boolean {
    if (payload === undefined) {
      return false;
    }
    const p = payload as OpenUrlPayload;
    return typeof p.uri === 'string';
  }

  /**
   * Check if payload is DownloadFilePayload.
   */
  static isDownloadFilePayload(payload: Object | undefined): boolean {
    if (payload === undefined) {
      return false;
    }
    const p = payload as DownloadFilePayload;
    return typeof p.uri === 'string' && typeof p.filename === 'string';
  }

  /**
   * Check if payload is CastMessagePayload.
   */
  static isCastMessagePayload(payload: Object | undefined): boolean {
    if (payload === undefined) {
      return false;
    }
    const p = payload as CastMessagePayload;
    return typeof p.action === 'string' && Array.isArray(p.args);
  }

  /**
   * Check if payload is UpdateMediaSessionPayload.
   */
  static isUpdateMediaSessionPayload(payload: Object | undefined): boolean {
    if (payload === undefined) {
      return false;
    }
    const p = payload as UpdateMediaSessionPayload;
    return typeof p.itemId === 'string';
  }

  /**
   * Check if payload is UpdateVolumePayload.
   */
  static isUpdateVolumePayload(payload: Object | undefined): boolean {
    if (payload === undefined) {
      return false;
    }
    const p = payload as UpdateVolumePayload;
    return typeof p.volume === 'number';
  }

  /**
   * Cast payload to ChangeFullscreenPayload.
   */
  static asChangeFullscreenPayload(payload: Object | undefined): ChangeFullscreenPayload | null {
    if (ActivityEventHelper.isChangeFullscreenPayload(payload)) {
      return payload as ChangeFullscreenPayload;
    }
    return null;
  }

  /**
   * Cast payload to PlayOptions.
   */
  static asPlayOptions(payload: Object | undefined): PlayOptions | null {
    if (ActivityEventHelper.isPlayOptions(payload)) {
      return payload as PlayOptions;
    }
    return null;
  }

  /**
   * Cast payload to OpenUrlPayload.
   */
  static asOpenUrlPayload(payload: Object | undefined): OpenUrlPayload | null {
    if (ActivityEventHelper.isOpenUrlPayload(payload)) {
      return payload as OpenUrlPayload;
    }
    return null;
  }

  /**
   * Cast payload to DownloadFilePayload.
   */
  static asDownloadFilePayload(payload: Object | undefined): DownloadFilePayload | null {
    if (ActivityEventHelper.isDownloadFilePayload(payload)) {
      return payload as DownloadFilePayload;
    }
    return null;
  }
}
