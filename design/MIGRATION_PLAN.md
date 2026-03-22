# Jellyfin HarmonyOS 迁移计划

> Pioneer 任务分批计划 v1.0
> 日期：2026-03-22
> 依赖顺序排列，每个 Batch 可独立提交测试

---

## Gap 分析总结

经过源码深度对比，当前 HarmonyOS 代码的完成状态：

| 模块 | 完成度 | 说明 |
|------|--------|------|
| EntryAbility | 90% | 缺少 DI 容器的数据库初始化 |
| MainPage | 50% | 路由导航未实现，WebView 嵌入缺失 |
| ConnectPage | 40% | UI 骨架存在，真正的 HTTP 验证、数据库保存未实现，UI 需对齐设计图 |
| WebViewPage | 60% | BridgeManager 注册逻辑存在，但 rawfile 资源映射、服务器 URL 传参未打通 |
| BridgeManager/NativeInterface/NativePlayer | 85% | 代理注册逻辑完整，deviceId 获取需用 @ohos.deviceInfo 实现 |
| ActivityEventHandler | 95% | 完整，无需改动 |
| AppPreferences | 95% | 完整，无需改动 |
| AppDependency | 70% | 缺少数据库、ApiClientController 的注入 |
| JellyfinDatabase + DAO | 85% | 建表 SQL 存在，DownloadDao 扩展字段与 DownloadService 不一致 |
| AVPlayerAdapter | 60% | 状态机回调基本完整，setVolume/speed 未实现，轨道选择为 TODO |
| PlayerPage | 30% | UI 骨架，缺少 XComponent 视频渲染、getPlaybackInfo 调用、进度上报 |
| DownloadService | 70% | 基本逻辑存在，DownloadDao 接口不匹配 |
| JellyfinApiService | 0% | **完全缺失**，需从零实现 |
| ConnectPage HTTP 验证 | 0% | 只有 placeholder |
| 页面路由 | 0% | 所有 router.pushUrl 均为 TODO |
| SettingsPage | 40% | 骨架存在，设置项目交互未实现 |
| DownloadsPage | 0% | 完全缺失 |
| 通知栏媒体控制 | 0% | 完全缺失（对应 RemotePlayerService） |

---

## Batch 1：核心基础层（无外部依赖）

**目标**：所有其他模块依赖的基础设施完整可用
**验收标准**：单元测试通过，数据库读写正常，偏好存储正常

### 任务 1.1：修复 DownloadEntity（扩展字段对齐）

**文件**：`data/entity/DownloadEntity.ets`

```typescript
// 修正后的 DownloadEntity
export interface DownloadEntity {
  id?: number;            // 数据库自增主键
  itemId: string;
  mediaSource: string;
  fileName: string;
  filePath: string;
  progress: number;       // 0-100
  status: DownloadStatus;
}

export enum DownloadStatus {
  PENDING = 'pending',
  DOWNLOADING = 'downloading',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

// DownloadEntityHelper.getCreateTableSql() 更新：
// CREATE TABLE IF NOT EXISTS Download (
//   id          INTEGER PRIMARY KEY AUTOINCREMENT,
//   item_id     TEXT NOT NULL UNIQUE,
//   media_source TEXT NOT NULL,
//   file_name   TEXT NOT NULL DEFAULT '',
//   file_path   TEXT NOT NULL DEFAULT '',
//   progress    INTEGER NOT NULL DEFAULT 0,
//   status      TEXT NOT NULL DEFAULT 'pending'
// )
```

### 任务 1.2：补全 DownloadDao 接口

**文件**：`data/dao/DownloadDao.ets`

补充 `queryAll`、`queryByStatus`、`updateProgress`、`deleteByItemId` 方法。

### 任务 1.3：AppDependency 注入数据库和 ApiClientController

**文件**：`core/di/AppDependency.ets`

```typescript
// 在 initialize() 中添加：
this._database = await getDatabase(context);
this._apiController = new ApiClientController(
  this._preferences!, this._database.serverDao, this._database.userDao
);
```

### 任务 1.4：实现 ApiClientController

**文件**：`api/ApiClientController.ets`（新建）

