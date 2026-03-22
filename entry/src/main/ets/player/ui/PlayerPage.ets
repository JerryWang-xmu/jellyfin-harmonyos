/**
 * Jellyfin HarmonyOS - 原生播放器页面
 * Batch 4：完整实现 AVPlayer 原生播放
 */

import window from '@ohos.window';
import {
  AVPlayerAdapter
} from '../adapter/AVPlayerAdapter';
import {
  IPlayerAdapter,
  PlayerState,
  PlayerEventListener,
  TrackInfo
} from '../adapter/IPlayerAdapter';
import {
  JellyfinApiService,
  PlaybackInfoRequestBody,
  JellyfinMediaSourceInfo
} from '../../api/JellyfinApiService';
import { PlayOptions } from '../../core/event/ActivityEvent';
import { App, getContext } from '../../core/di/AppDependency';
import { AppLog } from '../../common/utils/Logger';

const TAG: string = 'PlayerPage';

// ===== 路由参数接口 =====
export interface PlayerPageParams {
  playOptions: string; // JSON 序列化的 PlayOptions
}

// ===== 设备档案接口 =====
interface DirectPlayProfile {
  Container: string;
  Type: string;
}

interface TranscodingProfile {
  Container: string;
  Type: string;
  VideoCodec: string;
  AudioCodec: string;
  Protocol: string;
}

interface DeviceProfile {
  DirectPlayProfiles: DirectPlayProfile[];
  TranscodingProfiles: TranscodingProfile[];
}

// ===== 扩展 PlayerEventListener：桥接 PlayerPage 的状态回调 =====
class PlayerPageListener extends PlayerEventListener {
  private onStateChangedCb: (state: PlayerState) => void;
  private onPositionChangedCb: (pos: number) => void;
  private onDurationChangedCb: (dur: number) => void;
  private onErrorCb: (error: Error) => void;
  private onVideoSizeCb: (w: number, h: number) => void;
  private onCompletionCb: () => void;
  private onBufferingChangedCb: (isBuffering: boolean) => void;

  constructor(
    onState: (state: PlayerState) => void,
    onPosition: (pos: number) => void,
    onDuration: (dur: number) => void,
    onError: (error: Error) => void,
    onVideoSize: (w: number, h: number) => void,
    onCompletion: () => void,
    onBufferingChanged: (isBuffering: boolean) => void
  ) {
    super();
    this.onStateChangedCb = onState;
    this.onPositionChangedCb = onPosition;
    this.onDurationChangedCb = onDuration;
    this.onErrorCb = onError;
    this.onVideoSizeCb = onVideoSize;
    this.onCompletionCb = onCompletion;
    this.onBufferingChangedCb = onBufferingChanged;
  }

  onStateChanged(state: PlayerState): void {
    this.onStateChangedCb(state);
  }

  onPositionChanged(pos: number): void {
    this.onPositionChangedCb(pos);
  }

  onDurationChanged(dur: number): void {
    this.onDurationChangedCb(dur);
  }

  onError(error: Error): void {
    this.onErrorCb(error);
  }

  onVideoSizeChanged(width: number, height: number): void {
    this.onVideoSizeCb(width, height);
  }

  onCompletion(): void {
    this.onCompletionCb();
  }

  onBufferingChanged(isBuffering: boolean): void {
    this.onBufferingChangedCb(isBuffering);
  }
}

@Component
export struct PlayerPage {
  // ===== Navigation 参数 =====
  playerParams: PlayerPageParams = { playOptions: '{}' };
  @Consume('navPathStack') navPathStack: NavPathStack;
  private playOptions: PlayOptions | null = null;
  private playOptionsJson: string = '{}';

