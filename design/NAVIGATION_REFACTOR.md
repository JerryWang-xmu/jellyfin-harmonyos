# Navigation 重构方案

**文档版本**：v1.0
**状态**：实施中
**目标**：消除全部 19 个 HarmonyOS API 12 弃用警告（router.replaceUrl/pushUrl/back/getParams）

---

## 1. 路由映射表

| 原 Page Router URL | 原用途 | Navigation 目的地名称 | 说明 |
|---|---|---|---|
| `pages/Index` | 启动屏 | 并入 AppRoot | 内联到根页面初始内容 |
| `pages/MainPage` | 路由中枢 | 根页面（AppRoot） | 改为 `@Entry` 根组件，承载 Navigation |
| `setup/ConnectPage` | 服务器连接页 | `ConnectDestination` | 无参数 |
| `webapp/WebViewPage` | Web 主界面 | `WebViewDestination` | 参数：`WebViewPageParams` |
| `player/ui/PlayerPage` | 原生播放器 | `PlayerDestination` | 参数：`PlayerPageParams` |
| `settings/SettingsPage` | 设置页 | `SettingsDestination` | 无参数 |
| `downloads/DownloadsPage` | 下载列表 | `DownloadsDestination` | 无参数 |

---

## 2. 核心架构

### 整体层级

```
EntryAbility
  └── loadContent('pages/AppRoot')
        └── Navigation(navPathStack)
              ├── 初始内容：加载动画（替代 Index.ets）
              └── NavDestination 路由表（PageMap Builder）
                    ├── ConnectDestination   → ConnectPage
                    ├── WebViewDestination   → WebViewPage
                    ├── PlayerDestination    → PlayerPage
                    ├── SettingsDestination  → SettingsPage
                    └── DownloadsDestination → DownloadsPage
```

### NavPathStack 策略

- 在 `AppRoot` 中创建：`@Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack()`
- 子页面通过 `@Consume('navPathStack') navPathStack: NavPathStack` 接收
- 同时注册到 `AppDependency`，供事件回调访问：`App.setNavPathStack(stack)`

---

## 3. 参数传递方案

| 旧方法 | 新方法 |
|---|---|
| `router.replaceUrl({ url: 'X' })` | `navPathStack.replacePath({ name: 'XDestination' })` |
| `router.replaceUrl({ url: 'X', params: p })` | `navPathStack.replacePath({ name: 'XDestination', param: p })` |
| `router.pushUrl({ url: 'X' })` | `navPathStack.pushPath({ name: 'XDestination' })` |
| `router.pushUrl({ url: 'X', params: p })` | `navPathStack.pushPath({ name: 'XDestination', param: p })` |
| `router.back()` | `navPathStack.pop()` |
| `router.getParams() as T` | `pageParams: T`（构造参数注入） |

---

## 4. 接口契约

### WebViewDestination 参数
```typescript
export interface WebViewPageParams {
  serverUrl: string;   // Jellyfin 服务器 URL
  serverId: number;    // 数据库中的服务器 ID
}
```

### PlayerDestination 参数
```typescript
export interface PlayerPageParams {
  playOptions: string;  // PlayOptions 的 JSON 序列化字符串
}
```

### 无参数页面
- `ConnectDestination`、`SettingsDestination`、`DownloadsDestination`

---

## 5. 文件变更清单

### 新建
- `pages/AppRoot.ets` — 唯一 @Entry 根页面
- `pages/NavDestinationNames.ets` — 目的地名称常量

### 修改
- `core/di/AppDependency.ets` — 新增 NavPathStack 字段/setter/getter
- `entryability/EntryAbility.ets` — 加载 AppRoot
- `setup/ConnectPage.ets` — 移除 @Entry/router，改为 NavDestination
- `webapp/WebViewPage.ets` — 移除 @Entry/router，改为 NavDestination + 参数注入
- `player/ui/PlayerPage.ets` — 移除 @Entry/router，改为 NavDestination + 参数注入
- `settings/SettingsPage.ets` — 移除 @Entry/router，改为 NavDestination
- `downloads/DownloadsPage.ets` — 移除 @Entry/router，改为 NavDestination
- `resources/base/profile/main_pages.json` — 最终只保留 `pages/AppRoot`

### 删除（Batch E）
- `pages/MainPage.ets`
- `pages/Index.ets`

---

## 6. 分批次开发计划

| 批次 | 任务 | 前置依赖 |
|---|---|---|
| **A** | AppDependency + NavDestinationNames + 接口导出 | 无 |
| **B** | AppRoot.ets + EntryAbility + main_pages.json | A |
| **C** | ConnectPage、SettingsPage、DownloadsPage（可并行） | B |
| **D** | WebViewPage、PlayerPage（可并行） | C |
| **E** | 删除旧文件、最终清理 | D |

---

## 7. main_pages.json 最终状态（Batch E 后）

```json
{
  "src": [
    "pages/AppRoot"
  ]
}
```

---

## 8. ArkTS 约束注意事项

1. `@Provide`/`@Consume` 必须使用字符串字面量 key
2. PageMap Builder 的 `param` 类型为 `ESObject`，各分支内显式 cast
3. `replacePath` = 替换栈顶（等价 replaceUrl）；`pushPath` = 压栈（等价 pushUrl）
4. `Navigation` 需设置 `.hideTitleBar(true)`，所有子页面自绘标题栏
5. `onBackPressed` 返回 `true` 拦截；`false` 交由 Navigation 默认处理
