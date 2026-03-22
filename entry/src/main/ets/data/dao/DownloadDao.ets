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
 * DownloadDao - Data Access Object for Download entity.
 * Migrated from Android Room Dao to HarmonyOS RdbStore.
 *
 * Original: org.jellyfin.mobile.data.dao.DownloadDao
 */

import relationalStore from '@ohos.data.relationalStore';
import hilog from '@ohos.hilog';

import { DownloadEntity, DownloadEntityHelper, DownloadStatus } from '../entity/DownloadEntity';

const LOG_DOMAIN: number = 0xFF00;
const LOG_TAG: string = 'DownloadDao';

export class DownloadDao {
  private rdbStore: relationalStore.RdbStore;

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  /**
   * Insert or replace a download record.
   * Equivalent to @Insert(onConflict = OnConflictStrategy.REPLACE)
   * @param entity DownloadEntity to insert/replace (without id)
   * @returns The row ID of the inserted download
   */
  async insert(entity: DownloadEntity): Promise<number> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        item_id: entity.itemId,
        media_source: entity.mediaSource,
        file_name: entity.fileName,
        file_path: entity.filePath,
        progress: entity.progress,
        status: entity.status
      };

      // Use INSERT_OR_REPLACE conflict resolution
      const rowId = await this.rdbStore.insert(
        DownloadEntityHelper.TABLE_NAME,
        valueBucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
      );
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Inserted download with rowId: %d', rowId);
      return rowId;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to insert download: %{public}s', JSON.stringify(error));
      return -1;
    }
  }

  /**
   * Insert a download by item ID and media source JSON.
   * @param itemId The media item ID
   * @param mediaSourceJson The JSON-serialized LocalJellyfinMediaSource
   * @returns The row ID of the inserted download
   */
  async insertWithMediaSource(itemId: string, mediaSourceJson: string): Promise<number> {
    const entity = DownloadEntityHelper.create(itemId, mediaSourceJson);
    return await this.insert(entity);
  }

  /**
   * Query all downloads.
   * @returns Array of DownloadEntity
   */
  async queryAll(): Promise<DownloadEntity[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(DownloadEntityHelper.TABLE_NAME);
      predicates.orderByDesc('id');

      const resultSet = await this.rdbStore.query(predicates);
      const downloads: DownloadEntity[] = [];

      try {
        while (resultSet.goToNextRow()) {
          const entity = this.mapResultSetToEntity(resultSet);
          if (entity !== null) {
            downloads.push(entity);
          }
        }
        return downloads;
      } finally {
        resultSet.close();
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to queryAll downloads: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * Query downloads by status.
   * @param status The DownloadStatus to filter by
   * @returns Array of DownloadEntity with the given status
   */
  async queryByStatus(status: DownloadStatus): Promise<DownloadEntity[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(DownloadEntityHelper.TABLE_NAME);
      predicates.equalTo('status', status);
      predicates.orderByDesc('id');

      const resultSet = await this.rdbStore.query(predicates);
      const downloads: DownloadEntity[] = [];

      try {
        while (resultSet.goToNextRow()) {
          const entity = this.mapResultSetToEntity(resultSet);
          if (entity !== null) {
            downloads.push(entity);
          }
        }
        return downloads;
      } finally {
        resultSet.close();
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to queryByStatus: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * Query a single download by item ID.
   * @param itemId The Jellyfin item ID
   * @returns DownloadEntity or null if not found
   */
  async queryByItemId(itemId: string): Promise<DownloadEntity | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(DownloadEntityHelper.TABLE_NAME);
      predicates.equalTo('item_id', itemId);

      const resultSet = await this.rdbStore.query(predicates);

      try {
        if (resultSet.goToFirstRow()) {
          return this.mapResultSetToEntity(resultSet);
        }
        return null;
      } finally {
        resultSet.close();
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to queryByItemId: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * Update progress and status for a download identified by item ID.
   * @param itemId The Jellyfin item ID
   * @param progress Progress value 0-100
   * @param status The new DownloadStatus
   */
  async updateProgress(itemId: string, progress: number, status: DownloadStatus): Promise<void> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        progress: progress,
        status: status
      };

      const predicates = new relationalStore.RdbPredicates(DownloadEntityHelper.TABLE_NAME);
      predicates.equalTo('item_id', itemId);

      const rowsAffected = await this.rdbStore.update(valueBucket, predicates);
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Updated download progress, rows affected: %d', rowsAffected);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to updateProgress: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * Delete a download by item ID.
   * @param itemId The download item ID
   * @returns true if at least one row was deleted, false otherwise
   */
  async delete(itemId: string): Promise<boolean> {
    try {
      const predicates = new relationalStore.RdbPredicates(DownloadEntityHelper.TABLE_NAME);
      predicates.equalTo('item_id', itemId);

      const rowsAffected = await this.rdbStore.delete(predicates);
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Deleted download, rows affected: %d', rowsAffected);
      return rowsAffected > 0;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to delete download: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  /**
   * Get all downloads ordered by item ID descending.
   * Equivalent to @Query("SELECT * FROM Download ORDER BY item_id DESC")
   * Note: Android returns Flow<List<DownloadEntity>>, here we return Promise<DownloadEntity[]>
   * @returns Array of DownloadEntity
   * @deprecated Use queryAll() instead
   */
  async getAllDownloads(): Promise<DownloadEntity[]> {
    return this.queryAll();
  }

  /**
   * Get a download by item ID.
   * Equivalent to @Query("SELECT * FROM Download WHERE item_id LIKE :downloadId")
   * @param downloadId The download item ID
   * @returns DownloadEntity or null if not found
   * @deprecated Use queryByItemId() instead
   */
  async get(downloadId: string): Promise<DownloadEntity | null> {
    return this.queryByItemId(downloadId);
  }

  /**
   * Check if a download exists by item ID.
   * @param downloadId The download item ID
   * @returns true if download exists, false otherwise
   */
  async downloadExists(downloadId: string): Promise<boolean> {
    try {
      const predicates = new relationalStore.RdbPredicates(DownloadEntityHelper.TABLE_NAME);
      predicates.equalTo('item_id', downloadId);

      const resultSet = await this.rdbStore.query(predicates);

      try {
        return resultSet.rowCount > 0;
      } finally {
        resultSet.close();
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to check download exists: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  /**
   * Get the count of all downloads.
   * @returns Number of downloads
   */
  async getDownloadCount(): Promise<number> {
    try {
      const sql: string = 'SELECT COUNT(*) as count FROM Download';
      const resultSet = await this.rdbStore.querySql(sql);

      try {
        if (resultSet.goToFirstRow()) {
          return resultSet.getLong(resultSet.getColumnIndex('count'));
        }
        return 0;
      } finally {
        resultSet.close();
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get download count: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  /**
   * Delete all downloads.
   * @returns Number of rows affected
   */
  async deleteAll(): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(DownloadEntityHelper.TABLE_NAME);
      const rowsAffected = await this.rdbStore.delete(predicates);
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Deleted all downloads, rows affected: %d', rowsAffected);
      return rowsAffected;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to delete all downloads: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  /**
   * Map a result set row to DownloadEntity
   */
  private mapResultSetToEntity(resultSet: relationalStore.ResultSet): DownloadEntity | null {
    try {
      const id = resultSet.getLong(resultSet.getColumnIndex('id'));
      const itemId = resultSet.getString(resultSet.getColumnIndex('item_id'));
      const mediaSource = resultSet.getString(resultSet.getColumnIndex('media_source'));
      const fileName = resultSet.getString(resultSet.getColumnIndex('file_name'));
      const filePath = resultSet.getString(resultSet.getColumnIndex('file_path'));
      const progress = resultSet.getLong(resultSet.getColumnIndex('progress'));
      const status = resultSet.getString(resultSet.getColumnIndex('status'));

      return DownloadEntityHelper.fromValues(id, itemId, mediaSource, fileName, filePath, progress, status);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to map result set to entity: %{public}s', JSON.stringify(error));
      return null;
    }
  }
}