  // ===== UI 状态 =====
  @State isPlaying: boolean = false;
  @State currentPositionMs: number = 0;
  @State durationMs: number = 0;
  @State isBuffering: boolean = false;
  @State showControls: boolean = true;
  @State mediaTitle: string = '';
  @State audioTracks: TrackInfo[] = [];
  @State subtitleTracks: TrackInfo[] = [];
  @State selectedAudioIndex: number = -1;
  @State selectedSubtitleIndex: number = -1;
  @State playbackSpeed: number = 1.0;
  @State errorMessage: string = '';
  @State isFullscreen: boolean = true;

  // ===== 内部状态 =====
  private player: IPlayerAdapter | null = null;
  private apiService: JellyfinApiService | null = null;
  private progressTimer: number = -1;
  private controlsTimer: number = -1;
  private currentPlaySessionId: string = '';
  private currentItemId: string = '';
  private currentPlayMethod: string = 'DirectPlay';
  private xComponentController: XComponentController = new XComponentController();
  private windowObj: window.Window | null = null;

  // ===== 生命周期 =====

  aboutToAppear() {
    this.playOptionsJson = this.playerParams.playOptions;
    try {
      this.playOptions = JSON.parse(this.playOptionsJson) as PlayOptions;
    } catch {
      this.playOptions = null;
    }
    this.setupFullscreen();
    this.initPlayback();
  }

  aboutToDisappear() {
    this.clearTimers();
    this.reportPlaybackStop(false);
    this.player?.release();
    this.player = null;
    this.restoreSystemBars();
  }

  // ===== 播放初始化 =====

  private async initPlayback(): Promise<void> {
    if (!this.playOptions || this.playOptions.ids.length === 0) {
      this.errorMessage = '无效的播放参数';
      return;
    }

    try {
      this.apiService = new JellyfinApiService(App.apiController.config);
    } catch (e) {
      this.errorMessage = '服务未就绪，请重新登录';
      AppLog.e(TAG, 'App.apiController not ready: %{public}s', JSON.stringify(e));
      return;
    }

    const startIdx = this.playOptions.startIndex ?? 0;
    const itemId = this.playOptions.ids[startIdx];
    this.currentItemId = itemId;

    try {
      // 1. 获取播放信息
      const playbackInfoBody: PlaybackInfoRequestBody = {
        AutoOpenLiveStream: true,
        StartTimeTicks: this.playOptions.startPosition,
        AudioStreamIndex: this.playOptions.audioStreamIndex,
        SubtitleStreamIndex: this.playOptions.subtitleStreamIndex,
        DeviceProfile: this.buildDeviceProfile(),
      };
      const playbackInfo = await this.apiService.getPlaybackInfo(itemId, playbackInfoBody);

      this.currentPlaySessionId = playbackInfo.PlaySessionId ?? '';
      const source = playbackInfo.MediaSources?.[0];
      if (!source) {
        this.errorMessage = '无法获取媒体源';
        return;
      }

      // 2. 构建流 URL
      const streamUrl = this.buildStreamUrl(source);
      this.currentPlayMethod = source.PlayMethod ?? 'DirectPlay';

      // 3. 获取标题（失败时静默忽略）
      try {
        const userId = App.currentUser?.userId ?? '';
        const item = await this.apiService.getItem(userId, itemId);
        this.mediaTitle = (item.Name ?? item.name) ?? '';
      } catch { /* ignore */ }

      // 4. 初始化播放器
      this.player = new AVPlayerAdapter();
      this.player.setListener(this.createListener());
      await this.player.initialize();

      // 5. 准备媒体源（prepare 内部会触发 stateChange → prepared，再调用 play）
      await this.player.prepare({
        url: streamUrl,
        headers: { 'Authorization': this.apiService.buildAuthHeader() },
        startPositionMs: this.playOptions.startPosition
          ? Math.floor(this.playOptions.startPosition / 10000)
          : 0,
      });

    } catch (err) {
      this.errorMessage = '播放初始化失败：' + JSON.stringify(err);
      AppLog.e(TAG, 'PlayerPage init error: %{public}s', JSON.stringify(err));
    }
  }

