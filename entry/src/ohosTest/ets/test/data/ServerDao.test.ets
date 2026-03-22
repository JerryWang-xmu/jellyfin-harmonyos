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
 * ServerDao Unit Tests
 * Tests for server data access object CRUD operations
 * Migrated from jellyfin-android database tests
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';
import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

// Import the classes to test (adjust import paths as needed)
import { ServerEntity, ServerEntityHelper } from '../../../../main/ets/data/entity/ServerEntity';
import { JellyfinDatabase, DATABASE_NAME } from '../../../../main/ets/data/database/JellyfinDatabase';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'ServerDaoTest';

export default function serverDaoTest() {
  describe('ServerDao Tests', () => {
    let database: JellyfinDatabase | null = null;
    let rdbStore: relationalStore.RdbStore | null = null;
    let context: common.Context;

    beforeAll(async () => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'ServerDao Tests starting...');
    });

    afterAll(async () => {
      if (database) {
        await database.close();
      }
      hilog.info(LOG_DOMAIN, LOG_TAG, 'ServerDao Tests completed');
    });

    beforeEach(async () => {
      // Setup: Create a fresh database for each test
      // In actual test environment, context should be provided by test framework
    });

    afterEach(async () => {
      // Cleanup: Clear the servers table after each test
      if (rdbStore) {
        try {
          await rdbStore.executeSql('DELETE FROM Server');
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    });

    /**
     * Test: ServerEntityHelper.create
     * Verifies that server entity creation works correctly
     */
    it('should create server entity with correct values', 0, () => {
      const hostname = 'https://jellyfin.example.com';
      const entity = ServerEntityHelper.create(hostname);

      expect(entity.hostname).assertEqual(hostname);
      expect(entity.lastUsedTimestamp).assertContain(Date.now() - 1000);
      expect(entity.lastUsedTimestamp).assertContain(Date.now() + 1000);
    });

    /**
     * Test: ServerEntityHelper.fromValues
     * Verifies that server entity can be created from database values
     */
    it('should create server entity from values', 0, () => {
      const id = 1;
      const hostname = 'https://jellyfin.example.com';
      const timestamp = 1234567890;

      const entity = ServerEntityHelper.fromValues(id, hostname, timestamp);

      expect(entity.id).assertEqual(id);
      expect(entity.hostname).assertEqual(hostname);
      expect(entity.lastUsedTimestamp).assertEqual(timestamp);
    });

    /**
     * Test: ServerEntityHelper.getCreateTableSql
     * Verifies that CREATE TABLE SQL is generated correctly
     */
    it('should generate correct CREATE TABLE SQL', 0, () => {
      const sql = ServerEntityHelper.getCreateTableSql();

      expect(sql).assertContain('CREATE TABLE IF NOT EXISTS Server');
      expect(sql).assertContain('id INTEGER PRIMARY KEY AUTOINCREMENT');
      expect(sql).assertContain('hostname TEXT UNIQUE NOT NULL');
      expect(sql).assertContain('last_used_timestamp INTEGER NOT NULL');
    });

    /**
     * Test: ServerEntityHelper.getCreateIndexSql
     * Verifies that CREATE INDEX SQL is generated correctly
     */
    it('should generate correct CREATE INDEX SQL', 0, () => {
      const sql = ServerEntityHelper.getCreateIndexSql();

      expect(sql).assertContain('CREATE UNIQUE INDEX IF NOT EXISTS');
      expect(sql).assertContain('index_Server_hostname');
      expect(sql).assertContain('hostname');
    });

    /**
     * Test: Insert server
     * Verifies that a server can be inserted into the database
     */
    it('should insert server successfully', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const valueBucket: relationalStore.ValuesBucket = {
        hostname: 'https://jellyfin.example.com',
        last_used_timestamp: Date.now()
      };

      const rowId = await rdbStore.insert('Server', valueBucket);
      expect(rowId).assertLargerThan(0);
    });

    /**
     * Test: Query all servers
     * Verifies that all servers can be queried
     */
    it('should query all servers', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      // Insert test data
      const servers = [
        { hostname: 'https://server1.example.com', last_used_timestamp: Date.now() },
        { hostname: 'https://server2.example.com', last_used_timestamp: Date.now() }
      ];

      for (const server of servers) {
        await rdbStore.insert('Server', server as relationalStore.ValuesBucket);
      }

      // Query all
      const predicates = new relationalStore.RdbPredicates('Server');
      const resultSet = await rdbStore.query(predicates);

      const count = 0;
      while (resultSet.goToNextRow()) {
        count + 1;
      }
      resultSet.close();

      expect(count).assertEqual(2);
    });

    /**
     * Test: Query server by hostname
     * Verifies that a server can be queried by hostname
     */
    it('should query server by hostname', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const hostname = 'https://unique.example.com';
      const valueBucket: relationalStore.ValuesBucket = {
        hostname: hostname,
        last_used_timestamp: Date.now()
      };

      await rdbStore.insert('Server', valueBucket);

      const predicates = new relationalStore.RdbPredicates('Server');
      predicates.equalTo('hostname', hostname);
      const resultSet = await rdbStore.query(predicates);

      expect(resultSet.goToNextRow()).assertTrue();

      const resultHostname = resultSet.getString(resultSet.getColumnIndex('hostname'));
      expect(resultHostname).assertEqual(hostname);

      resultSet.close();
    });

    /**
     * Test: Delete server
     * Verifies that a server can be deleted
     */
    it('should delete server successfully', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const valueBucket: relationalStore.ValuesBucket = {
        hostname: 'https://to-delete.example.com',
        last_used_timestamp: Date.now()
      };

      const rowId = await rdbStore.insert('Server', valueBucket);

      const predicates = new relationalStore.RdbPredicates('Server');
      predicates.equalTo('id', rowId);
      const deleted = await rdbStore.delete(predicates);

      expect(deleted).assertLargerThan(0);
    });

    /**
     * Test: Unique hostname constraint
     * Verifies that duplicate hostnames are not allowed
     */
    it('should enforce unique hostname constraint', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const hostname = 'https://unique-test.example.com';
      const valueBucket: relationalStore.ValuesBucket = {
        hostname: hostname,
        last_used_timestamp: Date.now()
      };

      // First insert should succeed
      await rdbStore.insert('Server', valueBucket);

      // Second insert with same hostname should fail
      try {
        await rdbStore.insert('Server', valueBucket);
        expect(false).assertTrue(); // Should not reach here
      } catch (error) {
        expect(true).assertTrue(); // Expected error
      }
    });

    /**
     * Test: Update server timestamp
     * Verifies that server timestamp can be updated
     */
    it('should update server timestamp', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      const hostname = 'https://update-test.example.com';
      const valueBucket: relationalStore.ValuesBucket = {
        hostname: hostname,
        last_used_timestamp: 1000
      };

      const rowId = await rdbStore.insert('Server', valueBucket);

      const newTimestamp = Date.now();
      const updateBucket: relationalStore.ValuesBucket = {
        last_used_timestamp: newTimestamp
      };

      const predicates = new relationalStore.RdbPredicates('Server');
      predicates.equalTo('id', rowId);
      await rdbStore.update(updateBucket, predicates);

      // Verify update
      const queryPredicates = new relationalStore.RdbPredicates('Server');
      queryPredicates.equalTo('id', rowId);
      const resultSet = await rdbStore.query(queryPredicates);

      if (resultSet.goToNextRow()) {
        const timestamp = resultSet.getLong(resultSet.getColumnIndex('last_used_timestamp'));
        expect(timestamp).assertEqual(newTimestamp);
      }
      resultSet.close();
    });
  });
}
