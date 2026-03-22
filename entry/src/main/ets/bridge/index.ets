/*
 * Copyright (C) 2020-2026 Jellyfin Contributors
 * Copyright (C) 2026 WangRuijie
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * ---
 *
 * Based on jellyfin-android by Jellyfin Contributors
 * Original repository: https://github.com/jellyfin/jellyfin-android
 * Rewritten in 'ArkTS' with modifications by WangRuijie on 2026-03-22
 */

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