  private buildStreamUrl(source: JellyfinMediaSourceInfo): string {
    const base = App.apiController.config.baseUrl;
    if (source.TranscodingUrl) return `${base}${source.TranscodingUrl}`;
    if (source.DirectStreamUrl) return `${base}${source.DirectStreamUrl}`;
    // DirectPlay：使用 Items/{id}/File?api_key={token}
    const token = App.apiController.config.accessToken ?? '';
    return `${base}/Items/${this.currentItemId}/File?api_key=${token}`;
  }

  private buildDeviceProfile(): DeviceProfile {
    const directPlay0: DirectPlayProfile = { Container: 'mp4,mkv,ts,m4v', Type: 'Video' };
    const directPlay1: DirectPlayProfile = { Container: 'mp3,flac,aac,ogg', Type: 'Audio' };
    const transcode0: TranscodingProfile = {
      Container: 'ts',
      Type: 'Video',
      VideoCodec: 'h264',
      AudioCodec: 'aac',
      Protocol: 'hls'
    };
    const profile: DeviceProfile = {
      DirectPlayProfiles: [directPlay0, directPlay1],
      TranscodingProfiles: [transcode0]
    };
    return profile;
  }

  // ===== PlayerEventListener =====

  private createListener(): PlayerEventListener {
    return new PlayerPageListener(
      // onStateChanged
      (state: PlayerState): void => {
        if (state === PlayerState.PREPARED) {
          this.durationMs = this.player?.getDuration() ?? 0;
          this.audioTracks = this.player?.getAudioTracks() ?? [];
          this.subtitleTracks = this.player?.getSubtitleTracks() ?? [];
          // PREPARED → 自动开始播放
          this.player?.play();
        } else if (state === PlayerState.PLAYING) {
          this.isPlaying = true;
          this.isBuffering = false;
          this.durationMs = this.player?.getDuration() ?? this.durationMs;
          this.startProgressTimer();
          this.reportPlaybackStart();
        } else if (state === PlayerState.PAUSED) {
          this.isPlaying = false;
          this.stopProgressTimer();
        } else if (state === PlayerState.COMPLETED) {
          this.isPlaying = false;
          this.reportPlaybackStop(false);
          this.handleExit();
        } else if (state === PlayerState.ERROR) {
          this.errorMessage = '播放错误';
          this.isBuffering = false;
        }
      },
      // onPositionChanged
      (pos: number): void => {
        this.currentPositionMs = pos;
      },
      // onDurationChanged
      (dur: number): void => {
        if (dur > 0) this.durationMs = dur;
      },
      // onError
      (error: Error): void => {
        this.errorMessage = error.message ?? '未知错误';
        this.isBuffering = false;
        AppLog.e(TAG, 'Player error: %{public}s', error.message ?? '');
      },
      // onVideoSizeChanged
      (width: number, height: number): void => {
        AppLog.i(TAG, 'Video size: %{public}s x %{public}s', String(width), String(height));
      },
      // onCompletion
      (): void => {
        this.isPlaying = false;
        this.reportPlaybackStop(false);
        this.handleExit();
      },
      // onBufferingChanged
      (isBuffering: boolean): void => {
        this.isBuffering = isBuffering;
      }
    );
  }

  // ===== 进度上报 =====

  private startProgressTimer(): void {
    if (this.progressTimer !== -1) return;
    this.progressTimer = setInterval(async () => {
      if (!this.player?.isPlaying()) return;
      try {
        await this.apiService?.reportPlaybackProgress({
          ItemId: this.currentItemId,
          PositionTicks: this.currentPositionMs * 10000,
          IsPaused: false,
          IsMuted: false,
          VolumeLevel: this.player?.getVolume() ?? 100,
          PlaySessionId: this.currentPlaySessionId,
          PlayMethod: this.currentPlayMethod,
        });
      } catch { /* ignore */ }
    }, 10000);
  }

