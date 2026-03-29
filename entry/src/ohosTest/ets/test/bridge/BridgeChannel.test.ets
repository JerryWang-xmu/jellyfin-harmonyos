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
 * BridgeChannel Unit Tests
 * Tests for JS Bridge batch/queue mechanism, serialization, and conditional logging.
 * Covers: callFunction serialization, enqueue/flushQueue batching, verbose logging toggle
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { BridgeChannel } from '../../../../main/ets/bridge/BridgeChannel';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'BridgeChannelTest';

// ==================== Test Doubles ====================

/**
 * Minimal mock for webview.WebviewController that records scripts.
 * Avoids real WebView dependencies during tests.
 */
class MockWebviewController {
  public executedScripts: string[] = [];
  private shouldFail: boolean = false;

  setFailMode(fail: boolean): void {
    this.shouldFail = fail;
  }

  reset(): void {
    this.executedScripts = [];
    this.shouldFail = false;
  }

  async runJavaScript(script: string): Promise<string> {
    if (this.shouldFail) {
      throw new Error('Mock JS execution failure');
    }
    this.executedScripts.push(script);
    return 'ok';
  }
}

// ==================== Test Suite ====================

export default function bridgeChannelTest() {
  describe('BridgeChannel Tests', () => {
    let mockController: MockWebviewController;
    let bridgeChannel: BridgeChannel;

    beforeAll(() => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'BridgeChannel Tests starting...');
    });

    afterAll(() => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'BridgeChannel Tests completed');
    });

    beforeEach(() => {
      mockController = new MockWebviewController();
      bridgeChannel = new BridgeChannel({
        controller: mockController as unknown as ESObject
      });
    });

    afterEach(() => {
      bridgeChannel.destroy();
      mockController.reset();
    });

    // ============ Serialization / callFunction Tests ============

    /**
     * Test: callFunction with no arguments generates a bare function call
     */
    it('should generate correct JS code with no arguments', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      await bridgeChannel.callFunction('window.testFunc');

      expect(mockController.executedScripts.length).assertEqual(1);
      expect(mockController.executedScripts[0]).assertEqual('window.testFunc()');
    });

    /**
     * Test: callFunction correctly serializes string arguments
     */
    it('should correctly serialize string arguments', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      await bridgeChannel.callFunction('window.testFunc', 'hello');

      expect(mockController.executedScripts.length).assertEqual(1);
      expect(mockController.executedScripts[0]).assertEqual('window.testFunc("hello")');
    });

    /**
     * Test: callFunction correctly serializes number arguments
     */
    it('should correctly serialize number arguments', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      await bridgeChannel.callFunction('window.testFunc', 42, 3.14);

      expect(mockController.executedScripts.length).assertEqual(1);
      expect(mockController.executedScripts[0]).assertEqual('window.testFunc(42, 3.14)');
    });

    /**
     * Test: callFunction correctly serializes boolean arguments
     */
    it('should correctly serialize boolean arguments', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      await bridgeChannel.callFunction('window.testFunc', true, false);

      expect(mockController.executedScripts.length).assertEqual(1);
      expect(mockController.executedScripts[0]).assertEqual('window.testFunc(true, false)');
    });

    /**
     * Test: callFunction correctly serializes object arguments
     */
    it('should correctly serialize object arguments', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      const obj = { key: 'value', num: 1 };
      await bridgeChannel.callFunction('window.testFunc', obj);

      expect(mockController.executedScripts.length).assertEqual(1);
      expect(mockController.executedScripts[0]).assertEqual('window.testFunc({"key":"value","num":1})');
    });

    /**
     * Test: callFunction correctly serializes null arguments
     */
    it('should correctly serialize null arguments', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      await bridgeChannel.callFunction('window.testFunc', null);

      expect(mockController.executedScripts.length).assertEqual(1);
      expect(mockController.executedScripts[0]).assertEqual('window.testFunc(null)');
    });

    /**
     * Test: callFunction with mixed argument types serializes correctly
     */
    it('should correctly serialize mixed argument types', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      await bridgeChannel.callFunction('window.testFunc', 'text', 123, true, null);

      expect(mockController.executedScripts.length).assertEqual(1);
      expect(mockController.executedScripts[0]).assertEqual('window.testFunc("text", 123, true, null)');
    });

    // ============ Queue / Batch Tests ============

    /**
     * Test: enqueueFunction adds a call to the queue without immediate execution
     */
    it('should enqueue a function call without immediate execution', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      bridgeChannel.enqueueFunction('window.funcA', 'arg1');
      bridgeChannel.enqueueFunction('window.funcB', 42);

      // Nothing should be executed yet (flush not called)
      expect(mockController.executedScripts.length).assertEqual(0);
    });

    /**
     * Test: flushQueue merges all queued calls into a single runJavaScript call
     */
    it('should batch all queued calls into one runJavaScript call on flush', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      bridgeChannel.enqueueFunction('window.funcA', 'arg1');
      bridgeChannel.enqueueFunction('window.funcB', 42);
      bridgeChannel.enqueueFunction('window.funcC', true);

      await bridgeChannel.flushQueue();

      // All three calls should be merged into a single execution
      expect(mockController.executedScripts.length).assertEqual(1);
      // The merged script should contain all three function calls joined by semicolons
      const mergedScript = mockController.executedScripts[0];
      expect(mergedScript.includes('window.funcA("arg1")')).assertTrue();
      expect(mergedScript.includes('window.funcB(42)')).assertTrue();
      expect(mergedScript.includes('window.funcC(true)')).assertTrue();
    });

    /**
     * Test: flushQueue clears the queue after execution
     */
    it('should clear the queue after flush', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      bridgeChannel.enqueueFunction('window.funcA', 'arg1');
      await bridgeChannel.flushQueue();

      expect(mockController.executedScripts.length).assertEqual(1);

      // Reset and flush again -- nothing should execute
      mockController.reset();
      await bridgeChannel.flushQueue();
      expect(mockController.executedScripts.length).assertEqual(0);
    });

    /**
     * Test: queue is usable again after flush
     */
    it('should allow enqueuing after flush', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      bridgeChannel.enqueueFunction('window.first');
      await bridgeChannel.flushQueue();
      expect(mockController.executedScripts.length).assertEqual(1);

      mockController.reset();

      bridgeChannel.enqueueFunction('window.second');
      await bridgeChannel.flushQueue();
      expect(mockController.executedScripts.length).assertEqual(1);
      expect(mockController.executedScripts[0].includes('window.second()')).assertTrue();
    });

    /**
     * Test: flushQueue with an empty queue does nothing
     */
    it('should do nothing when flushing an empty queue', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      await bridgeChannel.flushQueue();

      expect(mockController.executedScripts.length).assertEqual(0);
    });

    /**
     * Test: callFunction (immediate) still works independently of the queue
     */
    it('should execute callFunction immediately regardless of queue state', 0, async () => {
      await bridgeChannel.initialize();
      mockController.reset();

      // Enqueue something (not flushed)
      bridgeChannel.enqueueFunction('window.queued');

      // Immediate call should work independently
      await bridgeChannel.callFunction('window.immediate', 'data');

      expect(mockController.executedScripts.length).assertEqual(1);
      expect(mockController.executedScripts[0]).assertEqual('window.immediate("data")');
    });

    /**
     * Test: getQueueSize returns the correct number of queued items
     */
    it('should report correct queue size', 0, async () => {
      await bridgeChannel.initialize();

      expect(bridgeChannel.getQueueSize()).assertEqual(0);

      bridgeChannel.enqueueFunction('window.func1');
      expect(bridgeChannel.getQueueSize()).assertEqual(1);

      bridgeChannel.enqueueFunction('window.func2');
      expect(bridgeChannel.getQueueSize()).assertEqual(2);

      await bridgeChannel.flushQueue();
      expect(bridgeChannel.getQueueSize()).assertEqual(0);
    });

    // ============ Verbose Logging Tests ============

    /**
     * Test: setVerboseLogging does not throw
     */
    it('should accept verbose logging toggle without error', 0, () => {
      // Should not throw
      bridgeChannel.setVerboseLogging(true);
      bridgeChannel.setVerboseLogging(false);
      expect(true).assertTrue();
    });

    /**
     * Test: isVerboseLogging returns the current state
     */
    it('should return correct verbose logging state', 0, () => {
      expect(bridgeChannel.isVerboseLogging()).assertFalse();

      bridgeChannel.setVerboseLogging(true);
      expect(bridgeChannel.isVerboseLogging()).assertTrue();

      bridgeChannel.setVerboseLogging(false);
      expect(bridgeChannel.isVerboseLogging()).assertFalse();
    });

    // ============ Error Handling Tests ============

    /**
     * Test: callFunction returns error result when not initialized
     */
    it('should return error when callFunction called before initialization', 0, async () => {
      // Do NOT initialize
      const result = await bridgeChannel.callFunction('window.test');
      expect(result.success).assertFalse();
      expect(result.error).assertNotNull();
    });

    /**
     * Test: runJavaScript returns error result when not initialized
     */
    it('should return error when runJavaScript called before initialization', 0, async () => {
      const result = await bridgeChannel.runJavaScript('1+1');
      expect(result.success).assertFalse();
      expect(result.error).assertNotNull();
    });

    /**
     * Test: flushQueue returns error when not initialized
     */
    it('should return error when flushQueue called before initialization', 0, async () => {
      bridgeChannel.enqueueFunction('window.test');
      const result = await bridgeChannel.flushQueue();
      expect(result.success).assertFalse();
    });

    // ============ Lifecycle Tests ============

    /**
     * Test: isInitialized returns false before initialize
     */
    it('should not be initialized before initialize call', 0, () => {
      expect(bridgeChannel.isInitialized()).assertFalse();
    });

    /**
     * Test: isInitialized returns true after initialize
     */
    it('should be initialized after initialize call', 0, async () => {
      await bridgeChannel.initialize();
      expect(bridgeChannel.isInitialized()).assertTrue();
    });

    /**
     * Test: initialize is idempotent
     */
    it('should handle double initialize gracefully', 0, async () => {
      await bridgeChannel.initialize();
      await bridgeChannel.initialize();
      expect(bridgeChannel.isInitialized()).assertTrue();
    });

    /**
     * Test: destroy resets initialization state
     */
    it('should reset initialization on destroy', 0, async () => {
      await bridgeChannel.initialize();
      bridgeChannel.destroy();
      expect(bridgeChannel.isInitialized()).assertFalse();
    });
  });
}
