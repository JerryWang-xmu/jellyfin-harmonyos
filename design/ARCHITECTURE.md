# Jellyfin HarmonyOS 整体架构文档

> 版本：1.0.0
> 日期：2026-03-22
> 基于 Android 源码分析 + HarmonyOS 6 现有代码

---

## 一、架构总览

Jellyfin HarmonyOS 采用 **HarmonyOS UIAbility + ArkUI + WebView 混合架构**，
核心思路与 Android 版完全一致：

```
┌──────────────────────────────────────────────────────┐
│                  EntryAbility（应用入口）               │
│          onCreate → initialize App → loadContent      │
└─────────────────────┬────────────────────────────────┘
                      │ windowStage.loadContent
                      ▼
┌──────────────────────────────────────────────────────┐
│                    MainPage（路由中枢）                 │
│   serverState: Pending / Unset / Available            │
│   ┌──────────────┐     ┌──────────────────────────┐  │
│   │  ConnectPage │     │      WebViewPage          │  │
│   │  服务器连接   │     │  加载 Jellyfin Web App    │  │
│   └──────────────┘     └────────────┬─────────────┘  │
└────────────────────────────────────┼─────────────────┘
                                     │ JS Bridge
              ┌──────────────────────┼──────────────────┐
              │           Bridge Layer（桥接层）          │
              │  NativeInterface  NativePlayer           │
              │  ExternalPlayer   MediaSegments          │
              │  BridgeManager    BridgeChannel          │
              └────────────┬─────────────────────────────┘
                           │ ActivityEvent
              ┌────────────▼─────────────────────────────┐
              │          Core Layer（核心层）              │
              │  ActivityEventHandler  AppPreferences     │
              │  AppDependency（DI容器）                  │
              └────────────┬─────────────────────────────┘
              ┌────────────▼─────────────────────────────┐
              │          Data Layer（数据层）              │
              │  JellyfinDatabase  ServerDao  UserDao     │
              │  DownloadDao  RelationalStore             │
              └──────────────────────────────────────────┘
              ┌──────────────────────────────────────────┐
              │         Service Layer（服务层）            │
              │  DownloadService  AVPlayerAdapter         │
              │  PlayerPage（原生播放器 UI）               │
              └──────────────────────────────────────────┘
```

### 核心设计原则

1. **WebView 优先**：主界面通过 WebView 加载 Jellyfin Web App，原生层仅提供系统能力桥接
2. **桥接驱动**：JS → ArkTS 通过 `registerJavaScriptProxy` 注册四个代理对象；ArkTS → JS 通过 `runJavaScript` 执行
3. **事件总线**：ActivityEventHandler 作为全局事件总线，使用 HarmonyOS `@ohos.events.emitter` 实现跨组件通信
4. **服务器状态机**：MainPage 维护 `ServerState` 三态（Pending/Unset/Available），驱动页面跳转
5. **单例 DI 容器**：AppDependency 替代 Android 的 Koin，提供全局服务访问

---

## 二、模块列表及职责

| 模块 | 路径 | 职责 | Android 对应 |
|------|------|------|-------------|
| EntryAbility | `entryability/EntryAbility.ets` | 应用生命周期、初始化 DI 容器 | JellyfinApplication + MainActivity |
| MainPage | `pages/MainPage.ets` | 路由中枢、ServerState 驱动页面切换 | MainActivity（Fragment 管理） |
| ConnectPage | `setup/ConnectPage.ets` | 服务器 URL 输入、连接验证 | ConnectFragment + ConnectScreen |
| WebViewPage | `webapp/WebViewPage.ets` | 加载 Jellyfin Web、注册 JS Bridge | WebViewFragment |
| WebappFunctionChannel | `webapp/WebappFunctionChannel.ets` | 向 WebApp 主动推送事件 | WebappFunctionChannel.kt |
| BridgeManager | `bridge/BridgeManager.ets` | 统一管理四个 JS 代理的注册与生命周期 | WebViewFragment.initialize() |
| BridgeChannel | `bridge/BridgeChannel.ets` | 封装 runJavaScript，ArkTS→JS 通道 | WebappFunctionChannel（部分） |
| NativeInterface | `bridge/NativeInterface.ets` | JS→ArkTS 通用接口（设备信息、全屏、下载等）| NativeInterface.kt |
| NativePlayer | `bridge/NativePlayer.ets` | JS→ArkTS 播放器控制接口 | NativePlayer.kt |
| ExternalPlayer | `bridge/ExternalPlayer.ets` | 外部播放器支持 | ExternalPlayer.kt |
| MediaSegments | `bridge/MediaSegments.ets` | 媒体片段（跳片头/片尾）支持 | MediaSegments.kt |
| ActivityEvent | `core/event/ActivityEvent.ets` | 事件类型定义 + 工厂方法 | ActivityEvent.kt |
| ActivityEventHandler | `core/event/ActivityEventHandler.ets` | 事件总线（发布/订阅） | ActivityEventHandler.kt |
| AppPreferences | `core/preferences/AppPreferences.ets` | 持久化偏好设置 | AppPreferences.kt |
| AppDependency | `core/di/AppDependency.ets` | 轻量级依赖注入容器 | Koin DI |
| JellyfinDatabase | `data/database/JellyfinDatabase.ets` | 数据库初始化、DAO 工厂 | JellyfinDatabase.kt（Room） |
| ServerDao | `data/dao/ServerDao.ets` | 服务器记录 CRUD | ServerDao.kt |
| UserDao | `data/dao/UserDao.ets` | 用户/Token 记录 CRUD | UserDao.kt |
| DownloadDao | `data/dao/DownloadDao.ets` | 下载记录 CRUD | DownloadDao.kt |
| AVPlayerAdapter | `player/adapter/AVPlayerAdapter.ets` | HarmonyOS AVPlayer 封装 | ExoPlayer（PlayerViewModel） |
| IPlayerAdapter | `player/adapter/IPlayerAdapter.ets` | 播放器抽象接口 | —（新增抽象层） |
| PlayerPage | `player/ui/PlayerPage.ets` | 原生播放器 UI | PlayerFragment.kt |
| DownloadService | `downloads/DownloadService.ets` | 下载任务管理 | JellyfinDownloadService.kt |
| SettingsPage | `settings/SettingsPage.ets` | 应用设置 | SettingsFragment.kt |
| Constants | `common/constants/Constants.ets` | 全局常量 | Constants.kt |

