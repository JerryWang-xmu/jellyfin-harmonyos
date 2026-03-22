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
 * Jellyfin HarmonyOS - JavaScript 回调基类
 * 迁移自 jellyfin-android/bridge/JavascriptCallback.kt
 * 用于处理从 Native 到 JavaScript 的异步回调
 */

import { BridgeChannel } from './BridgeChannel';
import { Logger } from '../common/utils/Logger';

/**
 * 回调结果类型
 */
export interface CallbackResult {
  keep: boolean;
  error: string | null;
  result: string | null;
}

/**
 * JavaScript 回调抽象类
 * 提供统一的回调接口，支持成功和失败两种状态
 */
export abstract class JavascriptCallback {
  private static readonly TAG: string = 'JavascriptCallback';

  protected bridgeChannel: BridgeChannel | null = null;
  protected callbackId: string;

  constructor(callbackId: string) {
    this.callbackId = callbackId;
  }

  /**
   * 设置桥接通道
   */
  setBridgeChannel(channel: BridgeChannel): void {
    this.bridgeChannel = channel;
  }

  /**
   * 抽象回调方法 - 子类必须实现
   * @param keep 是否保持回调 (可用于多次回调)
   * @param err 错误信息 (成功时为 null)
   * @param result 结果数据 (失败时为 null)
   */
  protected abstract callback(keep: boolean, err: string | null, result: string | null): void;

  /**
   * 成功回调 - 无结果
   * @param keep 是否保持回调
   */
  success(keep: boolean = false): void;

  /**
   * 成功回调 - 字符串结果
   * @param keep 是否保持回调
   * @param result 字符串结果
   */
  success(keep: boolean, result: string): void;

  /**
   * 成功回调 - 对象结果
   * @param keep 是否保持回调
   * @param result 对象结果
   */
  success(keep: boolean, result: object): void;

  /**
   * 成功回调 - 数组结果
   * @param keep 是否保持回调
   * @param result 数组结果
   */
  success(keep: boolean, result: unknown[]): void;

  // 实现
  success(keep: boolean = false, result?: string | object | unknown[]): void {
    if (result === undefined) {
      this.callback(keep, null, null);
    } else if (typeof result === 'string') {
      this.callback(keep, null, `"${result}"`);
    } else {
      // 对象或数组，序列化为 JSON
      this.callback(keep, null, JSON.stringify(result));
    }
    Logger.d(JavascriptCallback.TAG, 'Callback success [id=%{public}s, keep=%{public}s]', this.callbackId, String(keep));
  }

  /**
   * 错误回调 - 字符串消息
   * @param keep 是否保持回调
   * @param message 错误消息
   */
  error(keep: boolean, message: string): void;

  /**
   * 错误回调 - 对象
   * @param keep 是否保持回调
   * @param error 错误对象
   */
  error(keep: boolean, error: object): void;

  // 实现
  error(keep: boolean = false, errorOrMessage: string | object): void {
    if (typeof errorOrMessage === 'string') {
      this.callback(keep, `"${errorOrMessage}"`, null);
    } else {
      this.callback(keep, JSON.stringify(errorOrMessage), null);
    }
    Logger.e(JavascriptCallback.TAG, 'Callback error [id=%{public}s, keep=%{public}s]', this.callbackId, String(keep));
  }
}

/**
 * 简单回调实现
 * 直接将结果传递给回调函数
 */
export class SimpleJavascriptCallback extends JavascriptCallback {
  private callbackFn: (result: CallbackResult) => void;

  constructor(callbackId: string, callbackFn: (result: CallbackResult) => void) {
    super(callbackId);
    this.callbackFn = callbackFn;
  }

  protected callback(keep: boolean, err: string | null, result: string | null): void {
    this.callbackFn({ keep, error: err, result });
  }
}

/**
 * Cast 回调实现
 * 用于处理 Cast 操作的回调
 */
export class CastCallback extends JavascriptCallback {
  private action: string;

  constructor(action: string, bridgeChannel: BridgeChannel) {
    super(`cast_${action}`);
    this.action = action;
    this.setBridgeChannel(bridgeChannel);
  }

  protected async callback(keep: boolean, err: string | null, result: string | null): Promise<void> {
    if (this.bridgeChannel) {
      await this.bridgeChannel.castCallback(this.action, keep, err, result);
    } else {
      Logger.w(JavascriptCallback.TAG, 'BridgeChannel not set for CastCallback');
    }
  }
}

/**
 * 回调管理器
 * 管理多个回调的生命周期
 */
export class CallbackManager {
  private static readonly TAG: string = 'CallbackManager';

  private callbacks: Map<string, JavascriptCallback> = new Map();

  /**
   * 注册回调
   */
  register(callback: JavascriptCallback): void {
    // 使用反射获取 callbackId (简化实现)
    const id = (callback as unknown as Record<string, string>).callbackId;
    if (id) {
      this.callbacks.set(id, callback);
      Logger.d(CallbackManager.TAG, 'Callback registered: %{public}s', id);
    }
  }

  /**
   * 获取回调
   */
  get(callbackId: string): JavascriptCallback | undefined {
    return this.callbacks.get(callbackId);
  }

  /**
   * 移除回调
   */
  remove(callbackId: string): boolean {
    const removed = this.callbacks.delete(callbackId);
    if (removed) {
      Logger.d(CallbackManager.TAG, 'Callback removed: %{public}s', callbackId);
    }
    return removed;
  }

  /**
   * 清除所有回调
   */
  clear(): void {
    this.callbacks.clear();
    Logger.i(CallbackManager.TAG, 'All callbacks cleared');
  }

  /**
   * 获取回调数量
   */
  size(): number {
    return this.callbacks.size;
  }
}
