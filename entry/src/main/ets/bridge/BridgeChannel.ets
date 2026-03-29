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
 * Jellyfin HarmonyOS - WebView 桥接通道管理器
 * 负责管理 WebView 与 Native 之间的双向通信
 * 迁移自 jellyfin-android/webapp/WebappFunctionChannel.kt
 */

import webview from '@ohos.web.webview';
import { Logger } from '../common/utils/Logger';

/**
 * 桥接通道配置
 */
export interface BridgeChannelConfig {
  controller: webview.WebviewController;
  onJavaScriptError?: (error: Error) => void;
}

/**
 * JavaScript 执行结果
 */
export interface JavaScriptResult {
  success: boolean;
  result?: string;
  error?: string;
}

/**
 * 桥接通道类
 * 封装 WebView 的 JavaScript 执行功能
 *
 * 支持两种调用模式:
 * 1. 立即执行: callFunction() / runJavaScript() — 立即执行单次 JS 调用
 * 2. 排队批处理: enqueueFunction() + flushQueue() — 将多个调用合并为一次 runJavaScript 执行
 */
export class BridgeChannel {
  private static readonly TAG: string = 'BridgeChannel';

  private controller: webview.WebviewController;
  private onJavaScriptError?: (error: Error) => void;
  private initialized: boolean = false;

  // ---- 消息队列 ----
  private messageQueue: string[] = [];
  private queueFlushScheduled: boolean = false;

  // ---- 条件化日志 ----
  private verboseLogging: boolean = false;

  constructor(config: BridgeChannelConfig) {
    this.controller = config.controller;
    this.onJavaScriptError = config.onJavaScriptError;
    Logger.i(BridgeChannel.TAG, 'BridgeChannel created');
  }

  /**
   * 初始化桥接通道
   */
  async initialize(): Promise<void> {
    if (this.initialized) {
      Logger.w(BridgeChannel.TAG, 'BridgeChannel already initialized');
      return;
    }

    try {
      // 等待 WebView 准备就绪
      this.initialized = true;
      Logger.i(BridgeChannel.TAG, 'BridgeChannel initialized');
    } catch (error) {
      Logger.e(BridgeChannel.TAG, 'Failed to initialize BridgeChannel: %{public}s', JSON.stringify(error));
      const err = error as Error;
      throw new Error('Failed to initialize BridgeChannel: ' + (err?.message ?? 'unknown error'));
    }
  }

  /**
   * 执行 JavaScript 代码（立即执行）
   * @param script JavaScript 代码
   * @returns 执行结果
   */
  async runJavaScript(script: string): Promise<JavaScriptResult> {
    if (!this.initialized) {
      Logger.w(BridgeChannel.TAG, 'BridgeChannel not initialized');
      return { success: false, error: 'BridgeChannel not initialized' };
    }

    try {
      if (this.verboseLogging) {
        Logger.d(BridgeChannel.TAG, 'Running JavaScript: %{public}s', script.substring(0, 100));
      }
      const result = await this.controller.runJavaScript(script);
      if (this.verboseLogging) {
        Logger.d(BridgeChannel.TAG, 'JavaScript result: %{public}s', result);
      }
      return { success: true, result };
    } catch (error) {
      const err = error as Error;
      Logger.e(BridgeChannel.TAG, 'JavaScript execution failed: %{public}s', err.message);
      this.onJavaScriptError?.(err);
      return { success: false, error: err.message };
    }
  }

  /**
   * 调用全局函数（立即执行）
   * @param functionName 函数名 (如 "window.NativeShell.notifyEvent")
   * @param args 参数列表
   */
  async callFunction(functionName: string, ...args: (string | number | boolean | object | null)[]): Promise<JavaScriptResult> {
    const argsStr = args.map(arg => this.serializeArgument(arg)).join(', ');
    const script = `${functionName}(${argsStr})`;
    return this.runJavaScript(script);
  }

  /**
   * 将函数调用加入队列（延迟执行，等待 flushQueue 合并）
   * @param functionName 函数名
   * @param args 参数列表
   */
  enqueueFunction(functionName: string, ...args: (string | number | boolean | object | null)[]): void {
    const argsStr = args.map(arg => this.serializeArgument(arg)).join(', ');
    const script = `${functionName}(${argsStr})`;
    this.messageQueue.push(script);

    if (!this.queueFlushScheduled) {
      this.queueFlushScheduled = true;
    }
  }

