# Web Player & Keyboard Performance Refactoring Plan

> Generated: 2026-03-29 | Scope: Web Player, JS Bridge, Keyboard Animation | Excludes: Built-in Native Player

## Executive Summary

15 performance issues identified across 6 phases. Expected aggregate improvement:
- **Web page reload on navigation back**: Eliminated (~500-1000ms saved per back navigation)
- **Keyboard animation layout thrashing**: 50-70% reduction in layout work
- **WebViewPage over-rendering**: 3x fewer redundant renders on state changes
- **Startup time**: 50-200ms improvement from parallel initialization
- **JS Bridge call overhead**: Eliminated sync I/O on every `getDeviceInformation()` call

---

## Phase 1: Critical Fixes (Independent Files)

### P1-CRITICAL: Rewrite WebappFunctionChannel (Broken Module)
- **File**: `webapp/WebappFunctionChannel.ets`
- **Issue**: References `BridgeChannel.getInstance()` (non-existent), `sendMessageToWeb()` (non-existent), orphaned singleton
- **Fix**: Complete rewrite - inject BridgeChannel via constructor, use actual BridgeChannel APIs
- **Risk**: Low (module is already broken/unreachable)

### P4-HIGH: Cache DeviceId, Remove Sync I/O
- **File**: `bridge/NativeInterface.ets`
- **Issue**: `getDeviceId()` uses `prefs.getSync()/putSync()` blocking main thread; re-generates on every JS call
- **Fix**: Generate deviceId once in constructor, cache in field; replace sync prefs with async
- **Risk**: Low

### P10-HIGH: Refactor ActivityEventHandler Double-Dispatch
- **File**: `core/event/ActivityEventHandler.ets`
- **Issue**: `_emittingInsideEmit` flag is fragile; queue overflow at 10 silently drops events
- **Fix**: Replace `@ohos.events.emitter` with in-process `Map<EventType, Set<Callback>>`; configurable queue size
- **Risk**: Medium (affects all event subscribers)

---

## Phase 2: Bridge/WebView Performance (Sequential - BridgeManager.ets)

### P3-HIGH: Avoid Re-initializing BridgeManager on Navigation Back
- **File**: `bridge/BridgeManager.ets`
- **Issue**: Every `onControllerAttached` creates new BridgeManager + `refresh()`, reloading entire web app
- **Fix**: Add `isBridgeInitialized` flag; skip re-init on subsequent attaches
- **Risk**: High (proxy registration lifecycle)

### P2-HIGH: Minimize controller.refresh() Impact
- **File**: `bridge/BridgeManager.ets`
- **Issue**: `refresh()` forces full page reload, resets WebView state, causes visible flash
- **Fix**: Move proxy registration before first page load; only refresh on initial setup
- **Risk**: High (JS proxy availability)

### P11-HIGH: Fix BridgeManager Listener Cleanup
- **File**: `bridge/BridgeManager.ets`
- **Issue**: `destroy()` doesn't clear NativePlayer listeners or event bus subscriptions
- **Fix**: Call `clearListeners()` on all interfaces; remove event subscriptions
- **Risk**: Medium

---

## Phase 3: WebViewPage State & Keyboard (Sequential - WebViewPage.ets)

### P8-HIGH: Consolidate WebViewPage @State Variables
- **File**: `webapp/WebViewPage.ets`
- **Issue**: 5 @State vars; serverUrl/serverId never change after init; loadError+loadErrorMsg double-render
- **Fix**: Convert static vars to plain properties; merge load states into single enum @State
- **Risk**: Low

### P7-HIGH: Optimize Keyboard Avoidance Mode
- **File**: `webapp/WebViewPage.ets`
- **Issue**: `RESIZE_VISUAL` triggers full WebView viewport resize on every keyboard show/hide
- **Fix**: Switch to `RESIZE_CONTENT` or native-side keyboard handling via `window.on('keyboardHeightChange')`
- **Risk**: Medium (keyboard behavior may differ)

### P6-MEDIUM: Optimize Fullscreen Shim Injection
- **File**: `webapp/WebViewPage.ets`
- **Issue**: `injectFullscreenBridge()` runs on every `onPageEnd`; large JS string allocated each time
- **Fix**: Extract shim to static constant; inject only once with instance-level guard
- **Risk**: Low

---

## Phase 4: Startup & Network (Independent Files)

### P14-MEDIUM: Parallelize AppDependency Initialization
- **File**: `core/di/AppDependency.ets`
- **Issue**: Sequential await for independent init operations (preferences + database)
- **Fix**: `Promise.all()` for independent inits; sequential only for dependent ones
- **Risk**: Low

### P5-MEDIUM: Add JS Bridge Batching/Queueing
- **File**: `bridge/BridgeChannel.ets`
- **Issue**: Each ArkTS→JS call creates separate `runJavaScript()`; verbose logging on every call
- **Fix**: Message queue for high-frequency events; batch multiple JS calls; make logging conditional
- **Risk**: Medium

---

## Phase 5: Cleanup (Low Priority)

### P15-LOW: Fix EntryAbility Avoid Area Listener
- **File**: `entryability/EntryAbility.ets`
- **Issue**: Listener never removed; `getDefaultDisplaySync()` called on every avoid area change
- **Fix**: Remove listener in destroy; cache density value outside closure
- **Risk**: Very Low

---

## Dependency Graph

```
Phase 1 ──┬── P1 (WebappFunctionChannel.ets)
           ├── P4 (NativeInterface.ets)
           └── P10 (ActivityEventHandler.ets)
                    │
Phase 2 ─── P3 → P2 → P11 (all BridgeManager.ets, sequential)
                    │
Phase 3 ─── P8 → P7 → P6 (all WebViewPage.ets, sequential)
                    │
Phase 4 ──┬── P14 (AppDependency.ets) ── independent
           └── P5  (BridgeChannel.ets) ── independent
                    │
Phase 5 ─── P15 (EntryAbility.ets) ── independent
```

Phase 2 and Phase 3 touch different files and CAN run in parallel.
Phase 4 tasks are fully independent and CAN run in parallel with Phases 2-3.

## Execution Order (Respecting "No Same-File Concurrent Modification")

| Round | Parallel Tasks | Files |
|-------|---------------|-------|
| 1 | P1 + P4 + P10 | WebappFunctionChannel.ets, NativeInterface.ets, ActivityEventHandler.ets |
| 2 | P3→P2→P11 (seq) | BridgeManager.ets |
| 3 | P8→P7→P6 (seq) | WebViewPage.ets |
| 4 | P14 + P5 | AppDependency.ets, BridgeChannel.ets |
| 5 | P15 | EntryAbility.ets |

Rounds 2-4 can overlap on different files.

## Risk Matrix

| Phase | Risk | Mitigation |
|-------|------|------------|
| 1 | P1: Low (broken module), P4: Low, P10: Medium | P10: migrate callers incrementally |
| 2 | High (bridge registration) | Integration test after each sub-task |
| 3 | P8: Low, P7: Medium, P6: Low | P7: test keyboard on physical device |
| 4 | Low | Standard integration tests |
| 5 | Very Low | Surface changes |
