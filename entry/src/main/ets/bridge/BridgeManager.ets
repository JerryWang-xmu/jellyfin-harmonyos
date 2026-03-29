/*
 * Jellyfin for HarmonyOS
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
 * Jellyfin HarmonyOS - 桥接管理器
 * 统一管理所有 WebView 桥接接口的注册和生命周期
 * 迁移自 jellyfin-android/webapp 相关桥接初始化代码
 */

import webview from '@ohos.web.webview';
import { BridgeChannel } from './BridgeChannel';
import {
  NativeInterface,
  NativeInterfaceProxy,
  createNativeInterfaceProxy
} from './NativeInterface';
import {
  NativePlayer,
  NativePlayerProxy,
  createNativePlayerProxy
} from './NativePlayer';
import {
  ExternalPlayer,
  ExternalPlayerProxy,
  createExternalPlayerProxy
} from './ExternalPlayer';
import {
  MediaSegments,
  MediaSegmentsProxy,
  createMediaSegmentsProxy
} from './MediaSegments';
import { ActivityEventHandler } from '../core/event/ActivityEventHandler';
import { AppPreferences } from '../core/preferences/AppPreferences';
import { Logger } from '../common/utils/Logger';

/**
 * 桥接管理器配置
 */
export interface BridgeManagerConfig {
  context: Context;
  controller: webview.WebviewController;
  eventHandler: ActivityEventHandler;
  preferences: AppPreferences;
}

/**
 * 桥接接口集合
 */
export interface BridgeInterfaces {
  nativeInterface: NativeInterface;
  nativePlayer: NativePlayer;
  externalPlayer: ExternalPlayer;
  mediaSegments: MediaSegments;
}

/**
 * 桥接代理集合
 */
export interface BridgeProxies {
  NativeInterface: NativeInterfaceProxy;
  NativePlayer: NativePlayerProxy;
  ExternalPlayer: ExternalPlayerProxy;
  MediaSegments: MediaSegmentsProxy;
}

/**
 * 桥接管理器
 * 负责初始化和管理所有桥接组件
 */
interface BridgeNamesType {
  NATIVE_INTERFACE: string;
  NATIVE_PLAYER: string;
  EXTERNAL_PLAYER: string;
  MEDIA_SEGMENTS: string;
}

export class BridgeManager {
  private static readonly TAG: string = 'BridgeManager';
  private static readonly BRIDGE_NAMES: BridgeNamesType = {
    NATIVE_INTERFACE: 'NativeInterface',
    NATIVE_PLAYER: 'NativePlayer',
    EXTERNAL_PLAYER: 'ExternalPlayer',
    MEDIA_SEGMENTS: 'MediaSegments'
  };

  private context: Context;
  private controller: webview.WebviewController;
  private eventHandler: ActivityEventHandler;
  private preferences: AppPreferences;

  // 桥接组件
  private bridgeChannel: BridgeChannel | null = null;
  private interfaces: BridgeInterfaces | null = null;
  private proxies: BridgeProxies | null = null;

  // 状态
  private initialized: boolean = false;

  /**
   * 代理注册标志。
   * 一旦 JavaScript 代理通过 registerJavaScriptProxy + refresh 注册完毕，
   * 后续的 onControllerAttached 回调不应再重复整个初始化流程（避免页面重载闪烁）。
   * 仅在 destroy() 或 reinitialize() 中重置。
   */
  private isBridgeInitialized: boolean = false;

  constructor(config: BridgeManagerConfig) {
    this.context = config.context;
    this.controller = config.controller;
    this.eventHandler = config.eventHandler;
    this.preferences = config.preferences;

    Logger.i(BridgeManager.TAG, 'BridgeManager created');
  }

  /**
   * 初始化桥接管理器。
   * 幂等方法：如果代理已注册（isBridgeInitialized=true），直接返回，
   * 避免导航返回时重复初始化导致 WebView 页面重载。
   */
  async initialize(): Promise<void> {
    if (this.isBridgeInitialized) {
      Logger.i(BridgeManager.TAG, 'Bridge proxies already registered, skipping re-initialization');
      return;
    }

    if (this.initialized) {
      Logger.w(BridgeManager.TAG, 'BridgeManager already initialized');
      return;
    }

    try {
      Logger.i(BridgeManager.TAG, 'Initializing BridgeManager...');

      // 1. 创建桥接通道
      this.bridgeChannel = new BridgeChannel({
        controller: this.controller,
        onJavaScriptError: (error: Error) => {
          Logger.e(BridgeManager.TAG, 'JavaScript error: %{public}s', error.message);
        }
      });
      await this.bridgeChannel.initialize();

      // 2. 创建桥接接口
      this.interfaces = await this.createInterfaces();

      // 3. 创建代理
      this.proxies = this.createProxies();

      // 4. 注册 JavaScript 代理（包含唯一一次 refresh 调用）
      this.registerJavaScriptProxies();

      this.initialized = true;
      this.isBridgeInitialized = true;
      Logger.i(BridgeManager.TAG, 'BridgeManager initialized successfully');
    } catch (error) {
      Logger.e(BridgeManager.TAG, 'Failed to initialize BridgeManager: %{public}s', JSON.stringify(error));
      throw new Error(JSON.stringify(error));
    }
  }

