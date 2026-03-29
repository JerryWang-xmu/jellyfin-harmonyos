# HarmonyOS ArkTS Performance Optimization Reference

This document compiles best practices for HarmonyOS ArkTS performance optimization, sourced from Huawei developer documentation and community technical articles. Each section covers a specific optimization domain relevant to the jellyfin-harmonyos project.

---

## 1. WebView Performance Optimization

### 1.1 Web Engine Initialization

Initialize the Web engine early in the application lifecycle, before the WebView component is created. Call `initializeWebEngine()` in `EntryAbility.onCreate()` to front-load the engine startup cost.

```typescript
// EntryAbility.onCreate
webview.WebviewController.initializeWebEngine()
```

### 1.2 Pre-Connection and Pre-Load

Use `prepareForPageLoad()` to perform DNS resolution and TCP/TLS handshake before the page loads. This eliminates network round-trip latency for the initial request.

```typescript
webview.WebviewController.prepareForPageLoad(
  url,      // target URL
  true,     // allowRedirect
  2         // number of redirect hops to pre-connect
)
```

Call this method when the user is about to navigate (e.g., on server selection confirmation), not at app startup.

### 1.3 Page Prefetch with prefetchPage

For predictable navigation flows, prefetch the next page while the current one is still displayed.

```typescript
this.webController.prefetchPage(targetUrl, {
  method: 'GET',
  header: { 'Accept-Language': 'zh-CN' }
})
```

### 1.4 Pre-Rendering with NodeController/NodeContainer

For frequently visited WebView pages, use a hidden pre-rendered Web component wrapped in `NodeContainer` via `NodeController`. When the user navigates, swap the pre-rendered node into the visible tree instantly.

- Typical improvement: ~100ms reduction in first meaningful paint, ~40-50ms faster page transitions.
- Keep only one pre-rendered Web component at a time to limit memory overhead.

### 1.5 Cache and Resource Hints

- Enable DOM storage and application cache in Web attributes.
- Set appropriate `cacheMode` (e.g., `CacheMode.Default` for cached content reuse).
- Use `domStorageAccess(true)` and `databaseAccess(true)` for localStorage support.

### 1.6 Relevance to jellyfin-harmonyos

The app loads the Jellyfin Web App as its primary UI. Key optimizations:
- Call `initializeWebEngine()` in `EntryAbility.onCreate()` (currently done later).
- Call `prepareForPageLoad(serverUrl, true, 2)` when the user selects a server.
- Consider pre-rendering the WebView in `MainPage` before navigating to `WebViewPage`.

---

## 2. ArkUI State Management Optimization

### 2.1 V1 vs V2 State Management

| Feature | V1 (@State/@Prop/@Link) | V2 (@ObservedV2/@Trace/@Local/@Param) |
|---|---|---|
| Observation granularity | Object-level (entire object re-renders) | Field-level via @Trace |
| Decorator complexity | Many decorators for different scopes | Fewer, more consistent decorators |
| Performance | Degrades with large/nested objects | Better for complex state trees |
| Recommended for | Simple state (primitives, small objects) | Complex/nested state, large arrays |

### 2.2 @Track for Field-Level Observation (V1)

When using V1 state management with complex objects, apply `@Track` to individual fields to prevent unnecessary re-renders when unrelated fields change.

```typescript
@Observed
class UserInfo {
  @Track name: string = ''
  @Track avatar: string = ''
  score: number = 0  // changes to score won't trigger UI update
}
```

Without `@Track`, any field change in a `@State` object triggers re-render of all components observing that object.

### 2.3 Temporary Variable Pattern

For intermediate computations that don't need UI binding, use plain TypeScript variables (no decorator) to avoid reactive overhead.

```typescript
// Bad: reactive overhead for non-UI data
@State private tempResult: string = ''

// Good: plain variable, no reactivity cost
private tempResult: string = ''
```

### 2.4 @Computed for Derived State (V2)

Use `@Computed` to cache derived values. The computation only re-runs when tracked dependencies change.

```typescript
@ObservedV2
class ViewModel {
  @Trace items: Item[] = []
  @Trace filter: string = ''

  @Computed get filteredItems(): Item[] {
    return this.items.filter(item => item.name.includes(this.filter))
  }
}
```

### 2.5 State Update Batching

Minimize the number of `@State` assignments in a single function. Each assignment can trigger a separate re-render pass. Batch updates when possible.

```typescript
// Bad: multiple re-renders
this.isLoading = true
this.error = null
this.data = result

// Good: restructure to minimize intermediate states
this.updateState({ isLoading: false, error: null, data: result })
```

### 2.6 freezeWhenInactive

Apply `freezeWhenInactive` to components in non-visible tabs (e.g., TabContent). Frozen components stop reactive updates entirely, saving CPU.

```typescript
TabContent() {
  MyComponent()
}
.tabContentModifier({ freezeWhenInactive: true })
```

---

## 3. Component Lifecycle and Re-Render Optimization

### 3.1 @Reusable for Component Recycling

Mark components that are repeatedly created/destroyed (e.g., list items) with `@Reusable`. The framework reuses component instances instead of destroying and recreating them.

