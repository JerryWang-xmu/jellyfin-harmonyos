/**
 * DownloadDao - Data Access Object for Download entity.
 * Migrated from Android Room Dao to HarmonyOS RdbStore.
 *
 * Original: org.jellyfin.mobile.data.dao.DownloadDao
 */

import relationalStore from '@ohos.data.relationalStore';
import hilog from '@ohos.hilog';

import { DownloadEntity, DownloadEntityHelper } from '../entity/DownloadEntity';

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
   * @param entity DownloadEntity to insert/replace
   * @returns The row ID of the inserted download
   */
  async insert(entity: DownloadEntity): Promise<number> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        item_id: entity.itemId,
        media_source: entity.mediaSource
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
   * Delete a download by item ID.
   * Equivalent to @Query("DELETE FROM Download WHERE item_id LIKE :downloadId")
   * @param downloadId The download item ID
   * @returns Number of rows affected
   */
  async delete(downloadId: string): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(DownloadEntityHelper.TABLE_NAME);
      predicates.equalTo('item_id', downloadId);

      const rowsAffected = await this.rdbStore.delete(predicates);
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Deleted download, rows affected: %d', rowsAffected);
      return rowsAffected;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to delete download: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  /**
   * Get all downloads ordered by item ID descending.
   * Equivalent to @Query("SELECT * FROM Download ORDER BY item_id DESC")
   * Note: Android returns Flow<List<DownloadEntity>>, here we return Promise<DownloadEntity[]>
   * @returns Array of DownloadEntity
   */
  async getAllDownloads(): Promise<DownloadEntity[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(DownloadEntityHelper.TABLE_NAME);
      predicates.orderByDesc('item_id');

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
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get all downloads: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * Get a download by item ID.
   * Equivalent to @Query("SELECT * FROM Download WHERE item_id LIKE :downloadId")
   * @param downloadId The download item ID
   * @returns DownloadEntity or null if not found
   */
  async get(downloadId: string): Promise<DownloadEntity | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(DownloadEntityHelper.TABLE_NAME);
      predicates.equalTo('item_id', downloadId);

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
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get download: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * Check if a download exists by item ID.
   * Equivalent to @Query("SELECT EXISTS(SELECT * FROM Download WHERE item_id LIKE :downloadId)")
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
      const itemId = resultSet.getString(resultSet.getColumnIndex('item_id'));
      const mediaSource = resultSet.getString(resultSet.getColumnIndex('media_source'));

      return DownloadEntityHelper.create(itemId, mediaSource);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to map result set to entity: %{public}s', JSON.stringify(error));
      return null;
    }
  }
}
