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
 * ApiClientController - Manages the active API client configuration.
 * Coordinates server/user persistence with live API client settings.
 *
 * Part of Batch 1 core infrastructure.
 */

import { AppPreferences } from '../core/preferences/AppPreferences';
import { ServerDao } from '../data/dao/ServerDao';
import { UserDao } from '../data/dao/UserDao';
import { ServerEntity } from '../data/entity/ServerEntity';
import { UserEntity } from '../data/entity/UserEntity';

export interface ApiClientConfig {
  baseUrl: string;
  accessToken?: string;
  deviceId: string;
  deviceName: string;
  appName: string;
  appVersion: string;
}

export interface ServerUser {
  server: ServerEntity;
  user: UserEntity;
}

export class ApiClientController {
  config: ApiClientConfig;
  private preferences: AppPreferences;
  private serverDao: ServerDao;
  private userDao: UserDao;

  constructor(preferences: AppPreferences, serverDao: ServerDao, userDao: UserDao) {
    this.preferences = preferences;
    this.serverDao = serverDao;
    this.userDao = userDao;
    this.config = {
      baseUrl: '',
      deviceId: '',
      deviceName: 'HarmonyOS Device',
      appName: 'Jellyfin',
      appVersion: '0.0.1',
    };
  }

  /**
   * 建立服务器连接（验证通过后调用）
   * 返回 serverId
   */
  async setupServer(hostname: string): Promise<number> {
    let server = await this.serverDao.getServerByHostname(hostname);
    let serverId: number;
    if (server) {
      await this.serverDao.updateLastUsed(server.id);
      serverId = server.id;
    } else {
      serverId = await this.serverDao.insertByHostname(hostname);
    }
    this.config.baseUrl = hostname;
    this.preferences.instanceUrl = hostname;
    // 保存 currentServerId
    this.preferences.currentServerId = serverId;
    return serverId;
  }

  /**
   * 设置用户（登录成功后调用）
   */
  async setupUser(serverId: number, userId: string, accessToken: string): Promise<void> {
    await this.userDao.upsert(serverId, userId, accessToken);
    this.config.accessToken = accessToken;
  }

  /**
   * 加载已保存的服务器
   */
  async loadSavedServer(): Promise<ServerEntity | null> {
    const servers = await this.serverDao.getAllServers();
    if (servers.length === 0) return null;
    const server = servers[0]; // 最近使用的第一个
    this.config.baseUrl = server.hostname;
    return server;
  }

  /**
   * 加载已保存的服务器+用户（用于自动登录）
   */
  async loadSavedServerUser(): Promise<ServerUser | null> {
    const server = await this.loadSavedServer();
    if (!server) return null;
    const users = await this.userDao.getAllForServer(server.id);
    if (users.length === 0) return null;
    const user = users[0];
    if (user.accessToken) {
      this.config.accessToken = user.accessToken;
    }
    return { server, user };
  }

  /**
   * 获取历史服务器列表
   */
  async loadPreviouslyUsedServers(): Promise<ServerEntity[]> {
    return this.serverDao.getAllServers();
  }
}