```typescript
export class ApiClientController {
  config: ApiClientConfig;

  async setupServer(hostname: string): Promise<number>;
  async setupUser(serverId: number, userId: string, accessToken: string): Promise<void>;
  async loadSavedServer(): Promise<ServerEntity | null>;
  async loadSavedServerUser(): Promise<ServerUser | null>;
  async loadPreviouslyUsedServers(): Promise<ServerEntity[]>;
}
```

### 任务 1.5：完善 NativeInterface.getDeviceInformation()

**文件**：`bridge/NativeInterface.ets`

```typescript
import deviceInfo from '@ohos.deviceInfo';

private getDeviceId(): string {
  // 从 preferences 获取持久化的 deviceId（首次生成 UUID 并存储）
  let id = this.preferences.getRaw()?.getSync('device_id', '') as string;
  if (!id) {
    id = this.generateUUID();
    this.preferences.getRaw()?.putSync('device_id', id);
    this.preferences.getRaw()?.flushSync();
  }
  return id;
}

private getDeviceName(): string {
  return deviceInfo.marketName || deviceInfo.productModel || 'HarmonyOS Device';
}
```

---

## Batch 2：网络层（依赖 Batch 1）

**目标**：`JellyfinApiService` 完整可用，认证流程可端到端测试
**验收标准**：可用真实 Jellyfin 服务器完成登录

### 任务 2.1：实现 JellyfinApiService

**文件**：`api/JellyfinApiService.ets`（新建）

核心 HTTP 封装：
```typescript
private buildAuthHeader(withToken: boolean = true): string {
  let header = `MediaBrowser Client="${this.config.appName}", ` +
    `Device="${this.config.deviceName}", ` +
    `DeviceId="${this.config.deviceId}", ` +
    `Version="${this.config.appVersion}"`;
  if (withToken && this.config.accessToken) {
    header += `, Token="${this.config.accessToken}"`;
  }
  return header;
}

private async request<T>(method: string, path: string, body?: object): Promise<T> {
  const httpRequest = http.createHttp();
  try {
    const response = await httpRequest.request(
      `${this.config.baseUrl}${path}`,
      {
        method: method as http.RequestMethod,
        header: {
          'Content-Type': 'application/json',
          'Authorization': this.buildAuthHeader()
        },
        extraData: body ? JSON.stringify(body) : undefined,
        expectDataType: http.HttpDataType.STRING
      }
    );
    if (response.responseCode >= 400) {
      throw new Error(`HTTP ${response.responseCode}: ${path}`);
    }
    return JSON.parse(response.result as string) as T;
  } finally {
    httpRequest.destroy(); // 必须释放，防止内存泄漏
  }
}
```

必须实现的 API（见 INTERFACE_CONTRACT.md 完整列表）：
- getPublicSystemInfo
- authenticateByName / authenticateWithQuickConnect
- getUserViews / getItems / getItem / getResumeItems / getNextUp
- getPlaybackInfo
- reportPlaybackStart / reportPlaybackProgress / reportPlaybackStopped
- markItemPlayed / setFavorite
- buildImageUrl（纯 URL 拼接）
- getMediaSegments

### 任务 2.2：实现 ConnectionHelper

**文件**：`setup/ConnectionHelper.ets`（新建）

```typescript
export type CheckUrlState =
  | { type: 'success'; url: string }
  | { type: 'error'; message?: string }
  | { type: 'loading' };

export class ConnectionHelper {
  static async checkServerUrl(enteredUrl: string): Promise<CheckUrlState> {
    // 1. 规范化 URL（添加 http:// 前缀，移除尾部斜杠）
    // 2. 尝试 GET /System/Info/Public（超时 10 秒）
    // 3. 验证响应中含有 ServerName 字段
    // 4. 返回 { type: 'success', url: normalizedUrl } 或 { type: 'error', message }
  }
}
```

### 任务 2.3：修复 ConnectPage 连接逻辑

**文件**：`setup/ConnectPage.ets`

替换 `testConnection` placeholder 为真实 `ConnectionHelper.checkServerUrl()`，成功后：
```typescript
const result = await ConnectionHelper.checkServerUrl(this.serverUrl);
if (result.type === 'success') {
  const serverId = await App.apiController.setupServer(result.url);
  router.replaceUrl({
    url: 'pages/webapp/WebViewPage',
    params: { serverUrl: result.url, serverId }
  });
}
```

---

