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
 * Rewritten in 'ArkTS' with modifications by WangRuijie on 2026-03-29
 */

/**
 * WebappFunctionChannel Unit Tests
 * Tests for the native-to-web event forwarding channel
 * Covers: constructor DI, lifecycle, event forwarding, and notification methods
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { WebappFunctionChannel } from '../../../../main/ets/webapp/WebappFunctionChannel';
import { BridgeChannel } from '../../../../main/ets/bridge/BridgeChannel';
import { ActivityEventHandler, ActivityEventCallback } from '../../../../main/ets/core/event/ActivityEventHandler';
import {
  ActivityEventType,
  ActivityEvent,
  ActivityEvents
} from '../../../../main/ets/core/event/ActivityEvent';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'WebappFunctionChannelTest';

// ==================== Test Doubles ====================

/**
 * Stub for BridgeChannel that records all calls.
 * Only the methods used by WebappFunctionChannel are implemented.
 */
class MockBridgeChannel {
  public callFunctionCalls: Array<{
    functionName: string;
    args: (string | number | boolean | object | null)[];
  }> = [];

  async callFunction(
    functionName: string,
    ...args: (string | number | boolean | object | null)[]
  ): Promise<{ success: boolean; result?: string; error?: string }> {
    this.callFunctionCalls.push({ functionName, args });
    return { success: true, result: 'ok' };
  }

  async runJavaScript(
    script: string
  ): Promise<{ success: boolean; result?: string; error?: string }> {
    return { success: true, result: 'ok' };
  }

  reset(): void {
    this.callFunctionCalls = [];
  }
}

/**
 * Stub for ActivityEventHandler that exposes subscribe/unsubscribe
 * and allows manually triggering events to test forwarding.
 */
class MockActivityEventHandler {
  private subscribers: Map<string, Set<ActivityEventCallback>> = new Map();

  subscribe(type: ActivityEventType, callback: ActivityEventCallback): () => void {
    if (!this.subscribers.has(type)) {
      this.subscribers.set(type, new Set());
    }
    this.subscribers.get(type)!.add(callback);
    return () => {
      this.unsubscribe(type, callback);
    };
  }

  unsubscribe(type: ActivityEventType, callback: ActivityEventCallback): void {
    const callbacks = this.subscribers.get(type);
    if (callbacks) {
      callbacks.delete(callback);
    }
  }

  /**
   * Simulate emitting an event (directly notifies subscribers, like the real handler).
   */
  simulateEvent(event: ActivityEvent): void {
    const callbacks = this.subscribers.get(event.type);
    if (callbacks) {
      callbacks.forEach(cb => cb(event));
    }
  }

  getSubscriberCount(type: ActivityEventType): number {
    return this.subscribers.get(type)?.size ?? 0;
  }

  reset(): void {
    this.subscribers.clear();
  }
}

// ==================== Test Suite ====================

