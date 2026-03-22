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
 * Server entity representing a Jellyfin server connection.
 * Migrated from Android Room Entity to HarmonyOS ArkTS.
 */

export interface ServerEntity {
  id: number;
  hostname: string;
  lastUsedTimestamp: number;
}

/**
 * Server entity without ID (for insertion)
 */
export interface ServerEntityInput {
  hostname: string;
  lastUsedTimestamp: number;
}

export class ServerEntityHelper {
  static readonly TABLE_NAME: string = 'Server';
  static readonly ID: string = 'id';
  static readonly HOSTNAME: string = 'hostname';
  static readonly LAST_USED_TIMESTAMP: string = 'last_used_timestamp';

  /**
   * Create a new ServerEntityInput with auto-generated timestamp
   */
  static create(hostname: string): ServerEntityInput {
    const entity: ServerEntityInput = {
      hostname: hostname,
      lastUsedTimestamp: Date.now()
    };
    return entity;
  }

  /**
   * Create a ServerEntity with specific id (for database results)
   */
  static fromValues(id: number, hostname: string, lastUsedTimestamp: number): ServerEntity {
    const entity: ServerEntity = {
      id: id,
      hostname: hostname,
      lastUsedTimestamp: lastUsedTimestamp
    };
    return entity;
  }

  /**
   * Get CREATE TABLE SQL statement
   */
  static getCreateTableSql(): string {
    return 'CREATE TABLE IF NOT EXISTS Server (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'hostname TEXT UNIQUE NOT NULL, ' +
      'last_used_timestamp INTEGER NOT NULL)';
  }

  /**
   * Get CREATE INDEX SQL statement
   */
  static getCreateIndexSql(): string {
    return 'CREATE UNIQUE INDEX IF NOT EXISTS index_Server_hostname ON Server (hostname)';
  }
}