## Batch 3：页面层（依赖 Batch 1, 2）

**目标**：完整页面导航流程，WebView 可加载 Jellyfin Web
**验收标准**：可用真实 Jellyfin 服务器，WebView 正确加载 Web UI

### 任务 3.1：实现 MainPage 路由导航

**文件**：`pages/MainPage.ets`

```typescript
private async initializeApp(): Promise<void> {
  this.serverState = ServerState.Pending;
  const server = await App.apiController.loadSavedServer();
  if (server) {
    App.currentServer = server;
    this.serverState = ServerState.Available;
    router.replaceUrl({ url: 'pages/webapp/WebViewPage', params: { serverUrl: server.hostname, serverId: server.id } });
  } else {
    this.serverState = ServerState.Unset;
    router.replaceUrl({ url: 'pages/setup/ConnectPage' });
  }
}

// 订阅事件
App.eventHandler.subscribe(ActivityEventType.SELECT_SERVER, ...);
App.eventHandler.subscribe(ActivityEventType.LAUNCH_NATIVE_PLAYER, ...);
App.eventHandler.subscribe(ActivityEventType.OPEN_SETTINGS, ...);
App.eventHandler.subscribe(ActivityEventType.EXIT_APP, ...);
App.eventHandler.subscribe(ActivityEventType.CHANGE_FULLSCREEN, ...);
```

### 任务 3.2：完善 WebViewPage

**文件**：`webapp/WebViewPage.ets`

关键修复：
1. `onControllerAttached` 中初始化 BridgeManager（注册代理必须在此时机）
2. 从路由参数获取 `serverUrl`
3. Web 组件配置 `javaScriptAccess(true)`, `domStorageAccess(true)`, `fileAccess(true)`, `mixedMode(MixedMode.All)`
4. 10 秒连接超时处理

### 任务 3.3：ConnectPage 完整 UI（对齐设计图）

**文件**：`setup/ConnectPage.ets`

按 UI_SPEC.md 中的 ConnectPage 规范重写：
- 背景色 `#0f0f0f`
- 顶部：返回按钮 + Jellyfin Logo
- 标题 "连接到服务器"（32sp Bold #ffffff）
- "主机"标签 + 深色输入框
- 青蓝色"连接"按钮 + 暗色"取消"按钮
- 历史服务器列表

### 任务 3.4：DownloadsPage 骨架

**文件**：`downloads/DownloadsPage.ets`（新建）

简单列表页，展示 `DownloadService.getAllDownloads()` 结果。

### 任务 3.5：SettingsPage 完整实现

**文件**：`settings/SettingsPage.ets`

- 视频播放器类型选择（Web / Native）
- 手势控制开关
- 下载位置设置
- 注销/更改服务器

---

## Batch 4：播放器（依赖 Batch 2, 3）

**目标**：原生 AVPlayer 播放器可完整播放 Jellyfin 媒体，含进度上报
**验收标准**：可播放 HLS 流，字幕/音频切换正常，进度上报服务端

### 任务 4.1：完善 AVPlayerAdapter

**文件**：`player/adapter/AVPlayerAdapter.ets`

补全：
```typescript
// setVolume: 映射 0-100 → 0.0-1.0
setVolume(percent: number): void {
  this.avPlayer?.setVolume(Math.max(0, Math.min(100, percent)) / 100);
}

// setPlaybackSpeed: 映射 number → SpeedMode enum
setPlaybackSpeed(speed: number): void {
  const speedMode = {
    0.75: media.PlaybackSpeed.SPEED_FORWARD_0_75_X,
    1.0:  media.PlaybackSpeed.SPEED_FORWARD_1_00_X,
    1.25: media.PlaybackSpeed.SPEED_FORWARD_1_25_X,
    1.5:  media.PlaybackSpeed.SPEED_FORWARD_1_50_X,
    2.0:  media.PlaybackSpeed.SPEED_FORWARD_2_00_X,
  }[speed] ?? media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  this.avPlayer?.setSpeed(speedMode);
}

// 轨道选择: avPlayer.selectTrack(index)
// 获取 duration: 在 'prepared' stateChange 回调中读取 avPlayer.duration
// 视频尺寸: avPlayer.on('videoSizeChange', (w, h) => listener.onVideoSizeChanged(w, h))
```

