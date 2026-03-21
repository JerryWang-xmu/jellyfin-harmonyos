/**
 * DAO 测试
 * 测试 ServerDao, UserDao, DownloadDao 的基本功能
 */

import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import { JellyfinDatabase } from '../../../../main/ets/data/database/JellyfinDatabase';
import { ServerDao } from '../../../../main/ets/data/dao/ServerDao';
import { UserDao } from '../../../../main/ets/data/dao/UserDao';
import { DownloadDao } from '../../../../main/ets/data/dao/DownloadDao';
import { createServerEntity, ServerEntity } from '../../../../main/ets/data/entity/ServerEntity';
import { createUserEntity, UserEntity } from '../../../../main/ets/data/entity/UserEntity';
import { createDownloadEntity, DownloadEntity, DownloadStatus } from '../../../../main/ets/data/entity/DownloadEntity';

export default function DaoTest() {
  describe('ServerDao', () => {
    let database: JellyfinDatabase;
    let serverDao: ServerDao;
    let context: Context;

    beforeEach(async () => {
      context = getContext(this);
      database = new JellyfinDatabase(context);
      await database.initialize();
      serverDao = database.serverDao;
    });

    afterEach(async () => {
      await database.deleteDatabase();
    });

    /**
     * 测试插入服务器
     */
    it('should_insert_server', async () => {
      const server = createServerEntity('Test Server', 'https://example.com', '10.8.0');
      const id = await serverDao.insert(server);

      expect(id).assertGreater(0);
    });

    /**
     * 测试查询服务器
     */
    it('should_query_server_by_id', async () => {
      const server = createServerEntity('Test Server', 'https://example.com', '10.8.0');
      const id = await serverDao.insert(server);

      const retrieved = await serverDao.queryById(id);

      expect(retrieved).assertNotNull();
      expect(retrieved?.name).assertEqual('Test Server');
      expect(retrieved?.url).assertEqual('https://example.com');
    });

    /**
     * 测试查询所有服务器
     */
    it('should_query_all_servers', async () => {
      await serverDao.insert(createServerEntity('Server 1', 'https://server1.com', '10.8.0'));
      await serverDao.insert(createServerEntity('Server 2', 'https://server2.com', '10.8.1'));

      const servers = await serverDao.queryAll();

      expect(servers.length).assertEqual(2);
    });

    /**
     * 测试删除服务器
     */
    it('should_delete_server', async () => {
      const id = await serverDao.insert(createServerEntity('Test Server', 'https://example.com', '10.8.0'));

      await serverDao.delete(id);
      const retrieved = await serverDao.queryById(id);

      expect(retrieved).assertNull();
    });
  });

  describe('UserDao', () => {
    let database: JellyfinDatabase;
    let userDao: UserDao;
    let serverDao: ServerDao;
    let context: Context;
    let serverId: number;

    beforeEach(async () => {
      context = getContext(this);
      database = new JellyfinDatabase(context);
      await database.initialize();
      userDao = database.userDao;
      serverDao = database.serverDao;

      // 创建测试服务器
      serverId = await serverDao.insert(createServerEntity('Test Server', 'https://example.com', '10.8.0'));
    });

    afterEach(async () => {
      await database.deleteDatabase();
    });

    /**
     * 测试插入用户
     */
    it('should_insert_user', async () => {
      const user = createUserEntity(serverId, 'user123', 'test-token');
      const id = await userDao.insert(user);

      expect(id).assertGreater(0);
    });

    /**
     * 测试查询用户
     */
    it('should_query_user_by_server', async () => {
      await userDao.insert(createUserEntity(serverId, 'user123', 'test-token'));

      const users = await userDao.queryByServerId(serverId);

      expect(users.length).assertEqual(1);
      expect(users[0].userId).assertEqual('user123');
    });

    /**
     * 测试更新访问令牌
     */
    it('should_update_access_token', async () => {
      const id = await userDao.insert(createUserEntity(serverId, 'user123', 'old-token'));

      await userDao.updateAccessToken(id, 'new-token');
      const users = await userDao.queryByServerId(serverId);

      expect(users[0].accessToken).assertEqual('new-token');
    });

    /**
     * 测试删除用户
     */
    it('should_delete_user', async () => {
      const id = await userDao.insert(createUserEntity(serverId, 'user123', 'test-token'));

      await userDao.delete(id);
      const users = await userDao.queryByServerId(serverId);

      expect(users.length).assertEqual(0);
    });
  });

  describe('DownloadDao', () => {
    let database: JellyfinDatabase;
    let downloadDao: DownloadDao;
    let context: Context;

    beforeEach(async () => {
      context = getContext(this);
      database = new JellyfinDatabase(context);
      await database.initialize();
      downloadDao = database.downloadDao;
    });

    afterEach(async () => {
      await database.deleteDatabase();
    });

    /**
     * 测试插入下载
     */
    it('should_insert_download', async () => {
      const download = createDownloadEntity('item123', 'Test Movie', '/path/to/file.mp4');
      const id = await downloadDao.insert(download);

      expect(id).assertGreater(0);
    });

    /**
     * 测试查询下载
     */
    it('should_query_download_by_item_id', async () => {
      await downloadDao.insert(createDownloadEntity('item123', 'Test Movie', '/path/to/file.mp4'));

      const download = await downloadDao.queryByItemId('item123');

      expect(download).assertNotNull();
      expect(download?.title).assertEqual('Test Movie');
    });

    /**
     * 测试更新下载进度
     */
    it('should_update_download_progress', async () => {
      const id = await downloadDao.insert(createDownloadEntity('item123', 'Test Movie', '/path/to/file.mp4'));

      await downloadDao.updateProgress(id, 50, DownloadStatus.DOWNLOADING);
      const download = await downloadDao.queryByItemId('item123');

      expect(download?.progress).assertEqual(50);
      expect(download?.status).assertEqual(DownloadStatus.DOWNLOADING);
    });

    /**
     * 测试查询正在下载的项
     */
    it('should_query_downloading_items', async () => {
      await downloadDao.insert(createDownloadEntity('item1', 'Movie 1', '/path1'));
      const id2 = await downloadDao.insert(createDownloadEntity('item2', 'Movie 2', '/path2'));

      await downloadDao.updateProgress(id2, 30, DownloadStatus.DOWNLOADING);

      const downloading = await downloadDao.queryByStatus(DownloadStatus.DOWNLOADING);

      expect(downloading.length).assertEqual(1);
      expect(downloading[0].itemId).assertEqual('item2');
    });

    /**
     * 测试删除下载
     */
    it('should_delete_download', async () => {
      const id = await downloadDao.insert(createDownloadEntity('item123', 'Test Movie', '/path'));

      await downloadDao.delete(id);
      const download = await downloadDao.queryByItemId('item123');

      expect(download).assertNull();
    });
  });
}
