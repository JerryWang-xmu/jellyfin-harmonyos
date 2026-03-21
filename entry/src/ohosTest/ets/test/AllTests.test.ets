/**
 * Jellyfin HarmonyOS - Unit Test Suite
 * Main test entry file that imports and runs all test modules
 *
 * Test Modules:
 * - data/ServerDao.test.ets - Server database CRUD operations
 * - data/UserDao.test.ets - User database CRUD operations
 * - data/DownloadDao.test.ets - Download database CRUD operations
 * - data/DatabaseMigration.test.ets - Database schema and migrations
 * - event/ActivityEventHandler.test.ets - Event system tests
 * - preferences/AppPreferences.test.ets - Preferences tests
 * - player/AVPlayerAdapter.test.ets - Player adapter tests
 */

import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';

// Import test modules
import serverDaoTest from './data/ServerDao.test';
import userDaoTest from './data/UserDao.test';
import downloadDaoTest from './data/DownloadDao.test';
import databaseMigrationTest from './data/DatabaseMigration.test';
import activityEventHandlerTest from './event/ActivityEventHandler.test';
import appPreferencesTest from './preferences/AppPreferences.test';
import avPlayerAdapterTest from './player/AVPlayerAdapter.test';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'JellyfinTestSuite';

export default function testSuite() {
  describe('Jellyfin HarmonyOS Test Suite', () => {
    beforeAll(() => {
      hilog.info(LOG_DOMAIN, LOG_TAG, '========================================');
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Jellyfin HarmonyOS Unit Tests Starting');
      hilog.info(LOG_DOMAIN, LOG_TAG, '========================================');
    });

    afterAll(() => {
      hilog.info(LOG_DOMAIN, LOG_TAG, '========================================');
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Jellyfin HarmonyOS Unit Tests Completed');
      hilog.info(LOG_DOMAIN, LOG_TAG, '========================================');
    });

    // Run all test modules
    serverDaoTest();
    userDaoTest();
    downloadDaoTest();
    databaseMigrationTest();
    activityEventHandlerTest();
    appPreferencesTest();
    avPlayerAdapterTest();
  });
}
