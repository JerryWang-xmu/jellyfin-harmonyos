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
 * Jellyfin HarmonyOS - 播放器适配器接口
 * 抽象播放器实现，支持 AVPlayer 和其他播放器
 */

/**
 * 播放器状态
 */
export enum PlayerState {
  IDLE = 0,
  INITIALIZED = 1,
  PREPARED = 2,
  PLAYING = 3,
  PAUSED = 4,
  STOPPED = 5,
  COMPLETED = 6,
  ERROR = 7
}

/**
 * 轨道信息
 */
export interface TrackInfo {
  index: number;
  type: 'video' | 'audio' | 'subtitle';
  language: string;
  label: string;
  isSelected: boolean;
  codec?: string;
  bitrate?: number;
  width?: number;
  height?: number;
}

/**
 * 播放器事件监听器基类 (可继承覆盖需要的方法)
 */
export class PlayerEventListener {
  onStateChanged(_state: PlayerState): void {}
  onPositionChanged(_positionMs: number): void {}
  onDurationChanged(_durationMs: number): void {}
  onTracksChanged(_tracks: TrackInfo[]): void {}
  onVideoSizeChanged(_width: number, _height: number): void {}
  onError(_error: Error): void {}
  onCompletion(): void {}
  onBufferingChanged(_isBuffering: boolean): void {}
}

/**
 * 媒体源信息
 */
export interface MediaSourceInfo {
  url: string;
  headers?: Record<string, string>;
  mimeType?: string;
  startPositionMs?: number;
}

/**
 * 播放器适配器接口
 */
export interface IPlayerAdapter {
  /**
   * 初始化播放器
   */
  initialize(): Promise<void>;

  /**
   * 释放播放器资源
   */
  release(): void;

  /**
   * 设置渲染 Surface
   */
  setSurface(surfaceId: string): Promise<void>;

  /**
   * 准备媒体源
   */
  prepare(source: MediaSourceInfo): Promise<void>;

  /**
   * 开始播放
   */
  play(): void;

  /**
   * 暂停播放
   */
  pause(): void;

  /**
   * 停止播放
   */
  stop(): void;

  /**
   * 跳转到指定位置
   */
  seekTo(positionMs: number): void;

  /**
   * 相对跳转
   */
  seekToOffset(offsetMs: number): void;

  // ============ 状态 ============

  /**
   * 获取当前播放状态
   */
  getState(): PlayerState;

  /**
   * 获取当前播放位置 (毫秒)
   */
  getCurrentPosition(): number;

  /**
   * 获取媒体时长 (毫秒)
   */
  getDuration(): number;

  /**
   * 是否正在播放
   */
  isPlaying(): boolean;

  // ============ 音量 ============

  /**
   * 设置音量 (0-100)
   */
  setVolume(percent: number): void;

  /**
   * 获取音量
   */
  getVolume(): number;

  // ============ 播放速度 ============

  /**
   * 设置播放速度
   */
  setPlaybackSpeed(speed: number): void;

  /**
   * 获取播放速度
   */
  getPlaybackSpeed(): number;

  // ============ 轨道选择 ============

  /**
   * 获取所有轨道
   */
  getTracks(): TrackInfo[];

  /**
   * 获取音频轨道
   */
  getAudioTracks(): TrackInfo[];

  /**
   * 获取字幕轨道
   */
  getSubtitleTracks(): TrackInfo[];

  /**
   * 选择音频轨道
   */
  selectAudioTrack(index: number): void;

  /**
   * 选择字幕轨道
   */
  selectSubtitleTrack(index: number): void;

  /**
   * 禁用字幕
   */
  disableSubtitles(): void;

  // ============ 事件监听 ============

  /**
   * 设置事件监听器
   */
  setListener(listener: PlayerEventListener): void;

  /**
   * 移除事件监听器
   */
  removeListener(): void;
}
