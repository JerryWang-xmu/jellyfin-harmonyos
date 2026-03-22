# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Jellyfin media client for HarmonyOS 6 (SDK 6.0.0–6.0.2), targeting phone, tablet, and 2-in-1 form factors. Bundle ID: `org.jellyfin.harmony`.

The architecture is **WebView-first hybrid**: the main UI is the upstream Jellyfin Web App loaded in a `WebviewController`; the native ArkTS layer bridges system capabilities (player, downloads, settings, fullscreen) into that web context via JavaScript proxies.

## Build System

This project uses **Hvigor** (HarmonyOS's build system). Development is done in **DevEco Studio**. Source files use the `.ets` extension (ArkTS — a TypeScript superset).

```bash
# Build debug HAP
hvigorw assembleHap --mode debug

# Build release HAP
hvigorw assembleHap --mode release

# Build full app
hvigorw assembleApp

# Run linter (checks all *.ets files)
hvigorw codecheck

# Run on-device instrumented tests (requires connected device/emulator)
hvigorw ohosTest
```

Build targets are defined in `build-profile.json5`. Release builds have obfuscation rules at `entry/obfuscation-rules.txt`. Strict mode is enabled (`caseSensitiveCheck`, `useNormalizedOHMUrl`).

## Tests

Test framework: `@ohos/hypium` + `@ohos/hamock`. Tests live in:
- `entry/src/ohosTest/ets/test/` — on-device instrumented tests (DAO, event handler, preferences, player)
- `entry/src/test/` — unit test batches

The `AllTests.test.ets` file aggregates all test suites. Tests must run on a connected HarmonyOS device or emulator via `hvigorw ohosTest`.

## Code Architecture

All application code is under `entry/src/main/ets/`. The layers are:

### Startup Flow
1. `EntryAbility.onWindowStageCreate` → `App.initialize(context)` (initializes DI, preferences, database, API controller)
2. Loads `MainPage` as the root
3. `MainPage` calls `apiController.loadSavedServer()`:
   - No server → navigate to `setup/ConnectPage`
   - Server found → navigate to `webapp/WebViewPage` with `{serverUrl, serverId}`
4. `WebViewPage` registers 4 JS proxy objects via `BridgeManager`, then loads the Jellyfin Web App URL
5. JS events dispatch through `ActivityEventHandler`; `MainPage` routes to native pages (PlayerPage, SettingsPage, DownloadsPage)

### Layer Map

| Layer | Directory | Key Files |
|---|---|---|
| Entry/Lifecycle | `entryability/` | `EntryAbility.ets` |
| Page Router | `pages/` | `MainPage.ets`, `ServerState.ets` |
| Server Setup | `setup/` | `ConnectPage.ets`, `ConnectionHelper.ets` |
| WebView | `webapp/` | `WebViewPage.ets`, `WebappFunctionChannel.ets` |
| JS Bridge | `bridge/` | `BridgeManager.ets`, `BridgeChannel.ets`, `NativeInterface.ets`, `NativePlayer.ets`, `ExternalPlayer.ets`, `MediaSegments.ets` |
| Core / DI | `core/di/` | `AppDependency.ets` (singleton DI container, replaces Koin) |
| Events | `core/event/` | `ActivityEvent.ets`, `ActivityEventHandler.ets` (wraps `@ohos.events.emitter`) |
| Preferences | `core/preferences/` | `AppPreferences.ets` |
| API | `api/` | `ApiClientController.ets`, `JellyfinApiService.ets` |
| Database | `data/` | `JellyfinDatabase.ets` (RdbStore, no ORM), `dao/`, `entity/` |
| Player | `player/` | `IPlayerAdapter.ets`, `AVPlayerAdapter.ets`, `PlayerPage.ets` |
| Downloads | `downloads/` | `DownloadService.ets`, `DownloadsPage.ets` |
| Settings | `settings/` | `SettingsPage.ets` |
| Constants/Utils | `common/` | `Constants.ets`, `Logger.ets` |

### Key Design Patterns
- **JS Bridge**: JS→ArkTS via `registerJavaScriptProxy` (4 proxy objects); ArkTS→JS via `runJavaScript` (wrapped in `BridgeChannel`)
- **Event bus**: `ActivityEventHandler` is global pub/sub using `@ohos.events.emitter` for cross-component communication
- **Server state machine**: `MainPage` maintains `ServerState` (Pending/Unset/Available) to drive navigation
- **DI**: `AppDependency` singleton accessed as `AppDependency.getInstance()` — provides preferences, event handler, database, API controller
- **Database**: Raw SQL with `RdbStore` (no Room equivalent); DAOs in `data/dao/`, schemas in `data/entity/`

## HarmonyOS API Mappings

| Capability | HarmonyOS API |
|---|---|
| WebView | `@ohos.web.webview` / `WebviewController` |
| Native player | `@ohos.multimedia.media` / `AVPlayer` |
| Database | `@ohos.data.relationalStore` / `RdbStore` |
| Preferences | `@ohos.data.preferences` |
| Event bus | `@ohos.events.emitter` |
| HTTP | `@ohos.net.http` |
| Downloads | `@ohos.request` |
| Logging | `@kit.PerformanceAnalysisKit` / `hilog` |
| Window/Display | `@ohos.window`, `@ohos.display` |

## Design Documents

Detailed architecture, migration plan, interface contracts, and UI specs are in `design/`:
- `design/ARCHITECTURE.md` — full architecture doc with Android→HarmonyOS mapping table
- `design/MIGRATION_PLAN.md`, `design/INTERFACE_CONTRACT.md`, `design/MODULE_DEPENDENCY.md`, `design/UI_SPEC.md`
