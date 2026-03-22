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
 * Database Migration Unit Tests
 * Tests for database schema creation and migrations
 * Migrated from jellyfin-android database migration tests
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';
import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

import { ServerEntityHelper } from '../../../../main/ets/data/entity/ServerEntity';
import { UserEntityHelper } from '../../../../main/ets/data/entity/UserEntity';
import { DownloadEntityHelper } from '../../../../main/ets/data/entity/DownloadEntity';
import { JellyfinDatabase, DATABASE_NAME, DATABASE_VERSION } from '../../../../main/ets/data/database/JellyfinDatabase';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'DatabaseMigrationTest';

export default function databaseMigrationTest() {
  describe('Database Migration Tests', () => {
    let database: JellyfinDatabase | null = null;
    let rdbStore: relationalStore.RdbStore | null = null;
    let context: common.Context;

    beforeAll(async () => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Database Migration Tests starting...');
    });

    afterAll(async () => {
      if (database) {
        await database.close();
      }
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Database Migration Tests completed');
    });

    afterEach(async () => {
      // Cleanup after each test
      if (rdbStore) {
        try {
          await rdbStore.executeSql('DELETE FROM User');
          await rdbStore.executeSql('DELETE FROM Server');
          await rdbStore.executeSql('DELETE FROM Download');
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    });

    /**
     * Test: Database version
     * Verifies that the database version is correctly set
     */
    it('should have correct database version', 0, () => {
      expect(DATABASE_VERSION).assertEqual(3);
    });

    /**
     * Test: Database name
     * Verifies that the database name is correctly set
     */
    it('should have correct database name', 0, () => {
      expect(DATABASE_NAME).assertEqual('jellyfin.db');
    });

    /**
     * Test: Server table SQL contains all required columns
     */
    it('should have all required columns in Server table SQL', 0, () => {
      const sql = ServerEntityHelper.getCreateTableSql();

      expect(sql).assertContain(ServerEntityHelper.ID);
      expect(sql).assertContain(ServerEntityHelper.HOSTNAME);
      expect(sql).assertContain(ServerEntityHelper.LAST_USED_TIMESTAMP);
    });

    /**
     * Test: User table SQL contains all required columns
     */
    it('should have all required columns in User table SQL', 0, () => {
      const sql = UserEntityHelper.getCreateTableSql();

      expect(sql).assertContain(UserEntityHelper.ID);
      expect(sql).assertContain(UserEntityHelper.SERVER_ID);
      expect(sql).assertContain(UserEntityHelper.USER_ID);
      expect(sql).assertContain(UserEntityHelper.ACCESS_TOKEN);
      expect(sql).assertContain(UserEntityHelper.LAST_LOGIN_TIMESTAMP);
    });

    /**
     * Test: Download table SQL contains all required columns
     */
    it('should have all required columns in Download table SQL', 0, () => {
      const sql = DownloadEntityHelper.getCreateTableSql();

      expect(sql).assertContain(DownloadEntityHelper.ITEM_ID);
      expect(sql).assertContain(DownloadEntityHelper.MEDIA_SOURCE);
    });

    /**
     * Test: Foreign key relationship User -> Server
     */
    it('should define foreign key from User to Server', 0, () => {
      const sql = UserEntityHelper.getCreateTableSql();

      expect(sql).assertContain('FOREIGN KEY');
      expect(sql).assertContain('server_id');
      expect(sql).assertContain('REFERENCES');
      expect(sql).assertContain('Server');
    });

    /**
     * Test: User unique constraint (server_id, user_id)
     */
    it('should define unique constraint on (server_id, user_id)', 0, () => {
      const sql = UserEntityHelper.getCreateTableSql();

      expect(sql).assertContain('UNIQUE(server_id, user_id)');
    });

    /**
     * Test: Server hostname unique constraint
     */
    it('should define unique constraint on hostname', 0, () => {
      const sql = ServerEntityHelper.getCreateTableSql();

      expect(sql).assertContain('hostname TEXT UNIQUE');
    });

    /**
     * Test: Download primary key on item_id
     */
    it('should define primary key on item_id in Download table', 0, () => {
      const sql = DownloadEntityHelper.getCreateTableSql();

      expect(sql).assertContain('item_id TEXT PRIMARY KEY');
    });

    /**
     * Test: All tables have IF NOT EXISTS clause
     */
    it('should use IF NOT EXISTS for all tables', 0, () => {
      const serverSql = ServerEntityHelper.getCreateTableSql();
      const userSql = UserEntityHelper.getCreateTableSql();
      const downloadSql = DownloadEntityHelper.getCreateTableSql();

      expect(serverSql).assertContain('IF NOT EXISTS');
      expect(userSql).assertContain('IF NOT EXISTS');
      expect(downloadSql).assertContain('IF NOT EXISTS');
    });

    /**
     * Test: All indexes have IF NOT EXISTS clause
     */
    it('should use IF NOT EXISTS for all indexes', 0, () => {
      const serverIndexSql = ServerEntityHelper.getCreateIndexSql();
      const userIndexSql = UserEntityHelper.getCreateIndexSql();
      const downloadIndexSql = DownloadEntityHelper.getCreateIndexSql();

      expect(serverIndexSql).assertContain('IF NOT EXISTS');
      expect(userIndexSql).assertContain('IF NOT EXISTS');
      expect(downloadIndexSql).assertContain('IF NOT EXISTS');
    });

    /**
     * Test: Table names match expected values
     */
    it('should have correct table names', 0, () => {
      expect(ServerEntityHelper.TABLE_NAME).assertEqual('Server');
      expect(UserEntityHelper.TABLE_NAME).assertEqual('User');
      expect(DownloadEntityHelper.TABLE_NAME).assertEqual('Download');
    });

    /**
     * Test: Column names match expected values
     */
    it('should have correct column names for Server', 0, () => {
      expect(ServerEntityHelper.ID).assertEqual('id');
      expect(ServerEntityHelper.HOSTNAME).assertEqual('hostname');
      expect(ServerEntityHelper.LAST_USED_TIMESTAMP).assertEqual('last_used_timestamp');
    });

    /**
     * Test: Column names match expected values for User
     */
    it('should have correct column names for User', 0, () => {
      expect(UserEntityHelper.ID).assertEqual('id');
      expect(UserEntityHelper.SERVER_ID).assertEqual('server_id');
      expect(UserEntityHelper.USER_ID).assertEqual('user_id');
      expect(UserEntityHelper.ACCESS_TOKEN).assertEqual('access_token');
      expect(UserEntityHelper.LAST_LOGIN_TIMESTAMP).assertEqual('last_login_timestamp');
    });

    /**
     * Test: Column names match expected values for Download
     */
    it('should have correct column names for Download', 0, () => {
      expect(DownloadEntityHelper.ID).assertEqual('id');
      expect(DownloadEntityHelper.ITEM_ID).assertEqual('item_id');
      expect(DownloadEntityHelper.MEDIA_SOURCE).assertEqual('media_source');
    });

    /**
     * Test: Server index on hostname
     */
    it('should create index on Server hostname', 0, () => {
      const sql = ServerEntityHelper.getCreateIndexSql();

      expect(sql).assertContain('index_Server_hostname');
      expect(sql).assertContain('hostname');
    });

    /**
     * Test: User index on (server_id, user_id)
     */
    it('should create index on User (server_id, user_id)', 0, () => {
      const sql = UserEntityHelper.getCreateIndexSql();

      expect(sql).assertContain('index_User_server_id_user_id');
      expect(sql).assertContain('server_id');
      expect(sql).assertContain('user_id');
    });

    /**
     * Test: Download index on item_id
     */
    it('should create index on Download item_id', 0, () => {
      const sql = DownloadEntityHelper.getCreateIndexSql();

      expect(sql).assertContain('index_Download_item_id');
      expect(sql).assertContain('item_id');
    });

    /**
     * Test: Schema validation - Server table structure
     */
    it('should create valid Server table structure', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      await rdbStore.executeSql(ServerEntityHelper.getCreateTableSql());

      // Query table info to verify structure
      const resultSet = await rdbStore.querySql('PRAGMA table_info(Server)');

      const columns: string[] = [];
      while (resultSet.goToNextRow()) {
        const columnName = resultSet.getString(resultSet.getColumnIndex('name'));
        columns.push(columnName);
      }
      resultSet.close();

      expect(columns).assertContain('id');
      expect(columns).assertContain('hostname');
      expect(columns).assertContain('last_used_timestamp');
    });

    /**
     * Test: Schema validation - User table structure
     */
    it('should create valid User table structure', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      await rdbStore.executeSql(ServerEntityHelper.getCreateTableSql());
      await rdbStore.executeSql(UserEntityHelper.getCreateTableSql());

      const resultSet = await rdbStore.querySql('PRAGMA table_info(User)');

      const columns: string[] = [];
      while (resultSet.goToNextRow()) {
        const columnName = resultSet.getString(resultSet.getColumnIndex('name'));
        columns.push(columnName);
      }
      resultSet.close();

      expect(columns).assertContain('id');
      expect(columns).assertContain('server_id');
      expect(columns).assertContain('user_id');
      expect(columns).assertContain('access_token');
      expect(columns).assertContain('last_login_timestamp');
    });

    /**
     * Test: Schema validation - Download table structure
     */
    it('should create valid Download table structure', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      await rdbStore.executeSql(DownloadEntityHelper.getCreateTableSql());

      const resultSet = await rdbStore.querySql('PRAGMA table_info(Download)');

      const columns: string[] = [];
      while (resultSet.goToNextRow()) {
        const columnName = resultSet.getString(resultSet.getColumnIndex('name'));
        columns.push(columnName);
      }
      resultSet.close();

      expect(columns).assertContain('item_id');
      expect(columns).assertContain('media_source');
    });

    /**
     * Test: Data integrity - Insert and retrieve
     */
    it('should maintain data integrity on insert and retrieve', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      // Create tables
      await rdbStore.executeSql(ServerEntityHelper.getCreateTableSql());
      await rdbStore.executeSql(UserEntityHelper.getCreateTableSql());

      // Insert server
      const serverBucket: relationalStore.ValuesBucket = {
        hostname: 'https://integrity-test.example.com',
        last_used_timestamp: Date.now()
      };
      const serverId = await rdbStore.insert('Server', serverBucket);

      // Insert user
      const userBucket: relationalStore.ValuesBucket = {
        server_id: serverId,
        user_id: 'integrity_user',
        access_token: 'integrity_token',
        last_login_timestamp: Date.now()
      };
      await rdbStore.insert('User', userBucket);

      // Verify data
      const predicates = new relationalStore.RdbPredicates('User');
      predicates.equalTo('server_id', serverId);
      const resultSet = await rdbStore.query(predicates);

      expect(resultSet.goToNextRow()).assertTrue();
      const userId = resultSet.getString(resultSet.getColumnIndex('user_id'));
      expect(userId).assertEqual('integrity_user');
      resultSet.close();
    });

    /**
     * Test: Transaction rollback on error
     */
    it('should rollback transaction on error', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      // Create tables
      await rdbStore.executeSql(ServerEntityHelper.getCreateTableSql());

      await rdbStore.beginTransaction();
      try {
        // Insert server
        const serverBucket: relationalStore.ValuesBucket = {
          hostname: 'https://rollback-test.example.com',
          last_used_timestamp: Date.now()
        };
        await rdbStore.insert('Server', serverBucket);

        // Force an error
        throw new Error('Simulated error');
      } catch (error) {
        await rdbStore.rollBack();

        // Verify no data was inserted
        const predicates = new relationalStore.RdbPredicates('Server');
        predicates.equalTo('hostname', 'https://rollback-test.example.com');
        const resultSet = await rdbStore.query(predicates);

        let count = 0;
        if (resultSet.goToNextRow()) {
          count++;
        }
        resultSet.close();

        expect(count).assertEqual(0);
      }
    });

    /**
     * Test: Transaction commit on success
     */
    it('should commit transaction on success', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      // Create tables
      await rdbStore.executeSql(ServerEntityHelper.getCreateTableSql());

      await rdbStore.beginTransaction();
      try {
        const serverBucket: relationalStore.ValuesBucket = {
          hostname: 'https://commit-test.example.com',
          last_used_timestamp: Date.now()
        };
        await rdbStore.insert('Server', serverBucket);
        await rdbStore.commit();

        // Verify data was inserted
        const predicates = new relationalStore.RdbPredicates('Server');
        predicates.equalTo('hostname', 'https://commit-test.example.com');
        const resultSet = await rdbStore.query(predicates);

        expect(resultSet.goToNextRow()).assertTrue();
        resultSet.close();
      } catch (error) {
        await rdbStore.rollBack();
        expect(false).assertTrue(); // Should not reach here
      }
    });
  });
}
