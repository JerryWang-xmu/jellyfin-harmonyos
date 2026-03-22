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
 * UserDao - Data Access Object for User entity.
 * Migrated from Android Room Dao to HarmonyOS RdbStore.
 *
 * Original: org.jellyfin.mobile.data.dao.UserDao
 */

import relationalStore from '@ohos.data.relationalStore';
import hilog from '@ohos.hilog';

import { UserEntity, UserEntityHelper, UserEntityInput, ServerUser } from '../entity/UserEntity';
import { ServerEntity, ServerEntityHelper } from '../entity/ServerEntity';

const LOG_DOMAIN: number = 0xFF00;
const LOG_TAG: string = 'UserDao';

export class UserDao {
  private rdbStore: relationalStore.RdbStore;

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  /**
   * Insert a new user into the database.
   * Equivalent to @Insert(onConflict = OnConflictStrategy.ABORT)
   * @param entity UserEntityInput to insert (without id)
   * @returns The row ID of the inserted user, or -1 on conflict/error
   */
  async insert(entity: UserEntityInput): Promise<number> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        server_id: entity.serverId,
        user_id: entity.userId,
        access_token: entity.accessToken,
        last_login_timestamp: entity.lastLoginTimestamp
      };

      const rowId = await this.rdbStore.insert(UserEntityHelper.TABLE_NAME, valueBucket);
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Inserted user with rowId: %d', rowId);
      return rowId;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to insert user: %{public}s', JSON.stringify(error));
      return -1;
    }
  }

  /**
   * Insert a new user with server ID, user ID, and access token.
   * Convenience method matching Android: insert(serverId: Long, userId: String, accessToken: String?)
   * @param serverId The server ID
   * @param userId The user ID (string from Jellyfin server)
   * @param accessToken The access token (can be null)
   * @returns The row ID of the inserted user
   */
  async insertWithCredentials(serverId: number, userId: string, accessToken: string | null): Promise<number> {
    const entity = UserEntityHelper.create(serverId, userId, accessToken);
    return await this.insert(entity);
  }

  /**
   * Upsert a user - insert if not exists, update if exists.
   * Equivalent to @Transaction upsert(serverId: Long, userId: String, accessToken: String?): Long
   * @param serverId The server ID
   * @param userId The user ID (string from Jellyfin server)
   * @param accessToken The access token
   * @returns The user's row ID
   */
  async upsert(serverId: number, userId: string, accessToken: string | null): Promise<number> {
    try {
      const existingUser = await this.getByUserId(serverId, userId);

      if (existingUser) {
        await this.update(existingUser.id, accessToken);
        return existingUser.id;
      } else {
        return await this.insertWithCredentials(serverId, userId, accessToken);
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to upsert user: %{public}s', JSON.stringify(error));
      return -1;
    }
  }

  /**
   * Get a ServerUser (user with server info) by server ID and user row ID.
   * Equivalent to @Transaction @Query("SELECT * FROM User WHERE server_id = :serverId AND id = :userId")
   * @param serverId The server ID
   * @param userId The user's row ID (number)
   * @returns ServerUser or null if not found
   */
  async getServerUserById(serverId: number, userId: number): Promise<ServerUser | null> {
    try {
      const sql: string = 'SELECT u.*, s.* FROM User u INNER JOIN Server s ON u.server_id = s.id WHERE u.server_id = ? AND u.id = ?';

      const resultSet = await this.rdbStore.querySql(sql, [serverId.toString(), userId.toString()]);

      try {
        if (resultSet.goToFirstRow()) {
          return this.mapResultSetToServerUser(resultSet);
        }
        return null;
      } finally {
        resultSet.close();
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get server user by id: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * Get a ServerUser (user with server info) by server ID and user ID string.
   * Equivalent to @Transaction @Query("SELECT * FROM User WHERE server_id = :serverId AND user_id = :userId")
   * @param serverId The server ID
   * @param userId The user ID (string from Jellyfin server)
   * @returns ServerUser or null if not found
   */
  async getServerUser(serverId: number, userId: string): Promise<ServerUser | null> {
    try {
      const sql: string = 'SELECT u.*, s.* FROM User u INNER JOIN Server s ON u.server_id = s.id WHERE u.server_id = ? AND u.user_id = ?';

      const resultSet = await this.rdbStore.querySql(sql, [serverId.toString(), userId]);

      try {
        if (resultSet.goToFirstRow()) {
          return this.mapResultSetToServerUser(resultSet);
        }
        return null;
      } finally {
        resultSet.close();
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get server user: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * Get a user by server ID and user ID string.
   * Equivalent to @Query("SELECT * FROM User WHERE server_id = :serverId AND user_id = :userId")
   * @param serverId The server ID
   * @param userId The user ID (string from Jellyfin server)
   * @returns UserEntity or null if not found
   */
  async getByUserId(serverId: number, userId: string): Promise<UserEntity | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(UserEntityHelper.TABLE_NAME);
      predicates.equalTo('server_id', serverId);
      predicates.equalTo('user_id', userId);

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
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get user by userId: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * Get all users for a specific server.
   * Equivalent to @Query("SELECT * FROM User WHERE server_id = :serverId")
   * @param serverId The server ID
   * @returns Array of UserEntity
   */
  async getAllForServer(serverId: number): Promise<UserEntity[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(UserEntityHelper.TABLE_NAME);
      predicates.equalTo('server_id', serverId);

      const resultSet = await this.rdbStore.query(predicates);
      const users: UserEntity[] = [];

      try {
        while (resultSet.goToNextRow()) {
          const entity = this.mapResultSetToEntity(resultSet);
          if (entity !== null) {
            users.push(entity);
          }
        }
        return users;
      } finally {
        resultSet.close();
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get all users for server: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * Update the access token for a user.
   * Equivalent to @Query("UPDATE User SET access_token = :accessToken WHERE id = :userId")
   * @param userId The user's row ID
   * @param accessToken The new access token
   * @returns Number of rows affected
   */
  async update(userId: number, accessToken: string | null): Promise<number> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        access_token: accessToken
      };

      const predicates = new relationalStore.RdbPredicates(UserEntityHelper.TABLE_NAME);
      predicates.equalTo('id', userId);

      const rowsAffected = await this.rdbStore.update(valueBucket, predicates);
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Updated user access token, rows affected: %d', rowsAffected);
      return rowsAffected;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to update user: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  /**
   * Logout a user by clearing their access token.
   * Equivalent to @Query("UPDATE User SET access_token = NULL WHERE id = :userId")
   * @param userId The user's row ID
   * @returns Number of rows affected
   */
  async logout(userId: number): Promise<number> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        access_token: null
      };

      const predicates = new relationalStore.RdbPredicates(UserEntityHelper.TABLE_NAME);
      predicates.equalTo('id', userId);

      const rowsAffected = await this.rdbStore.update(valueBucket, predicates);
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Logged out user, rows affected: %d', rowsAffected);
      return rowsAffected;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to logout user: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  /**
   * Delete a user by ID.
   * @param userId The user's row ID
   * @returns Number of rows affected
   */
  async delete(userId: number): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(UserEntityHelper.TABLE_NAME);
      predicates.equalTo('id', userId);

      const rowsAffected = await this.rdbStore.delete(predicates);
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Deleted user, rows affected: %d', rowsAffected);
      return rowsAffected;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to delete user: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  /**
   * Map a result set row to UserEntity
   */
  private mapResultSetToEntity(resultSet: relationalStore.ResultSet): UserEntity | null {
    try {
      const id = resultSet.getLong(resultSet.getColumnIndex('id'));
      const serverId = resultSet.getLong(resultSet.getColumnIndex('server_id'));
      const userId = resultSet.getString(resultSet.getColumnIndex('user_id'));
      const accessTokenIndex = resultSet.getColumnIndex('access_token');
      const accessToken = resultSet.isColumnNull(accessTokenIndex) ? null : resultSet.getString(accessTokenIndex);
      const lastLoginTimestamp = resultSet.getLong(resultSet.getColumnIndex('last_login_timestamp'));

      return UserEntityHelper.fromValues(id, serverId, userId, accessToken, lastLoginTimestamp);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to map result set to entity: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * Map a joined result set row to ServerUser
   */
  private mapResultSetToServerUser(resultSet: relationalStore.ResultSet): ServerUser | null {
    try {
      // Map user entity
      const userId = resultSet.getLong(resultSet.getColumnIndex('id'));
      const serverId = resultSet.getLong(resultSet.getColumnIndex('server_id'));
      const jellyfinUserId = resultSet.getString(resultSet.getColumnIndex('user_id'));
      const accessTokenIndex = resultSet.getColumnIndex('access_token');
      const accessToken = resultSet.isColumnNull(accessTokenIndex) ? null : resultSet.getString(accessTokenIndex);
      const lastLoginTimestamp = resultSet.getLong(resultSet.getColumnIndex('last_login_timestamp'));

      const user = UserEntityHelper.fromValues(userId, serverId, jellyfinUserId, accessToken, lastLoginTimestamp);

      // Map server entity
      const serverIdCol = resultSet.getLong(resultSet.getColumnIndex('id'));
      const hostname = resultSet.getString(resultSet.getColumnIndex('hostname'));
      const lastUsedTimestamp = resultSet.getLong(resultSet.getColumnIndex('last_used_timestamp'));

      const server = ServerEntityHelper.fromValues(serverIdCol, hostname, lastUsedTimestamp);

      const result: ServerUser = { user: user, server: server };
      return result;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to map result set to server user: %{public}s', JSON.stringify(error));
      return null;
    }
  }
}
