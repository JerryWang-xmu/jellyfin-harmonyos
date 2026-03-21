/**
 * 数据库测试
 * 测试 JellyfinDatabase 的基本功能
 */

import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import relationalStore from '@ohos.data.relationalStore';
import { JellyfinDatabase, DATABASE_NAME, DATABASE_VERSION } from '../../../../main/ets/data/database/JellyfinDatabase';
import { ServerEntityHelper, createServerEntity } from '../../../../main/ets/data/entity/ServerEntity';
import { UserEntityHelper, createUserEntity } from '../../../../main/ets/data/entity/UserEntity';
import { DownloadEntityHelper, createDownloadEntity } from '../../../../main/ets/data/entity/DownloadEntity';

export default function DatabaseTest() {
  describe('JellyfinDatabase', () => {
    let database: JellyfinDatabase;
    let context: Context;

    beforeEach(async () => {
      // 获取测试上下文
      context = getContext(this);
      database = new JellyfinDatabase(context);
      await database.initialize();
    });

    afterEach(async () => {
      await database.deleteDatabase();
    });

    /**
     * 测试数据库初始化
     */
    it('should_initialize_database_correctly', async () => {
      expect(database).assertNotNull();
      expect(database.getRdbStore()).assertNotNull();
    });

    /**
     * 测试数据库版本
     */
    it('should_have_correct_version', () => {
      expect(DATABASE_VERSION).assertEqual(3);
    });

    /**
     * 测试数据库表创建
     */
    it('should_create_all_tables', async () => {
      const rdbStore = database.getRdbStore();

      // 验证 Server 表存在
      const serverSql = "SELECT name FROM sqlite_master WHERE type='table' AND name='Server'";
      let resultSet = await rdbStore.querySql(serverSql);
      expect(resultSet.rowCount).assertEqual(1);
      resultSet.close();

      // 验证 User 表存在
      const userSql = "SELECT name FROM sqlite_master WHERE type='table' AND name='User'";
      resultSet = await rdbStore.querySql(userSql);
      expect(resultSet.rowCount).assertEqual(1);
      resultSet.close();

      // 验证 Download 表存在
      const downloadSql = "SELECT name FROM sqlite_master WHERE type='table' AND name='Download'";
      resultSet = await rdbStore.querySql(downloadSql);
      expect(resultSet.rowCount).assertEqual(1);
      resultSet.close();
    });

    /**
     * 测试事务
     */
    it('should_run_transaction_correctly', async () => {
      let transactionExecuted = false;

      await database.runInTransaction(async () => {
        transactionExecuted = true;
      });

      expect(transactionExecuted).assertTrue();
    });
  });
}