```typescript
@Reusable
@Component
struct MediaItem {
  aboutToReuse(params: Record<string, Object>) {
    // Reset state for reused instance
    this.title = params.title as string
  }
}
```

Applicable to `ForEach` and `LazyForEach` child components.

### 3.2 LazyForEach with cacheCount

Use `LazyForEach` instead of `ForEach` for large lists. Set `cacheCount` to pre-render items outside the visible area.

```typescript
List() {
  LazyForEach(this.dataSource, (item: Item) => {
    ListItem() {
      MediaItem({ item: item })
    }
  }, (item: Item) => item.id.toString())
}
.cachedCount(5)  // render 5 items beyond viewport on each side
```

- `ForEach` creates all items upfront; `LazyForEach` creates only visible + cached items.
- Always provide a stable key generator function to avoid unnecessary re-creations.

### 3.3 ListItemReuseStrategy

For lists with mixed item types, configure reuse strategy:

```typescript
List() {
  LazyForEach(this.dataSource, (item) => {
    ListItem() { /* ... */ }
  })
}
.reuseThreshold(0.5)  // reuse when scroll offset exceeds 50% of item height
```

### 3.4 Reduce Layout Nesting with RelativeContainer

`RelativeContainer` uses a flat constraint model instead of nested flex/stack, reducing layout pass depth.

```typescript
// Prefer flat RelativeContainer over deeply nested Row/Column
RelativeContainer() {
  Text('Title')
    .alignRules({ top: { anchor: '__container__', align: VerticalAlign.Top } })
  Image('cover.jpg')
    .alignRules({ right: { anchor: '__container__', align: HorizontalAlign.End } })
}
```

Benefits: fewer layout passes, better performance for complex card layouts.

### 3.5 Conditional Rendering Best Practices

- Use `if/else` for mutually exclusive branches (framework optimizes these).
- Avoid deeply nested ternary expressions in build().
- Move complex conditional logic to `@Builder` functions for clarity and potential reuse.

### 3.6 Relevance to jellyfin-harmonyos

- Apply `@Reusable` to list item components in settings and downloads pages.
- Use `LazyForEach` with `cachedCount` for any large media lists.
- Consider `RelativeContainer` for media card layouts to reduce nesting depth.

---

## 4. Soft Keyboard (Input Method) UI Optimization

### 4.1 KeyboardAvoidMode

HarmonyOS provides two keyboard avoidance modes:

| Mode | Behavior | Best For |
|---|---|---|
| `RESIZE` | Resizes the window/layout to fit above keyboard | Forms, chat interfaces |
| `OFFSET` | Shifts the focused input upward without resizing | Fixed layouts, media overlays |

```typescript
// Set in EntryAbility or WindowStage
window.getLastWindow(this.context).then(win => {
  win.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE)
})
```

### 4.2 expandSafeArea for Keyboard

Use `expandSafeArea([SafeAreaType.KEYBOARD])` on containers that should adapt to keyboard presence.

```typescript
Column() {
  // content
  TextInput()
}
.expandSafeArea([SafeAreaType.KEYBOARD])
```

This is the recommended approach over manual offset calculation.

### 4.3 NavDestinationMode.DIALOG

When using Navigation, set `NavDestinationMode.DIALOG` for pages that contain input fields. This prevents the navigation container from applying its own keyboard avoidance logic on top of the system's.

### 4.4 Avoid Redundant Keyboard Handling

Do not combine multiple keyboard avoidance mechanisms (e.g., both `expandSafeArea` and manual `translate` offset). Choose one approach and apply it consistently.

### 4.5 Relevance to jellyfin-harmonyos

- The server connection page (`ConnectPage`) has text inputs; ensure proper `KeyboardAvoidMode.RESIZE`.
- Any future search or login UI should use `expandSafeArea([SafeAreaType.KEYBOARD])`.

---

## 5. Async Programming and TaskPool Thread Optimization

### 5.1 TaskPool vs Worker

| Aspect | TaskPool | Worker |
|---|---|---|
| Thread management | Auto-managed pool (auto-scaling) | Manual creation/lifecycle |
| Max threads | Auto-determined by system | Up to 64 (managed by developer) |
| Task priority | Supports HIGH/MEDIUM/LOW/IMMEDIATE | No priority system |
| Cancellation | Supports task cancellation | Requires custom message protocol |
| TaskGroup | Supports grouped tasks with results | Not available |
| Use case | Most background work | Long-running dedicated threads |
| Serialization | Structured clone + @Sendable | Structured clone |

**Prefer TaskPool for most background operations.** Worker is only needed for dedicated long-running threads.

### 5.2 TaskPool Usage Pattern

```typescript
import { taskpool } from '@kit.ArkTS'

@Concurrent
function processMediaData(data: MediaData[]): ProcessedData[] {
  // Heavy computation off main thread
  return data.map(item => processItem(item))
}

// Execute
const task = new taskpool.Task(processMediaData, rawData)
const result = await taskpool.execute(task)
```

### 5.3 TaskGroup for Parallel Work

