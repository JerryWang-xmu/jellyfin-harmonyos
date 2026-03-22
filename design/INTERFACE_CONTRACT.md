# Jellyfin HarmonyOS 接口契约

> Pioneer 开发规范 v1.0
> 日期：2026-03-22
> 本文档是 Pioneer 开发的唯一参考，不需要阅读 Android 源码

---

## a) 页面路由契约

| 页面路径 | 文件 | 入参（router params） | 导航方式 |
|---------|------|----------------------|----------|
| `pages/MainPage` | MainPage.ets | 无 | windowStage.loadContent（入口） |
| `pages/setup/ConnectPage` | setup/ConnectPage.ets | `{ showError?: boolean }` | router.pushUrl |
| `pages/webapp/WebViewPage` | webapp/WebViewPage.ets | `{ serverUrl: string, serverId: number }` | router.replaceUrl |
| `pages/player/PlayerPage` | player/ui/PlayerPage.ets | `{ playOptions: string }` (JSON) | router.pushUrl |
| `pages/settings/SettingsPage` | settings/SettingsPage.ets | 无 | router.pushUrl |
| `pages/downloads/DownloadsPage` | downloads/DownloadsPage.ets | 无 | router.pushUrl |

### 导航规则

- `ConnectPage` → 连接成功：`router.replaceUrl({ url: 'pages/webapp/WebViewPage', params: { serverUrl, serverId } })`
- `WebViewPage` → 收到 `LAUNCH_NATIVE_PLAYER`：`router.pushUrl({ url: 'pages/player/PlayerPage', params: { playOptions: JSON.stringify(opts) } })`
- `PlayerPage` → 播放结束/返回：`router.back()`
- 收到 `SELECT_SERVER`：`router.replaceUrl({ url: 'pages/setup/ConnectPage' })`
- 收到 `OPEN_SETTINGS`：`router.pushUrl({ url: 'pages/settings/SettingsPage' })`
- 收到 `OPEN_DOWNLOADS`：`router.pushUrl({ url: 'pages/downloads/DownloadsPage' })`

**注意**：需在 `entry/src/main/resources/base/profile/main_pages.json` 中注册所有页面路径。

---

## b) 数据模型接口

```typescript
// ===== 服务器实体 =====
export interface ServerEntity {
  id: number;                    // 主键，自增
  hostname: string;              // 服务器 URL，如 http://192.168.1.100:8096
  lastUsedTimestamp: number;     // Unix 时间戳（毫秒）
}

// ===== 用户实体 =====
export interface UserEntity {
  id: number;
  serverId: number;
  userId: string;                // Jellyfin 服务端用户 UUID（字符串）
  accessToken: string | null;
  lastLoginTimestamp: number;
}

// ===== 服务器+用户组合 =====
export interface ServerUser {
  server: ServerEntity;
  user: UserEntity;
}

// ===== 下载实体 =====
export interface DownloadEntity {
  id?: number;
  itemId: string;
  mediaSource: string;           // JSON 序列化的媒体源
  fileName: string;
  filePath: string;
  progress: number;              // 0-100
  status: DownloadStatus;
}

export enum DownloadStatus {
  PENDING = 'pending',
  DOWNLOADING = 'downloading',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

// ===== PlayOptions（播放请求，从 JS 传入）=====
export interface PlayOptions {
  ids: string[];
  mediaSourceId?: string;
  startIndex: number;
  startPosition?: number;        // ticks（1 tick = 100ns）
  audioStreamIndex?: number;
  subtitleStreamIndex?: number;
  playFromDownloads?: boolean;
}

// ===== 媒体流信息 =====
export interface MediaStreamInfo {
  index: number;
  type: 'Video' | 'Audio' | 'Subtitle';
  codec?: string;
  language?: string;
  displayTitle?: string;
  isDefault?: boolean;
  isForced?: boolean;
  isExternal?: boolean;
  deliveryUrl?: string;
}

// ===== Jellyfin 媒体源 =====
export interface JellyfinMediaSourceInfo {
  id: string;
  name?: string;
  runTimeTicks?: number;
  playMethod?: 'DirectPlay' | 'DirectStream' | 'Transcode';
  playSessionId?: string;
  liveStreamId?: string;
  mediaStreams?: MediaStreamInfo[];
  defaultAudioStreamIndex?: number;
  defaultSubtitleStreamIndex?: number;
  transcodingUrl?: string;
  directStreamUrl?: string;
  supportsTranscoding?: boolean;
  supportsDirectPlay?: boolean;
}

// ===== 媒体项（BaseItemDto 简化）=====
export interface MediaItem {
  id: string;
  name?: string;
  type?: 'Movie' | 'Episode' | 'Series' | 'MusicAlbum' | 'Audio' | 'TvChannel';
  seriesName?: string;
  indexNumber?: number;
  parentIndexNumber?: number;
  productionYear?: number;
  overview?: string;
  officialRating?: string;
  communityRating?: number;
  criticRating?: number;
  runTimeTicks?: number;
  imageTags?: Record<string, string>;
  backdropImageTags?: string[];
  chapters?: ChapterInfo[];
  mediaSources?: JellyfinMediaSourceInfo[];
  userData?: UserItemData;
}

export interface ChapterInfo {
  startPositionTicks: number;
  name?: string;
  imagePath?: string;
}

export interface UserItemData {
  isFavorite: boolean;
  playbackPositionTicks: number;
  played: boolean;
  unplayedItemCount?: number;
  playedPercentage?: number;
}

export interface DeviceInformation {
  deviceId: string;
  deviceName: string;
  appName: string;
  appVersion: string;
}

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

export interface MediaSegment {
  id: string;
  itemId: string;
  type: 'Intro' | 'Outro' | 'Preview' | 'Recap' | 'Commercial';
  startTicks: number;
  endTicks: number;
}
```

