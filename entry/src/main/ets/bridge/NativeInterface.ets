/**
 * Jellyfin HarmonyOS - NativeInterface 桥接接口
 * 主桥接接口，提供设备信息、全屏控制、下载等功能
 * 迁移自 jellyfin-android/bridge/NativeInterface.kt
 */

import { BridgeChannel } from './BridgeChannel';
import { ActivityEventType, ActivityEvents, MediaSessionInfo, DownloadInfo } from '../core/event/ActivityEvent';
import { ActivityEventHandler } from '../core/event/ActivityEventHandler';
import { AppPreferences } from '../core/preferences/AppPreferences';
import { Logger } from '../common/utils/Logger';
import { Constants } from '../common/constants/Constants';
import deviceInfo from '@ohos.deviceInfo';

/**
 * 设备信息接口
 */
export interface DeviceInformation {
  deviceId: string;
  deviceName: string;
  appName: string;
  appVersion: string;
}

/**
 * NativeInterface 桥接类
 * 提供给 JavaScript 调用的原生接口
 */
export class NativeInterface {
  private static readonly TAG: string = 'NativeInterface';

  private context: Context;
  private eventHandler: ActivityEventHandler;
  private preferences: AppPreferences;
  private bridgeChannel: BridgeChannel | null = null;

  // 设备信息缓存
  private deviceInfo: DeviceInformation | null = null;

  constructor(context: Context, eventHandler: ActivityEventHandler, preferences: AppPreferences) {
    this.context = context;
    this.eventHandler = eventHandler;
    this.preferences = preferences;
    Logger.i(NativeInterface.TAG, 'NativeInterface created');
  }

  /**
   * 设置桥接通道
   */
  setBridgeChannel(channel: BridgeChannel): void {
    this.bridgeChannel = channel;
  }

  /**
   * 初始化设备信息
   */
  async initializeDeviceInfo(): Promise<void> {
    try {
      // 获取设备信息
      const deviceInfo = this.getDeviceInformation();
      if (deviceInfo) {
        this.deviceInfo = JSON.parse(deviceInfo);
        Logger.i(NativeInterface.TAG, 'Device info initialized: %{public}s', deviceInfo);
      }
    } catch (error) {
      Logger.e(NativeInterface.TAG, 'Failed to initialize device info: %{public}s', JSON.stringify(error));
    }
  }

  // ============ JavaScript 可调用方法 ============

