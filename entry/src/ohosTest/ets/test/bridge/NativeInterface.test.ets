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
 * NativeInterface Unit Tests
 * Tests for device ID caching, device information structure, and
 * performance refactoring that eliminates synchronous I/O on each JS call.
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { NativeInterface } from '../../../../main/ets/bridge/NativeInterface';
import { ActivityEventHandler } from '../../../../main/ets/core/event/ActivityEventHandler';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'NativeInterfaceTest';

/**
 * Minimal mock for AppPreferences that provides getRawPreferences()
 * returning an in-memory store. This avoids real I/O during tests.
 */
class MockPreferences {
  private store: Record<string, string> = {};

  getRawPreferences(): Object | null {
    const self = this;
    return {
      getSync(key: string, defaultValue: string): string {
        if (key in self.store) {
          return self.store[key];
        }
        return defaultValue;
      },
      putSync(key: string, value: string): void {
        self.store[key] = value;
      },
      flush(): void {
        // no-op in mock
      }
    };
  }
}

export default function nativeInterfaceTest() {
  describe('NativeInterface Tests', () => {
    let eventHandler: ActivityEventHandler | null = null;
    let mockPrefs: MockPreferences | null = null;
    let nativeInterface: NativeInterface | null = null;

    beforeAll(() => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'NativeInterface Tests starting...');
    });

    afterAll(() => {
      if (eventHandler) {
        eventHandler.destroy();
      }
      hilog.info(LOG_DOMAIN, LOG_TAG, 'NativeInterface Tests completed');
    });

    beforeEach(() => {
      eventHandler = new ActivityEventHandler();
      mockPrefs = new MockPreferences();
      // Pass mockPrefs as any to satisfy the AppPreferences type in constructor
      nativeInterface = new NativeInterface(
        getContext(this),
        eventHandler!,
        mockPrefs as ESObject
      );
    });

    afterEach(() => {
      if (eventHandler) {
        eventHandler.clear();
        eventHandler.destroy();
        eventHandler = null;
      }
      mockPrefs = null;
      nativeInterface = null;
    });

    // ============ getDeviceId Caching Tests ============

    /**
     * Test: After initialize(), getDeviceInformation should return a non-null string
     * This verifies the basic contract -- deviceId is generated and cached.
     */
    it('should return non-null device info after initialize', 0, () => {
      // getDeviceInformation is synchronous; after construction it should work
      // because initialize() reads from prefs synchronously in the refactored version.
      const result = nativeInterface!.getDeviceInformation();
      expect(result).assertNotNull();
    });

    /**
     * Test: getDeviceInformation returns a valid deviceId (UUID v4 format)
     * Verifies that the deviceId is a UUID-like string (8-4-4-4-12 hex pattern).
     */
    it('should return deviceId in UUID v4 format', 0, () => {
      const result = nativeInterface!.getDeviceInformation();
      expect(result).assertNotNull();

      const parsed = JSON.parse(result!) as ESObject;
      const deviceId = parsed['deviceId'] as string;

      expect(deviceId).assertNotNull();
      expect(deviceId.length).assertLargerThan(0);

      // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
      expect(uuidPattern.test(deviceId)).assertTrue();
    });

    /**
     * Test: Multiple calls to getDeviceInformation return the same deviceId
     * This is the core caching verification -- the deviceId should NOT change
     * between calls and should NOT trigger repeated I/O.
     */
    it('should return the same deviceId on multiple calls', 0, () => {
      const result1 = nativeInterface!.getDeviceInformation();
      const result2 = nativeInterface!.getDeviceInformation();
      const result3 = nativeInterface!.getDeviceInformation();

      expect(result1).assertNotNull();
      expect(result2).assertNotNull();
      expect(result3).assertNotNull();

      const parsed1 = JSON.parse(result1!) as ESObject;
      const parsed2 = JSON.parse(result2!) as ESObject;
      const parsed3 = JSON.parse(result3!) as ESObject;

      const deviceId1 = parsed1['deviceId'] as string;
      const deviceId2 = parsed2['deviceId'] as string;
      const deviceId3 = parsed3['deviceId'] as string;

      expect(deviceId1).assertEqual(deviceId2);
      expect(deviceId2).assertEqual(deviceId3);
    });

    /**
     * Test: deviceId persists across separate NativeInterface instances
     * using the same mock preferences store.
     * Verifies that once written to prefs, a new instance reads the same ID.
     */
    it('should persist deviceId across NativeInterface instances', 0, () => {
      // First instance generates and stores deviceId
      const result1 = nativeInterface!.getDeviceInformation();
      expect(result1).assertNotNull();
      const parsed1 = JSON.parse(result1!) as ESObject;
      const deviceId1 = parsed1['deviceId'] as string;

      // Create a second instance sharing the same mock prefs store
      const nativeInterface2 = new NativeInterface(
        getContext(this),
        eventHandler!,
        mockPrefs as ESObject
      );

      const result2 = nativeInterface2.getDeviceInformation();
      expect(result2).assertNotNull();
      const parsed2 = JSON.parse(result2!) as ESObject;
      const deviceId2 = parsed2['deviceId'] as string;

      expect(deviceId1).assertEqual(deviceId2);
    });

    // ============ getDeviceInformation Structure Tests ============

    /**
     * Test: getDeviceInformation returns correct JSON structure
     * Must contain: deviceId, deviceName, appName, appVersion
     */
    it('should return JSON with all required fields', 0, () => {
      const result = nativeInterface!.getDeviceInformation();
      expect(result).assertNotNull();

      const parsed = JSON.parse(result!) as ESObject;

      expect('deviceId' in parsed).assertTrue();
      expect('deviceName' in parsed).assertTrue();
      expect('appName' in parsed).assertTrue();
      expect('appVersion' in parsed).assertTrue();
    });

    /**
     * Test: appName should be 'Jellyfin HarmonyOS'
     */
    it('should return correct appName', 0, () => {
      const result = nativeInterface!.getDeviceInformation();
      expect(result).assertNotNull();

      const parsed = JSON.parse(result!) as ESObject;
      expect(parsed['appName']).assertEqual('Jellyfin HarmonyOS');
    });

    /**
     * Test: appVersion should be '1.0.0'
     */
    it('should return correct appVersion', 0, () => {
      const result = nativeInterface!.getDeviceInformation();
      expect(result).assertNotNull();

      const parsed = JSON.parse(result!) as ESObject;
      expect(parsed['appVersion']).assertEqual('1.0.0');
    });

    /**
     * Test: deviceName should be a non-empty string
     */
    it('should return non-empty deviceName', 0, () => {
      const result = nativeInterface!.getDeviceInformation();
      expect(result).assertNotNull();

      const parsed = JSON.parse(result!) as ESObject;
      const deviceName = parsed['deviceName'] as string;
      expect(deviceName.length).assertLargerThan(0);
    });

    /**
     * Test: getDeviceInformation returns valid JSON string
     */
    it('should return a valid JSON string', 0, () => {
      const result = nativeInterface!.getDeviceInformation();
      expect(result).assertNotNull();

      // Should not throw when parsing
      let parsed: ESObject | null = null;
      try {
        parsed = JSON.parse(result!) as ESObject;
      } catch (e) {
        // Fail the test if parsing throws
        expect(true).assertFalse();
      }
      expect(parsed).assertNotNull();
    });

    // ============ No Repeated I/O Verification ============

    /**
     * Test: The cached device info JSON is identical across calls (reference stability)
     * Verifies that after the first call, the exact same JSON string is returned,
     * meaning no re-computation or re-serialization occurs.
     */
    it('should return identical JSON strings across calls', 0, () => {
      const result1 = nativeInterface!.getDeviceInformation();
      const result2 = nativeInterface!.getDeviceInformation();

      expect(result1).assertEqual(result2);
    });
  });
}