---

## c) API 服务接口

```typescript
// ===== ApiClientConfig =====
export interface ApiClientConfig {
  baseUrl: string;
  accessToken?: string;
  deviceId: string;
  deviceName: string;
  appName: string;
  appVersion: string;
}

// Authorization Header 格式：
// MediaBrowser Client="{appName}", Device="{deviceName}", DeviceId="{deviceId}", Version="{appVersion}", Token="{token}"

// ===== JellyfinApiService（需从零实现）=====
export class JellyfinApiService {
  // --- 服务器发现 ---
  async getPublicSystemInfo(): Promise<PublicSystemInfo>;

  // --- 认证 ---
  async authenticateByName(username: string, password: string): Promise<AuthenticationResult>;
  async quickConnectInitiate(): Promise<QuickConnectResult>;
  async quickConnectConnect(secret: string): Promise<QuickConnectResult>;
  async authenticateWithQuickConnect(secret: string): Promise<AuthenticationResult>;
  async logout(): Promise<void>;

  // --- 用户 ---
  async getCurrentUser(): Promise<UserDto>;
  async getUserViews(userId: string): Promise<ItemsResult<MediaItem>>;
  async getItems(userId: string, params: GetItemsParams): Promise<ItemsResult<MediaItem>>;
  async getItem(userId: string, itemId: string): Promise<MediaItem>;
  async getResumeItems(userId: string, params?: object): Promise<ItemsResult<MediaItem>>;
  async getNextUp(userId: string, params?: object): Promise<ItemsResult<MediaItem>>;

  // --- 播放信息 ---
  async getPlaybackInfo(itemId: string, body: PlaybackInfoRequestBody): Promise<PlaybackInfoResponse>;
  async reportPlaybackStart(info: PlaybackProgressReport): Promise<void>;
  async reportPlaybackProgress(info: PlaybackProgressReport): Promise<void>;
  async reportPlaybackStopped(info: PlaybackStopReport): Promise<void>;
  async markItemPlayed(userId: string, itemId: string): Promise<UserItemData>;
  async stopActiveEncoding(deviceId: string, playSessionId: string): Promise<void>;

  // --- 收藏 ---
  async setFavorite(userId: string, itemId: string, favorite: boolean): Promise<UserItemData>;

  // --- 图片（纯 URL 拼接，无 HTTP 请求）---
  buildImageUrl(itemId: string, imageType: 'Primary' | 'Thumb' | 'Backdrop', tag: string, maxWidth?: number): string;
  // 格式：{baseUrl}/Items/{itemId}/Images/{imageType}?tag={tag}&maxWidth={w}&quality=90

  // --- 媒体片段 ---
  async getMediaSegments(itemId: string): Promise<MediaSegment[]>;

  // --- 辅助方法（公开，供 PlayerPage 使用）---
  buildAuthHeader(withToken?: boolean): string;
}

// ===== 关联类型 =====
export interface PublicSystemInfo {
  ServerName: string;
  Version: string;
  Id?: string;
}

export interface AuthenticationResult {
  User: UserDto;
  AccessToken: string;
  ServerId: string;
}

export interface UserDto {
  Id: string;
  Name: string;
  ServerId: string;
  HasPassword: boolean;
}

export interface QuickConnectResult {
  Secret: string;
  Code: string;
  Authenticated: boolean;
}

export interface ItemsResult<T> {
  Items: T[];
  TotalRecordCount: number;
  StartIndex: number;
}

export interface GetItemsParams {
  parentId?: string;
  includeItemTypes?: string;
  sortBy?: string;
  sortOrder?: 'Ascending' | 'Descending';
  startIndex?: number;
  limit?: number;
  recursive?: boolean;
  fields?: string;
}

export interface PlaybackInfoRequestBody {
  userId?: string;
  mediaSourceId?: string;
  deviceProfile?: object;
  maxStreamingBitrate?: number;
  startTimeTicks?: number;
  audioStreamIndex?: number;
  subtitleStreamIndex?: number;
  autoOpenLiveStream?: boolean;
}

export interface PlaybackInfoResponse {
  MediaSources: JellyfinMediaSourceInfo[];
  PlaySessionId?: string;
}

export interface PlaybackProgressReport {
  itemId: string;
  positionTicks: number;
  isPaused: boolean;
  isMuted: boolean;
  volumeLevel: number;
  playSessionId?: string;
  liveStreamId?: string;
  audioStreamIndex?: number;
  subtitleStreamIndex?: number;
  playMethod?: 'DirectPlay' | 'DirectStream' | 'Transcode';
}

export interface PlaybackStopReport {
  itemId: string;
  positionTicks: number;
  playSessionId?: string;
  failed: boolean;
}

// ===== 认证流程 =====
// 1. GET /System/Info/Public → 验证服务器
// 2. POST /Users/AuthenticateByName { Username, Pw } → 获取 AccessToken
// 3. 存储：ServerDao.insertByHostname(url) → UserDao.upsert(serverId, userId, token)
// 4. 更新 ApiClientConfig.accessToken = token
// 5. 后续请求 Header：Authorization: MediaBrowser Client="...", Token="..."
```

