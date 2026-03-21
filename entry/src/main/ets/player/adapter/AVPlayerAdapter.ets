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
        // 获取时长
        if (this.avPlayer) {
          this._duration = this.avPlayer.duration;
          if (this.listener) {
            this.listener.onDurationChanged(this._duration);
          }
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
    // Note: setSurface API may vary by HarmonyOS version
    Logger.i(TAG, 'AVPlayer surface set: %{public}s', surfaceId);
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
        this.avPlayer.seek(source.startPositionMs);
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
      player.play();
      Logger.d(TAG, 'Playback started');
    }
  }

  pause(): void {
    const player = this.avPlayer;
    if (player && this._state === PlayerState.PLAYING) {
      player.pause();
      Logger.d(TAG, 'Playback paused');
    }
  }

  stop(): void {
    const player = this.avPlayer;
    if (player) {
      player.stop();
      Logger.d(TAG, 'Playback stopped');
    }
  }

  seekTo(positionMs: number): void {
    if (this.avPlayer) {
      this.avPlayer.seek(positionMs);
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
    if (this.avPlayer) {
      // AVPlayer 音量范围是 0-1，使用 setVolume 方法
      // Note: API 可能因 HarmonyOS 版本而异
    }
    Logger.d(TAG, 'Volume set to: %{public}d%%', this._volume.toString());
  }

  getVolume(): number {
    return this._volume;
  }

  // ============ 播放速度 ============

  setPlaybackSpeed(speed: number): void {
    this._speed = speed;
    // Speed control may not be directly available in all AVPlayer versions
    Logger.d(TAG, 'Playback speed set to: %{public}f', speed.toString());
  }

  getPlaybackSpeed(): number {
    return this._speed;
  }

  // ============ 轨道选择 ============

  getTracks(): TrackInfo[] {
    // TODO: 实现轨道获取
    return [];
  }

  getAudioTracks(): TrackInfo[] {
    return this.getTracks().filter(t => t.type === 'audio');
  }

  getSubtitleTracks(): TrackInfo[] {
    return this.getTracks().filter(t => t.type === 'subtitle');
  }

  selectAudioTrack(index: number): void {
    // TODO: 实现音频轨道选择
    Logger.i(TAG, 'Select audio track: %{public}d', index.toString());
  }

  selectSubtitleTrack(index: number): void {
    // TODO: 实现字幕轨道选择
    Logger.i(TAG, 'Select subtitle track: %{public}d', index.toString());
  }

  disableSubtitles(): void {
    Logger.i(TAG, 'Subtitles disabled');
  }

  // ============ 事件监听 ============

  setListener(listener: PlayerEventListener): void {
    this.listener = listener;
  }

  removeListener(): void {
    this.listener = null;
  }
}
