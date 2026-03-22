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
 * Jellyfin HarmonyOS - AVPlayer 适配器
 * 使用 HarmonyOS AVPlayer 实现播放器接口
 */

import media from '@ohos.multimedia.media';
import { Logger } from '../../common/utils/Logger';
import {
  IPlayerAdapter,
  PlayerState,
  TrackInfo,
  PlayerEventListener,
  MediaSourceInfo
} from './IPlayerAdapter';

const TAG: string = 'AVPlayerAdapter';

/**
 * AVPlayer 适配器实现
 */
export class AVPlayerAdapter implements IPlayerAdapter {
  private avPlayer: media.AVPlayer | null = null;
  private listener: PlayerEventListener | null = null;
  private surfaceId: string = '';
  private currentSource: MediaSourceInfo | null = null;

  private _state: PlayerState = PlayerState.IDLE;
  private _duration: number = 0;
  private _position: number = 0;
  private _volume: number = 100;
  private _speed: number = 1.0;
  private _selectedAudioIndex: number = -1;
  private _selectedSubtitleIndex: number = -1;

  constructor() {
    Logger.i(TAG, 'AVPlayerAdapter created');
  }

  // ============ 生命周期 ============

  async initialize(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();
      this.setupCallbacks();
      this._state = PlayerState.INITIALIZED;
      Logger.i(TAG, 'AVPlayer initialized');
    } catch (error) {
      Logger.e(TAG, 'Failed to initialize AVPlayer: %{public}s', JSON.stringify(error));
      const err = error as Error;
      throw new Error('Failed to initialize AVPlayer: ' + (err?.message ?? 'unknown error'));
    }
  }

  private setupCallbacks(): void {
    if (!this.avPlayer) return;

    // 状态变化回调
    this.avPlayer.on('stateChange', (state: string) => {
      Logger.d(TAG, 'AVPlayer state changed to: %{public}s', state);
      this.handleStateChange(state);
    });

    // 时间更新回调
    this.avPlayer.on('timeUpdate', (time: number) => {
      this._position = time;
      if (this.listener) {
        this.listener.onPositionChanged(time);
      }
    });

    // 错误回调
    this.avPlayer.on('error', (error) => {
      Logger.e(TAG, 'AVPlayer error: %{public}s', JSON.stringify(error));
      this._state = PlayerState.ERROR;
      if (this.listener) {
        this.listener.onError(new Error('AVPlayer error'));
      }
    });

    // 视频尺寸变化回调
    this.avPlayer.on('videoSizeChange', (width: number, height: number) => {
      Logger.d(TAG, 'Video size changed: %{public}s x %{public}s', String(width), String(height));
      if (this.listener) {
        this.listener.onVideoSizeChanged(width, height);
      }
    });
  }

  private handleStateChange(state: string): void {
    switch (state) {
      case 'idle':
        this._state = PlayerState.IDLE;
        break;
      case 'initialized':
        this._state = PlayerState.INITIALIZED;
        break;
      case 'prepared':
        this._state = PlayerState.PREPARED;
        // 获取时长（单位：毫秒）
        this._duration = this.avPlayer?.duration ?? 0;
        if (this.listener) {
          this.listener.onDurationChanged(this._duration);
        }
        break;
      case 'playing':
        this._state = PlayerState.PLAYING;
        break;
      case 'paused':
        this._state = PlayerState.PAUSED;
        break;
      case 'completed':
        this._state = PlayerState.COMPLETED;
        if (this.listener) {
          this.listener.onCompletion();
        }
        break;
      case 'stopped':
        this._state = PlayerState.STOPPED;
        break;
      case 'error':
        this._state = PlayerState.ERROR;
        break;
    }
    if (this.listener) {
      this.listener.onStateChanged(this._state);
    }
  }

  release(): void {
    try {
      this.avPlayer?.release();
      this.avPlayer = null;
      this._state = PlayerState.IDLE;
      this.currentSource = null;
      Logger.i(TAG, 'AVPlayer released');
    } catch (error) {
      Logger.e(TAG, 'Failed to release AVPlayer: %{public}s', JSON.stringify(error));
    }
  }

  // ============ Surface ============

  async setSurface(surfaceId: string): Promise<void> {
    this.surfaceId = surfaceId;
    if (this.avPlayer && surfaceId) {
      try {
        this.avPlayer.surfaceId = surfaceId;
        Logger.i(TAG, 'AVPlayer surface set: %{public}s', surfaceId);
      } catch (e) {
        // setSurfaceId API 可能因版本而异，忽略错误
        Logger.w(TAG, 'setSurfaceId not available, surfaceId stored: %{public}s', surfaceId);
      }
    }
  }

  // ============ 媒体加载 ============

  async prepare(source: MediaSourceInfo): Promise<void> {
    if (!this.avPlayer) {
      throw new Error('Player not initialized');
    }

    this.currentSource = source;
    Logger.i(TAG, 'Preparing media source: %{public}s', source.url);

    try {
      // 使用 url 直接准备播放
      this.avPlayer.url = source.url;

      // 准备播放
      await this.avPlayer.prepare();

      // 跳转到起始位置
      if (source.startPositionMs && source.startPositionMs > 0) {
        try {
          this.avPlayer.seek(source.startPositionMs, media.SeekMode.SEEK_PREV_SYNC);
        } catch (e) {
          this.avPlayer.seek(source.startPositionMs);
        }
      }

      Logger.i(TAG, 'Media source prepared successfully');
    } catch (error) {
      Logger.e(TAG, 'Failed to prepare media source: %{public}s', JSON.stringify(error));
      const err = error as Error;
      throw new Error('Failed to prepare media source: ' + (err?.message ?? 'unknown error'));
    }
  }

  // ============ 播放控制 ============

  play(): void {
    const player = this.avPlayer;
    if (player && (this._state === PlayerState.PREPARED || this._state === PlayerState.PAUSED)) {
      try { player.play(); } catch (e) { Logger.e(TAG, 'play() error: %{public}s', JSON.stringify(e)); }
      Logger.d(TAG, 'Playback started');
    }
  }

  pause(): void {
    const player = this.avPlayer;
    if (player && this._state === PlayerState.PLAYING) {
      try { player.pause(); } catch (e) { Logger.e(TAG, 'pause() error: %{public}s', JSON.stringify(e)); }
      Logger.d(TAG, 'Playback paused');
    }
  }

  stop(): void {
    const player = this.avPlayer;
    if (player) {
      try { player.stop(); } catch (e) { Logger.e(TAG, 'stop() error: %{public}s', JSON.stringify(e)); }
      Logger.d(TAG, 'Playback stopped');
    }
  }

  seekTo(positionMs: number): void {
    if (this.avPlayer) {
      try {
        // media.SeekMode.SEEK_PREV_SYNC 跳转到最近关键帧（毫秒单位）
        this.avPlayer.seek(positionMs, media.SeekMode.SEEK_PREV_SYNC);
      } catch (e) {
        this.avPlayer.seek(positionMs);
      }
      Logger.d(TAG, 'Seek to: %{public}d ms', positionMs.toString());
    }
  }

  seekToOffset(offsetMs: number): void {
    const newPosition = this._position + offsetMs;
    if (newPosition >= 0 && newPosition <= this._duration) {
      this.seekTo(newPosition);
    }
  }

  // ============ 状态获取 ============

  getState(): PlayerState {
    return this._state;
  }

  getCurrentPosition(): number {
    return this._position;
  }

  getDuration(): number {
    return this._duration;
  }

  isPlaying(): boolean {
    return this._state === PlayerState.PLAYING;
  }

  // ============ 音量控制 ============

  setVolume(percent: number): void {
    this._volume = Math.max(0, Math.min(100, percent));
    try {
      // AVPlayer 音量范围 0.0-1.0，percent 范围 0-100
      this.avPlayer?.setVolume(this._volume / 100);
    } catch (e) {
      // setVolume API 不可用时忽略
    }
    Logger.d(TAG, 'Volume set to: %{public}d%%', this._volume.toString());
  }

  getVolume(): number {
    return this._volume;
  }

  // ============ 播放速度 ============

  setPlaybackSpeed(speed: number): void {
    this._speed = speed;
    const speedMap: Record<number, media.PlaybackSpeed> = {
      0.75: media.PlaybackSpeed.SPEED_FORWARD_0_75_X,
      1.0:  media.PlaybackSpeed.SPEED_FORWARD_1_00_X,
      1.25: media.PlaybackSpeed.SPEED_FORWARD_1_25_X,
      1.5:  media.PlaybackSpeed.SPEED_FORWARD_1_50_X,
      2.0:  media.PlaybackSpeed.SPEED_FORWARD_2_00_X,
    };
    const mode = speedMap[speed] ?? media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
    try {
      this.avPlayer?.setSpeed(mode);
    } catch (e) {
      // setSpeed API 不可用时忽略
    }
    Logger.d(TAG, 'Playback speed set to: %{public}f', speed.toString());
  }

  getPlaybackSpeed(): number {
    return this._speed;
  }

  // ============ 轨道选择 ============

  getTracks(): TrackInfo[] {
    // TODO: 实现轨道获取（需要 AVPlayer trackChange 事件支持）
    return [];
  }

  getAudioTracks(): TrackInfo[] {
    return this.getTracks().filter(t => t.type === 'audio');
  }

  getSubtitleTracks(): TrackInfo[] {
    return this.getTracks().filter(t => t.type === 'subtitle');
  }

  selectAudioTrack(index: number): void {
    try {
      // HarmonyOS AVPlayer selectTrack API（若平台支持）
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (this.avPlayer as ESObject)?.selectTrack(index);
      this._selectedAudioIndex = index;
      Logger.i(TAG, 'Selected audio track: %{public}d', index.toString());
    } catch (e) {
      // TODO: 若 selectTrack 不可用，可尝试 setMediaMuted 或忽略
      Logger.w(TAG, 'selectTrack not available for audio track: %{public}d', index.toString());
    }
  }

  selectSubtitleTrack(index: number): void {
    try {
      // HarmonyOS AVPlayer selectTrack API（若平台支持）
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (this.avPlayer as ESObject)?.selectTrack(index);
      this._selectedSubtitleIndex = index;
      Logger.i(TAG, 'Selected subtitle track: %{public}d', index.toString());
    } catch (e) {
      // TODO: 若 selectTrack 不可用，可尝试 setMediaMuted 或忽略
      Logger.w(TAG, 'selectTrack not available for subtitle track: %{public}d', index.toString());
    }
  }

  disableSubtitles(): void {
    try {
      const idx = this._selectedSubtitleIndex;
      if (idx >= 0) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (this.avPlayer as ESObject)?.deselectTrack(idx);
      }
      this._selectedSubtitleIndex = -1;
      Logger.i(TAG, 'Subtitles disabled');
    } catch (e) {
      // TODO: 若 deselectTrack 不可用，可尝试 setMediaMuted 或忽略
      Logger.w(TAG, 'deselectTrack not available, subtitles disable skipped');
    }
  }

  // ============ 事件监听 ============

  setListener(listener: PlayerEventListener): void {
    this.listener = listener;
  }

  removeListener(): void {
    this.listener = null;
  }
}
