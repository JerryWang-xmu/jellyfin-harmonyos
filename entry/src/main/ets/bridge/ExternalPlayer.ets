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
 * Jellyfin HarmonyOS - ExternalPlayer 桥接接口
 * 外部播放器桥接，支持调用系统或第三方播放器
 * 迁移自 jellyfin-android/bridge/ExternalPlayer.kt
 */

import { BridgeChannel } from './BridgeChannel';
import { AppPreferences, VideoPlayerType, ExternalPlayerPackage } from '../core/preferences/AppPreferences';
import { Logger } from '../common/utils/Logger';
import { Constants } from '../common/constants/Constants';

/**
 * 外部播放器事件常量类型
 */
interface ExternalPlayerEventsType {
  CANCELED: string;
  ENDED: string;
  TIME_UPDATE: string;
}

/**
 * 外部播放器事件常量
 */
export const ExternalPlayerEvents: ExternalPlayerEventsType = {
  CANCELED: 'CANCELED',
  ENDED: 'ENDED',
  TIME_UPDATE: 'TIME_UPDATE'
};

/**
 * 允许的事件列表
 */
const ALLOWED_EVENTS = [
  ExternalPlayerEvents.CANCELED,
  ExternalPlayerEvents.ENDED,
  ExternalPlayerEvents.TIME_UPDATE
];

/**
 * 播放选项接口
 */
export interface ExternalPlayOptions {
  ids: string[];
  mediaSourceId?: string;
  startIndex: number;
  startPosition?: number;
  audioStreamIndex?: number;
  subtitleStreamIndex?: number;
}

/**
 * 媒体源信息
 */
export interface MediaSourceInfo {
  itemId: string;
  id: string;
  playSessionId: string;
  name: string;
  playMethod: string;
  startTime: number;
  mediaStreams: MediaStreamInfo[];
  externalSubtitleStreams: ExternalSubtitleStream[];
  selectedSubtitleStream?: MediaStreamInfo;
}

/**
 * 媒体流信息
 */
export interface MediaStreamInfo {
  index: number;
  type: string;
  codec?: string;
  language?: string;
  displayTitle?: string;
  deliveryUrl?: string;
}

/**
 * 外部字幕流
 */
export interface ExternalSubtitleStream extends MediaStreamInfo {
  deliveryUrl: string;
}

/**
 * 外部播放器桥接类
 */
export class ExternalPlayer {
  private static readonly TAG: string = 'ExternalPlayer';

  private context: Context;
  private preferences: AppPreferences;
  private bridgeChannel: BridgeChannel | null = null;

  constructor(context: Context, preferences: AppPreferences) {
    this.context = context;
    this.preferences = preferences;
    Logger.i(ExternalPlayer.TAG, 'ExternalPlayer created');
  }

  /**
   * 设置桥接通道
   */
  setBridgeChannel(channel: BridgeChannel): void {
    this.bridgeChannel = channel;
  }

  // ============ JavaScript 可调用方法 ============

  /**
   * 检查外部播放器是否启用
   * @returns 是否启用
   */
  isEnabled(): boolean {
    const enabled = this.preferences.videoPlayerType === VideoPlayerType.EXTERNAL_PLAYER;
    Logger.d(ExternalPlayer.TAG, 'isEnabled: %{public}s', String(enabled));
    return enabled;
  }

  /**
   * 初始化播放器
   * @param args JSON 格式的播放选项
   */
  initPlayer(args: string): void {
    Logger.d(ExternalPlayer.TAG, 'initPlayer called with args: %{public}s', args);

    try {
      const playOptions = this.parsePlayOptions(args);
      if (!playOptions || playOptions.ids.length === 0) {
        Logger.e(ExternalPlayer.TAG, 'Invalid play options');
        this.showToast('Invalid play options');
        return;
      }

      // 启动外部播放器
      this.launchExternalPlayer(playOptions);
    } catch (error) {
      Logger.e(ExternalPlayer.TAG, 'initPlayer error: %{public}s', JSON.stringify(error));
      this.showToast('Failed to initialize player');
    }
  }

