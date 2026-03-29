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
 * WebappFunctionChannel
 * Provides a native-to-web event forwarding channel.
 *
 * Responsibilities:
 * - Forward native-side events (media session, volume, etc.) to the Jellyfin Web App
 * - Offer convenience methods for specific notifications (user login, server connected, etc.)
 *
 * All dependencies are injected via the constructor. Call initialize() to subscribe
 * to event-handler events, and destroy() to clean up.
 */

import { BridgeChannel } from '../bridge/BridgeChannel';
import { ActivityEventHandler, ActivityEventCallback } from '../core/event/ActivityEventHandler';
import { ActivityEventType, ActivityEvent } from '../core/event/ActivityEvent';
import { Logger } from '../common/utils/Logger';

export class WebappFunctionChannel {
  private static readonly TAG: string = 'WebappFunctionChannel';

  private bridgeChannel: BridgeChannel;
  private eventHandler: ActivityEventHandler;
  private initialized: boolean = false;

  // Keep unsubscribe functions so destroy() can clean them up
  private unsubscribeFns: (() => void)[] = [];

  constructor(bridgeChannel: BridgeChannel, eventHandler: ActivityEventHandler) {
    this.bridgeChannel = bridgeChannel;
    this.eventHandler = eventHandler;
    Logger.i(WebappFunctionChannel.TAG, 'WebappFunctionChannel created');
  }

  /**
   * Subscribe to native events that need to be forwarded to the web app.
   * Safe to call multiple times; subsequent calls are no-ops.
   */
  initialize(): void {
    if (this.initialized) {
      Logger.w(WebappFunctionChannel.TAG, 'Already initialized, skipping');
      return;
    }

    this.subscribeEvent(ActivityEventType.UPDATE_MEDIA_SESSION, (event) => {
      this.bridgeChannel.callFunction('window.NativeShell.updateMediaSession', event.payload ?? null);
    });

    this.subscribeEvent(ActivityEventType.HIDE_MEDIA_SESSION, () => {
      this.bridgeChannel.callFunction('window.NativeShell.hideMediaSession');
    });

    this.initialized = true;
    Logger.i(WebappFunctionChannel.TAG, 'WebappFunctionChannel initialized');
  }

  /**
   * Clean up all subscriptions. Safe to call multiple times.
   */
  destroy(): void {
    if (!this.initialized && this.unsubscribeFns.length === 0) {
      return;
    }

    for (const unsub of this.unsubscribeFns) {
      unsub();
    }
    this.unsubscribeFns = [];
    this.initialized = false;
    Logger.i(WebappFunctionChannel.TAG, 'WebappFunctionChannel destroyed');
  }

  // ==================== Notification Methods ====================

  /**
   * Notify the web app that a user has logged in.
   */
  notifyUserLogin(userId: string, userName: string): void {
    this.notifyWebapp('userLogin', { userId, userName });
    Logger.i(WebappFunctionChannel.TAG, 'Notified webapp of user login: %{public}s', userName);
  }

  /**
   * Notify the web app that a server connection has been established.
   */
  notifyServerConnected(serverUrl: string, serverName: string): void {
    this.notifyWebapp('serverConnected', { serverUrl, serverName });
    Logger.i(WebappFunctionChannel.TAG, 'Notified webapp of server connection: %{public}s', serverName);
  }

  /**
   * Send download progress to the web app.
   */
  notifyDownloadProgress(itemId: string, progress: number): void {
    this.notifyWebapp('downloadProgress', { itemId, progress });
  }

  /**
   * Request the web app to navigate to a specific route.
   */
  navigateTo(route: string): void {
    this.notifyWebapp('navigate', { route });
    Logger.d(WebappFunctionChannel.TAG, 'Requested navigation to: %{public}s', route);
  }

  /**
   * Report playback state to the web app.
   */
  reportPlaybackState(state: Record<string, Object>): void {
    this.notifyWebapp('playbackState', state);
  }

  /**
   * Generic notification to the web app.
   * Calls window.NativeShell.notifyEvent(eventName, data) in the WebView.
   */
  notifyWebapp(eventName: string, data?: Record<string, Object>): void {
    this.bridgeChannel.callFunction(
      'window.NativeShell.notifyEvent',
      eventName,
      data ?? {}
    );
  }

  // ==================== Private Helpers ====================

  /**
   * Subscribe to an event type and track the unsubscribe function.
   */
  private subscribeEvent(type: ActivityEventType, callback: ActivityEventCallback): void {
    const unsub = this.eventHandler.subscribe(type, callback);
    this.unsubscribeFns.push(unsub);
  }
}