  /**
   * 刷新队列：将所有排队的 JS 调用合并为一次 runJavaScript 执行
   * @returns 合并执行的结果
   */
  async flushQueue(): Promise<JavaScriptResult> {
    this.queueFlushScheduled = false;

    if (this.messageQueue.length === 0) {
      return { success: true };
    }

    if (!this.initialized) {
      Logger.w(BridgeChannel.TAG, 'BridgeChannel not initialized, flushing skipped');
      this.messageQueue = [];
      return { success: false, error: 'BridgeChannel not initialized' };
    }

    // 将所有脚本用分号连接成一个合并脚本
    const mergedScript = this.messageQueue.join(';');
    const count = this.messageQueue.length;
    this.messageQueue = [];

    try {
      if (this.verboseLogging) {
        Logger.d(BridgeChannel.TAG, 'Flushing %{public}d queued JS calls', String(count));
        Logger.d(BridgeChannel.TAG, 'Running JavaScript (batch): %{public}s', mergedScript.substring(0, 200));
      }
      const result = await this.controller.runJavaScript(mergedScript);
      if (this.verboseLogging) {
        Logger.d(BridgeChannel.TAG, 'Batch JavaScript result: %{public}s', result);
      }
      return { success: true, result };
    } catch (error) {
      const err = error as Error;
      Logger.e(BridgeChannel.TAG, 'Batch JavaScript execution failed: %{public}s', err.message);
      this.onJavaScriptError?.(err);
      return { success: false, error: err.message };
    }
  }

  /**
   * 获取当前队列中的调用数量
   */
  getQueueSize(): number {
    return this.messageQueue.length;
  }

  /**
   * 设置是否启用详细日志
   * @param enabled true 启用 "Running JavaScript: ..." 日志; false 只保留错误日志
   */
  setVerboseLogging(enabled: boolean): void {
    this.verboseLogging = enabled;
    Logger.i(BridgeChannel.TAG, 'Verbose logging %{public}s', enabled ? 'enabled' : 'disabled');
  }

  /**
   * 查询当前详细日志状态
   */
  isVerboseLogging(): boolean {
    return this.verboseLogging;
  }

  /**
   * 调用 window 上的方法
   * @param methodName 方法名
   * @param args 参数
   */
  async callWindowMethod(methodName: string, ...args: (string | number | boolean | object | null)[]): Promise<JavaScriptResult> {
    return this.callFunction(`window.${methodName}`, ...args);
  }

  /**
   * 通知外部播放器事件
   * @param event 事件名称
   * @param parameters 参数
   */
  async notifyExternalPlayerEvent(event: string, parameters: string = ''): Promise<JavaScriptResult> {
    return this.callFunction(`window.ExtPlayer.notify${event}`, parameters);
  }

  /**
   * 通知媒体会话更新
   */
  async notifyMediaSessionUpdate(): Promise<JavaScriptResult> {
    return this.callWindowMethod('NativeShell', 'updateMediaSession');
  }

  /**
   * Cast 回调
   * @param action 动作名称
   * @param keep 是否保持回调
   * @param err 错误信息
   * @param result 结果
   */
  async castCallback(action: string, keep: boolean, err: string | null, result: string | null): Promise<JavaScriptResult> {
    const errArg = err ? `"${err}"` : 'null';
    const resultArg = result ? result : 'null';
    return this.callFunction(`window.NativeShell.castCallback`, action, keep, errArg, resultArg);
  }

  /**
   * 序列化参数
   */
  private serializeArgument(arg: string | number | boolean | object | null): string {
    if (arg === null || arg === undefined) {
      return 'null';
    }
    if (typeof arg === 'string') {
      return `"${arg.replace(/"/g, '\\"')}"`;
    }
    if (typeof arg === 'number' || typeof arg === 'boolean') {
      return String(arg);
    }
    if (typeof arg === 'object') {
      return JSON.stringify(arg);
    }
    return 'null';
  }

  /**
   * 检查是否已初始化
   */
  isInitialized(): boolean {
    return this.initialized;
  }

  /**
   * 销毁通道
   */
  destroy(): void {
    this.initialized = false;
    this.messageQueue = [];
    this.queueFlushScheduled = false;
    Logger.i(BridgeChannel.TAG, 'BridgeChannel destroyed');
  }
}
