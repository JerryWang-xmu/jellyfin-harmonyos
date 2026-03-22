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
 * ConnectionHelper - 服务器 URL 验证与规范化工具
 * 负责在连接服务器前验证地址是否可达，并规范化 URL 格式
 *
 * Batch 2 网络层实现
 */

import http from '@ohos.net.http';

export interface CheckUrlSuccess {
  type: string;
  url: string;
}

export interface CheckUrlError {
  type: string;
  message: string;
}

export interface CheckUrlLoading {
  type: string;
}

export type CheckUrlState = CheckUrlSuccess | CheckUrlError | CheckUrlLoading;

export class ConnectionHelper {
  /**
   * 验证并规范化 Jellyfin 服务器 URL
   * 尝试连接 /System/Info/Public 接口确认服务器可达且为 Jellyfin 服务器
   *
   * 处理逻辑：
   * 1. 移除首尾空格
   * 2. 移除尾部斜杠
   * 3. 自动补充 http:// 协议前缀（如果缺失）
   * 4. 尝试 http 连接，失败后自动重试 https
   */
  static async checkServerUrl(enteredUrl: string): Promise<CheckUrlState> {
    try {
      // 1. 规范化 URL
      let url = enteredUrl.trim();
      if (!url) {
        const errResult: CheckUrlError = { type: 'error', message: '请输入服务器地址' };
        return errResult;
      }

      // 移除尾部斜杠
      url = url.replace(/\/+$/, '');

      // 添加协议前缀（如果缺少）
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://' + url;
      }

      // 2. 尝试连接
      const result = await ConnectionHelper.testConnection(url);
      if (result) {
        const successResult: CheckUrlSuccess = { type: 'success', url: url };
        return successResult;
      }

      // 3. 如果 http 失败，自动尝试 https
      if (url.startsWith('http://')) {
        const httpsUrl = url.replace('http://', 'https://');
        const httpsResult = await ConnectionHelper.testConnection(httpsUrl);
        if (httpsResult) {
          const successResult: CheckUrlSuccess = { type: 'success', url: httpsUrl };
          return successResult;
        }
      }

      const notFoundResult: CheckUrlError = { type: 'error', message: '无法连接到服务器，请检查地址是否正确' };
      return notFoundResult;
    } catch (err) {
      const catchResult: CheckUrlError = { type: 'error', message: '连接失败：' + (err as Error).message };
      return catchResult;
    }
  }

  /**
   * 实际测试 URL 是否可达，并验证响应为 Jellyfin 服务器
   * 通过 /System/Info/Public 端点验证，检查响应中是否包含 ServerName 或 Version 字段
   *
   * @returns true 表示目标地址是可达的 Jellyfin 服务器
   */
  private static async testConnection(url: string): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(
        `${url}/System/Info/Public`,
        {
          method: http.RequestMethod.GET,
          header: { 'Content-Type': 'application/json' },
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 10000,
          readTimeout: 10000
        }
      );
      if (response.responseCode === 200) {
        // 验证是否是 Jellyfin 服务器（响应中应有 ServerName 或 Version 字段）
        try {
          const info: ESObject = JSON.parse(response.result as string) as ESObject;
          return !!(info['ServerName'] || info['Version']);
        } catch {
          return false;
        }
      }
      return false;
    } catch {
      return false;
    } finally {
      httpRequest.destroy();
    }
  }
}
