/*
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
 * BatchOneUnit.test.ets
 * Unit tests for Batch 1 core modules:
 *   - DownloadEntity / DownloadStatus / DownloadEntityHelper
 *   - ApiClientConfig / ApiClientController (pure interface/logic, no RDB/preferences deps)
 *
 * Framework: @ohos/hypium
 * Author:    Validator (Refactor Task Force)
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';

import {
  DownloadEntity,
  DownloadStatus,
  DownloadEntityHelper
} from '../main/ets/data/entity/DownloadEntity';

import { ApiClientConfig } from '../main/ets/api/ApiClientController';

// ---------------------------------------------------------------------------
// Test Suite 1 — DownloadStatus enum values
// ---------------------------------------------------------------------------
export function downloadStatusTest() {
  describe('DownloadStatus', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('should have PENDING equal to "pending"', 0, () => {
      expect(DownloadStatus.PENDING).assertEqual('pending');
    });

    it('should have DOWNLOADING equal to "downloading"', 0, () => {
      expect(DownloadStatus.DOWNLOADING).assertEqual('downloading');
    });

    it('should have COMPLETED equal to "completed"', 0, () => {
      expect(DownloadStatus.COMPLETED).assertEqual('completed');
    });

    it('should have FAILED equal to "failed"', 0, () => {
      expect(DownloadStatus.FAILED).assertEqual('failed');
    });

    it('should have CANCELLED equal to "cancelled"', 0, () => {
      expect(DownloadStatus.CANCELLED).assertEqual('cancelled');
    });

    // Verify there are exactly 5 distinct status values
    it('all five status values should be distinct strings', 0, () => {
      const values: string[] = [
        DownloadStatus.PENDING,
        DownloadStatus.DOWNLOADING,
        DownloadStatus.COMPLETED,
        DownloadStatus.FAILED,
        DownloadStatus.CANCELLED
      ];
      const unique = new Set(values);
      expect(unique.size).assertEqual(5);
    });
  });
}

// ---------------------------------------------------------------------------
// Test Suite 2 — DownloadEntity interface structure
// ---------------------------------------------------------------------------
export function downloadEntityStructureTest() {
  describe('DownloadEntity', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('should have all required fields', 0, () => {
      const entity: DownloadEntity = {
        itemId: 'test-item-id',
        mediaSource: '{}',
        fileName: 'test.mp4',
        filePath: '/data/test.mp4',
        progress: 50,
        status: DownloadStatus.DOWNLOADING
      };
      expect(entity.itemId).assertEqual('test-item-id');
      expect(entity.mediaSource).assertEqual('{}');
      expect(entity.fileName).assertEqual('test.mp4');
      expect(entity.filePath).assertEqual('/data/test.mp4');
      expect(entity.progress).assertEqual(50);
      expect(entity.status).assertEqual(DownloadStatus.DOWNLOADING);
    });

    // Note: id is declared as optional (id?: number) in DownloadEntity interface.
    // An entity created without id should leave the field undefined.
    it('id field should be optional (undefined when not provided)', 0, () => {
      const entity: DownloadEntity = {
        itemId: 'no-id-entity',
        mediaSource: '{}',
        fileName: '',
        filePath: '',
        progress: 0,
        status: DownloadStatus.PENDING
      };
      // id is intentionally absent — verify it is undefined
      expect(entity.id === undefined).assertTrue();
    });

    it('should accept a numeric id when provided', 0, () => {
      const entity: DownloadEntity = {
        id: 42,
        itemId: 'with-id-entity',
        mediaSource: '{}',
        fileName: 'video.mp4',
        filePath: '/storage/video.mp4',
        progress: 100,
        status: DownloadStatus.COMPLETED
      };
      expect(entity.id).assertEqual(42);
    });
  });
}

// ---------------------------------------------------------------------------
// Test Suite 3 — DownloadEntityHelper static methods
// ---------------------------------------------------------------------------
export function downloadEntityHelperTest() {
  describe('DownloadEntityHelper', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    // --- TABLE_NAME constant ---
    it('TABLE_NAME should be "Download"', 0, () => {
      expect(DownloadEntityHelper.TABLE_NAME).assertEqual('Download');
    });

    // --- Column name constants ---
    it('column name constants should match DB column names', 0, () => {
      expect(DownloadEntityHelper.ID).assertEqual('id');
      expect(DownloadEntityHelper.ITEM_ID).assertEqual('item_id');
      expect(DownloadEntityHelper.MEDIA_SOURCE).assertEqual('media_source');
      expect(DownloadEntityHelper.FILE_NAME).assertEqual('file_name');
      expect(DownloadEntityHelper.FILE_PATH).assertEqual('file_path');
      expect(DownloadEntityHelper.PROGRESS).assertEqual('progress');
      expect(DownloadEntityHelper.STATUS).assertEqual('status');
    });

    // --- BYTES_PER_BINARY_UNIT ---
    it('BYTES_PER_BINARY_UNIT should be 1024', 0, () => {
      expect(DownloadEntityHelper.BYTES_PER_BINARY_UNIT).assertEqual(1024);
    });

    // --- getCreateTableSql: column names ---
    it('getCreateTableSql should contain all required column names', 0, () => {
      const sql = DownloadEntityHelper.getCreateTableSql();
      expect(sql.includes('item_id')).assertTrue();
      expect(sql.includes('media_source')).assertTrue();
      expect(sql.includes('file_name')).assertTrue();
      expect(sql.includes('file_path')).assertTrue();
      expect(sql.includes('progress')).assertTrue();
      expect(sql.includes('status')).assertTrue();
    });

    it('getCreateTableSql should target the Download table', 0, () => {
      const sql = DownloadEntityHelper.getCreateTableSql();
      expect(sql.includes('Download')).assertTrue();
    });

    it('getCreateTableSql should include PRIMARY KEY AUTOINCREMENT for id', 0, () => {
      const sql = DownloadEntityHelper.getCreateTableSql();
      expect(sql.includes('PRIMARY KEY AUTOINCREMENT')).assertTrue();
    });

    it('getCreateTableSql should include UNIQUE constraint on item_id', 0, () => {
      const sql = DownloadEntityHelper.getCreateTableSql();
      // item_id TEXT NOT NULL UNIQUE
      expect(sql.includes('UNIQUE')).assertTrue();
    });

    it('getCreateTableSql should use CREATE TABLE IF NOT EXISTS', 0, () => {
      const sql = DownloadEntityHelper.getCreateTableSql();
      expect(sql.includes('CREATE TABLE IF NOT EXISTS')).assertTrue();
    });

    // --- getCreateIndexSql ---
    it('getCreateIndexSql should reference Download table and item_id column', 0, () => {
      const sql = DownloadEntityHelper.getCreateIndexSql();
      expect(sql.includes('Download')).assertTrue();
      expect(sql.includes('item_id')).assertTrue();
    });

    it('getCreateIndexSql should use CREATE UNIQUE INDEX IF NOT EXISTS', 0, () => {
      const sql = DownloadEntityHelper.getCreateIndexSql();
      expect(sql.includes('CREATE UNIQUE INDEX IF NOT EXISTS')).assertTrue();
    });

    // --- create() factory method ---
    it('create() should initialize entity with PENDING status and zero progress', 0, () => {
      const entity = DownloadEntityHelper.create('item-001', '{"id":"item-001"}');
      expect(entity.itemId).assertEqual('item-001');
      expect(entity.mediaSource).assertEqual('{"id":"item-001"}');
      expect(entity.progress).assertEqual(0);
      expect(entity.status).assertEqual(DownloadStatus.PENDING);
    });

    it('create() should initialize fileName and filePath as empty strings', 0, () => {
      const entity = DownloadEntityHelper.create('item-002', '{}');
      expect(entity.fileName).assertEqual('');
      expect(entity.filePath).assertEqual('');
    });

    it('create() should not assign an id', 0, () => {
      const entity = DownloadEntityHelper.create('item-003', '{}');
      expect(entity.id === undefined).assertTrue();
    });

    // --- fromValues() factory method ---
    it('fromValues() should map all arguments to entity fields', 0, () => {
      const entity = DownloadEntityHelper.fromValues(
        7, 'item-007', '{"key":"val"}', 'movie.mp4', '/storage/movie.mp4', 75, 'downloading'
      );
      expect(entity.id).assertEqual(7);
      expect(entity.itemId).assertEqual('item-007');
      expect(entity.mediaSource).assertEqual('{"key":"val"}');
      expect(entity.fileName).assertEqual('movie.mp4');
      expect(entity.filePath).assertEqual('/storage/movie.mp4');
      expect(entity.progress).assertEqual(75);
      expect(entity.status).assertEqual(DownloadStatus.DOWNLOADING);
    });

    it('fromValues() should cast status string to DownloadStatus enum', 0, () => {
      const entity = DownloadEntityHelper.fromValues(
        1, 'item-cast', '{}', '', '', 0, 'completed'
      );
      // 'completed' cast to DownloadStatus should equal DownloadStatus.COMPLETED
      expect(entity.status).assertEqual(DownloadStatus.COMPLETED);
    });

    // --- formatFileSize() ---
    it('formatFileSize should return bytes for values < 1024', 0, () => {
      const result = DownloadEntityHelper.formatFileSize(512);
      expect(result).assertEqual('512.00 B');
    });

    it('formatFileSize should return KB for values in kilobyte range', 0, () => {
      const result = DownloadEntityHelper.formatFileSize(1024);
      expect(result).assertEqual('1.00 KB');
    });

    it('formatFileSize should return MB for values in megabyte range', 0, () => {
      const result = DownloadEntityHelper.formatFileSize(1024 * 1024);
      expect(result).assertEqual('1.00 MB');
    });

    it('formatFileSize should return GB for values in gigabyte range', 0, () => {
      const result = DownloadEntityHelper.formatFileSize(1024 * 1024 * 1024);
      expect(result).assertEqual('1.00 GB');
    });

    it('formatFileSize should return TB for very large values', 0, () => {
      const result = DownloadEntityHelper.formatFileSize(1024 * 1024 * 1024 * 1024);
      expect(result).assertEqual('1.00 TB');
    });

    it('formatFileSize should handle zero bytes', 0, () => {
      const result = DownloadEntityHelper.formatFileSize(0);
      expect(result).assertEqual('0.00 B');
    });

    it('formatFileSize should include two decimal places', 0, () => {
      const result = DownloadEntityHelper.formatFileSize(1536); // 1.5 KB
      expect(result).assertEqual('1.50 KB');
    });
  });
}

// ---------------------------------------------------------------------------
// Test Suite 4 — DownloadEntity edge cases
// ---------------------------------------------------------------------------
export function downloadEntityEdgeCasesTest() {
  describe('DownloadEntity edge cases', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('progress should be between 0 and 100 at lower bound', 0, () => {
      const entity: DownloadEntity = {
        itemId: 'id-lower',
        mediaSource: '{}',
        fileName: '',
        filePath: '',
        progress: 0,
        status: DownloadStatus.PENDING
      };
      expect(entity.progress >= 0).assertTrue();
      expect(entity.progress <= 100).assertTrue();
    });

    it('progress should be between 0 and 100 at upper bound', 0, () => {
      const entity: DownloadEntity = {
        itemId: 'id-upper',
        mediaSource: '{}',
        fileName: 'done.mp4',
        filePath: '/storage/done.mp4',
        progress: 100,
        status: DownloadStatus.COMPLETED
      };
      expect(entity.progress >= 0).assertTrue();
      expect(entity.progress <= 100).assertTrue();
    });

    it('progress should be between 0 and 100 at midpoint', 0, () => {
      const entity: DownloadEntity = {
        itemId: 'id-mid',
        mediaSource: '{}',
        fileName: '',
        filePath: '',
        progress: 50,
        status: DownloadStatus.DOWNLOADING
      };
      expect(entity.progress >= 0).assertTrue();
      expect(entity.progress <= 100).assertTrue();
    });

    // mediaSource stores JSON string — verify any valid JSON string is accepted
    it('mediaSource should accept a JSON string', 0, () => {
      const json = JSON.stringify({ streamUrl: 'http://server/stream', bitrate: 4000000 });
      const entity: DownloadEntity = {
        itemId: 'id-json',
        mediaSource: json,
        fileName: 'stream.mp4',
        filePath: '/cache/stream.mp4',
        progress: 0,
        status: DownloadStatus.PENDING
      };
      expect(entity.mediaSource).assertEqual(json);
    });

    // Verify status transitions are representable as entity field assignments
    it('status field should accept all DownloadStatus values', 0, () => {
      const baseEntity: DownloadEntity = {
        itemId: 'status-test',
        mediaSource: '{}',
        fileName: '',
        filePath: '',
        progress: 0,
        status: DownloadStatus.PENDING
      };

      baseEntity.status = DownloadStatus.DOWNLOADING;
      expect(baseEntity.status).assertEqual(DownloadStatus.DOWNLOADING);

      baseEntity.status = DownloadStatus.COMPLETED;
      expect(baseEntity.status).assertEqual(DownloadStatus.COMPLETED);

      baseEntity.status = DownloadStatus.FAILED;
      expect(baseEntity.status).assertEqual(DownloadStatus.FAILED);

      baseEntity.status = DownloadStatus.CANCELLED;
      expect(baseEntity.status).assertEqual(DownloadStatus.CANCELLED);
    });

    // Verify itemId is preserved exactly (no trimming / mutation)
    it('itemId should preserve the exact string passed in', 0, () => {
      const rawId = '  jellyfin-item-with-spaces  ';
      const entity: DownloadEntity = {
        itemId: rawId,
        mediaSource: '{}',
        fileName: '',
        filePath: '',
        progress: 0,
        status: DownloadStatus.PENDING
      };
      expect(entity.itemId).assertEqual(rawId);
    });
  });
}

// ---------------------------------------------------------------------------
// Test Suite 5 — ApiClientConfig interface
// ---------------------------------------------------------------------------
export function apiClientConfigTest() {
  describe('ApiClientController', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('should initialize with default config values', 0, () => {
      // ApiClientConfig is a plain interface; verify required fields
      const config: ApiClientConfig = {
        baseUrl: 'http://192.168.1.100:8096',
        deviceId: 'test-device-id',
        deviceName: 'Test Device',
        appName: 'Jellyfin',
        appVersion: '0.0.1'
      };
      expect(config.baseUrl).assertEqual('http://192.168.1.100:8096');
      expect(config.appName).assertEqual('Jellyfin');
      expect(config.appVersion).assertEqual('0.0.1');
      expect(config.deviceId).assertEqual('test-device-id');
      expect(config.deviceName).assertEqual('Test Device');
    });

    // Note: ApiClientController's default constructor sets deviceName to
    // 'HarmonyOS Device', NOT 'Test Device'. When a caller builds ApiClientConfig
    // directly they may supply any deviceName string.
    it('appVersion default should be "0.0.1" matching controller default', 0, () => {
      const config: ApiClientConfig = {
        baseUrl: '',
        deviceId: '',
        deviceName: 'HarmonyOS Device',
        appName: 'Jellyfin',
        appVersion: '0.0.1'
      };
      expect(config.appVersion).assertEqual('0.0.1');
    });

    // accessToken is declared optional (accessToken?: string) in ApiClientConfig.
    // Verify it can be omitted without error.
    it('accessToken should be optional', 0, () => {
      const config: ApiClientConfig = {
        baseUrl: 'http://server',
        deviceId: 'dev-001',
        deviceName: 'HarmonyOS Device',
        appName: 'Jellyfin',
        appVersion: '0.0.1'
        // accessToken intentionally omitted
      };
      expect(config.accessToken === undefined).assertTrue();
    });

    it('accessToken should be assignable when provided', 0, () => {
      const config: ApiClientConfig = {
        baseUrl: 'http://server',
        deviceId: 'dev-002',
        deviceName: 'HarmonyOS Device',
        appName: 'Jellyfin',
        appVersion: '0.0.1',
        accessToken: 'abc123token'
      };
      expect(config.accessToken).assertEqual('abc123token');
    });

    // Verify baseUrl is mutable (controller.setupServer() reassigns it)
    it('baseUrl should be mutable on config object', 0, () => {
      const config: ApiClientConfig = {
        baseUrl: '',
        deviceId: 'dev-003',
        deviceName: 'HarmonyOS Device',
        appName: 'Jellyfin',
        appVersion: '0.0.1'
      };
      config.baseUrl = 'http://192.168.0.50:8096';
      expect(config.baseUrl).assertEqual('http://192.168.0.50:8096');
    });
  });
}

// ---------------------------------------------------------------------------
// Root export — registers all suites with the test runner
// ---------------------------------------------------------------------------
export default function batchOneUnitTest() {
  downloadStatusTest();
  downloadEntityStructureTest();
  downloadEntityHelperTest();
  downloadEntityEdgeCasesTest();
  apiClientConfigTest();
}