  private stopProgressTimer(): void {
    if (this.progressTimer !== -1) {
      clearInterval(this.progressTimer);
      this.progressTimer = -1;
    }
  }

  private async reportPlaybackStart(): Promise<void> {
    try {
      await this.apiService?.reportPlaybackStart({
        ItemId: this.currentItemId,
        PositionTicks: 0,
        IsPaused: false,
        IsMuted: false,
        VolumeLevel: 100,
        PlaySessionId: this.currentPlaySessionId,
        PlayMethod: this.currentPlayMethod,
      });
    } catch { /* ignore */ }
  }

  private async reportPlaybackStop(failed: boolean): Promise<void> {
    this.stopProgressTimer();
    if (!this.currentItemId) return;
    try {
      await this.apiService?.reportPlaybackStopped({
        ItemId: this.currentItemId,
        PositionTicks: this.currentPositionMs * 10000,
        PlaySessionId: this.currentPlaySessionId,
        Failed: failed,
      });
    } catch { /* ignore */ }
  }

  // ===== 全屏管理 =====

  private async setupFullscreen(): Promise<void> {
    try {
      this.windowObj = await window.getLastWindow(getContext());
      await this.windowObj.setWindowSystemBarEnable([]);
    } catch { /* ignore */ }
  }

  private async restoreSystemBars(): Promise<void> {
    try {
      await this.windowObj?.setWindowSystemBarEnable(['status', 'navigation']);
    } catch { /* ignore */ }
  }

  // ===== 定时器管理 =====

  private clearTimers(): void {
    this.stopProgressTimer();
    if (this.controlsTimer !== -1) {
      clearTimeout(this.controlsTimer);
      this.controlsTimer = -1;
    }
  }

  private handleExit(): void {
    // 防重入：避免 aboutToDisappear 再次上报
    const savedItemId = this.currentItemId;
    this.currentItemId = '';
    if (savedItemId) {
      this.currentItemId = savedItemId;
      this.reportPlaybackStop(false);
      this.currentItemId = '';
    }
    this.navPathStack.pop();
  }

  private showControlsTemporarily(): void {
    this.showControls = true;
    if (this.controlsTimer !== -1) clearTimeout(this.controlsTimer);
    this.controlsTimer = setTimeout(() => {
      this.showControls = false;
      this.controlsTimer = -1;
    }, 3000);
  }

  // ===== @Builder 组件 =====

  @Builder
  VideoSurface() {
    XComponent({
      id: 'player_video_surface',
      type: XComponentType.SURFACE,
      controller: this.xComponentController
    })
      .onLoad(async () => {
        try {
          const surfaceId = this.xComponentController.getXComponentSurfaceId();
          await this.player?.setSurface(surfaceId);
        } catch (e) {
          AppLog.e(TAG, 'setSurface error: %{public}s', JSON.stringify(e));
        }
      })
      .width('100%')
      .height('100%')
  }