  // ============ 私有方法 ============

  /**
   * 解析播放选项
   */
  private parsePlayOptions(args: string): ExternalPlayOptions | null {
    try {
      const json: ESObject = JSON.parse(args) as ESObject;

      const opts: ExternalPlayOptions = {
        ids: (json['ids'] as string[] | undefined) ?? [],
        mediaSourceId: json['mediaSourceId'] !== undefined ? String(json['mediaSourceId']) : undefined,
        startIndex: (json['startIndex'] as number | undefined) ?? 0,
        startPosition: json['startPosition'] !== undefined ? (json['startPosition'] as number) : undefined,
        audioStreamIndex: json['audioStreamIndex'] !== undefined ? (json['audioStreamIndex'] as number) : undefined,
        subtitleStreamIndex: json['subtitleStreamIndex'] !== undefined ? (json['subtitleStreamIndex'] as number) : undefined
      };
      return opts;
    } catch (error) {
      Logger.e(ExternalPlayer.TAG, 'Failed to parse play options: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 启动外部播放器
   */
  private async launchExternalPlayer(playOptions: ExternalPlayOptions): Promise<void> {
    try {
      // 获取媒体源信息
      const mediaSource = await this.resolveMediaSource(playOptions);
      if (!mediaSource) {
        Logger.e(ExternalPlayer.TAG, 'Failed to resolve media source');
        this.showToast('Failed to resolve media source');
        return;
      }

      // 构建播放 URL
      const playUrl = this.buildPlayUrl(mediaSource);

      // 启动外部播放器
      await this.startPlayerActivity(playUrl, mediaSource);
    } catch (error) {
      Logger.e(ExternalPlayer.TAG, 'launchExternalPlayer error: %{public}s', JSON.stringify(error));
      this.showToast('Failed to launch external player');
    }
  }

  /**
   * 解析媒体源
   */
  private async resolveMediaSource(playOptions: ExternalPlayOptions): Promise<MediaSourceInfo | null> {
    // 简化实现，实际应该调用 API 获取媒体源信息
    const itemId = playOptions.ids[0];

    return {
      itemId: itemId,
      id: playOptions.mediaSourceId || itemId,
      playSessionId: `session_${Date.now()}`,
      name: 'Media',
      playMethod: 'DirectPlay',
      startTime: playOptions.startPosition || 0,
      mediaStreams: [],
      externalSubtitleStreams: []
    };
  }

  /**
   * 构建播放 URL
   */
  private buildPlayUrl(mediaSource: MediaSourceInfo): string {
    // 简化实现，实际应该使用 API 客户端构建 URL
    return `https://server/video/${mediaSource.itemId}/stream?MediaSourceId=${mediaSource.id}&Static=true`;
  }

  /**
   * 启动播放器 Activity
   */
  private async startPlayerActivity(url: string, source: MediaSourceInfo): Promise<void> {
    // 在 HarmonyOS 中，使用 Want 启动外部应用
    Logger.i(ExternalPlayer.TAG, 'Starting external player with URL: %{public}s', url);

    // 实际实现应该使用 @ohos.app.ability.common 或 similar API
    // 这里是简化版本
    const playerPackage = this.preferences.externalPlayerApp;

    Logger.i(ExternalPlayer.TAG, 'External player package: %{public}s', playerPackage);
    Logger.i(ExternalPlayer.TAG, 'Play info: title=%{public}s, position=%{public}s',
      source.name, String(source.startTime));
  }

  /**
   * 通知事件
   */
  private notifyEvent(event: string, parameters: string = ''): void {
    if (!ALLOWED_EVENTS.includes(event)) {
      Logger.w(ExternalPlayer.TAG, 'Event not allowed: %{public}s', event);
      return;
    }

    if (parameters && !/^\d+$/.test(parameters)) {
      Logger.w(ExternalPlayer.TAG, 'Invalid parameters, must be digits only');
      return;
    }

    if (this.bridgeChannel) {
      this.bridgeChannel.notifyExternalPlayerEvent(event, parameters);
    } else {
      Logger.w(ExternalPlayer.TAG, 'BridgeChannel not set');
    }
  }

  /**
   * 显示 Toast 消息
   */
  private showToast(message: string): void {
    Logger.d(ExternalPlayer.TAG, 'Toast: %{public}s', message);
    // 实际实现应该使用 @ohos.promptAction.showToast
  }

  // ============ 播放器结果处理 ============

  /**
   * 处理播放结果
   */
  handlePlayerResult(resultCode: number, data: ESObject): void {
    const playerPackage = this.preferences.externalPlayerApp;

    switch (playerPackage) {
      case ExternalPlayerPackage.MPV:
        this.handleMPVPlayerResult(resultCode, data);
        break;
      case ExternalPlayerPackage.MX_PLAYER:
        this.handleMXPlayerResult(resultCode, data);
        break;
      case ExternalPlayerPackage.VLC:
        this.handleVLCPlayerResult(resultCode, data);
        break;
      case ExternalPlayerPackage.MPVKT:
        this.handleMPVKTPlayerResult(resultCode, data);
        break;
      default:
        this.handleUnknownPlayerResult(resultCode, data);
        break;
    }
  }

  /**
   * 处理 MPV 播放器结果
   */
  private handleMPVPlayerResult(resultCode: number, data: ESObject): void {
    const player = 'MPV Player';

    if (resultCode === 0) { // RESULT_OK
      const position: number = (data['position'] as number | undefined) ?? -1;

      if (position > 0) {
        Logger.d(ExternalPlayer.TAG, 'Playback stopped [player=%{public}s, position=%{public}s]', player, String(position));
        this.notifyEvent(ExternalPlayerEvents.TIME_UPDATE, String(position));
        this.notifyEvent(ExternalPlayerEvents.ENDED);
      } else if (position === 0) {
        Logger.d(ExternalPlayer.TAG, 'Playback canceled [player=%{public}s]', player);
        this.notifyEvent(ExternalPlayerEvents.CANCELED);
      } else {
        Logger.d(ExternalPlayer.TAG, 'Playback completed [player=%{public}s]', player);
        this.notifyEvent(ExternalPlayerEvents.TIME_UPDATE);
        this.notifyEvent(ExternalPlayerEvents.ENDED);
      }
    } else {
      Logger.d(ExternalPlayer.TAG, 'Playback stopped by unknown error [player=%{public}s]', player);
      this.notifyEvent(ExternalPlayerEvents.CANCELED);
      this.showToast('External player error');
    }
  }

  /**
   * 处理 MX Player 结果
   */
  private handleMXPlayerResult(resultCode: number, data: ESObject): void {
    const player = 'MX Player';

    if (resultCode === 0) { // RESULT_OK
      const endBy: string = String(data['end_by'] ?? '');

      if (endBy === 'playback_completion') {
        Logger.d(ExternalPlayer.TAG, 'Playback completed [player=%{public}s]', player);
        this.notifyEvent(ExternalPlayerEvents.TIME_UPDATE);
        this.notifyEvent(ExternalPlayerEvents.ENDED);
      } else if (endBy === 'user') {
        const position: number = (data['position'] as number | undefined) ?? -1;

        if (position > 0) {
          Logger.d(ExternalPlayer.TAG, 'Playback stopped [player=%{public}s, position=%{public}s]', player, String(position));
          this.notifyEvent(ExternalPlayerEvents.TIME_UPDATE, String(position));
          this.notifyEvent(ExternalPlayerEvents.ENDED);
        } else {
          Logger.d(ExternalPlayer.TAG, 'Playback canceled [player=%{public}s]', player);
          this.notifyEvent(ExternalPlayerEvents.CANCELED);
        }
      } else {
        Logger.d(ExternalPlayer.TAG, 'Invalid state [player=%{public}s]', player);
        this.notifyEvent(ExternalPlayerEvents.CANCELED);
      }
    } else {
      Logger.d(ExternalPlayer.TAG, 'Playback stopped by user [player=%{public}s]', player);
      this.notifyEvent(ExternalPlayerEvents.CANCELED);
    }
  }

  /**
   * 处理 VLC 播放器结果
   */
  private handleVLCPlayerResult(resultCode: number, data: ESObject): void {
    const player = 'VLC Player';

    if (resultCode === 0) { // RESULT_OK
      const extraPosition: number = (data['extra_position'] as number | undefined) ?? -1;
      const extraDuration: number = (data['extra_duration'] as number | undefined) ?? -1;

      if (extraDuration === extraPosition && extraPosition > 0) {
        Logger.d(ExternalPlayer.TAG, 'Playback completed [player=%{public}s]', player);
        this.notifyEvent(ExternalPlayerEvents.TIME_UPDATE);
        this.notifyEvent(ExternalPlayerEvents.ENDED);
      } else if (extraPosition > 0) {
        Logger.d(ExternalPlayer.TAG, 'Playback stopped [player=%{public}s, position=%{public}s]', player, String(extraPosition));
        this.notifyEvent(ExternalPlayerEvents.TIME_UPDATE, String(extraPosition));
        this.notifyEvent(ExternalPlayerEvents.ENDED);
      } else {
        Logger.d(ExternalPlayer.TAG, 'Playback canceled [player=%{public}s]', player);
        this.notifyEvent(ExternalPlayerEvents.CANCELED);
      }
    } else {
      Logger.d(ExternalPlayer.TAG, 'Playback failed [player=%{public}s]', player);
      this.notifyEvent(ExternalPlayerEvents.CANCELED);
    }
  }

  /**
   * 处理 mpvKt 播放器结果
   */
  private handleMPVKTPlayerResult(resultCode: number, data: ESObject): void {
    const player = 'mpvKt Player';

    if (resultCode === 0) { // RESULT_OK
      const position: number = (data['position'] as number | undefined) ?? -1;

      if (position > 0) {
        Logger.d(ExternalPlayer.TAG, 'Playback stopped [player=%{public}s, position=%{public}s]', player, String(position));
        this.notifyEvent(ExternalPlayerEvents.TIME_UPDATE, String(position));
        this.notifyEvent(ExternalPlayerEvents.ENDED);
      } else if (position === 0) {
        Logger.d(ExternalPlayer.TAG, 'Playback canceled [player=%{public}s]', player);
        this.notifyEvent(ExternalPlayerEvents.CANCELED);
      } else {
        Logger.d(ExternalPlayer.TAG, 'Playback completed [player=%{public}s]', player);
        this.notifyEvent(ExternalPlayerEvents.TIME_UPDATE);
        this.notifyEvent(ExternalPlayerEvents.ENDED);
      }
    } else {
      Logger.d(ExternalPlayer.TAG, 'Invalid state [player=%{public}s]', player);
      this.notifyEvent(ExternalPlayerEvents.CANCELED);
    }
  }

  /**
   * 处理未知播放器结果
   */
  private handleUnknownPlayerResult(resultCode: number, data: ESObject): void {
    Logger.d(ExternalPlayer.TAG, 'Unknown player result [resultCode=%{public}s]', String(resultCode));
    this.notifyEvent(ExternalPlayerEvents.CANCELED);
    this.showToast('External player not supported');
  }
}

/**
 * ExternalPlayer 代理对象
 */
export interface ExternalPlayerProxy {
  isEnabled: () => boolean;
  initPlayer: (args: string) => void;
}

/**
 * 创建 ExternalPlayer 代理
 */
export function createExternalPlayerProxy(externalPlayer: ExternalPlayer): ExternalPlayerProxy {
  return {
    isEnabled: (): boolean => externalPlayer.isEnabled(),
    initPlayer: (args: string): void => externalPlayer.initPlayer(args)
  };
}