  /**
   * 创建桥接接口
   */
  private async createInterfaces(): Promise<BridgeInterfaces> {
    const nativeInterface = new NativeInterface(
      this.context,
      this.eventHandler,
      this.preferences
    );
    nativeInterface.setBridgeChannel(this.bridgeChannel!);
    // initialize() is currently a no-op (cache is built in constructor),
    // but we await it for future-proofing in case async init is needed later.
    await nativeInterface.initialize();

    const nativePlayer = new NativePlayer(
      this.preferences,
      this.eventHandler
    );

    const externalPlayer = new ExternalPlayer(
      this.context,
      this.preferences
    );
    externalPlayer.setBridgeChannel(this.bridgeChannel!);

    const mediaSegments = new MediaSegments();

    return {
      nativeInterface,
      nativePlayer,
      externalPlayer,
      mediaSegments
    };
  }

  /**
   * 创建代理对象
   */
  private createProxies(): BridgeProxies {
    if (!this.interfaces) {
      throw new Error('Interfaces not created');
    }

    return {
      NativeInterface: createNativeInterfaceProxy(this.interfaces.nativeInterface),
      NativePlayer: createNativePlayerProxy(this.interfaces.nativePlayer),
      ExternalPlayer: createExternalPlayerProxy(this.interfaces.externalPlayer),
      MediaSegments: createMediaSegmentsProxy(this.interfaces.mediaSegments)
    };
  }

  /**
   * 注册 JavaScript 代理到 WebView
   */
  private registerJavaScriptProxies(): void {
    if (!this.proxies) {
      throw new Error('Proxies not created');
    }

    try {
      // 注册 NativeInterface
      this.controller.registerJavaScriptProxy(
        this.proxies.NativeInterface,
        BridgeManager.BRIDGE_NAMES.NATIVE_INTERFACE,
        [
          'getDeviceInformation',
          'enableFullscreen',
          'disableFullscreen',
          'openUrl',
          'updateMediaSession',
          'hideMediaSession',
          'updateVolumeLevel',
          'downloadFiles',
          'openDownloadManager',
          'openClientSettings',
          'openDownloads',
          'openServerSelection',
          'exitApp',
          'execCast'
        ]
      );

      // 注册 NativePlayer
      this.controller.registerJavaScriptProxy(
        this.proxies.NativePlayer,
        BridgeManager.BRIDGE_NAMES.NATIVE_PLAYER,
        [
          'isEnabled',
          'loadPlayer',
          'pausePlayer',
          'resumePlayer',
          'stopPlayer',
          'destroyPlayer',
          'seekTicks',
          'seekMs',
          'setVolume'
        ]
      );

      // 注册 ExternalPlayer
      this.controller.registerJavaScriptProxy(
        this.proxies.ExternalPlayer,
        BridgeManager.BRIDGE_NAMES.EXTERNAL_PLAYER,
        ['isEnabled', 'initPlayer']
      );

      // 注册 MediaSegments
      this.controller.registerJavaScriptProxy(
        this.proxies.MediaSegments,
        BridgeManager.BRIDGE_NAMES.MEDIA_SEGMENTS,
        ['setSegmentTypeAction', 'getSupportedSegmentTypes']
      );

      // 刷新代理注册
      this.controller.refresh();

      Logger.i(BridgeManager.TAG, 'JavaScript proxies registered');
    } catch (error) {
      Logger.e(BridgeManager.TAG, 'Failed to register JavaScript proxies: %{public}s', JSON.stringify(error));
      throw new Error(JSON.stringify(error));
    }
  }

  /**
   * 获取桥接通道
   */
  getBridgeChannel(): BridgeChannel | null {
    return this.bridgeChannel;
  }

  /**
   * 获取桥接接口
   */
  getInterfaces(): BridgeInterfaces | null {
    return this.interfaces;
  }

  /**
   * 获取代理对象
   */
  getProxies(): BridgeProxies | null {
    return this.proxies;
  }

  /**
   * 执行 JavaScript
   */
  async runJavaScript(script: string): Promise<string | null> {
    if (!this.bridgeChannel) {
      Logger.w(BridgeManager.TAG, 'BridgeChannel not available');
      return null;
    }

    const result = await this.bridgeChannel.runJavaScript(script);
    return result.success ? result.result ?? null : null;
  }

  /**
   * 调用 JavaScript 函数
   */
  async callFunction(functionName: string, ...args: (string | number | boolean | object | null)[]): Promise<void> {
    if (!this.bridgeChannel) {
      Logger.w(BridgeManager.TAG, 'BridgeChannel not available');
      return;
    }

    await this.bridgeChannel.callFunction(functionName, ...args);
  }

  /**
   * 检查是否已初始化
   */
  isInitialized(): boolean {
    return this.initialized;
  }

  /**
   * 销毁桥接管理器。
   * 清理所有接口的 listeners、bridgeChannel 引用，并重置状态标志。
   */
  destroy(): void {
    Logger.i(BridgeManager.TAG, 'Destroying BridgeManager...');

    // 清理各接口的 listeners
    if (this.interfaces) {
      this.interfaces.nativePlayer.clearListeners();
    }

    // 销毁桥接通道
    this.bridgeChannel?.destroy();
    this.bridgeChannel = null;

    // 清除引用
    this.interfaces = null;
    this.proxies = null;

    this.initialized = false;
    this.isBridgeInitialized = false;
    Logger.i(BridgeManager.TAG, 'BridgeManager destroyed');
  }

  /**
   * 强制重新初始化桥接管理器。
   * 用于需要完全重建的场景（如切换服务器）。
   * 先销毁当前状态，再执行完整初始化。
   */
  async reinitialize(): Promise<void> {
    Logger.i(BridgeManager.TAG, 'Reinitializing BridgeManager...');
    this.destroy();
    await this.initialize();
    Logger.i(BridgeManager.TAG, 'BridgeManager reinitialized');
  }
}

/**
 * 创建桥接管理器
 */
export function createBridgeManager(config: BridgeManagerConfig): BridgeManager {
  return new BridgeManager(config);
}
