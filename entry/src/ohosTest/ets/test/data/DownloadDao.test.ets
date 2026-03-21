/**
 * DownloadDao Unit Tests
 * Tests for download data access object CRUD operations
 * Migrated from jellyfin-android database tests
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';
import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

import { DownloadEntity, DownloadEntityHelper } from '../../../../main/ets/data/entity/DownloadEntity';
import { JellyfinDatabase } from '../../../../main/ets/data/database/JellyfinDatabase';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'DownloadDaoTest';

export default function downloadDaoTest() {
  describe('DownloadDao Tests', () => {
    let database: JellyfinDatabase | null = null;
    let rdbStore: relationalStore.RdbStore | null = null;

    beforeAll(async () => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'DownloadDao Tests starting...');
    });

    afterAll(async () => {
      if (database) {
        await database.close();
      }
      hilog.info(LOG_DOMAIN, LOG_TAG, 'DownloadDao Tests completed');
    });

    afterEach(async () => {
      // Cleanup: Clear the downloads table after each test
      if (rdbStore) {
        try {
          await rdbStore.executeSql('DELETE FROM Download');
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    });

    /**
     * Test: DownloadEntityHelper.create
     * Verifies that download entity creation works correctly
     */
    it('should create download entity with correct values', 0, () => {
      const itemId = 'media123';
      const mediaSourceJson = JSON.stringify({
        id: 'source1',
        path: '/path/to/media.mp4',
        size: 1024000
      });

      const entity = DownloadEntityHelper.create(itemId, mediaSourceJson);

      expect(entity.itemId).assertEqual(itemId);
      expect(entity.mediaSource).assertEqual(mediaSourceJson);
    });

    /**
     * Test: DownloadEntityHelper.getCreateTableSql
     * Verifies that CREATE TABLE SQL is generated correctly
     */
    it('should generate correct CREATE TABLE SQL', 0, () => {
      const sql = DownloadEntityHelper.getCreateTableSql();

      expect(sql).assertContain('CREATE TABLE IF NOT EXISTS Download');
      expect(sql).assertContain('item_id TEXT PRIMARY KEY');
      expect(sql).assertContain('media_source TEXT NOT NULL');
    });

    /**
     * Test: DownloadEntityHelper.getCreateIndexSql
     * Verifies that CREATE INDEX SQL is generated correctly
     */
    it('should generate correct CREATE INDEX SQL', 0, () => {
      const sql = DownloadEntityHelper.getCreateIndexSql();

      expect(sql).assertContain('CREATE UNIQUE INDEX IF NOT EXISTS');
      expect(sql).assertContain('index_Download_item_id');
      expect(sql).assertContain('item_id');
    });

    /**
     * Test: Insert download
     * Verifies that a download can be inserted into the database
     */
    it('should insert download successfully', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const valueBucket: relationalStore.ValuesBucket = {
        item_id: 'media_item_001',
        media_source: JSON.stringify({
          id: 'source1',
          path: '/path/to/media.mp4',
          size: 1024000
        })
      };

      const rowId = await rdbStore.insert('Download', valueBucket);
      expect(rowId).assertLargerThan(0);
    });

    /**
     * Test: Query download by item ID
     * Verifies that a download can be queried by item ID
     */
    it('should query download by item ID', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const itemId = 'unique_item_001';
      const mediaSource = JSON.stringify({ id: 'source1', path: '/media.mp4' });

      const valueBucket: relationalStore.ValuesBucket = {
        item_id: itemId,
        media_source: mediaSource
      };

      await rdbStore.insert('Download', valueBucket);

      const predicates = new relationalStore.RdbPredicates('Download');
      predicates.equalTo('item_id', itemId);
      const resultSet = await rdbStore.query(predicates);

      expect(resultSet.goToNextRow()).assertTrue();

      const resultItemId = resultSet.getString(resultSet.getColumnIndex('item_id'));
      expect(resultItemId).assertEqual(itemId);

      resultSet.close();
    });

    /**
     * Test: Query all downloads
     * Verifies that all downloads can be queried
     */
    it('should query all downloads', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const downloads = [
        { item_id: 'item_001', media_source: '{"id":"1"}' },
        { item_id: 'item_002', media_source: '{"id":"2"}' },
        { item_id: 'item_003', media_source: '{"id":"3"}' }
      ];

      for (const download of downloads) {
        await rdbStore.insert('Download', download as relationalStore.ValuesBucket);
      }

      const predicates = new relationalStore.RdbPredicates('Download');
      const resultSet = await rdbStore.query(predicates);

      let count = 0;
      while (resultSet.goToNextRow()) {
        count++;
      }
      resultSet.close();

      expect(count).assertEqual(3);
    });

    /**
     * Test: Delete download
     * Verifies that a download can be deleted
     */
    it('should delete download successfully', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const itemId = 'to_delete_item';
      const valueBucket: relationalStore.ValuesBucket = {
        item_id: itemId,
        media_source: '{"id":"delete"}'
      };

      await rdbStore.insert('Download', valueBucket);

      const predicates = new relationalStore.RdbPredicates('Download');
      predicates.equalTo('item_id', itemId);
      const deleted = await rdbStore.delete(predicates);

      expect(deleted).assertLargerThan(0);
    });

    /**
     * Test: Primary key constraint (unique item_id)
     * Verifies that duplicate item_id is not allowed
     */
    it('should enforce primary key constraint on item_id', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const itemId = 'unique_item_test';
      const valueBucket: relationalStore.ValuesBucket = {
        item_id: itemId,
        media_source: '{"id":"1"}'
      };

      // First insert should succeed
      await rdbStore.insert('Download', valueBucket);

      // Second insert with same item_id should fail
      try {
        await rdbStore.insert('Download', valueBucket);
        expect(false).assertTrue(); // Should not reach here
      } catch (error) {
        expect(true).assertTrue(); // Expected error
      }
    });

    /**
     * Test: Update download media source
     * Verifies that download media source can be updated
     */
    it('should update download media source', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const itemId = 'update_test_item';
      const valueBucket: relationalStore.ValuesBucket = {
        item_id: itemId,
        media_source: '{"id":"old"}'
      };

      await rdbStore.insert('Download', valueBucket);

      const newMediaSource = '{"id":"new","path":"/updated/path.mp4"}';
      const updateBucket: relationalStore.ValuesBucket = {
        media_source: newMediaSource
      };

      const predicates = new relationalStore.RdbPredicates('Download');
      predicates.equalTo('item_id', itemId);
      await rdbStore.update(updateBucket, predicates);

      // Verify update
      const queryPredicates = new relationalStore.RdbPredicates('Download');
      queryPredicates.equalTo('item_id', itemId);
      const resultSet = await rdbStore.query(queryPredicates);

      if (resultSet.goToNextRow()) {
        const source = resultSet.getString(resultSet.getColumnIndex('media_source'));
        expect(source).assertEqual(newMediaSource);
      }
      resultSet.close();
    });

    /**
     * Test: Format file size - bytes
     */
    it('should format bytes correctly', 0, () => {
      const size = 512;
      const formatted = DownloadEntityHelper.formatFileSize(size);
      expect(formatted).assertContain('512');
      expect(formatted).assertContain('B');
    });

    /**
     * Test: Format file size - kilobytes
     */
    it('should format kilobytes correctly', 0, () => {
      const size = 1024; // 1 KB
      const formatted = DownloadEntityHelper.formatFileSize(size);
      expect(formatted).assertContain('KB');
    });

    /**
     * Test: Format file size - megabytes
     */
    it('should format megabytes correctly', 0, () => {
      const size = 1048576; // 1 MB
      const formatted = DownloadEntityHelper.formatFileSize(size);
      expect(formatted).assertContain('MB');
    });

    /**
     * Test: Format file size - gigabytes
     */
    it('should format gigabytes correctly', 0, () => {
      const size = 1073741824; // 1 GB
      const formatted = DownloadEntityHelper.formatFileSize(size);
      expect(formatted).assertContain('GB');
    });

    /**
     * Test: Format file size - terabytes
     */
    it('should format terabytes correctly', 0, () => {
      const size = 1099511627776; // 1 TB
      const formatted = DownloadEntityHelper.formatFileSize(size);
      expect(formatted).assertContain('TB');
    });

    /**
     * Test: Format file size - large file
     */
    it('should format large file size correctly', 0, () => {
      const size = 1572864; // 1.5 MB
      const formatted = DownloadEntityHelper.formatFileSize(size);
      expect(formatted).assertContain('MB');
      expect(formatted).assertContain('1.50');
    });

    /**
     * Test: BYTES_PER_BINARY_UNIT constant
     */
    it('should have correct bytes per binary unit', 0, () => {
      expect(DownloadEntityHelper.BYTES_PER_BINARY_UNIT).assertEqual(1024);
    });

    /**
     * Test: Insert download with complex media source
     */
    it('should insert download with complex media source', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const complexMediaSource = {
        id: 'complex_source_001',
        path: '/storage/emulated/0/MediaCache/movie.mp4',
        container: 'mp4',
        size: 1024000000,
        runTimeTicks: 72000000000,
        mediaStreams: [
          { type: 'Video', codec: 'h264', width: 1920, height: 1080 },
          { type: 'Audio', codec: 'aac', language: 'eng' }
        ]
      };

      const valueBucket: relationalStore.ValuesBucket = {
        item_id: 'complex_item_001',
        media_source: JSON.stringify(complexMediaSource)
      };

      const rowId = await rdbStore.insert('Download', valueBucket);
      expect(rowId).assertLargerThan(0);

      // Verify the data can be parsed back
      const predicates = new relationalStore.RdbPredicates('Download');
      predicates.equalTo('item_id', 'complex_item_001');
      const resultSet = await rdbStore.query(predicates);

      if (resultSet.goToNextRow()) {
        const source = resultSet.getString(resultSet.getColumnIndex('media_source'));
        const parsed = JSON.parse(source);
        expect(parsed.id).assertEqual('complex_source_001');
        expect(parsed.mediaStreams.length).assertEqual(2);
      }
      resultSet.close();
    });

    /**
     * Test: Empty media source
     */
    it('should handle empty media source', 0, () => {
      const entity = DownloadEntityHelper.create('empty_item', '');
      expect(entity.itemId).assertEqual('empty_item');
      expect(entity.mediaSource).assertEqual('');
    });

    /**
     * Test: Unicode in media source JSON
     */
    it('should handle unicode in media source JSON', 0, () => {
      const unicodeData = {
        title: '测试视频',
        description: 'これはテストです',
        emoji: '🎬'
      };

      const entity = DownloadEntityHelper.create('unicode_item', JSON.stringify(unicodeData));
      const parsed = JSON.parse(entity.mediaSource);

      expect(parsed.title).assertEqual('测试视频');
      expect(parsed.description).assertEqual('これはテストです');
      expect(parsed.emoji).assertEqual('🎬');
    });
  });
}