---

## d) 事件总线契约

```typescript
// ===== ActivityEventType 完整枚举 =====
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
  UPDATE_VOLUME = 'UpdateVolume',
  PLAYBACK_START = 'PlaybackStart',
  PLAYBACK_STOP = 'PlaybackStop',
  PLAYBACK_PROGRESS = 'PlaybackProgress',
  DOWNLOAD_COMPLETE = 'DownloadComplete',
  DOWNLOAD_PROGRESS = 'DownloadProgress',
}

// ===== Payload 类型 =====
export interface ChangeFullscreenPayload { isFullscreen: boolean; }
export interface OpenUrlPayload { uri: string; }
export interface DownloadFilePayload { uri: string; title: string; filename: string; }
export interface RemoveDownloadPayload { downloadId: string; downloadPath: string; force: boolean; }
export interface UpdateVolumePayload { volume: number; muted: boolean; }
export interface PlaybackStatePayload { itemId: string; positionMs: number; durationMs: number; isPlaying: boolean; }

// ===== 使用示例 =====
// 订阅（在 aboutToAppear 中）：
const unsubscribeToken = App.eventHandler.subscribe(
  ActivityEventType.LAUNCH_NATIVE_PLAYER,
  (event) => {
    const opts = JSON.parse(event.payload as string) as PlayOptions;
    router.pushUrl({ url: 'pages/player/PlayerPage', params: { playOptions: JSON.stringify(opts) } });
  }
);
// 取消（在 aboutToDisappear 中）：unsubscribeToken();
// 发布：App.eventHandler.emit(ActivityEvents.launchNativePlayer(playOptions));
```

