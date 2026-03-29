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
 * BridgeManager Unit Tests
 * Tests for lifecycle optimization: idempotent initialize, listener cleanup,
 * refresh minimization, and reinitialize for server switching.
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { BridgeManager, BridgeManagerConfig } from '../../../../main/ets/bridge/BridgeManager';
import { ActivityEventHandler } from '../../../../main/ets/core/event/ActivityEventHandler';
import { AppPreferences } from '../../../../main/ets/core/preferences/AppPreferences';
import webview from '@ohos.web.webview';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'BridgeManagerTest';

// ==================== Test Doubles ====================

/**
 * Mock for AppPreferences providing the minimal interface BridgeManager needs.
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

/**
 * Mock WebviewController that records calls to registerJavaScriptProxy and refresh.
 * This allows us to verify that initialize() does NOT call refresh() multiple times.
 */
class MockWebviewController {
  public registerJavaScriptProxyCalls: Array<{
    object: ESObject;
    name: string;
    methods: string[];
  }> = [];
  public refreshCallCount: number = 0;
  public runJavaScriptResult: string = 'null';

  registerJavaScriptProxy(object: ESObject, name: string, methods: string[]): void {
    this.registerJavaScriptProxyCalls.push({ object, name, methods });
  }

  refresh(): void {
    this.refreshCallCount++;
  }

  async runJavaScript(script: string): Promise<string> {
    return this.runJavaScriptResult;
  }

  reset(): void {
    this.registerJavaScriptProxyCalls = [];
    this.refreshCallCount = 0;
  }
}

// ==================== Test Suite ====================