```typescript
const taskGroup = new taskpool.TaskGroup()
for (const chunk of dataChunks) {
  taskGroup.addTask(new taskpool.Task(processChunk, chunk))
}
const results = await taskpool.execute(taskGroup)
```

### 5.4 @Sendable for Cross-Thread Data

Use `@Sendable` decorator on classes that need to cross thread boundaries. This enables shared-memory transfer instead of structured clone, reducing serialization overhead.

```typescript
@Sendable
class MediaItem {
  constructor(public id: string, public title: string) {}
}
```

### 5.5 Performance Benchmarks

- TaskPool with TaskGroup achieves 50-65% concurrency gains over sequential processing for CPU-bound work.
- Auto-scaling thread pool adapts to device core count without manual tuning.

### 5.6 Relevance to jellyfin-harmonyos

- Database operations in `JellyfinDatabase` (RdbStore) already run async; ensure heavy SQL queries don't block UI.
- Media metadata processing and download chunk management are good candidates for TaskPool.
- Consider `@Sendable` for `entity/` classes that may be passed to background tasks.

---

## 6. Event System (Emitter) Performance Optimization

### 6.1 Subscription Lifecycle Management

Always unsubscribe in `aboutToDisappear` (or equivalent cleanup). Dangling subscriptions cause memory leaks and duplicate event handling.

```typescript
aboutToAppear() {
  emitter.on({ eventId: EVENT_PLAYBACK_STATE }, this.handlePlayback)
}

aboutToDisappear() {
  emitter.off(EVENT_PLAYBACK_STATE)  // Always clean up
}
```

### 6.2 Avoid Duplicate Subscriptions

Guard against re-subscribing in `aboutToAppear` if the component might be reused or re-attached.

```typescript
private subscribed: boolean = false

aboutToAppear() {
  if (!this.subscribed) {
    emitter.on({ eventId: EVENT_ID }, this.handler)
    this.subscribed = true
  }
}
```

### 6.3 Avoid Blocking Operations in Callbacks

Emitter callbacks run on the main thread. Do not perform synchronous I/O, heavy computation, or synchronous HTTP requests inside event handlers.

```typescript
// Bad: blocks main thread
emitter.on({ eventId: EVENT_ID }, () => {
  const data = db.querySync()  // BLOCKS UI
})

// Good: offload to async
emitter.on({ eventId: EVENT_ID }, async () => {
  const data = await db.query()  // non-blocking
})
```

### 6.4 Minimize Event Payload Size

The emitter serializes event data. Keep payloads small and avoid sending large objects or arrays through emitter events. For large data, use a shared store or database reference instead.

### 6.5 Use Specific Event IDs

Avoid using a single "catch-all" event ID with a discriminator field. Use distinct event IDs for distinct event types. This reduces the number of callbacks invoked per event dispatch.

```typescript
// Bad: single event with type discrimination
emitter.on({ eventId: 1 }, (data) => {
  switch (data.type) { /* all listeners check all types */ }
})

// Good: separate events
emitter.on({ eventId: EVENT_PLAYBACK }, handlePlayback)
emitter.on({ eventId: EVENT_DOWNLOAD }, handleDownload)
```

### 6.6 Relevance to jellyfin-harmonyos

The app uses `ActivityEventHandler` (wrapping `@ohos.events.emitter`) as its primary cross-component communication mechanism. Key optimizations:
- Audit all `on()` calls for matching `off()` in cleanup paths.
- Ensure event handlers in bridge components (`BridgeManager`, `NativePlayer`) don't perform synchronous work.
- Review `ActivityEventHandler` for opportunities to use more specific event IDs.

---

## Quick Reference Checklist

| Optimization | Impact | Effort | Priority |
|---|---|---|---|
| `initializeWebEngine()` early | High (100ms+) | Low | P0 |
| `prepareForPageLoad()` before navigation | Medium (40-50ms) | Low | P0 |
| `@Track` on hot state fields | Medium | Low | P1 |
| `@Reusable` on list items | Medium | Low | P1 |
| `LazyForEach` + `cachedCount` | High for large lists | Medium | P1 |
| `freezeWhenInactive` on tabs | Medium | Low | P1 |
| Emitter subscription cleanup | Medium (memory) | Low | P1 |
| `KeyboardAvoidMode` proper setup | Medium (UX) | Low | P2 |
| `expandSafeArea` for inputs | Low-Medium | Low | P2 |
| TaskPool for heavy computation | High (CPU) | Medium | P2 |
| `RelativeContainer` to reduce nesting | Low-Medium | Medium | P3 |
| Pre-rendering WebView pages | Medium | High | P3 |

---

## Sources

- Huawei Developer Documentation: WebView performance, state management, ArkUI optimization
- Zhihu: WebView pre-rendering and initialization optimization (p/696850579)
- CSDN: WebView performance with NodeController pre-rendering (article/148534787)
- Tencent Cloud: State management V1 vs V2 comparison (article/2474761)
- CSDN: TaskPool vs Worker benchmarks (article/143308088)
- Juejin: ArkUI layout and LazyForEach optimization (post/7540652656911024164)
- Juejin: Soft keyboard avoidance patterns (post/7476991471972450330)