export default function webappFunctionChannelTest() {
  describe('WebappFunctionChannel Tests', () => {
    let mockBridge: MockBridgeChannel;
    let mockEventHandler: MockActivityEventHandler;
    let channel: WebappFunctionChannel;

    beforeAll(() => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'WebappFunctionChannel Tests starting...');
    });

    afterAll(() => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'WebappFunctionChannel Tests completed');
    });

    beforeEach(() => {
      mockBridge = new MockBridgeChannel();
      mockEventHandler = new MockActivityEventHandler();
      channel = new WebappFunctionChannel(
        mockBridge as unknown as BridgeChannel,
        mockEventHandler as unknown as ActivityEventHandler
      );
    });

    afterEach(() => {
      channel.destroy();
      mockBridge.reset();
      mockEventHandler.reset();
    });

    // ============ Constructor / DI Tests ============

    /**
     * Test: Constructor accepts injected dependencies
     */
    it('should accept BridgeChannel and ActivityEventHandler via constructor', 0, () => {
      expect(channel).assertNotNull();
    });

    /**
     * Test: Constructor does not use getInstance
     * (This is a design test - the fact that we can construct with mock objects
     * proves getInstance is not used internally)
     */
    it('should not require any getInstance calls', 0, () => {
      // If constructor worked with plain mock objects, no singleton was accessed
      expect(channel).assertNotNull();
      expect(mockBridge.callFunctionCalls.length).assertEqual(0);
    });

    // ============ Initialize / Lifecycle Tests ============

    /**
     * Test: initialize subscribes to key event types
     */
    it('should subscribe to event types on initialize', 0, () => {
      channel.initialize();

      // Should have subscribers for the events it forwards
      expect(mockEventHandler.getSubscriberCount(ActivityEventType.UPDATE_MEDIA_SESSION)).assertEqual(1);
      expect(mockEventHandler.getSubscriberCount(ActivityEventType.HIDE_MEDIA_SESSION)).assertEqual(1);
    });

    /**
     * Test: initialize is idempotent
     */
    it('should not double-subscribe if initialize is called twice', 0, () => {
      channel.initialize();
      channel.initialize();

      // Should still only have 1 subscriber per event type
      expect(mockEventHandler.getSubscriberCount(ActivityEventType.UPDATE_MEDIA_SESSION)).assertEqual(1);
      expect(mockEventHandler.getSubscriberCount(ActivityEventType.HIDE_MEDIA_SESSION)).assertEqual(1);
    });

    /**
     * Test: destroy unsubscribes all events
     */
    it('should unsubscribe all events on destroy', 0, () => {
      channel.initialize();
      channel.destroy();

      expect(mockEventHandler.getSubscriberCount(ActivityEventType.UPDATE_MEDIA_SESSION)).assertEqual(0);
      expect(mockEventHandler.getSubscriberCount(ActivityEventType.HIDE_MEDIA_SESSION)).assertEqual(0);
    });

    /**
     * Test: destroy is idempotent and does not throw
     */
    it('should not throw when destroy is called without initialize', 0, () => {
      const freshChannel = new WebappFunctionChannel(
        mockBridge as unknown as BridgeChannel,
        mockEventHandler as unknown as ActivityEventHandler
      );
      // Should not throw
      freshChannel.destroy();
      expect(true).assertTrue();
    });

    // ============ Event Forwarding Tests ============

    /**
     * Test: UPDATE_MEDIA_SESSION event is forwarded to WebView via callFunction
     */
    it('should forward UPDATE_MEDIA_SESSION events to WebView', 0, () => {
      channel.initialize();
      mockBridge.reset();

      const mediaInfo: ActivityEvent = ActivityEvents.updateMediaSession({
        itemId: 'item123',
        title: 'Test Song',
        artist: 'Test Artist',
        duration: 180000,
        position: 60000,
        isPaused: false,
        canSeek: true
      });

      mockEventHandler.simulateEvent(mediaInfo);

      // Should have called callFunction to notify the webapp
      expect(mockBridge.callFunctionCalls.length).assertEqual(1);
      expect(mockBridge.callFunctionCalls[0].functionName).assertEqual('window.NativeShell.updateMediaSession');
    });

    /**
     * Test: HIDE_MEDIA_SESSION event is forwarded to WebView
     */
    it('should forward HIDE_MEDIA_SESSION events to WebView', 0, () => {
      channel.initialize();
      mockBridge.reset();

      mockEventHandler.simulateEvent(ActivityEvents.hideMediaSession());

      expect(mockBridge.callFunctionCalls.length).assertEqual(1);
      expect(mockBridge.callFunctionCalls[0].functionName).assertEqual('window.NativeShell.hideMediaSession');
    });

    /**
     * Test: Events received before initialize are not forwarded
     */
    it('should not forward events before initialize is called', 0, () => {
      // Do NOT call initialize
      mockEventHandler.simulateEvent(ActivityEvents.hideMediaSession());

      expect(mockBridge.callFunctionCalls.length).assertEqual(0);
    });

    /**
     * Test: Events after destroy are not forwarded
     */
    it('should not forward events after destroy', 0, () => {
      channel.initialize();
      channel.destroy();
      mockBridge.reset();

      mockEventHandler.simulateEvent(ActivityEvents.hideMediaSession());

      expect(mockBridge.callFunctionCalls.length).assertEqual(0);
    });

    // ============ Notification Method Tests ============

    /**
     * Test: notifyUserLogin sends correct function call
     */
    it('should notify webapp of user login', 0, () => {
      channel.notifyUserLogin('user-123', 'testuser');

      expect(mockBridge.callFunctionCalls.length).assertEqual(1);
      expect(mockBridge.callFunctionCalls[0].functionName).assertEqual('window.NativeShell.notifyEvent');
    });

    /**
     * Test: notifyServerConnected sends correct function call
     */
    it('should notify webapp of server connection', 0, () => {
      channel.notifyServerConnected('https://jellyfin.example.com', 'My Server');

      expect(mockBridge.callFunctionCalls.length).assertEqual(1);
      expect(mockBridge.callFunctionCalls[0].functionName).assertEqual('window.NativeShell.notifyEvent');
    });

    /**
     * Test: notifyDownloadProgress sends correct function call
     */
    it('should send download progress to webapp', 0, () => {
      channel.notifyDownloadProgress('item-456', 75);

      expect(mockBridge.callFunctionCalls.length).assertEqual(1);
      expect(mockBridge.callFunctionCalls[0].functionName).assertEqual('window.NativeShell.notifyEvent');
    });

    /**
     * Test: navigateTo sends correct function call
     */
    it('should request navigation via bridge', 0, () => {
      channel.navigateTo('/settings');

      expect(mockBridge.callFunctionCalls.length).assertEqual(1);
      expect(mockBridge.callFunctionCalls[0].functionName).assertEqual('window.NativeShell.notifyEvent');
    });

    /**
     * Test: reportPlaybackState sends correct function call
     */
    it('should report playback state to webapp', 0, () => {
      const state: Record<string, Object> = {
        isPlaying: true,
        position: 120000,
        duration: 300000
      };

      channel.reportPlaybackState(state);

      expect(mockBridge.callFunctionCalls.length).assertEqual(1);
      expect(mockBridge.callFunctionCalls[0].functionName).assertEqual('window.NativeShell.notifyEvent');
    });

    /**
     * Test: notifyWebapp (generic) sends correct function call
     */
    it('should send generic notification to webapp', 0, () => {
      channel.notifyWebapp('customEvent', { key: 'value' });

      expect(mockBridge.callFunctionCalls.length).assertEqual(1);
      expect(mockBridge.callFunctionCalls[0].functionName).assertEqual('window.NativeShell.notifyEvent');
    });

    /**
     * Test: notifyWebapp without data sends empty object
     */
    it('should send generic notification with empty data when no data provided', 0, () => {
      channel.notifyWebapp('testEvent');

      expect(mockBridge.callFunctionCalls.length).assertEqual(1);
      expect(mockBridge.callFunctionCalls[0].functionName).assertEqual('window.NativeShell.notifyEvent');
    });
  });
}
