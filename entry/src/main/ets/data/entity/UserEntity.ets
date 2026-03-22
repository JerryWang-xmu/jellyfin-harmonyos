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
 * User entity representing a user account on a Jellyfin server.
 * Migrated from Android Room Entity to HarmonyOS ArkTS.
 */

export interface UserEntity {
  id: number;
  serverId: number;
  userId: string;
  accessToken: string | null;
  lastLoginTimestamp: number;
}

/**
 * User entity without ID (for insertion)
 */
export interface UserEntityInput {
  serverId: number;
  userId: string;
  accessToken: string | null;
  lastLoginTimestamp: number;
}

export class UserEntityHelper {
  static readonly TABLE_NAME: string = 'User';
  static readonly ID: string = 'id';
  static readonly SERVER_ID: string = 'server_id';
  static readonly USER_ID: string = 'user_id';
  static readonly ACCESS_TOKEN: string = 'access_token';
  static readonly LAST_LOGIN_TIMESTAMP: string = 'last_login_timestamp';

  /**
   * Create a new UserEntityInput with auto-generated timestamp
   */
  static create(serverId: number, userId: string, accessToken: string | null): UserEntityInput {
    const entity: UserEntityInput = {
      serverId: serverId,
      userId: userId,
      accessToken: accessToken,
      lastLoginTimestamp: Date.now()
    };
    return entity;
  }

  /**
   * Create a UserEntity with specific id (for database results)
   */
  static fromValues(
    id: number,
    serverId: number,
    userId: string,
    accessToken: string | null,
    lastLoginTimestamp: number
  ): UserEntity {
    const entity: UserEntity = {
      id: id,
      serverId: serverId,
      userId: userId,
      accessToken: accessToken,
      lastLoginTimestamp: lastLoginTimestamp
    };
    return entity;
  }

  /**
   * Get CREATE TABLE SQL statement
   */
  static getCreateTableSql(): string {
    return 'CREATE TABLE IF NOT EXISTS User (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'server_id INTEGER NOT NULL, ' +
      'user_id TEXT NOT NULL, ' +
      'access_token TEXT, ' +
      'last_login_timestamp INTEGER NOT NULL, ' +
      'FOREIGN KEY (server_id) REFERENCES Server(id), ' +
      'UNIQUE(server_id, user_id))';
  }

  /**
   * Get CREATE INDEX SQL statement
   */
  static getCreateIndexSql(): string {
    return 'CREATE UNIQUE INDEX IF NOT EXISTS index_User_server_id_user_id ON User (server_id, user_id)';
  }
}

/**
 * ServerUser is a combined entity representing a user with their associated server.
 * Equivalent to Android Room's @Embedded + @Relation.
 */
export interface ServerUser {
  user: UserEntity;
  server: import('./ServerEntity').ServerEntity;
}
