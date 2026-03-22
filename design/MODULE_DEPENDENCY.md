# Jellyfin HarmonyOS 模块依赖图

> 版本：1.0.0
> 日期：2026-03-22

---

## 一、整体模块依赖（Mermaid）

```mermaid
graph TD
    subgraph Ability层
        EA[EntryAbility]
    end

    subgraph Page层
        MP[MainPage\n路由中枢]
        CP[ConnectPage\n服务器连接]
        WVP[WebViewPage\nWebView容器]
        PP[PlayerPage\n原生播放器]
        SP[SettingsPage\n设置]
    end

    subgraph Bridge层
        BM[BridgeManager\n桥接管理器]
        BC[BridgeChannel\nJS执行通道]
        NI[NativeInterface\n通用桥接]
        NPL[NativePlayer\n播放器桥接]
        EP[ExternalPlayer\n外部播放器]
        MS[MediaSegments\n媒体片段]
        WFC[WebappFunctionChannel\n主动通知]
    end

    subgraph Core层
        AEH[ActivityEventHandler\n事件总线]
        AE[ActivityEvent\n事件定义]
        APF[AppPreferences\n偏好存储]
        AD[AppDependency\nDI容器]
    end

    subgraph Data层
        DB[JellyfinDatabase\nRDB初始化]
        SDao[ServerDao]
        UDao[UserDao]
        DDao[DownloadDao]
        SE[ServerEntity]
        UE[UserEntity]
        DE[DownloadEntity]
    end

    subgraph Service层
        DS[DownloadService\n下载服务]
        AVPA[AVPlayerAdapter\nAVPlayer封装]
        IPA[IPlayerAdapter\n播放器接口]
    end

    subgraph API层
        ACS[ApiClientController]
        JAS[JellyfinApiService]
        CH[ConnectionHelper]
    end

    subgraph JS资源
        NS[nativeshell.js]
        EXPP[ExoPlayerPlugin.js]
    end

    %% Ability → Page
    EA -->|initialize| AD
    EA -->|loadContent| MP

    %% Page 依赖
    MP -->|serverState=Unset| CP
    MP -->|serverState=Available| WVP
    MP -->|LAUNCH_NATIVE_PLAYER| PP
    MP -->|OPEN_SETTINGS| SP
    WVP -->|创建| BM

    %% Bridge
    BM --> BC
    BM --> NI
    BM --> NPL
    BM --> EP
    BM --> MS
    WVP --> WFC
    WFC --> BC
    NI -->|emit| AEH
    NPL -->|emit| AEH

    %% Core
    AD --> AEH
    AD --> APF
    AD --> ACS
    AEH --> AE
    MP -->|subscribe| AEH
    PP -->|subscribe| AEH

    %% Data
    AD -->|lazy init| DB
    DB --> SDao
    DB --> UDao
    DB --> DDao
    SDao --> SE
    UDao --> UE
    DDao --> DE

    %% API
    ACS --> SDao
    ACS --> UDao
    ACS --> APF
    JAS --> ACS
    CH --> JAS
    CP --> CH

    %% Service
    PP --> AVPA
    PP --> JAS
    AVPA -.implements.-> IPA
    DS --> DDao
    DS --> AEH
    DS --> JAS

    %% JS
    WVP -->|inject| NS
    NS -->|calls| NI
    NS -->|calls| NPL
    EXPP -->|calls| NPL
```

---

## 二、页面导航依赖图

```mermaid
graph LR
    MP[MainPage] -->|Unset| CP[ConnectPage]
    MP -->|Available| WVP[WebViewPage]
    WVP -->|NativePlayer.loadPlayer| PP[PlayerPage]
    WVP -->|openClientSettings| SP[SettingsPage]
    WVP -->|openDownloads| DLP[DownloadsPage\n待实现]
    CP -->|连接成功| WVP
    PP -->|返回| WVP
    SP -->|返回| WVP
```

---

## 三、数据层依赖图

```mermaid
graph TD
    JDB[JellyfinDatabase] -->|owns| SDao[ServerDao]
    JDB -->|owns| UDao[UserDao]
    JDB -->|owns| DDao[DownloadDao]

    SDao -->|操作| ST[Server表\nid/hostname/last_used_timestamp]
    UDao -->|操作| UT[User表\nid/server_id/user_id/access_token/last_login_timestamp]
    DDao -->|操作| DT[Download表\nitem_id/media_source/file_name/file_path/progress/status]

    UT -->|FK server_id| ST

    APF[AppPreferences] -->|存储| CSID[currentServerId\nLong]
    APF -->|存储| CUID[currentUserId\nLong]
    APF -->|存储| IU[instanceUrl\nString]
    APF -->|存储| DID[device_id\nString]

    AD[AppDependency] -->|持有| APF
    AD -->|持有 currentServer| SE[ServerEntity]
    AD -->|持有 currentUser| UE[UserEntity]
    AD -->|持有| ACS[ApiClientController]
```

---

## 四、事件流依赖图

```mermaid
sequenceDiagram
    participant JS as Jellyfin Web (JS)
    participant NI as NativeInterface
    participant AEH as ActivityEventHandler
    participant MP as MainPage
    participant WFC as WebappFunctionChannel
    participant BC as BridgeChannel

    JS->>NI: openServerSelection()
    NI->>AEH: emit(SELECT_SERVER)
    AEH->>MP: callback(event)
    MP->>MP: serverState = Unset
    MP->>MP: router → ConnectPage

    JS->>NI: NativePlayer.loadPlayer(opts)
    NI->>AEH: emit(LAUNCH_NATIVE_PLAYER)
    AEH->>MP: callback(event)
    MP->>MP: router → PlayerPage

    Note over BC,JS: ArkTS → JS 方向
    BC->>JS: runJavaScript("window.NavigationHelper.playbackManager.seekMs(pos)")
    WFC->>BC: callFunction("window.ExtPlayer.notifyENDED")
```

---

## 五、Bridge 注册依赖

```
WebViewPage.onControllerAttached()
    └── BridgeManager.initialize()
            ├── BridgeChannel.initialize()
            │       └── WebviewController（引用）
            ├── NativeInterface(context, eventHandler, preferences)
            │       └── registerJavaScriptProxy("NativeInterface", [...14 methods])
            ├── NativePlayer(preferences, eventHandler)
            │       └── registerJavaScriptProxy("NativePlayer", [...9 methods])
            ├── ExternalPlayer(context, preferences)
            │       └── registerJavaScriptProxy("ExternalPlayer", [...2 methods])
            └── MediaSegments()
                    └── registerJavaScriptProxy("MediaSegments", [...2 methods])
```

**重要**：`registerJavaScriptProxy` 必须在 `Web` 组件的 `onControllerAttached` 回调中调用，且注册后需要调用 `controller.refresh()` 使代理生效。每次页面销毁重建（如从 PlayerPage 返回）需要重新注册。
