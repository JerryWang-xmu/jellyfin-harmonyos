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
