/*
 * Jellyfin for HarmonyOS
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
 * Jellyfin HarmonyOS - NativePlayer 桥接接口
 * 原生播放器桥接，提供播放控制接口
 * 迁移自 jellyfin-android/bridge/NativePlayer.kt
 */

import { ActivityEventHandler } from '../core/event/ActivityEventHandler';
import { ActivityEvents, PlayOptions } from '../core/event/ActivityEvent';
import { AppPreferences, VideoPlayerType } from '../core/preferences/AppPreferences';
import { Logger } from '../common/utils/Logger';

/**
 * 播放器事件类型
 */
export enum PlayerEventType {
  PAUSE = 'Pause',
  RESUME = 'Resume',
  STOP = 'Stop',
  DESTROY = 'Destroy',
  SEEK = 'Seek',
  SET_VOLUME = 'SetVolume'
}

/**
 * 播放器事件接口
 */
export interface PlayerEvent {
  type: PlayerEventType;
  payload?: ESObject;
}

/**
 * NativePlayer 桥接类
 * 提供给 JavaScript 调用的原生播放器接口
 */
export class NativePlayer {
  private static readonly TAG: string = 'NativePlayer';

  private preferences: AppPreferences;
  private eventHandler: ActivityEventHandler;
  private playerEventListeners: ((event: PlayerEvent) => void)[] = [];

  constructor(preferences: AppPreferences, eventHandler: ActivityEventHandler) {
    this.preferences = preferences;
    this.eventHandler = eventHandler;
    Logger.i(NativePlayer.TAG, 'NativePlayer created');
  }

  // ============ JavaScript 可调用方法 ============

  /**
   * 检查原生播放器是否启用
   * @returns 是否启用
   */
  isEnabled(): boolean {
    const enabled = this.preferences.videoPlayerType === VideoPlayerType.EXO_PLAYER;
    Logger.d(NativePlayer.TAG, 'isEnabled: %{public}s', String(enabled));
    return enabled;
  }