  /**
   * 获取设备信息
   * @returns JSON 格式的设备信息字符串
   */
  getDeviceInformation(): string | null {
    try {
      // 在 HarmonyOS 中获取设备信息
      const deviceInfo: DeviceInformation = {
        deviceId: this.getDeviceId(),
        deviceName: this.getDeviceName(),
        appName: Constants.APP_INFO_NAME,
        appVersion: Constants.APP_INFO_VERSION
      };

      return JSON.stringify(deviceInfo);
    } catch (error) {
      Logger.e(NativeInterface.TAG, 'Failed to get device information: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 启用全屏模式
   * @returns 是否成功
   */
  enableFullscreen(): boolean {
    Logger.d(NativeInterface.TAG, 'enableFullscreen called');
    this.eventHandler.emit(ActivityEvents.changeFullscreen(true));
    return true;
  }

  /**
   * 禁用全屏模式
   * @returns 是否成功
   */
  disableFullscreen(): boolean {
    Logger.d(NativeInterface.TAG, 'disableFullscreen called');
    this.eventHandler.emit(ActivityEvents.changeFullscreen(false));
    return true;
  }

  /**
   * 打开外部 URL
   * @param uri URL 地址
   * @returns 是否成功
   */
  openUrl(uri: string): boolean {
    Logger.d(NativeInterface.TAG, 'openUrl called: %{public}s', uri);
    this.eventHandler.emit(ActivityEvents.openUrl(uri));
    return true;
  }

  /**
   * 更新媒体会话
   * @param args JSON 格式的媒体信息
   * @returns 是否成功
   */
  updateMediaSession(args: string): boolean {
    Logger.d(NativeInterface.TAG, 'updateMediaSession called');

    try {
      const options: ESObject = JSON.parse(args) as ESObject;

      const mediaInfo: MediaSessionInfo = {
        itemId: String(options['itemId'] ?? ''),
        title: String(options['title'] ?? ''),
        artist: options['artist'] !== undefined ? String(options['artist']) : undefined,
        album: options['album'] !== undefined ? String(options['album']) : undefined,
        imageUrl: options['imageUrl'] !== undefined ? String(options['imageUrl']) : undefined,
        duration: (options['duration'] as number | undefined) ?? 0,
        position: (options['position'] as number | undefined) ?? -1,
        isPaused: (options['isPaused'] as boolean | undefined) ?? true,
        canSeek: (options['canSeek'] as boolean | undefined) ?? false
      };

      this.eventHandler.emit(ActivityEvents.updateMediaSession(mediaInfo));

      // 请求蓝牙权限（用于蓝牙断开事件处理）
      this.eventHandler.emit(ActivityEvents.requestBluetoothPermission());

      return true;
    } catch (error) {
      Logger.e(NativeInterface.TAG, 'updateMediaSession error: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 隐藏媒体会话
   * @returns 是否成功
   */
  hideMediaSession(): boolean {
    Logger.d(NativeInterface.TAG, 'hideMediaSession called');
    this.eventHandler.emit(ActivityEvents.hideMediaSession());
    return true;
  }

  /**
   * 更新音量级别
   * @param value 音量值 (0-100)
   */
  updateVolumeLevel(value: number): void {
    Logger.d(NativeInterface.TAG, 'updateVolumeLevel called: %{public}s', String(value));
    this.eventHandler.emit(ActivityEvents.updateVolume(value));
  }

  /**
   * 下载文件
   * @param args JSON 格式的文件信息数组
   * @returns 是否成功
   */
  downloadFiles(args: string): boolean {
    Logger.d(NativeInterface.TAG, 'downloadFiles called');

    try {
      const files: ESObject[] = JSON.parse(args) as ESObject[];

      if (!Array.isArray(files)) {
        Logger.e(NativeInterface.TAG, 'downloadFiles: args is not an array');
        return false;
      }

      for (let fi = 0; fi < files.length; fi++) {
        const fileObj: ESObject = files[fi];
        const downloadInfo: DownloadInfo = {
          uri: String(fileObj['url'] ?? ''),
          title: String(fileObj['title'] ?? ''),
          filename: String(fileObj['filename'] ?? '')
        };

        this.eventHandler.emit(ActivityEvents.downloadFile(
          downloadInfo.uri,
          downloadInfo.title,
          downloadInfo.filename
        ));
      }

      return true;
    } catch (error) {
      Logger.e(NativeInterface.TAG, 'downloadFiles error: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 打开下载管理器
   */
  openDownloadManager(): void {
    Logger.d(NativeInterface.TAG, 'openDownloadManager called');
    this.eventHandler.emit(ActivityEvents.openDownloads());
  }

  /**
   * 打开客户端设置
   */
  openClientSettings(): void {
    Logger.d(NativeInterface.TAG, 'openClientSettings called');
    this.eventHandler.emit(ActivityEvents.openSettings());
  }

  /**
   * 打开下载页面
   */
  openDownloads(): void {
    Logger.d(NativeInterface.TAG, 'openDownloads called');
    this.eventHandler.emit(ActivityEvents.openDownloads());
  }

  /**
   * 打开服务器选择页面
   */
  openServerSelection(): void {
    Logger.d(NativeInterface.TAG, 'openServerSelection called');
    this.eventHandler.emit(ActivityEvents.selectServer());
  }

  /**
   * 退出应用
   */
  exitApp(): void {
    Logger.d(NativeInterface.TAG, 'exitApp called');
    this.eventHandler.emit(ActivityEvents.exitApp());
  }

  /**
   * 执行 Cast 操作
   * @param action 动作名称
   * @param args JSON 格式的参数数组
   */
  execCast(action: string, args: string): void {
    Logger.d(NativeInterface.TAG, 'execCast called: action=%{public}s', action);

    try {
      const argsArray = JSON.parse(args) as string[];
      this.eventHandler.emit(ActivityEvents.castMessage(action, argsArray));
    } catch (error) {
      Logger.e(NativeInterface.TAG, 'execCast error: %{public}s', JSON.stringify(error));
    }
  }

  // ============ 私有辅助方法 ============

  /**
   * 获取设备 ID（持久化存储，基于 UUID v4）
   * 在 HarmonyOS 中通过 preferences 持久化设备唯一标识符
   */
  private getDeviceId(): string {
    try {
      const DEVICE_ID_KEY = 'device_id';
      const prefs = this.preferences.getRawPreferences();
      let id = prefs ? (prefs.getSync(DEVICE_ID_KEY, '') as string) : '';
      if (!id || id.length === 0) {
        // 生成 UUID v4
        id = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
          const r = Math.random() * 16 | 0;
          const v = c === 'x' ? r : (r & 0x3 | 0x8);
          return v.toString(16);
        });
        if (prefs) {
          prefs.putSync(DEVICE_ID_KEY, id);
          prefs.flush();
        }
      }
      return id;
    } catch (error) {
      Logger.e(NativeInterface.TAG, 'Failed to get device ID: %{public}s', JSON.stringify(error));
      return 'unknown_device';
    }
  }

  /**
   * 获取设备名称
   * 使用 @ohos.deviceInfo 获取真实设备名称
   */
  private getDeviceName(): string {
    try {
      return deviceInfo.marketName || deviceInfo.productModel || 'HarmonyOS Device';
    } catch (error) {
      Logger.e(NativeInterface.TAG, 'Failed to get device name: %{public}s', JSON.stringify(error));
      return 'HarmonyOS Device';
    }
  }

  /**
   * 编码参数值 (移除特殊字符)
   */
  private encodeParameterValue(value: string): string {
    return value.replace(/[^\w\s-]/g, '').trim();
  }
}

/**
 * NativeInterface 代理对象
 * 用于注册到 WebView 的 JavaScript 代理
 */
export interface NativeInterfaceProxy {
  getDeviceInformation: () => string | null;
  enableFullscreen: () => boolean;
  disableFullscreen: () => boolean;
  openUrl: (uri: string) => boolean;
  updateMediaSession: (args: string) => boolean;
  hideMediaSession: () => boolean;
  updateVolumeLevel: (value: number) => void;
  downloadFiles: (args: string) => boolean;
  openDownloadManager: () => void;
  openClientSettings: () => void;
  openDownloads: () => void;
  openServerSelection: () => void;
  exitApp: () => void;
  execCast: (action: string, args: string) => void;
}

/**
 * 创建 NativeInterface 代理
 */
export function createNativeInterfaceProxy(nativeInterface: NativeInterface): NativeInterfaceProxy {
  return {
    getDeviceInformation: (): string | null => nativeInterface.getDeviceInformation(),
    enableFullscreen: (): boolean => nativeInterface.enableFullscreen(),
    disableFullscreen: (): boolean => nativeInterface.disableFullscreen(),
    openUrl: (uri: string): boolean => nativeInterface.openUrl(uri),
    updateMediaSession: (args: string): boolean => nativeInterface.updateMediaSession(args),
    hideMediaSession: (): boolean => nativeInterface.hideMediaSession(),
    updateVolumeLevel: (value: number): void => nativeInterface.updateVolumeLevel(value),
    downloadFiles: (args: string): boolean => nativeInterface.downloadFiles(args),
    openDownloadManager: (): void => nativeInterface.openDownloadManager(),
    openClientSettings: (): void => nativeInterface.openClientSettings(),
    openDownloads: (): void => nativeInterface.openDownloads(),
    openServerSelection: (): void => nativeInterface.openServerSelection(),
    exitApp: (): void => nativeInterface.exitApp(),
    execCast: (action: string, args: string): void => nativeInterface.execCast(action, args)
  };
}