---

## 三、技术选型

| 能力 | HarmonyOS API | Android 对应 | 说明 |
|------|-------------|-------------|------|
| WebView | `@ohos.web.webview` | `android.webkit.WebView` | WebviewController 控制 |
| JS 桥接 | `registerJavaScriptProxy` | `addJavascriptInterface` | 需要预先注册，reload 后生效 |
| 播放器 | `@ohos.multimedia.media` AVPlayer | ExoPlayer（media3） | AVPlayer 状态机与 ExoPlayer 不同 |
| 数据库 | `@ohos.data.relationalStore` | Room Database | 手写 SQL，无 ORM |
| 偏好存储 | `@ohos.data.preferences` | SharedPreferences | 异步初始化 |
| 事件总线 | `@ohos.events.emitter` | Kotlin Flow / SharedFlow | eventId = 1001 |
| HTTP 网络 | `@ohos.net.http` | OkHttp / Retrofit | 需自行封装 Jellyfin REST API |
| 下载 | `@ohos.request` | media3 DownloadManager | DownloadTask 回调 |
| 权限 | `@ohos.abilityAccessCtrl` | ActivityCompat.requestPermissions | 异步请求 |
| 设备信息 | `@ohos.deviceInfo` | Build.SERIAL / Settings | 用于 Jellyfin deviceId |
| 通知 | `@ohos.notificationManager` | NotificationCompat | 播放控制通知 |
| 后台服务 | UIExtensionAbility / ServiceExtensionAbility | RemotePlayerService | 音乐后台播放 |

---

## 四、Android → HarmonyOS 技术映射表

| Android 概念 | HarmonyOS 对应 | 注意事项 |
|-------------|---------------|---------|
| Activity | UIAbility | 一个 App 通常只有一个 UIAbility |
| Fragment | @Component struct（Page 级） | 通过 router.pushUrl 导航 |
| ViewModel | @State + class（无内置 ViewModel） | 需手动管理生命周期 |
| LiveData/StateFlow | @State / @Link / @Prop | 单向数据流，需在 UI 线程更新 |
| RecyclerView | List + LazyForEach | 懒加载列表 |
| Koin DI | 单例 AppDependency | 无框架支持 |
| Room Database | relationalStore.RdbStore | 手写 SQL，无自动迁移 |
| SharedPreferences | @ohos.data.preferences | 需 async initialize() |
| WorkManager | TaskDispatcher / BackgroundTask | HarmonyOS 限制后台能力 |
| ExoPlayer | media.AVPlayer | API 差异较大，状态机不同 |
| MediaSession | AVSessionManager | 通知栏媒体控制 |
| DownloadManager | @ohos.request.downloadFile | 不支持断点续传（部分版本） |
| Intent extras | router.pushUrl params | 通过路由参数传递 |
| BroadcastReceiver | emitter.on | 进程内事件总线 |
| Service | ServiceExtensionAbility | 需配置 extensionAbilities |
| PiP | pip.PiPWindow（API 11+） | 画中画支持 |

---

## 五、关键数据流

### 5.1 服务器连接流程

```
用户输入 URL
    ↓
ConnectPage.connectToServer()
    ↓
HTTP GET {url}/System/Info/Public
    ↓ 成功
ServerDao.getServerByHostname() / insertByHostname()
    ↓
AppPreferences.currentServerId = serverId
    ↓
App.currentServer = ServerEntity
    ↓
emit(SELECT_SERVER 已处理) → MainPage.serverState = Available
    ↓
router.replaceUrl('pages/webapp/WebViewPage') with server param
```

### 5.2 WebView 播放触发流程

```
Jellyfin Web App (JS)
    ↓ NativePlayer.loadPlayer(JSON)
BridgeManager 注册的 NativePlayer 代理
    ↓ parsePlayOptions(args)
ActivityEvents.launchNativePlayer(playOptions)
    ↓ ActivityEventHandler.emit()
MainPage 订阅 LAUNCH_NATIVE_PLAYER
    ↓ router.pushUrl('pages/PlayerPage') with playOptions
PlayerPage.aboutToAppear()
    ↓
AVPlayerAdapter.initialize() → prepare(mediaSource) → play()
```

### 5.3 播放进度上报流程

```
AVPlayerAdapter.on('timeUpdate', time)
    ↓
PlayerPage._currentPosition = time
    ↓
每 10 秒调用：
JellyfinApiService.reportPlaybackProgress({positionTicks: time*10000, ...})
    ↓
http.POST {serverUrl}/Sessions/Playing/Progress
```
