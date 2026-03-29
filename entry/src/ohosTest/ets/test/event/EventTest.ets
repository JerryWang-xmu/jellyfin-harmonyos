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
 * 活动事件处理器测试
 * 测试 ActivityEventHandler 的事件发送和订阅功能
 */

import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import { ActivityEventHandler } from '../../../../main/ets/core/event/ActivityEventHandler';
import { ActivityEventType, ActivityEvents, ActivityEvent } from '../../../../main/ets/core/event/ActivityEvent';

export default function EventTest() {
  describe('ActivityEventHandler', () => {
    let eventHandler: ActivityEventHandler;

    beforeEach(() => {
      eventHandler = new ActivityEventHandler();
    });

    afterEach(() => {
      eventHandler.destroy();
    });

    /**
     * 测试事件订阅
     */
    it('should_subscribe_to_event', () => {
      let received = false;
      eventHandler.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        received = true;
      });

      eventHandler.emit(ActivityEvents.openSettings());

      expect(received).assertTrue();
    });

    /**
     * 测试事件取消订阅
     */
    it('should_unsubscribe_from_event', () => {
      let callCount = 0;
      const callback = (event: ActivityEvent) => {
        callCount++;
      };
      eventHandler.subscribe(ActivityEventType.OPEN_SETTINGS, callback);

      eventHandler.emit(ActivityEvents.openSettings());
      expect(callCount).assertEqual(1);

      eventHandler.unsubscribe(ActivityEventType.OPEN_SETTINGS, callback);
      eventHandler.emit(ActivityEvents.openSettings());
      expect(callCount).assertEqual(1); // 应该还是 1，因为已取消订阅
    });

    /**
     * 测试事件负载
     */
    it('should_deliver_event_payload', () => {
      let receivedEvent: ActivityEvent | null = null;
      eventHandler.subscribe(ActivityEventType.CHANGE_FULLSCREEN, (event) => {
        receivedEvent = event;
      });

      eventHandler.emit(ActivityEvents.changeFullscreen(true));

      expect(receivedEvent).assertNotNull();
      expect(receivedEvent?.type).assertEqual(ActivityEventType.CHANGE_FULLSCREEN);
      expect(receivedEvent?.payload?.isFullscreen).assertTrue();
    });

    /**
     * 测试清除所有订阅
     */
    it('should_clear_all_subscriptions', () => {
      let callCount = 0;

      eventHandler.subscribe(ActivityEventType.OPEN_SETTINGS, (event) => {
        callCount++;
      });
      eventHandler.subscribe(ActivityEventType.SELECT_SERVER, (event) => {
        callCount++;
      });

      eventHandler.clear();

      eventHandler.emit(ActivityEvents.openSettings());
      eventHandler.emit(ActivityEvents.selectServer());

      expect(callCount).assertEqual(0);
    });
  });

  describe('ActivityEvents', () => {
    /**
     * 测试 openSettings 事件工厂
     */
    it('should_create_open_settings_event', () => {
      const event = ActivityEvents.openSettings();
      expect(event.type).assertEqual(ActivityEventType.OPEN_SETTINGS);
      expect(event.payload).assertUndefined();
    });

    /**
     * 测试 changeFullscreen 事件工厂
     */
    it('should_create_change_fullscreen_event', () => {
      const event = ActivityEvents.changeFullscreen(true);
      expect(event.type).assertEqual(ActivityEventType.CHANGE_FULLSCREEN);
      expect(event.payload?.isFullscreen).assertTrue();
    });

    /**
     * 测试 openUrl 事件工厂
     */
    it('should_create_open_url_event', () => {
      const event = ActivityEvents.openUrl('https://example.com');
      expect(event.type).assertEqual(ActivityEventType.OPEN_URL);
      expect(event.payload?.uri).assertEqual('https://example.com');
    });

    /**
     * 测试 downloadFile 事件工厂
     */
    it('should_create_download_file_event', () => {
      const event = ActivityEvents.downloadFile('https://example.com/file.mp4', 'Test File', 'file.mp4');
      expect(event.type).assertEqual(ActivityEventType.DOWNLOAD_FILE);
      expect(event.payload?.uri).assertEqual('https://example.com/file.mp4');
      expect(event.payload?.title).assertEqual('Test File');
      expect(event.payload?.filename).assertEqual('file.mp4');
    });
  });
}