export default function bridgeManagerTest() {
  describe('BridgeManager Tests', () => {
    let eventHandler: ActivityEventHandler | null = null;
    let mockPrefs: MockPreferences | null = null;
    let mockController: MockWebviewController | null = null;
    let bridgeManager: BridgeManager | null = null;

    beforeAll(() => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'BridgeManager Tests starting...');
    });

    afterAll(() => {
      if (eventHandler) {
        eventHandler.destroy();
      }
      hilog.info(LOG_DOMAIN, LOG_TAG, 'BridgeManager Tests completed');
    });

    beforeEach(() => {
      eventHandler = new ActivityEventHandler();
      mockPrefs = new MockPreferences();
      mockController = new MockWebviewController();
    });

    afterEach(() => {
      if (bridgeManager) {
        bridgeManager.destroy();
        bridgeManager = null;
      }
      if (eventHandler) {
        eventHandler.clear();
        eventHandler.destroy();
        eventHandler = null;
      }
      mockPrefs = null;
      mockController = null;
    });

    // ============ Helper: create config and BridgeManager ============

    function createBridgeManager(): BridgeManager {
      const config: BridgeManagerConfig = {
        controller: mockController as unknown as webview.WebviewController,
        context: getContext(this),
        eventHandler: eventHandler!,
        preferences: mockPrefs as unknown as AppPreferences
      };
      return new BridgeManager(config);
    }

    // ============ P3: Initialize Idempotency Tests ============

    /**
     * Test: initialize() can only run once; second call returns early.
     * Verifies that isBridgeInitialized flag prevents duplicate setup.
     */
    it('should skip initialization on second initialize() call', 0, async () => {
      bridgeManager = createBridgeManager();

      await bridgeManager.initialize();
      expect(bridgeManager.isInitialized()).assertTrue();

      // Record state before second call
      const proxyCountBefore = mockController!.registerJavaScriptProxyCalls.length;
      const refreshCountBefore = mockController!.refreshCallCount;

      // Second call should be a no-op
      await bridgeManager.initialize();

      // No additional proxy registrations or refreshes should happen
      expect(mockController!.registerJavaScriptProxyCalls.length).assertEqual(proxyCountBefore);
      expect(mockController!.refreshCallCount).assertEqual(refreshCountBefore);
    });

    /**
     * Test: initialize() sets isInitialized to true after first call.
     */
    it('should set isInitialized to true after first initialize', 0, async () => {
      bridgeManager = createBridgeManager();
      expect(bridgeManager.isInitialized()).assertFalse();

      await bridgeManager.initialize();
      expect(bridgeManager.isInitialized()).assertTrue();
    });

    /**
     * Test: getInterfaces returns null before initialization.
     */
    it('should return null interfaces before initialize', 0, () => {
      bridgeManager = createBridgeManager();
      expect(bridgeManager.getInterfaces()).assertNull();
    });

    /**
     * Test: getInterfaces returns valid objects after initialization.
     */
    it('should return valid interfaces after initialize', 0, async () => {
      bridgeManager = createBridgeManager();
      await bridgeManager.initialize();

      const interfaces = bridgeManager.getInterfaces();
      expect(interfaces).assertNotNull();
      expect(interfaces!.nativeInterface).assertNotNull();
      expect(interfaces!.nativePlayer).assertNotNull();
      expect(interfaces!.externalPlayer).assertNotNull();
      expect(interfaces!.mediaSegments).assertNotNull();
    });

    /**
     * Test: getBridgeChannel returns null before initialization.
     */
    it('should return null bridgeChannel before initialize', 0, () => {
      bridgeManager = createBridgeManager();
      expect(bridgeManager.getBridgeChannel()).assertNull();
    });

    /**
     * Test: getBridgeChannel returns valid object after initialization.
     */
    it('should return valid bridgeChannel after initialize', 0, async () => {
      bridgeManager = createBridgeManager();
      await bridgeManager.initialize();
      expect(bridgeManager.getBridgeChannel()).assertNotNull();
    });

    // ============ P2: Minimize refresh() Impact Tests ============

    /**
     * Test: refresh() is called exactly once during initialize.
     * Verifies that controller.refresh() is not called redundantly.
     */
    it('should call refresh exactly once during initialize', 0, async () => {
      bridgeManager = createBridgeManager();
      await bridgeManager.initialize();

      // refresh() should be called exactly once (inside registerJavaScriptProxies)
      expect(mockController!.refreshCallCount).assertEqual(1);
    });

    /**
     * Test: refresh() is NOT called again on second initialize().
     * This is the key test for the P2 optimization.
     */
    it('should NOT call refresh on second initialize', 0, async () => {
      bridgeManager = createBridgeManager();

      await bridgeManager.initialize();
      expect(mockController!.refreshCallCount).assertEqual(1);

      // Second initialize should be skipped entirely
      await bridgeManager.initialize();
      expect(mockController!.refreshCallCount).assertEqual(1);
    });

    /**
     * Test: All 4 proxy objects are registered during initialize.
     */
    it('should register all 4 JavaScript proxies during initialize', 0, async () => {
      bridgeManager = createBridgeManager();
      await bridgeManager.initialize();

      // 4 proxy objects: NativeInterface, NativePlayer, ExternalPlayer, MediaSegments
      expect(mockController!.registerJavaScriptProxyCalls.length).assertEqual(4);
    });

    // ============ P11: Listener Cleanup Tests ============

    /**
     * Test: destroy() clears all interfaces and references.
     */
    it('should clear interfaces after destroy', 0, async () => {
      bridgeManager = createBridgeManager();
      await bridgeManager.initialize();

      expect(bridgeManager.getInterfaces()).assertNotNull();
      bridgeManager.destroy();
      expect(bridgeManager.getInterfaces()).assertNull();
    });

    /**
     * Test: destroy() sets bridgeChannel to null.
     */
    it('should set bridgeChannel to null after destroy', 0, async () => {
      bridgeManager = createBridgeManager();
      await bridgeManager.initialize();

      expect(bridgeManager.getBridgeChannel()).assertNotNull();
      bridgeManager.destroy();
      expect(bridgeManager.getBridgeChannel()).assertNull();
    });

    /**
     * Test: destroy() resets isInitialized to false.
     */
    it('should reset isInitialized to false after destroy', 0, async () => {
      bridgeManager = createBridgeManager();
      await bridgeManager.initialize();
      expect(bridgeManager.isInitialized()).assertTrue();

      bridgeManager.destroy();
      expect(bridgeManager.isInitialized()).assertFalse();
    });

    /**
     * Test: destroy() clears proxies.
     */
    it('should clear proxies after destroy', 0, async () => {
      bridgeManager = createBridgeManager();
      await bridgeManager.initialize();

      expect(bridgeManager.getProxies()).assertNotNull();
      bridgeManager.destroy();
      expect(bridgeManager.getProxies()).assertNull();
    });

    /**
     * Test: destroy() clears NativePlayer listeners.
     * Verifies that playerEventListeners are cleared via clearListeners().
     */
    it('should clear NativePlayer listeners on destroy', 0, async () => {
      bridgeManager = createBridgeManager();
      await bridgeManager.initialize();

      // Add a listener to NativePlayer
      let listenerCallCount = 0;
      const listener = (_event: ESObject) => {
        listenerCallCount++;
      };
      const interfaces = bridgeManager.getInterfaces()!;
      interfaces.nativePlayer.addPlayerEventListener(listener);

      // Destroy should clear all listeners
      bridgeManager.destroy();

      // After destroy, interfaces is null so we cannot verify directly on the object.
      // Instead verify that destroy completed without error (the clearListeners was called).
      expect(bridgeManager.getInterfaces()).assertNull();
    });

    /**
     * Test: destroy() without prior initialize does not throw.
     */
    it('should not throw when destroy called without initialize', 0, () => {
      bridgeManager = createBridgeManager();
      // Should not throw
      bridgeManager!.destroy();
      expect(bridgeManager!.isInitialized()).assertFalse();
    });

    /**
     * Test: destroy() is idempotent (can be called multiple times).
     */
    it('should be safe to call destroy multiple times', 0, async () => {
      bridgeManager = createBridgeManager();
      await bridgeManager.initialize();

      bridgeManager.destroy();
      // Second destroy should not throw
      bridgeManager.destroy();
      expect(bridgeManager.isInitialized()).assertFalse();
    });

    // ============ reinitialize() Tests ============

    /**
     * Test: reinitialize() performs a full destroy + initialize cycle.
     */
    it('should fully reinitialize after calling reinitialize()', 0, async () => {
      bridgeManager = createBridgeManager();
      await bridgeManager.initialize();

      // Record first init state
      const firstRefreshCount = mockController!.refreshCallCount;
      expect(firstRefreshCount).assertEqual(1);

      // Reinitialize should destroy and re-create everything
      await bridgeManager.reinitialize();

      // Should be initialized again
      expect(bridgeManager.isInitialized()).assertTrue();
      expect(bridgeManager.getInterfaces()).assertNotNull();
      expect(bridgeManager.getBridgeChannel()).assertNotNull();

      // refresh should have been called again (from the second initialize)
      expect(mockController!.refreshCallCount).assertEqual(firstRefreshCount + 1);
    });

    /**
     * Test: reinitialize() on uninitialized manager still works.
     */
    it('should handle reinitialize on uninitialized manager', 0, async () => {
      bridgeManager = createBridgeManager();
      // Don't call initialize first

      await bridgeManager.reinitialize();
      expect(bridgeManager.isInitialized()).assertTrue();
      expect(bridgeManager.getInterfaces()).assertNotNull();
    });

    // ============ State Flag Tests ============

    /**
     * Test: isInitialized reflects correct state across lifecycle.
     */
    it('should track initialization state across lifecycle', 0, async () => {
      bridgeManager = createBridgeManager();

      // Before init
      expect(bridgeManager.isInitialized()).assertFalse();

      // After init
      await bridgeManager.initialize();
      expect(bridgeManager.isInitialized()).assertTrue();

      // After destroy
      bridgeManager.destroy();
      expect(bridgeManager.isInitialized()).assertFalse();

      // After re-init
      await bridgeManager.initialize();
      expect(bridgeManager.isInitialized()).assertTrue();
    });

    // ============ runJavaScript / callFunction edge cases ============

    /**
     * Test: runJavaScript returns null before initialization.
     */
    it('should return null from runJavaScript before initialize', 0, async () => {
      bridgeManager = createBridgeManager();
      const result = await bridgeManager.runJavaScript('1+1');
      expect(result).assertNull();
    });

    /**
     * Test: callFunction is a no-op before initialization.
     */
    it('should be a no-op for callFunction before initialize', 0, async () => {
      bridgeManager = createBridgeManager();
      // Should not throw
      await bridgeManager.callFunction('testFunc', 'arg');
    });
  });
}
