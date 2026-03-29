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
 * ActivityEventHandler Unit Tests
 * Tests for activity event system - event sending, subscription, and unsubscription
 * Migrated from jellyfin-android events tests
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';

import {
  ActivityEventType,
  ActivityEvent,
  PlayOptions,
  MediaSessionInfo,
  DownloadInfo,
  ActivityEvents
} from '../../../../main/ets/core/event/ActivityEvent';
import { ActivityEventHandler } from '../../../../main/ets/core/event/ActivityEventHandler';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'ActivityEventHandlerTest';

export default function activityEventHandlerTest() {
  describe('ActivityEventHandler Tests', () => {
    let eventHandler: ActivityEventHandler | null = null;

    beforeAll(() => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'ActivityEventHandler Tests starting...');
    });

    afterAll(() => {
      if (eventHandler) {
        eventHandler.destroy();
      }
      hilog.info(LOG_DOMAIN, LOG_TAG, 'ActivityEventHandler Tests completed');
    });

    beforeEach(() => {
      eventHandler = new ActivityEventHandler();
    });

    afterEach(() => {
      if (eventHandler) {
        eventHandler.clear();
        eventHandler.destroy();
        eventHandler = null;
      }
    });

    // ============ ActivityEventType Tests ============

    /**
     * Test: ActivityEventType enum values
     */
    it('should have correct ActivityEventType values', 0, () => {
      expect(ActivityEventType.CHANGE_FULLSCREEN).assertEqual('ChangeFullscreen');
      expect(ActivityEventType.LAUNCH_NATIVE_PLAYER).assertEqual('LaunchNativePlayer');
      expect(ActivityEventType.OPEN_URL).assertEqual('OpenUrl');
      expect(ActivityEventType.DOWNLOAD_FILE).assertEqual('DownloadFile');
      expect(ActivityEventType.REMOVE_DOWNLOAD).assertEqual('RemoveDownload');
      expect(ActivityEventType.CAST_MESSAGE).assertEqual('CastMessage');
      expect(ActivityEventType.REQUEST_BLUETOOTH_PERMISSION).assertEqual('RequestBluetoothPermission');
      expect(ActivityEventType.OPEN_SETTINGS).assertEqual('OpenSettings');
      expect(ActivityEventType.SELECT_SERVER).assertEqual('SelectServer');
      expect(ActivityEventType.EXIT_APP).assertEqual('ExitApp');
      expect(ActivityEventType.OPEN_DOWNLOADS).assertEqual('OpenDownloads');
      expect(ActivityEventType.UPDATE_MEDIA_SESSION).assertEqual('UpdateMediaSession');
      expect(ActivityEventType.HIDE_MEDIA_SESSION).assertEqual('HideMediaSession');
      expect(ActivityEventType.UPDATE_VOLUME).assertEqual('UpdateVolume');
    });

    // ============ ActivityEvents Factory Tests ============

    /**
     * Test: ActivityEvents.changeFullscreen
     */
    it('should create changeFullscreen event', 0, () => {
      const event = ActivityEvents.changeFullscreen(true);

      expect(event.type).assertEqual(ActivityEventType.CHANGE_FULLSCREEN);
      expect(event.payload?.isFullscreen).assertTrue();
    });

    /**
     * Test: ActivityEvents.changeFullscreen with false
     */
    it('should create changeFullscreen event with false', 0, () => {
      const event = ActivityEvents.changeFullscreen(false);

      expect(event.type).assertEqual(ActivityEventType.CHANGE_FULLSCREEN);
      expect(event.payload?.isFullscreen).assertFalse();
    });

    /**
     * Test: ActivityEvents.launchNativePlayer
     */
    it('should create launchNativePlayer event', 0, () => {
      const playOptions: PlayOptions = {
        ids: ['media1', 'media2'],
        startIndex: 0,
        startPosition: 5000
      };

      const event = ActivityEvents.launchNativePlayer(playOptions);

      expect(event.type).assertEqual(ActivityEventType.LAUNCH_NATIVE_PLAYER);
      expect(event.payload?.ids).assertDeepEquals(['media1', 'media2']);
      expect(event.payload?.startIndex).assertEqual(0);
      expect(event.payload?.startPosition).assertEqual(5000);
    });

    /**
     * Test: ActivityEvents.openUrl
     */
    it('should create openUrl event', 0, () => {
      const uri = 'https://jellyfin.example.com';
      const event = ActivityEvents.openUrl(uri);

      expect(event.type).assertEqual(ActivityEventType.OPEN_URL);
      expect(event.payload?.uri).assertEqual(uri);
    });

    /**
     * Test: ActivityEvents.downloadFile
     */
    it('should create downloadFile event', 0, () => {
      const uri = 'https://example.com/media.mp4';
      const title = 'Test Video';
      const filename = 'test_video.mp4';

      const event = ActivityEvents.downloadFile(uri, title, filename);

      expect(event.type).assertEqual(ActivityEventType.DOWNLOAD_FILE);
      expect(event.payload?.uri).assertEqual(uri);
      expect(event.payload?.title).assertEqual(title);
      expect(event.payload?.filename).assertEqual(filename);
    });

    /**
     * Test: ActivityEvents.removeDownload
     */
    it('should create removeDownload event', 0, () => {
      const downloadId = 'media123';
      const downloadPath = '/downloads/media123.mp4';
      const event = ActivityEvents.removeDownload(downloadId, downloadPath);

      expect(event.type).assertEqual(ActivityEventType.REMOVE_DOWNLOAD);
      expect(event.payload?.downloadId).assertEqual(downloadId);
      expect(event.payload?.downloadPath).assertEqual(downloadPath);
      expect(event.payload?.force).assertFalse();
    });

    /**
     * Test: ActivityEvents.removeDownload with force
     */
    it('should create removeDownload event with force', 0, () => {
      const downloadId = 'media123';
      const downloadPath = '/downloads/media123.mp4';
      const event = ActivityEvents.removeDownload(downloadId, downloadPath, true);

      expect(event.type).assertEqual(ActivityEventType.REMOVE_DOWNLOAD);
      expect(event.payload?.downloadId).assertEqual(downloadId);
      expect(event.payload?.downloadPath).assertEqual(downloadPath);
      expect(event.payload?.force).assertTrue();
    });

    /**
     * Test: ActivityEvents.castMessage
     */
    it('should create castMessage event', 0, () => {
      const action = 'play';
      const args = ['arg1', 'arg2'];

      const event = ActivityEvents.castMessage(action, args);

      expect(event.type).assertEqual(ActivityEventType.CAST_MESSAGE);
      expect(event.payload?.action).assertEqual(action);
      expect(event.payload?.args).assertDeepEquals(args);
    });

    /**
     * Test: ActivityEvents.requestBluetoothPermission
     */
    it('should create requestBluetoothPermission event', 0, () => {
      const event = ActivityEvents.requestBluetoothPermission();

      expect(event.type).assertEqual(ActivityEventType.REQUEST_BLUETOOTH_PERMISSION);
      expect(event.payload).assertUndefined();
    });

    /**
     * Test: ActivityEvents.openSettings
     */
    it('should create openSettings event', 0, () => {
      const event = ActivityEvents.openSettings();

      expect(event.type).assertEqual(ActivityEventType.OPEN_SETTINGS);
      expect(event.payload).assertUndefined();
    });

    /**
     * Test: ActivityEvents.selectServer
     */
    it('should create selectServer event', 0, () => {
      const event = ActivityEvents.selectServer();

      expect(event.type).assertEqual(ActivityEventType.SELECT_SERVER);
      expect(event.payload).assertUndefined();
    });

    /**
     * Test: ActivityEvents.exitApp
     */
    it('should create exitApp event', 0, () => {
      const event = ActivityEvents.exitApp();

      expect(event.type).assertEqual(ActivityEventType.EXIT_APP);
      expect(event.payload).assertUndefined();
    });

    /**
     * Test: ActivityEvents.openDownloads
     */
    it('should create openDownloads event', 0, () => {
      const event = ActivityEvents.openDownloads();

      expect(event.type).assertEqual(ActivityEventType.OPEN_DOWNLOADS);
      expect(event.payload).assertUndefined();
    });

    /**
     * Test: ActivityEvents.updateMediaSession
     */
    it('should create updateMediaSession event', 0, () => {
      const mediaInfo: MediaSessionInfo = {
        itemId: 'media123',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        imageUrl: 'https://example.com/cover.jpg',
        duration: 180000,
        position: 60000,
        isPaused: false,
        canSeek: true
      };

      const event = ActivityEvents.updateMediaSession(mediaInfo);

      expect(event.type).assertEqual(ActivityEventType.UPDATE_MEDIA_SESSION);
      expect(event.payload?.itemId).assertEqual('media123');
      expect(event.payload?.title).assertEqual('Test Song');
      expect(event.payload?.artist).assertEqual('Test Artist');
      expect(event.payload?.duration).assertEqual(180000);
      expect(event.payload?.isPaused).assertFalse();
    });

    /**
     * Test: ActivityEvents.hideMediaSession
     */
    it('should create hideMediaSession event', 0, () => {
      const event = ActivityEvents.hideMediaSession();

      expect(event.type).assertEqual(ActivityEventType.HIDE_MEDIA_SESSION);
      expect(event.payload).assertUndefined();
    });

    /**
     * Test: ActivityEvents.updateVolume
     */
    it('should create updateVolume event', 0, () => {
      const volume = 75;
      const event = ActivityEvents.updateVolume(volume);

      expect(event.type).assertEqual(ActivityEventType.UPDATE_VOLUME);
      expect(event.payload?.volume).assertEqual(volume);
    });

    // ============ Basic emit/on Tests ============

    /**
     * Test: Subscribe to event and verify listener is registered
     */
    it('should subscribe to event type', 0, () => {
      eventHandler!.subscribe(ActivityEventType.CHANGE_FULLSCREEN, (event) => {});

      expect(eventHandler!.hasListeners(ActivityEventType.CHANGE_FULLSCREEN)).assertTrue();
    });

    /**
     * Test: hasSubscribers alias works (backward compat)
     */
    it('should report subscribers via hasSubscribers alias', 0, () => {
      eventHandler!.subscribe(ActivityEventType.CHANGE_FULLSCREEN, (event) => {});

      expect(eventHandler!.hasSubscribers(ActivityEventType.CHANGE_FULLSCREEN)).assertTrue();
    });

    /**
     * Test: Emit event and receive callback
     */
    it('should emit event and trigger callback', 0, () => {
      let receivedEvent: ActivityEvent | null = null;

      eventHandler!.subscribe(ActivityEventType.CHANGE_FULLSCREEN, (event) => {
        receivedEvent = event;
      });

      const event = ActivityEvents.changeFullscreen(true);
      eventHandler!.emit(event);

      expect(receivedEvent).assertNotNull();
      expect(receivedEvent!.type).assertEqual(ActivityEventType.CHANGE_FULLSCREEN);
      expect(receivedEvent!.payload?.isFullscreen).assertTrue();
    });

    /**
     * Test: Emit event without subscriber does not throw
     */
    it('should emit event without subscriber without error', 0, () => {
      const event = ActivityEvents.changeFullscreen(true);

      // Should not throw error
      eventHandler!.emit(event);
      expect(true).assertTrue();
    });

    /**
     * Test: Unsubscribe from event type
     */
    it('should unsubscribe from event type', 0, () => {
      const callback = (event: ActivityEvent) => {};
      eventHandler!.subscribe(ActivityEventType.CHANGE_FULLSCREEN, callback);
      expect(eventHandler!.hasListeners(ActivityEventType.CHANGE_FULLSCREEN)).assertTrue();

      eventHandler!.unsubscribe(ActivityEventType.CHANGE_FULLSCREEN, callback);
      expect(eventHandler!.hasListeners(ActivityEventType.CHANGE_FULLSCREEN)).assertFalse();
    });

    /**
     * Test: hasListeners returns false for unsubscribed type
     */
    it('should return false for unsubscribed event type', 0, () => {
      expect(eventHandler!.hasListeners(ActivityEventType.EXIT_APP)).assertFalse();
    });

    // ============ Multiple Listeners Tests ============

    /**
     * Test: Multiple subscribers for same event type all receive events
     */
    it('should notify all subscribers for same event type', 0, () => {
      let callCount1 = 0;
      let callCount2 = 0;
      let callCount3 = 0;

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        callCount1++;
      });

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        callCount2++;
      });

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        callCount3++;
      });

      eventHandler!.emit(ActivityEvents.openSettings());

      expect(callCount1).assertEqual(1);
      expect(callCount2).assertEqual(1);
      expect(callCount3).assertEqual(1);
    });

    /**
     * Test: Subscribe to multiple event types -- only matching type gets called
     */
    it('should subscribe to multiple event types independently', 0, () => {
      let settingsCalled = false;
      let downloadsCalled = false;

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        settingsCalled = true;
      });

      eventHandler!.subscribe(ActivityEventType.OPEN_DOWNLOADS, (event) => {
        downloadsCalled = true;
      });

      eventHandler!.emit(ActivityEvents.openSettings());

      expect(settingsCalled).assertTrue();
      expect(downloadsCalled).assertFalse();
    });

    /**
     * Test: Subscribe returns an unsubscribe function
     */
    it('should return unsubscribe function from subscribe', 0, () => {
      let callCount = 0;

      const unsub = eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        callCount++;
      });

      eventHandler!.emit(ActivityEvents.openSettings());
      expect(callCount).assertEqual(1);

      unsub();

      eventHandler!.emit(ActivityEvents.openSettings());
      expect(callCount).assertEqual(1); // Still 1 after unsubscribe
    });

    // ============ off / unsubscribe Tests ============

    /**
     * Test: Re-subscribe after unsubscribe
     */
    it('should allow re-subscription after unsubscribe', 0, () => {
      let callCount = 0;

      const callback = (event: ActivityEvent) => {
        callCount++;
      };

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, callback);

      eventHandler!.emit(ActivityEvents.openSettings());
      expect(callCount).assertEqual(1);

      eventHandler!.unsubscribe(ActivityEventType.OPEN_SETTINGS, callback);
      eventHandler!.emit(ActivityEvents.openSettings());
      expect(callCount).assertEqual(1);

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, callback);

      eventHandler!.emit(ActivityEvents.openSettings());
      expect(callCount).assertEqual(2);
    });

    /**
     * Test: Removing one listener does not affect others on same event type
     */
    it('should only remove specific listener not others', 0, () => {
      let callCount1 = 0;
      let callCount2 = 0;

      const callback1 = (event: ActivityEvent) => {
        callCount1++;
      };
      const callback2 = (event: ActivityEvent) => {
        callCount2++;
      };

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, callback1);
      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, callback2);

      eventHandler!.emit(ActivityEvents.openSettings());
      expect(callCount1).assertEqual(1);
      expect(callCount2).assertEqual(1);

      // Remove only callback1
      eventHandler!.unsubscribe(ActivityEventType.OPEN_SETTINGS, callback1);

      eventHandler!.emit(ActivityEvents.openSettings());
      expect(callCount1).assertEqual(1); // Not called again
      expect(callCount2).assertEqual(2); // Called again
    });

    // ============ removeAllListeners / clear Tests ============

    /**
     * Test: Clear all subscriptions
     */
    it('should clear all subscriptions', 0, () => {
      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {});
      eventHandler!.subscribe(ActivityEventType.OPEN_DOWNLOADS, (event) => {});

      expect(eventHandler!.hasListeners(ActivityEventType.OPEN_SETTINGS)).assertTrue();
      expect(eventHandler!.hasListeners(ActivityEventType.OPEN_DOWNLOADS)).assertTrue();

      eventHandler!.clear();

      expect(eventHandler!.hasListeners(ActivityEventType.OPEN_SETTINGS)).assertFalse();
      expect(eventHandler!.hasListeners(ActivityEventType.OPEN_DOWNLOADS)).assertFalse();
    });

    /**
     * Test: Clear removes all listeners so no callbacks fire
     */
    it('should not trigger any callbacks after clear', 0, () => {
      let callCount = 0;

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        callCount++;
      });
      eventHandler!.subscribe(ActivityEventType.SELECT_SERVER, (event) => {
        callCount++;
      });

      eventHandler!.clear();

      eventHandler!.emit(ActivityEvents.openSettings());
      eventHandler!.emit(ActivityEvents.selectServer());

      expect(callCount).assertEqual(0);
    });

    // ============ Reentrancy Safety Tests ============

    /**
     * Test: Emitting another event inside a callback does not cause issues
     */
    it('should handle reentrant emit safely', 0, () => {
      let outerReceived = false;
      let innerReceived = false;

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        outerReceived = true;
        // Emit a different event from inside the callback
        eventHandler!.emit(ActivityEvents.openDownloads());
      });

      eventHandler!.subscribe(ActivityEventType.OPEN_DOWNLOADS, (event) => {
        innerReceived = true;
      });

      eventHandler!.emit(ActivityEvents.openSettings());

      expect(outerReceived).assertTrue();
      expect(innerReceived).assertTrue();
    });

    /**
     * Test: Reentrant emit of same event type does not cause infinite loop
     */
    it('should handle reentrant emit of same event type without infinite loop', 0, () => {
      let callCount = 0;
      const MAX_EXPECTED = 2; // First call + one reentrant call

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        callCount++;
        // Only re-emit once to prevent actual infinite loop in test
        if (callCount < MAX_EXPECTED) {
          eventHandler!.emit(ActivityEvents.openSettings());
        }
      });

      eventHandler!.emit(ActivityEvents.openSettings());

      expect(callCount).assertEqual(MAX_EXPECTED);
    });

    /**
     * Test: Listener exception does not affect other listeners
     */
    it('should not let one throwing listener affect others', 0, () => {
      let secondCalled = false;

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        throw new Error('Intentional test error');
      });

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        secondCalled = true;
      });

      // Should not throw, and second listener should still be called
      eventHandler!.emit(ActivityEvents.openSettings());

      expect(secondCalled).assertTrue();
    });

    // ============ Queue Overflow Tests ============

    /**
     * Test: Default queue size should be at least 100
     */
    it('should support at least 100 queued events by default', 0, () => {
      const receivedEvents: ActivityEvent[] = [];

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        receivedEvents.push(event);
      });

      // Emit 100 events -- all should be delivered, none dropped
      for (let i = 0; i < 100; i++) {
        eventHandler!.emit(ActivityEvents.openSettings());
      }

      // All 100 events should have been delivered to the listener
      expect(receivedEvents.length).assertEqual(100);
    });

    /**
     * Test: Queue can be configured via setMaxQueueSize
     */
    it('should allow configuring max queue size', 0, () => {
      eventHandler!.setMaxQueueSize(5);

      // Emit 7 events -- queue should hold at most 5
      for (let i = 0; i < 7; i++) {
        eventHandler!.emit(ActivityEvents.openSettings());
      }

      const queue = eventHandler!.getEventQueue();
      expect(queue.length).assertEqual(5);
    });

    /**
     * Test: High frequency events are not silently lost from listener perspective
     */
    it('should deliver all events to listeners regardless of queue size', 0, () => {
      let deliveryCount = 0;

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        deliveryCount++;
      });

      // Emit 50 events -- all 50 should be delivered to listeners synchronously
      for (let i = 0; i < 50; i++) {
        eventHandler!.emit(ActivityEvents.openSettings());
      }

      expect(deliveryCount).assertEqual(50);
    });

    // ============ destroy Tests ============

    /**
     * Test: Destroy event handler clears all listeners
     */
    it('should destroy event handler and clear listeners', 0, () => {
      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {});

      eventHandler!.destroy();

      expect(eventHandler!.hasListeners(ActivityEventType.OPEN_SETTINGS)).assertFalse();
    });

    /**
     * Test: No callbacks fire after destroy
     */
    it('should not deliver events after destroy', 0, () => {
      let callCount = 0;

      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        callCount++;
      });

      eventHandler!.destroy();

      eventHandler!.emit(ActivityEvents.openSettings());

      expect(callCount).assertEqual(0);
    });

    /**
     * Test: Destroy clears the event queue
     */
    it('should clear event queue on destroy', 0, () => {
      eventHandler!.emit(ActivityEvents.openSettings());
      eventHandler!.emit(ActivityEvents.openSettings());

      eventHandler!.destroy();

      const queue = eventHandler!.getEventQueue();
      expect(queue.length).assertEqual(0);
    });

    /**
     * Test: Can re-initialize after destroy
     */
    it('should allow re-initialization after destroy', 0, () => {
      eventHandler!.initialize();
      eventHandler!.destroy();

      // Re-initialize should work
      eventHandler!.initialize();

      let received = false;
      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        received = true;
      });

      eventHandler!.emit(ActivityEvents.openSettings());
      expect(received).assertTrue();
    });

    // ============ Double-Dispatch Prevention Tests ============

    /**
     * Test: emit() should notify listener exactly once (not twice)
     */
    it('should notify listener exactly once per emit', 0, () => {
      let callCount = 0;

      eventHandler!.initialize();
      eventHandler!.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        callCount++;
      });

      eventHandler!.emit(ActivityEvents.openSettings());

      expect(callCount).assertEqual(1);
    });

    /**
     * Test: multiple emits should each trigger exactly one callback
     */
    it('should trigger exactly one callback per emit when emitting multiple events', 0, () => {
      let callCount = 0;

      eventHandler!.initialize();
      eventHandler!.subscribe(ActivityEventType.CHANGE_FULLSCREEN, (event) => {
        callCount++;
      });

      eventHandler!.emit(ActivityEvents.changeFullscreen(true));
      eventHandler!.emit(ActivityEvents.changeFullscreen(false));
      eventHandler!.emit(ActivityEvents.changeFullscreen(true));

      expect(callCount).assertEqual(3);
    });

    // ============ subscribeAll Tests ============

    /**
     * Test: subscribeAll registers callback for all known event types
     */
    it('should subscribe to all event types via subscribeAll', 0, () => {
      const receivedTypes: string[] = [];

      eventHandler!.subscribeAll((event) => {
        receivedTypes.push(event.type);
      });

      // Emit several different event types
      eventHandler!.emit(ActivityEvents.openSettings());
      eventHandler!.emit(ActivityEvents.changeFullscreen(true));
      eventHandler!.emit(ActivityEvents.exitApp());

      expect(receivedTypes.length).assertEqual(3);
      expect(receivedTypes.includes(ActivityEventType.OPEN_SETTINGS)).assertTrue();
      expect(receivedTypes.includes(ActivityEventType.CHANGE_FULLSCREEN)).assertTrue();
      expect(receivedTypes.includes(ActivityEventType.EXIT_APP)).assertTrue();
    });

    /**
     * Test: subscribeAll returns a function that unsubscribes from all types
     */
    it('should unsubscribe from all types via returned function', 0, () => {
      let callCount = 0;

      const unsubAll = eventHandler!.subscribeAll((event) => {
        callCount++;
      });

      eventHandler!.emit(ActivityEvents.openSettings());
      expect(callCount).assertEqual(1);

      unsubAll();

      eventHandler!.emit(ActivityEvents.openSettings());
      eventHandler!.emit(ActivityEvents.exitApp());
      expect(callCount).assertEqual(1); // No new calls
    });

    // ============ tryEmit Tests ============

    /**
     * Test: tryEmit returns true on success
     */
    it('should return true from tryEmit on success', 0, () => {
      const result = eventHandler!.tryEmit(ActivityEvents.openSettings());
      expect(result).assertTrue();
    });

    // ============ Event Payload Tests ============

    /**
     * Test: Emit with complex payload
     */
    it('should emit event with complex payload', 0, () => {
      let receivedEvent: ActivityEvent | null = null;

      eventHandler!.subscribe(ActivityEventType.LAUNCH_NATIVE_PLAYER, (event) => {
        receivedEvent = event;
      });

      const playOptions: PlayOptions = {
        ids: ['id1', 'id2', 'id3'],
        mediaSourceId: 'source1',
        startIndex: 1,
        startPosition: 10000,
        audioStreamIndex: 2,
        subtitleStreamIndex: 0,
        playFromDownloads: true
      };

      eventHandler!.emit(ActivityEvents.launchNativePlayer(playOptions));

      expect(receivedEvent).assertNotNull();
      expect(receivedEvent!.payload?.ids.length).assertEqual(3);
      expect(receivedEvent!.payload?.mediaSourceId).assertEqual('source1');
      expect(receivedEvent!.payload?.startPosition).assertEqual(10000);
      expect(receivedEvent!.payload?.playFromDownloads).assertTrue();
    });

    // ============ PlayOptions Interface Tests ============

    /**
     * Test: PlayOptions with minimal fields
     */
    it('should create PlayOptions with minimal fields', 0, () => {
      const options: PlayOptions = {
        ids: ['media1'],
        startIndex: 0
      };

      expect(options.ids.length).assertEqual(1);
      expect(options.startIndex).assertEqual(0);
      expect(options.startPosition).assertUndefined();
      expect(options.playFromDownloads).assertUndefined();
    });

    /**
     * Test: PlayOptions with all fields
     */
    it('should create PlayOptions with all fields', 0, () => {
      const options: PlayOptions = {
        ids: ['media1', 'media2'],
        mediaSourceId: 'source1',
        startIndex: 0,
        startPosition: 5000,
        audioStreamIndex: 1,
        subtitleStreamIndex: 2,
        playFromDownloads: false
      };

      expect(options.ids.length).assertEqual(2);
      expect(options.mediaSourceId).assertEqual('source1');
      expect(options.startPosition).assertEqual(5000);
      expect(options.audioStreamIndex).assertEqual(1);
      expect(options.subtitleStreamIndex).assertEqual(2);
      expect(options.playFromDownloads).assertFalse();
    });

    // ============ MediaSessionInfo Interface Tests ============

    /**
     * Test: MediaSessionInfo with all fields
     */
    it('should create MediaSessionInfo with all fields', 0, () => {
      const info: MediaSessionInfo = {
        itemId: 'item1',
        title: 'Test Title',
        artist: 'Test Artist',
        album: 'Test Album',
        imageUrl: 'https://example.com/image.jpg',
        duration: 180000,
        position: 60000,
        isPaused: true,
        canSeek: true
      };

      expect(info.itemId).assertEqual('item1');
      expect(info.title).assertEqual('Test Title');
      expect(info.artist).assertEqual('Test Artist');
      expect(info.duration).assertEqual(180000);
      expect(info.isPaused).assertTrue();
    });

    /**
     * Test: MediaSessionInfo with required fields only
     */
    it('should create MediaSessionInfo with required fields only', 0, () => {
      const info: MediaSessionInfo = {
        itemId: 'item1',
        title: 'Test Title',
        duration: 180000,
        position: 60000,
        isPaused: false,
        canSeek: false
      };

      expect(info.itemId).assertEqual('item1');
      expect(info.artist).assertUndefined();
      expect(info.album).assertUndefined();
      expect(info.imageUrl).assertUndefined();
    });

    // ============ Singleton Tests ============

    /**
     * Test: getInstance returns the same instance
     */
    it('should return same singleton instance from getInstance', 0, () => {
      const instance1 = ActivityEventHandler.getInstance();
      const instance2 = ActivityEventHandler.getInstance();

      expect(instance1 === instance2).assertTrue();
    });
  });
}
