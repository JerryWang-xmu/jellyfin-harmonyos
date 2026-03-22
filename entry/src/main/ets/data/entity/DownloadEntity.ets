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
 * Download entity representing a downloaded media item.
 * Migrated from Android Room Entity to HarmonyOS ArkTS.
 *
 * Note: The mediaSource field stores JSON-serialized LocalJellyfinMediaSource data.
 */

export enum DownloadStatus {
  PENDING = 'pending',
  DOWNLOADING = 'downloading',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

export interface DownloadEntity {
  id?: number;
  itemId: string;
  mediaSource: string; // JSON string of LocalJellyfinMediaSource
  fileName: string;
  filePath: string;
  progress: number;    // 0-100
  status: DownloadStatus;
}

export class DownloadEntityHelper {
  static readonly TABLE_NAME: string = 'Download';
  static readonly ID: string = 'id';
  static readonly ITEM_ID: string = 'item_id';
  static readonly MEDIA_SOURCE: string = 'media_source';
  static readonly FILE_NAME: string = 'file_name';
  static readonly FILE_PATH: string = 'file_path';
  static readonly PROGRESS: string = 'progress';
  static readonly STATUS: string = 'status';

  static readonly BYTES_PER_BINARY_UNIT: number = 1024;

  /**
   * Create a new DownloadEntity
   */
  static create(itemId: string, mediaSourceJson: string): DownloadEntity {
    const entity: DownloadEntity = {
      itemId: itemId,
      mediaSource: mediaSourceJson,
      fileName: '',
      filePath: '',
      progress: 0,
      status: DownloadStatus.PENDING
    };
    return entity;
  }

  /**
   * Create a full DownloadEntity with all fields (for database results)
   */
  static fromValues(
    id: number,
    itemId: string,
    mediaSource: string,
    fileName: string,
    filePath: string,
    progress: number,
    status: string
  ): DownloadEntity {
    return {
      id: id,
      itemId: itemId,
      mediaSource: mediaSource,
      fileName: fileName,
      filePath: filePath,
      progress: progress,
      status: status as DownloadStatus
    };
  }

  /**
   * Get CREATE TABLE SQL statement
   */
  static getCreateTableSql(): string {
    return 'CREATE TABLE IF NOT EXISTS Download (' +
      'id           INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'item_id      TEXT NOT NULL UNIQUE, ' +
      'media_source TEXT NOT NULL, ' +
      'file_name    TEXT NOT NULL DEFAULT \'\', ' +
      'file_path    TEXT NOT NULL DEFAULT \'\', ' +
      'progress     INTEGER NOT NULL DEFAULT 0, ' +
      'status       TEXT NOT NULL DEFAULT \'pending\'' +
      ')';
  }

  /**
   * Get CREATE INDEX SQL statement
   */
  static getCreateIndexSql(): string {
    return 'CREATE UNIQUE INDEX IF NOT EXISTS index_Download_item_id ON Download (item_id)';
  }

  /**
   * Format file size to human-readable string
   */
  static formatFileSize(bytes: number): string {
    const units: string[] = ['B', 'KB', 'MB', 'GB', 'TB'];
    let size: number = bytes;
    let unitIndex: number = 0;

    while (size >= DownloadEntityHelper.BYTES_PER_BINARY_UNIT && unitIndex < units.length - 1) {
      size = size / DownloadEntityHelper.BYTES_PER_BINARY_UNIT;
      unitIndex = unitIndex + 1;
    }

    return size.toFixed(2) + ' ' + units[unitIndex];
  }
}
