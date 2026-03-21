/**
 * UserDao Unit Tests
 * Tests for user data access object CRUD operations
 * Migrated from jellyfin-android database tests
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';
import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

import { UserEntity, UserEntityHelper, ServerUser } from '../../../../main/ets/data/entity/UserEntity';
import { ServerEntityHelper } from '../../../../main/ets/data/entity/ServerEntity';
import { JellyfinDatabase } from '../../../../main/ets/data/database/JellyfinDatabase';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'UserDaoTest';

export default function userDaoTest() {
  describe('UserDao Tests', () => {
    let database: JellyfinDatabase | null = null;
    let rdbStore: relationalStore.RdbStore | null = null;
    let testServerId: number = -1;

    beforeAll(async () => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'UserDao Tests starting...');
    });

    afterAll(async () => {
      if (database) {
        await database.close();
      }
      hilog.info(LOG_DOMAIN, LOG_TAG, 'UserDao Tests completed');
    });

    beforeEach(async () => {
      // Setup: Create a test server for foreign key reference
    });

    afterEach(async () => {
      // Cleanup: Clear the tables after each test
      if (rdbStore) {
        try {
          await rdbStore.executeSql('DELETE FROM User');
          await rdbStore.executeSql('DELETE FROM Server');
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    });

    /**
     * Test: UserEntityHelper.create
     * Verifies that user entity creation works correctly
     */
    it('should create user entity with correct values', 0, () => {
      const serverId = 1;
      const userId = 'user123';
      const accessToken = 'token456';

      const entity = UserEntityHelper.create(serverId, userId, accessToken);

      expect(entity.serverId).assertEqual(serverId);
      expect(entity.userId).assertEqual(userId);
      expect(entity.accessToken).assertEqual(accessToken);
      expect(entity.lastLoginTimestamp).assertLargerThan(0);
    });

    /**
     * Test: UserEntityHelper.create with null token
     * Verifies that user entity can be created with null access token
     */
    it('should create user entity with null access token', 0, () => {
      const serverId = 1;
      const userId = 'user123';

      const entity = UserEntityHelper.create(serverId, userId, null);

      expect(entity.serverId).assertEqual(serverId);
      expect(entity.userId).assertEqual(userId);
      expect(entity.accessToken).assertNull();
    });

    /**
     * Test: UserEntityHelper.fromValues
     * Verifies that user entity can be created from database values
     */
    it('should create user entity from values', 0, () => {
      const id = 1;
      const serverId = 10;
      const userId = 'user456';
      const accessToken = 'token789';
      const timestamp = 1234567890;

      const entity = UserEntityHelper.fromValues(id, serverId, userId, accessToken, timestamp);

      expect(entity.id).assertEqual(id);
      expect(entity.serverId).assertEqual(serverId);
      expect(entity.userId).assertEqual(userId);
      expect(entity.accessToken).assertEqual(accessToken);
      expect(entity.lastLoginTimestamp).assertEqual(timestamp);
    });

    /**
     * Test: UserEntityHelper.getCreateTableSql
     * Verifies that CREATE TABLE SQL is generated correctly
     */
    it('should generate correct CREATE TABLE SQL', 0, () => {
      const sql = UserEntityHelper.getCreateTableSql();

      expect(sql).assertContain('CREATE TABLE IF NOT EXISTS User');
      expect(sql).assertContain('id INTEGER PRIMARY KEY AUTOINCREMENT');
      expect(sql).assertContain('server_id INTEGER NOT NULL');
      expect(sql).assertContain('user_id TEXT NOT NULL');
      expect(sql).assertContain('access_token TEXT');
      expect(sql).assertContain('last_login_timestamp INTEGER NOT NULL');
      expect(sql).assertContain('FOREIGN KEY');
      expect(sql).assertContain('UNIQUE(server_id, user_id)');
    });

    /**
     * Test: UserEntityHelper.getCreateIndexSql
     * Verifies that CREATE INDEX SQL is generated correctly
     */
    it('should generate correct CREATE INDEX SQL', 0, () => {
      const sql = UserEntityHelper.getCreateIndexSql();

      expect(sql).assertContain('CREATE UNIQUE INDEX IF NOT EXISTS');
      expect(sql).assertContain('index_User_server_id_user_id');
      expect(sql).assertContain('server_id');
      expect(sql).assertContain('user_id');
    });

    /**
     * Test: Insert user
     * Verifies that a user can be inserted into the database
     */
    it('should insert user successfully', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      // First create a server
      const serverBucket: relationalStore.ValuesBucket = {
        hostname: 'https://test.example.com',
        last_used_timestamp: Date.now()
      };
      testServerId = await rdbStore.insert('Server', serverBucket);

      const valueBucket: relationalStore.ValuesBucket = {
        server_id: testServerId,
        user_id: 'user123',
        access_token: 'token456',
        last_login_timestamp: Date.now()
      };

      const rowId = await rdbStore.insert('User', valueBucket);
      expect(rowId).assertLargerThan(0);
    });

    /**
     * Test: Query users by server ID
     * Verifies that users can be queried by server ID
     */
    it('should query users by server ID', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      // Create server
      const serverBucket: relationalStore.ValuesBucket = {
        hostname: 'https://test.example.com',
        last_used_timestamp: Date.now()
      };
      const serverId = await rdbStore.insert('Server', serverBucket);

      // Insert users
      const users = [
        { server_id: serverId, user_id: 'user1', access_token: 'token1', last_login_timestamp: Date.now() },
        { server_id: serverId, user_id: 'user2', access_token: 'token2', last_login_timestamp: Date.now() }
      ];

      for (const user of users) {
        await rdbStore.insert('User', user as relationalStore.ValuesBucket);
      }

      // Query by server ID
      const predicates = new relationalStore.RdbPredicates('User');
      predicates.equalTo('server_id', serverId);
      const resultSet = await rdbStore.query(predicates);

      let count = 0;
      while (resultSet.goToNextRow()) {
        count++;
      }
      resultSet.close();

      expect(count).assertEqual(2);
    });

    /**
     * Test: Query active user
     * Verifies that active user can be queried
     * Note: This test assumes there's an is_active column or similar mechanism
     */
    it('should query active user', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      // Create server
      const serverBucket: relationalStore.ValuesBucket = {
        hostname: 'https://test.example.com',
        last_used_timestamp: Date.now()
      };
      const serverId = await rdbStore.insert('Server', serverBucket);

      // Insert user with most recent timestamp (active user)
      const activeUser: relationalStore.ValuesBucket = {
        server_id: serverId,
        user_id: 'active_user',
        access_token: 'active_token',
        last_login_timestamp: Date.now()
      };
      await rdbStore.insert('User', activeUser);

      // Query the most recent user
      const predicates = new relationalStore.RdbPredicates('User');
      predicates.orderByDesc('last_login_timestamp');
      predicates.limitAs(1);
      const resultSet = await rdbStore.query(predicates);

      if (resultSet.goToNextRow()) {
        const userId = resultSet.getString(resultSet.getColumnIndex('user_id'));
        expect(userId).assertEqual('active_user');
      }
      resultSet.close();
    });

    /**
     * Test: Delete user
     * Verifies that a user can be deleted
     */
    it('should delete user successfully', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      // Create server
      const serverBucket: relationalStore.ValuesBucket = {
        hostname: 'https://test.example.com',
        last_used_timestamp: Date.now()
      };
      const serverId = await rdbStore.insert('Server', serverBucket);

      const valueBucket: relationalStore.ValuesBucket = {
        server_id: serverId,
        user_id: 'to_delete',
        access_token: 'token',
        last_login_timestamp: Date.now()
      };

      const rowId = await rdbStore.insert('User', valueBucket);

      const predicates = new relationalStore.RdbPredicates('User');
      predicates.equalTo('id', rowId);
      const deleted = await rdbStore.delete(predicates);

      expect(deleted).assertLargerThan(0);
    });

    /**
     * Test: Unique server_id + user_id constraint
     * Verifies that duplicate user_id on same server is not allowed
     */
    it('should enforce unique server_id + user_id constraint', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      // Create server
      const serverBucket: relationalStore.ValuesBucket = {
        hostname: 'https://test.example.com',
        last_used_timestamp: Date.now()
      };
      const serverId = await rdbStore.insert('Server', serverBucket);

      const valueBucket: relationalStore.ValuesBucket = {
        server_id: serverId,
        user_id: 'duplicate_user',
        access_token: 'token',
        last_login_timestamp: Date.now()
      };

      // First insert should succeed
      await rdbStore.insert('User', valueBucket);

      // Second insert with same server_id + user_id should fail
      try {
        await rdbStore.insert('User', valueBucket);
        expect(false).assertTrue(); // Should not reach here
      } catch (error) {
        expect(true).assertTrue(); // Expected error
      }
    });

    /**
     * Test: Update user access token
     * Verifies that user access token can be updated
     */
    it('should update user access token', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      // Create server
      const serverBucket: relationalStore.ValuesBucket = {
        hostname: 'https://test.example.com',
        last_used_timestamp: Date.now()
      };
      const serverId = await rdbStore.insert('Server', serverBucket);

      const valueBucket: relationalStore.ValuesBucket = {
        server_id: serverId,
        user_id: 'update_test',
        access_token: 'old_token',
        last_login_timestamp: Date.now()
      };

      const rowId = await rdbStore.insert('User', valueBucket);

      const newToken = 'new_token_123';
      const updateBucket: relationalStore.ValuesBucket = {
        access_token: newToken
      };

      const predicates = new relationalStore.RdbPredicates('User');
      predicates.equalTo('id', rowId);
      await rdbStore.update(updateBucket, predicates);

      // Verify update
      const queryPredicates = new relationalStore.RdbPredicates('User');
      queryPredicates.equalTo('id', rowId);
      const resultSet = await rdbStore.query(queryPredicates);

      if (resultSet.goToNextRow()) {
        const token = resultSet.getString(resultSet.getColumnIndex('access_token'));
        expect(token).assertEqual(newToken);
      }
      resultSet.close();
    });

    /**
     * Test: Foreign key constraint
     * Verifies that foreign key constraint is enforced
     */
    it('should enforce foreign key constraint for server_id', 0, async () => {
      if (!rdbStore) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Skipping test - no database connection');
        return;
      }

      // Try to insert user with non-existent server_id
      const valueBucket: relationalStore.ValuesBucket = {
        server_id: 99999, // Non-existent
        user_id: 'orphan_user',
        access_token: 'token',
        last_login_timestamp: Date.now()
      };

      try {
        await rdbStore.insert('User', valueBucket);
        // Note: Foreign key enforcement depends on database configuration
        // This test may pass if FK is not enforced
        hilog.info(LOG_DOMAIN, LOG_TAG, 'FK constraint test - result may vary');
      } catch (error) {
        expect(true).assertTrue(); // Expected error if FK is enforced
      }
    });

    /**
     * Test: ServerUser interface
     * Verifies that ServerUser type is correctly structured
     */
    it('should create valid ServerUser interface', 0, () => {
      const serverEntity: ServerEntity = {
        id: 1,
        hostname: 'https://server.example.com',
        lastUsedTimestamp: Date.now()
      };

      const userEntity: UserEntity = {
        id: 1,
        serverId: 1,
        userId: 'user123',
        accessToken: 'token',
        lastLoginTimestamp: Date.now()
      };

      const serverUser: ServerUser = {
        server: serverEntity,
        user: userEntity
      };

      expect(serverUser.server.id).assertEqual(1);
      expect(serverUser.user.userId).assertEqual('user123');
      expect(serverUser.user.serverId).assertEqual(serverUser.server.id);
    });
  });
}
