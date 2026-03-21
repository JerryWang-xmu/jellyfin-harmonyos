/**
 * Server entity representing a Jellyfin server connection.
 * Migrated from Android Room Entity to HarmonyOS ArkTS.
 */

export interface ServerEntity {
  id: number;
  hostname: string;
  lastUsedTimestamp: number;
}

/**
 * Server entity without ID (for insertion)
 */
export interface ServerEntityInput {
  hostname: string;
  lastUsedTimestamp: number;
}

export class ServerEntityHelper {
  static readonly TABLE_NAME: string = 'Server';
  static readonly ID: string = 'id';
  static readonly HOSTNAME: string = 'hostname';
  static readonly LAST_USED_TIMESTAMP: string = 'last_used_timestamp';

  /**
   * Create a new ServerEntityInput with auto-generated timestamp
   */
  static create(hostname: string): ServerEntityInput {
    const entity: ServerEntityInput = {
      hostname: hostname,
      lastUsedTimestamp: Date.now()
    };
    return entity;
  }

  /**
   * Create a ServerEntity with specific id (for database results)
   */
  static fromValues(id: number, hostname: string, lastUsedTimestamp: number): ServerEntity {
    const entity: ServerEntity = {
      id: id,
      hostname: hostname,
      lastUsedTimestamp: lastUsedTimestamp
    };
    return entity;
  }

  /**
   * Get CREATE TABLE SQL statement
   */
  static getCreateTableSql(): string {
    return 'CREATE TABLE IF NOT EXISTS Server (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'hostname TEXT UNIQUE NOT NULL, ' +
      'last_used_timestamp INTEGER NOT NULL)';
  }

  /**
   * Get CREATE INDEX SQL statement
   */
  static getCreateIndexSql(): string {
    return 'CREATE UNIQUE INDEX IF NOT EXISTS index_Server_hostname ON Server (hostname)';
  }
}
