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
 * - bridge/NativeInterface.test.ets - NativeInterface device ID caching tests
 * - bridge/WebappFunctionChannel.test.ets - WebappFunctionChannel native-to-web forwarding tests
 * - bridge/BridgeChannel.test.ets - BridgeChannel JS bridge queue/batch and serialization tests
 * - bridge/BridgeManager.test.ets - BridgeManager lifecycle optimization tests
 * - core/AppDependency.test.ets - AppDependency singleton DI container and parallel initialization tests
 * - webapp/WebViewPage.test.ets - WebViewPage state management and optimization tests
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
import nativeInterfaceTest from './bridge/NativeInterface.test';
import webappFunctionChannelTest from './bridge/WebappFunctionChannel.test';
import bridgeChannelTest from './bridge/BridgeChannel.test';
import bridgeManagerTest from './bridge/BridgeManager.test';
import appDependencyTest from './core/AppDependency.test';
import webViewPageTest from './webapp/WebViewPage.test';

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
    nativeInterfaceTest();
    webappFunctionChannelTest();
    bridgeChannelTest();
    bridgeManagerTest();
    appDependencyTest();
    webViewPageTest();
  });
}