---

## e) Bridge 接口契约

### JS → ArkTS（registerJavaScriptProxy 代理）

```typescript
// ===== NativeInterface（注册名："NativeInterface"）=====
interface NativeInterfaceProxy {
  getDeviceInformation(): string | null;    // 返回 JSON: DeviceInformation
  enableFullscreen(): boolean;
  disableFullscreen(): boolean;
  openUrl(uri: string): boolean;
  updateMediaSession(args: string): boolean; // JSON: MediaSessionInfo
  hideMediaSession(): boolean;
  updateVolumeLevel(value: number): void;
  downloadFiles(args: string): boolean;      // JSON 数组: DownloadInfo[]
  openDownloadManager(): void;
  openClientSettings(): void;
  openDownloads(): void;
  openServerSelection(): void;
  exitApp(): void;
  execCast(action: string, args: string): void;
}

// ===== NativePlayer（注册名："NativePlayer"）=====
interface NativePlayerProxy {
  isEnabled(): boolean;
  loadPlayer(args: string): void;    // JSON: PlayOptions
  pausePlayer(): void;
  resumePlayer(): void;
  stopPlayer(): void;
  destroyPlayer(): void;
  seekTicks(ticks: number): void;    // 1 tick = 100ns
  seekMs(ms: number): void;
  setVolume(volume: number): void;   // 0-100
}

// ===== ExternalPlayer（注册名："ExternalPlayer"）=====
interface ExternalPlayerProxy {
  isEnabled(): boolean;
  initPlayer(itemId: string, mediaUrl: string, mediaTitle: string): void;
}

// ===== MediaSegments（注册名："MediaSegments"）=====
interface MediaSegmentsProxy {
  setSegmentTypeAction(segmentType: string, action: string): void;
  getSupportedSegmentTypes(): string;  // 返回 JSON 数组
}
```

### ArkTS → JS（BridgeChannel.runJavaScript）

```typescript
class BridgeChannel {
  async runJavaScript(script: string): Promise<string>;

  // 播放管理器操作
  // action: 'unpause'|'pause'|'previousTrack'|'nextTrack'|'rewind'|'fastForward'|'stop'|'volumeUp'|'volumeDown'
  async callPlaybackManagerAction(action: string): Promise<void>;

  async setVolume(volume: number): Promise<void>;
  async seekTo(posMs: number): Promise<void>;
  async goBack(): Promise<void>;

  // 外部播放器事件
  async notifyExternalPlayerEvent(event: 'ENDED' | 'TIME_UPDATE' | 'CANCELED', parameters?: string): Promise<void>;

  // Cast 回调
  async castCallback(action: string, keep: boolean, err: string | null, result: string | null): Promise<void>;
}
```

### Bridge 注册时机（关键）

```
WebViewPage.Web 组件
  .onControllerAttached(() => {
    // 必须在此处初始化，否则 registerJavaScriptProxy 无效
    this.bridgeManager = new BridgeManager(controller, context, App.eventHandler, App.preferences);
    this.bridgeManager.initialize();
    // 注册后需要 controller.refresh() 触发代理生效
    controller.refresh();
  })
  .onPageBegin(() => { /* 重新加载时可能需要重新注册 */ })
```

---

## f) Player 接口契约