  @Builder
  ProgressBarArea() {
    Column() {
      // 时间显示
      Row() {
        Text(this.formatTime(this.currentPositionMs))
          .fontSize(12)
          .fontColor('#ffffff')
        Blank()
        Text(this.formatTime(this.durationMs))
          .fontSize(12)
          .fontColor('#b0b0b0')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // 进度条
      Slider({
        value: this.durationMs > 0
          ? (this.currentPositionMs / this.durationMs) * 100
          : 0,
        min: 0,
        max: 100,
        step: 0.1,
        style: SliderStyle.OutSet
      })
        .trackColor('#444444')
        .selectedColor('#00a4dc')
        .blockColor('#00a4dc')
        .width('100%')
        .onChange((value: number) => {
          if (this.durationMs > 0) {
            const posMs = Math.floor((value / 100) * this.durationMs);
            this.player?.seekTo(posMs);
          }
        })
    }
  }

  @Builder
  ControlBar() {
    Row({ space: 32 }) {
      // 后退 10 秒
      Image($r('sys.media.ohos_ic_back'))
        .width(36)
        .height(36)
        .fillColor('#ffffff')
        .onClick(() => {
          this.player?.seekTo(Math.max(0, this.currentPositionMs - 10000));
        })

      // 播放/暂停
      Image(this.isPlaying
        ? $r('sys.media.ohos_ic_public_pause')
        : $r('sys.media.ohos_ic_public_play'))
        .width(48)
        .height(48)
        .fillColor('#ffffff')
        .onClick(() => {
          if (this.isPlaying) {
            this.player?.pause();
          } else {
            this.player?.play();
          }
        })

      // 前进 10 秒
      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(36)
        .height(36)
        .fillColor('#ffffff')
        .onClick(() => {
          this.player?.seekTo(this.currentPositionMs + 10000);
        })
    }
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  TopBar() {
    Row() {
      // 返回按钮
      Image($r('sys.media.ohos_ic_back'))
        .width(24)
        .height(24)
        .fillColor('#ffffff')
        .onClick(() => this.handleExit())

      // 标题
      Text(this.mediaTitle)
        .fontSize(16)
        .fontColor('#ffffff')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 16 })
        .layoutWeight(1)

      // 速度选择（点击循环切换）
      Text(`${this.playbackSpeed}x`)
        .fontSize(14)
        .fontColor('#ffffff')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#2d2d2d')
        .borderRadius(4)
        .onClick(() => {
          const speeds: number[] = [0.75, 1.0, 1.25, 1.5, 2.0];
          const idx = speeds.indexOf(this.playbackSpeed);
          this.playbackSpeed = speeds[(idx + 1) % speeds.length];
          this.player?.setPlaybackSpeed(this.playbackSpeed);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#CC000000', 0], ['#00000000', 1]]
    })
  }

  @Builder
  BottomControls() {
    Column() {
      this.ProgressBarArea()
      this.ControlBar()
    }
    .width('100%')
    .padding({ bottom: 16 })
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [['#CC000000', 0], ['#00000000', 1]]
    })
  }

  // ===== 主 build =====

  build() {
    NavDestination() {
      Stack() {
        // 黑色背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#000000')

        // 视频画面
        this.VideoSurface()

        // 透明点击层：显示/隐藏控制栏
        Column()
          .width('100%')
          .height('100%')
          .onClick(() => this.showControlsTemporarily())

        // 缓冲指示器
        if (this.isBuffering) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color('#00a4dc')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }

        // 错误提示
        if (this.errorMessage) {
          Column({ space: 16 }) {
            Text('播放错误')
              .fontSize(18)
              .fontColor('#ffffff')
              .fontWeight(FontWeight.Bold)
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor('#b0b0b0')
              .textAlign(TextAlign.Center)
            Button('返回')
              .backgroundColor('#2d2d2d')
              .onClick(() => this.handleExit())
          }
          .width('100%')
          .height('100%')
          .padding(32)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#CC000000')
        }

        // 控制覆盖层
        if (this.showControls) {
          Column() {
            this.TopBar()
            Blank()
            this.BottomControls()
          }
          .width('100%')
          .height('100%')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
      .gesture(
        TapGesture({ count: 1 })
          .onAction(() => this.showControlsTemporarily())
      )
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.handleExit();
      return true;
    })
  }

  // ===== 工具方法 =====

  private formatTime(ms: number): string {
    if (ms <= 0) return '00:00';
    const totalSeconds = Math.floor(ms / 1000);
    const h = Math.floor(totalSeconds / 3600);
    const m = Math.floor((totalSeconds % 3600) / 60);
    const s = totalSeconds % 60;
    const mm = m.toString().padStart(2, '0');
    const ss = s.toString().padStart(2, '0');
    if (h > 0) return `${h}:${mm}:${ss}`;
    return `${mm}:${ss}`;
  }
}

export default PlayerPage;
