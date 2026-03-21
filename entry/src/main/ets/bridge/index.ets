/**
 * Jellyfin HarmonyOS - 桥接模块导出
 * 统一导出所有桥接相关的类和接口
 */

// 桥接通道
export { BridgeChannel, BridgeChannelConfig, JavaScriptResult } from './BridgeChannel';

// JavaScript 回调
export {
  JavascriptCallback,
  SimpleJavascriptCallback,
  CastCallback,
  CallbackManager,
  CallbackResult
} from './JavascriptCallback';

// NativeInterface 桥接
export {
  NativeInterface,
  NativeInterfaceProxy,
  DeviceInformation,
  createNativeInterfaceProxy
} from './NativeInterface';

// NativePlayer 桥接
export {
  NativePlayer,
  NativePlayerProxy,
  PlayerEventType,
  PlayerEvent,
  createNativePlayerProxy
} from './NativePlayer';

// ExternalPlayer 桥接
export {
  ExternalPlayer,
  ExternalPlayerProxy,
  ExternalPlayOptions,
  MediaSourceInfo,
  MediaStreamInfo,
  ExternalSubtitleStream,
  ExternalPlayerEvents,
  createExternalPlayerProxy
} from './ExternalPlayer';

// MediaSegments 桥接
export {
  MediaSegments,
  MediaSegmentsProxy,
  MediaSegmentRepository,
  DefaultMediaSegmentRepository,
  MediaSegmentType,
  MediaSegmentAction,
  MediaSegment,
  SUPPORTED_SEGMENT_TYPES,
  createMediaSegmentsProxy
} from './MediaSegments';

// 桥接管理器
export {
  BridgeManager,
  BridgeManagerConfig,
  BridgeInterfaces,
  BridgeProxies,
  createBridgeManager
} from './BridgeManager';