```typescript
// ===== IPlayerAdapter =====
export interface IPlayerAdapter {
  initialize(): Promise<void>;
  release(): void;
  setSurface(surfaceId: string): Promise<void>;
  prepare(source: MediaSourceInfo): Promise<void>;
  play(): void;
  pause(): void;
  stop(): void;
  seekTo(positionMs: number): void;
  getState(): PlayerState;
  getCurrentPosition(): number;    // 毫秒
  getDuration(): number;           // 毫秒
  isPlaying(): boolean;
  setVolume(percent: number): void; // 0-100
  getVolume(): number;
  setPlaybackSpeed(speed: number): void;
  getPlaybackSpeed(): number;
  getAudioTracks(): TrackInfo[];
  getSubtitleTracks(): TrackInfo[];
  selectAudioTrack(index: number): void;
  selectSubtitleTrack(index: number): void;
  disableSubtitles(): void;
  setListener(listener: PlayerEventListener): void;
  removeListener(): void;
}

export interface MediaSourceInfo {
  url: string;
  headers?: Record<string, string>;
  mimeType?: string;
  startPositionMs?: number;
}

export enum PlayerState {
  IDLE = 0, INITIALIZED = 1, PREPARED = 2,
  PLAYING = 3, PAUSED = 4, STOPPED = 5, COMPLETED = 6, ERROR = 7
}

export interface TrackInfo {
  index: number;
  language?: string;
  displayTitle?: string;
  isDefault?: boolean;
}

export interface PlayerEventListener {
  onStateChanged(state: PlayerState): void;
  onProgressUpdate(positionMs: number, durationMs: number): void;
  onBufferingUpdate(percent: number): void;
  onError(error: string): void;
  onVideoSizeChanged(width: number, height: number): void;
  onPlaybackCompleted(): void;
}

// ===== PlayerPage @State 变量清单 =====
// @State isPlaying: boolean = false
// @State currentPositionMs: number = 0
// @State durationMs: number = 0
// @State isBuffering: boolean = false
// @State showControls: boolean = true
// @State mediaTitle: string = ''
// @State audioTracks: TrackInfo[] = []
// @State subtitleTracks: TrackInfo[] = []
// @State selectedAudioIndex: number = -1
// @State selectedSubtitleIndex: number = -1
// @State playbackSpeed: number = 1.0
// @State errorMessage: string = ''
// @State currentMediaSegment: MediaSegment | null = null
// @State isFullscreen: boolean = true
```

---

## g) Database 接口契约

### Schema SQL

```sql
-- Server 表
CREATE TABLE IF NOT EXISTS Server (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  hostname            TEXT NOT NULL,
  last_used_timestamp INTEGER NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS index_Server_hostname ON Server (hostname);

-- User 表
CREATE TABLE IF NOT EXISTS User (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  server_id             INTEGER NOT NULL,
  user_id               TEXT NOT NULL,
  access_token          TEXT,
  last_login_timestamp  INTEGER NOT NULL,
  FOREIGN KEY (server_id) REFERENCES Server(id)
);
CREATE UNIQUE INDEX IF NOT EXISTS index_User_server_id_user_id ON User (server_id, user_id);

-- Download 表
CREATE TABLE IF NOT EXISTS Download (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id      TEXT NOT NULL UNIQUE,
  media_source TEXT NOT NULL,
  file_name    TEXT NOT NULL DEFAULT '',
  file_path    TEXT NOT NULL DEFAULT '',
  progress     INTEGER NOT NULL DEFAULT 0,
  status       TEXT NOT NULL DEFAULT 'pending'
);
```

### DAO 方法签名

