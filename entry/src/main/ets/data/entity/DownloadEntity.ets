/**
 * Download entity representing a downloaded media item.
 * Migrated from Android Room Entity to HarmonyOS ArkTS.
 *
 * Note: The mediaSource field stores JSON-serialized LocalJellyfinMediaSource data.
 */

export interface DownloadEntity {
  itemId: string;
  mediaSource: string; // JSON string of LocalJellyfinMediaSource
}

export class DownloadEntityHelper {
  static readonly TABLE_NAME: string = 'Download';
  static readonly ID: string = 'id';
  static readonly ITEM_ID: string = 'item_id';
  static readonly MEDIA_SOURCE: string = 'media_source';

  static readonly BYTES_PER_BINARY_UNIT: number = 1024;

  /**
   * Create a new DownloadEntity
   */
  static create(itemId: string, mediaSourceJson: string): DownloadEntity {
    const entity: DownloadEntity = {
      itemId: itemId,
      mediaSource: mediaSourceJson
    };
    return entity;
  }

  /**
   * Get CREATE TABLE SQL statement
   */
  static getCreateTableSql(): string {
    return 'CREATE TABLE IF NOT EXISTS Download (' +
      'item_id TEXT PRIMARY KEY, ' +
      'media_source TEXT NOT NULL)';
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
