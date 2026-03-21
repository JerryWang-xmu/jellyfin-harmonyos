/**
 * JellyfinDatabase - Main database management class for HarmonyOS.
 * Migrated from Android Room Database to HarmonyOS RdbStore.
 *
 * Uses @ohos.data.relationalStore for database operations.
 */

import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import hilog from '@ohos.hilog';

import { ServerEntityHelper } from '../entity/ServerEntity';
import { UserEntityHelper } from '../entity/UserEntity';
import { DownloadEntityHelper } from '../entity/DownloadEntity';
import { ServerDao } from '../dao/ServerDao';
import { UserDao } from '../dao/UserDao';
import { DownloadDao } from '../dao/DownloadDao';

const LOG_DOMAIN: number = 0xFF00;
const LOG_TAG: string = 'JellyfinDatabase';

export const DATABASE_NAME: string = 'jellyfin.db';
export const DATABASE_VERSION: number = 3;

export class JellyfinDatabase {
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: common.Context;

  // DAO instances
  private serverDaoInstance: ServerDao | null = null;
  private userDaoInstance: UserDao | null = null;
  private downloadDaoInstance: DownloadDao | null = null;

  constructor(context: common.Context) {
    this.context = context;
  }

  /**
   * Initialize the database. Must be called before any database operations.
   */
  async initialize(): Promise<void> {
    try {
      const config: relationalStore.StoreConfig = {
        name: DATABASE_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };

      this.rdbStore = await relationalStore.getRdbStore(this.context, config);

      hilog.info(LOG_DOMAIN, LOG_TAG, 'Database opened successfully, version: %d', DATABASE_VERSION);

      // Create tables if not exist
      await this.createTables();

      // Initialize DAOs
      if (this.rdbStore !== null) {
        this.serverDaoInstance = new ServerDao(this.rdbStore);
        this.userDaoInstance = new UserDao(this.rdbStore);
        this.downloadDaoInstance = new DownloadDao(this.rdbStore);
      }

      hilog.info(LOG_DOMAIN, LOG_TAG, 'Database initialization complete');
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to initialize database: %{public}s', JSON.stringify(error));
      const err = error as Error;
      throw new Error('Failed to initialize database: ' + (err?.message ?? 'unknown error'));
    }
  }

  /**
   * Create all database tables
   */
  private async createTables(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('Database not initialized');
    }

    try {
      // Create Server table
      await this.rdbStore.executeSql(ServerEntityHelper.getCreateTableSql());
      await this.rdbStore.executeSql(ServerEntityHelper.getCreateIndexSql());
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Server table created');

      // Create User table
      await this.rdbStore.executeSql(UserEntityHelper.getCreateTableSql());
      await this.rdbStore.executeSql(UserEntityHelper.getCreateIndexSql());
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'User table created');

      // Create Download table
      await this.rdbStore.executeSql(DownloadEntityHelper.getCreateTableSql());
      await this.rdbStore.executeSql(DownloadEntityHelper.getCreateIndexSql());
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'Download table created');
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to create tables: %{public}s', JSON.stringify(error));
      const err = error as Error;
      throw new Error('Failed to create tables: ' + (err?.message ?? 'unknown error'));
    }
  }

  /**
   * Get the RdbStore instance
   */
  getRdbStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('Database not initialized. Call initialize() first.');
    }
    return this.rdbStore;
  }

  /**
   * Get Server DAO instance
   */
  get serverDao(): ServerDao {
    if (!this.serverDaoInstance) {
      throw new Error('Database not initialized. Call initialize() first.');
    }
    return this.serverDaoInstance;
  }

  /**
   * Get User DAO instance
   */
  get userDao(): UserDao {
    if (!this.userDaoInstance) {
      throw new Error('Database not initialized. Call initialize() first.');
    }
    return this.userDaoInstance;
  }

  /**
   * Get Download DAO instance
   */
  get downloadDao(): DownloadDao {
    if (!this.downloadDaoInstance) {
      throw new Error('Database not initialized. Call initialize() first.');
    }
    return this.downloadDaoInstance;
  }

  /**
   * Close the database connection
   */
  async close(): Promise<void> {
    if (this.rdbStore) {
      try {
        await relationalStore.deleteRdbStore(this.context, DATABASE_NAME);
        this.rdbStore = null;
        this.serverDaoInstance = null;
        this.userDaoInstance = null;
        this.downloadDaoInstance = null;
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Database closed');
      } catch (error) {
        hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to close database: %{public}s', JSON.stringify(error));
        const err = error as Error;
        throw new Error('Failed to close database: ' + (err?.message ?? 'unknown error'));
      }
    }
  }

  /**
   * Delete the entire database (useful for destructive migration)
   */
  async deleteDatabase(): Promise<void> {
    try {
      await relationalStore.deleteRdbStore(this.context, DATABASE_NAME);
      this.rdbStore = null;
      this.serverDaoInstance = null;
      this.userDaoInstance = null;
      this.downloadDaoInstance = null;
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Database deleted');
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to delete database: %{public}s', JSON.stringify(error));
      const err = error as Error;
      throw new Error('Failed to delete database: ' + (err?.message ?? 'unknown error'));
    }
  }

  /**
   * Run a transaction
   */
  async runInTransaction(action: () => Promise<void>): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('Database not initialized');
    }

    await this.rdbStore.beginTransaction();
    try {
      await action();
      await this.rdbStore.commit();
    } catch (error) {
      await this.rdbStore.rollBack();
      const err = error as Error;
      throw new Error('Transaction failed: ' + (err?.message ?? 'unknown error'));
    }
  }
}

// Singleton instance holder
let databaseInstance: JellyfinDatabase | null = null;

/**
 * Get or create the database singleton instance
 */
export async function getDatabase(context: common.Context): Promise<JellyfinDatabase> {
  if (!databaseInstance) {
    databaseInstance = new JellyfinDatabase(context);
    await databaseInstance.initialize();
  }
  return databaseInstance;
}

/**
 * Close and reset the database instance
 */
export async function resetDatabase(): Promise<void> {
  if (databaseInstance) {
    await databaseInstance.close();
    databaseInstance = null;
  }
}