### 任务 4.2：实现 PlayerPage 完整 UI 和逻辑

**文件**：`player/ui/PlayerPage.ets`

```typescript
// 1. XComponent 视频渲染
XComponent({
  id: 'player_surface',
  type: XComponentType.SURFACE,
  controller: this.xComponentController
})
.onLoad(async () => {
  const surfaceId = this.xComponentController.getXComponentSurfaceId();
  await this.player?.setSurface(surfaceId);
})

// 2. 播放信息获取
private async initPlayback(): Promise<void> {
  const itemId = this.playOptions!.ids[this.playOptions!.startIndex];
  const playbackInfo = await this.apiService!.getPlaybackInfo(itemId, {
    deviceProfile: this.buildDeviceProfile(),
    startTimeTicks: this.playOptions!.startPosition,
  });
  const source = playbackInfo.MediaSources[0];
  const streamUrl = source.transcodingUrl
    ? `${App.apiController.config.baseUrl}${source.transcodingUrl}`
    : `${App.apiController.config.baseUrl}${source.directStreamUrl}`;
  await this.player!.prepare({ url: streamUrl, startPositionMs: ... });
  this.player!.play();
  await this.apiService!.reportPlaybackStart({...});
  this.startProgressTimer();
}

// 3. 进度上报（每 10 秒）
private startProgressTimer(): void {
  this.progressTimer = setInterval(async () => {
    if (!this.player?.isPlaying()) return;
    await this.apiService!.reportPlaybackProgress({
      itemId: this.currentItemId,
      positionTicks: this.player!.getCurrentPosition() * 10000,
      isPaused: false, isMuted: false, volumeLevel: 100,
    });
  }, 10000);
}
```

### 任务 4.3：通知栏媒体控制（可选）

使用 `@ohos.multimedia.avsession` 实现通知栏播放控制，对应 Android RemotePlayerService。

---

## Batch 5：下载服务（依赖 Batch 2, 3）

**目标**：下载功能可用，下载列表展示
**验收标准**：可下载 Jellyfin 媒体文件并在 DownloadsPage 展示

### 任务 5.1：对齐 DownloadService 与 DownloadDao

**文件**：`downloads/DownloadService.ets`

修复 `DownloadDao.getInstance()` 错误：
```typescript
// 改为通过 AppDependency 获取
private downloadDao: DownloadDao = App.database.downloadDao;
```

### 任务 5.2：实现 DownloadsPage 完整 UI

**文件**：`downloads/DownloadsPage.ets`

缩略图 + 标题 + 进度条 + 状态 + 操作按钮（暂停/取消/删除）。

---

## Batch 6：UI 精修（依赖 Batch 1-5）

**目标**：所有页面对齐高保真设计图

- ConnectPage：完全对齐 `design/UI/首页.png`
- 登录页（WebView内加载，可选实现原生登录页对齐 `design/UI/登录页.png`）
- PlayerPage：全屏横屏，手势调节亮度/音量，片头片尾跳过按钮
- SettingsPage：完整设置项交互
- 安全区适配（刘海屏/挖孔屏）

---

## 关键风险与注意事项

1. **registerJavaScriptProxy 时机**：必须在 `onControllerAttached` 中调用，且需要 `controller.refresh()` 才能生效。每次页面导航回来需要重新注册。

2. **AVPlayer 状态机**：与 ExoPlayer 完全不同。`prepared` 状态才能调用 `play()`，`playing` 状态才能调用 `pause()`，错误状态需要 `reset()` 后重新 `prepare()`。

3. **HarmonyOS 跨线程 UI 更新**：所有 `@State` 变量更新必须在 UI 线程。在 AVPlayer 回调中更新 `@State` 需要确保线程安全。

4. **http 模块**：每次请求后必须调用 `httpRequest.destroy()` 释放资源，否则会造成内存泄漏。

5. **rawfile 资源路径**：`nativeshell.js` 通过 `rawfile` 目录提供，Jellyfin Web 通过 `/native/nativeshell.js` 路径引用，需确保 Web 组件 `fileAccess(true)` 且资源路径映射正确。

6. **deviceId 持久化**：HarmonyOS 禁止应用直接读取设备硬件 ID，必须首次启动时生成 UUID 并存储到 preferences。