```typescript
// ===== ServerDao =====
class ServerDao {
  async insert(entity: { hostname: string; lastUsedTimestamp: number }): Promise<number>;
  async insertByHostname(hostname: string): Promise<number>;
  async getServer(id: number): Promise<ServerEntity | null>;
  async getAllServers(): Promise<ServerEntity[]>;
  async getServerByHostname(hostname: string): Promise<ServerEntity | null>;
  async updateLastUsed(id: number): Promise<number>;
  async delete(id: number): Promise<number>;
}

// ===== UserDao =====
class UserDao {
  async upsert(serverId: number, userId: string, accessToken: string | null): Promise<number>;
  async getServerUser(serverId: number, userId: string): Promise<ServerUser | null>;
  async getByUserId(serverId: number, userId: string): Promise<UserEntity | null>;
  async getAllForServer(serverId: number): Promise<UserEntity[]>;
  async update(id: number, accessToken: string | null): Promise<number>;
  async logout(id: number): Promise<number>;
  async delete(id: number): Promise<number>;
}

// ===== DownloadDao =====
class DownloadDao {
  async insert(entity: Omit<DownloadEntity, 'id'>): Promise<number>;
  async queryAll(): Promise<DownloadEntity[]>;
  async queryByStatus(status: DownloadStatus): Promise<DownloadEntity[]>;
  async queryByItemId(itemId: string): Promise<DownloadEntity | null>;
  async updateProgress(itemId: string, progress: number, status: DownloadStatus): Promise<void>;
  async delete(itemId: string): Promise<boolean>;
}
```

---

## h) UI 组件接口

### MainPage

```typescript
@Entry
@Component
struct MainPage {
  @State serverState: ServerState = ServerState.Pending;
  // 事件订阅：SELECT_SERVER, LAUNCH_NATIVE_PLAYER, OPEN_SETTINGS, OPEN_DOWNLOADS, EXIT_APP, CHANGE_FULLSCREEN
  // ServerState: 'Pending' | 'Unset' | 'Available'
}
```

### ConnectPage

```typescript
@Entry
@Component
struct ConnectPage {
  @State serverUrl: string = '';
  @State isConnecting: boolean = false;
  @State errorMessage: string = '';
  @State recentServers: ServerEntity[] = [];

  @Builder ConnectButton() { ... }
  @Builder RecentServerItem(server: ServerEntity) { ... }
  // 连接成功 → router.replaceUrl('pages/webapp/WebViewPage', { serverUrl, serverId })
}
```

### WebViewPage

```typescript
@Entry
@Component
struct WebViewPage {
  @State serverUrl: string = '';
  @State serverId: number = 0;
  @State isLoading: boolean = true;
  @State loadError: boolean = false;

  controller: webview.WebviewController = new webview.WebviewController();
  private bridgeManager: BridgeManager | null = null;
  // onControllerAttached → 初始化 BridgeManager
  // Web({ src: serverUrl, controller }) + javaScriptAccess + domStorageAccess + fileAccess + mixedMode
}
```

### PlayerPage

```typescript
@Entry
@Component
struct PlayerPage {
  // 路由参数（JSON 字符串）
  private playOptionsJson: string = (router.getParams() as { playOptions: string }).playOptions;
  private playOptions: PlayOptions = JSON.parse(this.playOptionsJson);

  @State isPlaying: boolean = false;
  @State currentPositionMs: number = 0;
  @State durationMs: number = 0;
  @State isBuffering: boolean = false;
  @State showControls: boolean = true;
  @State mediaTitle: string = '';
  @State audioTracks: TrackInfo[] = [];
  @State subtitleTracks: TrackInfo[] = [];
  @State playbackSpeed: number = 1.0;
  @State errorMessage: string = '';
  @State currentMediaSegment: MediaSegment | null = null;

  private player: IPlayerAdapter | null = null;
  private progressTimer: number = -1;
  private controlsTimer: number = -1;
  private currentPlaySessionId: string = '';
  private currentItemId: string = '';

  @Builder ControlBar() { ... }
  @Builder ProgressBar() { ... }
  @Builder TrackSelector() { ... }
  @Builder SkipSegmentButton() { ... }
  @Builder VideoSurface() { ... }
}
```

### SettingsPage

```typescript
@Entry
@Component
struct SettingsPage {
  @State videoPlayerType: string = 'web';  // 'web' | 'native'
  @State exoPlayerAllowSwipeGestures: boolean = true;
  @State appVersion: string = Constants.APP_INFO_VERSION;
  @State serverName: string = '';
  @State userName: string = '';

  @Builder SectionHeader(title: string) { ... }
  @Builder ToggleItem(title: string, value: boolean, onChange: (v: boolean) => void) { ... }
  @Builder NavigationItem(title: string, subtitle: string, onClick: () => void) { ... }
}
```