  /**
   * 加载播放器
   * @param args JSON 格式的播放选项
   */
  loadPlayer(args: string): void {
    Logger.d(NativePlayer.TAG, 'loadPlayer called with args: %{public}s', args);

    try {
      const options = this.parsePlayOptions(args);
      if (options) {
        this.eventHandler.emit(ActivityEvents.launchNativePlayer(options));
      } else {
        Logger.e(NativePlayer.TAG, 'Failed to parse play options');
      }
    } catch (error) {
      Logger.e(NativePlayer.TAG, 'loadPlayer error: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 暂停播放器
   */
  pausePlayer(): void {
    Logger.d(NativePlayer.TAG, 'pausePlayer called');
    this.emitPlayerEvent({ type: PlayerEventType.PAUSE });
  }

  /**
   * 恢复播放器
   */
  resumePlayer(): void {
    Logger.d(NativePlayer.TAG, 'resumePlayer called');
    this.emitPlayerEvent({ type: PlayerEventType.RESUME });
  }

  /**
   * 停止播放器
   */
  stopPlayer(): void {
    Logger.d(NativePlayer.TAG, 'stopPlayer called');
    this.emitPlayerEvent({ type: PlayerEventType.STOP });
  }

  /**
   * 销毁播放器
   */
  destroyPlayer(): void {
    Logger.d(NativePlayer.TAG, 'destroyPlayer called');
    this.emitPlayerEvent({ type: PlayerEventType.DESTROY });
  }

  /**
   * 按时间刻度跳转
   * @param ticks 时间刻度 (100纳秒为单位)
   */
  seekTicks(ticks: number): void {
    Logger.d(NativePlayer.TAG, 'seekTicks called: %{public}s', String(ticks));
    // 转换 ticks 到毫秒 (1 tick = 100ns, 1ms = 10000 ticks)
    const milliseconds = Math.floor(ticks / 10000);
    this.emitPlayerEvent({
      type: PlayerEventType.SEEK,
      payload: { milliseconds, ticks }
    });
  }

  /**
   * 按毫秒跳转
   * @param ms 毫秒数
   */
  seekMs(ms: number): void {
    Logger.d(NativePlayer.TAG, 'seekMs called: %{public}s', String(ms));
    this.emitPlayerEvent({
      type: PlayerEventType.SEEK,
      payload: { milliseconds: ms }
    });
  }

  /**
   * 设置音量
   * @param volume 音量值 (0-100)
   */
  setVolume(volume: number): void {
    Logger.d(NativePlayer.TAG, 'setVolume called: %{public}s', String(volume));
    this.emitPlayerEvent({
      type: PlayerEventType.SET_VOLUME,
      payload: { volume }
    });
  }

  // ============ 事件监听 ============

  /**
   * 添加播放器事件监听器
   * @param listener 监听器函数
   */
  addPlayerEventListener(listener: (event: PlayerEvent) => void): void {
    this.playerEventListeners.push(listener);
  }

  /**
   * 移除播放器事件监听器
   * @param listener 监听器函数
   */
  removePlayerEventListener(listener: (event: PlayerEvent) => void): void {
    const index = this.playerEventListeners.indexOf(listener);
    if (index >= 0) {
      this.playerEventListeners.splice(index, 1);
    }
  }

  /**
   * 清除所有监听器
   */
  clearListeners(): void {
    this.playerEventListeners = [];
  }

  // ============ 私有方法 ============

  /**
   * 解析播放选项
   */
  private parsePlayOptions(args: string): PlayOptions | null {
    try {
      const json: ESObject = JSON.parse(args) as ESObject;

      const opts: PlayOptions = {
        ids: (json['ids'] as string[] | undefined) ?? [],
        mediaSourceId: json['mediaSourceId'] !== undefined ? String(json['mediaSourceId']) : undefined,
        startIndex: (json['startIndex'] as number | undefined) ?? 0,
        startPosition: json['startPosition'] !== undefined ? (json['startPosition'] as number) : undefined,
        audioStreamIndex: json['audioStreamIndex'] !== undefined ? (json['audioStreamIndex'] as number) : undefined,
        subtitleStreamIndex: json['subtitleStreamIndex'] !== undefined ? (json['subtitleStreamIndex'] as number) : undefined,
        playFromDownloads: (json['playFromDownloads'] as boolean | undefined) ?? false
      };
      return opts;
    } catch (error) {
      Logger.e(NativePlayer.TAG, 'Failed to parse play options: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 发送播放器事件
   */
  private emitPlayerEvent(event: PlayerEvent): void {
    for (const listener of this.playerEventListeners) {
      try {
        listener(event);
      } catch (error) {
        Logger.e(NativePlayer.TAG, 'Player event listener error: %{public}s', JSON.stringify(error));
      }
    }
  }
}

/**
 * NativePlayer 代理对象
 * 用于注册到 WebView 的 JavaScript 代理
 */
export interface NativePlayerProxy {
  isEnabled: () => boolean;
  loadPlayer: (args: string) => void;
  pausePlayer: () => void;
  resumePlayer: () => void;
  stopPlayer: () => void;
  destroyPlayer: () => void;
  seekTicks: (ticks: number) => void;
  seekMs: (ms: number) => void;
  setVolume: (volume: number) => void;
}

/**
 * 创建 NativePlayer 代理
 */
export function createNativePlayerProxy(nativePlayer: NativePlayer): NativePlayerProxy {
  return {
    isEnabled: (): boolean => nativePlayer.isEnabled(),
    loadPlayer: (args: string): void => nativePlayer.loadPlayer(args),
    pausePlayer: (): void => nativePlayer.pausePlayer(),
    resumePlayer: (): void => nativePlayer.resumePlayer(),
    stopPlayer: (): void => nativePlayer.stopPlayer(),
    destroyPlayer: (): void => nativePlayer.destroyPlayer(),
    seekTicks: (ticks: number): void => nativePlayer.seekTicks(ticks),
    seekMs: (ms: number): void => nativePlayer.seekMs(ms),
    setVolume: (volume: number): void => nativePlayer.setVolume(volume)
  };
}
