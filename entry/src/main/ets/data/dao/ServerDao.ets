/**
 * ServerDao - Data Access Object for Server entity.
 * Migrated from Android Room Dao to HarmonyOS RdbStore.
 *
 * Original: org.jellyfin.mobile.data.dao.ServerDao
 */

import relationalStore from '@ohos.data.relationalStore';
import hilog from '@ohos.hilog';

import { ServerEntity, ServerEntityHelper, ServerEntityInput } from '../entity/ServerEntity';

const LOG_DOMAIN: number = 0xFF00;
const LOG_TAG: string = 'ServerDao';

export class ServerDao {
  private rdbStore: relationalStore.RdbStore;

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  /**
   * Insert a new server into the database.
   * Equivalent to @Insert(onConflict = OnConflictStrategy.ABORT)
   * @param entity ServerEntityInput to insert (without id)
   * @returns The row ID of the inserted server, or -1 on conflict/error
   */
  async insert(entity: ServerEntityInput): Promise<number> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        hostname: entity.hostname,
        last_used_timestamp: entity.lastUsedTimestamp
      };

      const rowId = await this.rdbStore.insert(ServerEntityHelper.TABLE_NAME, valueBucket);
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Inserted server with rowId: %d', rowId);
      return rowId;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to insert server: %{public}s', JSON.stringify(error));
      return -1;
    }
  }

  /**
   * Insert a new server by hostname.
   * Convenience method matching Android: insert(hostname: String)
   * @param hostname The server hostname
   * @returns The row ID of the inserted server
   */
  async insertByHostname(hostname: string): Promise<number> {
    const entity = ServerEntityHelper.create(hostname);
    return await this.insert(entity);
  }

  /**
   * Get a server by ID.
   * Equivalent to @Query("SELECT * FROM Server WHERE id = :id")
   * @param id The server ID
   * @returns ServerEntity or null if not found
   */
  async getServer(id: number): Promise<ServerEntity | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(ServerEntityHelper.TABLE_NAME);
      predicates.equalTo('id', id);

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
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get server by id: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * Get all servers ordered by last used timestamp (most recent first).
   * Equivalent to @Query("SELECT * FROM Server ORDER BY last_used_timestamp DESC")
   * @returns Array of ServerEntity
   */
  async getAllServers(): Promise<ServerEntity[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(ServerEntityHelper.TABLE_NAME);
      predicates.orderByDesc('last_used_timestamp');

      const resultSet = await this.rdbStore.query(predicates);
      const servers: ServerEntity[] = [];

      try {
        while (resultSet.goToNextRow()) {
          const entity = this.mapResultSetToEntity(resultSet);
          if (entity !== null) {
            servers.push(entity);
          }
        }
        return servers;
      } finally {
        resultSet.close();
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get all servers: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * Get a server by hostname.
   * Equivalent to @Query("SELECT * FROM Server WHERE hostname = :hostname")
   * @param hostname The server hostname
   * @returns ServerEntity or null if not found
   */
  async getServerByHostname(hostname: string): Promise<ServerEntity | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(ServerEntityHelper.TABLE_NAME);
      predicates.equalTo('hostname', hostname);

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
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get server by hostname: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * Update the last used timestamp for a server to current time.
   * @param id The server ID
   * @returns Number of rows affected
   */
  async updateLastUsed(id: number): Promise<number> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        last_used_timestamp: Date.now()
      };

      const predicates = new relationalStore.RdbPredicates(ServerEntityHelper.TABLE_NAME);
      predicates.equalTo('id', id);

      const rowsAffected = await this.rdbStore.update(valueBucket, predicates);
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Updated server last used, rows affected: %d', rowsAffected);
      return rowsAffected;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to update server last used: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  /**
   * Delete a server by ID.
   * @param id The server ID
   * @returns Number of rows affected
   */
  async delete(id: number): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(ServerEntityHelper.TABLE_NAME);
      predicates.equalTo('id', id);

      const rowsAffected = await this.rdbStore.delete(predicates);
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Deleted server, rows affected: %d', rowsAffected);
      return rowsAffected;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to delete server: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  /**
   * Map a result set row to ServerEntity
   */
  private mapResultSetToEntity(resultSet: relationalStore.ResultSet): ServerEntity | null {
    try {
      const id = resultSet.getLong(resultSet.getColumnIndex('id'));
      const hostname = resultSet.getString(resultSet.getColumnIndex('hostname'));
      const lastUsedTimestamp = resultSet.getLong(resultSet.getColumnIndex('last_used_timestamp'));

      return ServerEntityHelper.fromValues(id, hostname, lastUsedTimestamp);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to map result set to entity: %{public}s', JSON.stringify(error));
      return null;
    }
  }
}
