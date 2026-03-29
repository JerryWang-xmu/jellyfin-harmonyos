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
 * Jellyfin HarmonyOS - ActivityEventHandler
 * Migrated from jellyfin-android/events/ActivityEventHandler.kt
 *
 * Handles activity events from the web app using HarmonyOS emitter.
 */

import emitter from '@ohos.events.emitter';
import { ActivityEvent, ActivityEventType } from './ActivityEvent';
import { Logger, AppLog } from '../../common/utils/Logger';

// ==================== Types ====================

/**
 * Event handler callback type.
 */
export type ActivityEventCallback = (event: ActivityEvent) => void;

/**
 * Event handler map type.
 */
type EventListenerMap = Map<ActivityEventType, Set<ActivityEventCallback>>;

/**
 * Internal event data structure for emitter.
 */
interface EmitterEventData {
  type: string;
  payload: string;
}

// ==================== ActivityEventHandler ====================

/**
 * ActivityEventHandler manages the emission and subscription of activity events.
 * Uses HarmonyOS emitter for cross-component communication.
 */
export class ActivityEventHandler {
  private static readonly EVENT_ID: number = 1001;
  private static instance: ActivityEventHandler | null = null;

  private listeners: EventListenerMap = new Map();
  private eventQueue: ActivityEvent[] = [];
  private maxQueueSize: number = 10;
  private isInitialized: boolean = false;
  // 标记位：防止 emitter.on 回调与 emit() 直接通知造成双重分发。
  // emit() 通过 emitter.emit() 广播后，同进程 emitter.on 回调会同步触发，
  // 此时 _emittingInsideEmit 为 true，handleEmitterEvent 跳过本地通知。
  private _emittingInsideEmit: boolean = false;

  private constructor() {
    // Private constructor for singleton
  }

  /**
   * Get singleton instance.
   */
  static getInstance(): ActivityEventHandler {
    if (!ActivityEventHandler.instance) {
      ActivityEventHandler.instance = new ActivityEventHandler();
    }
    return ActivityEventHandler.instance;
  }

  /**
   * Initialize the event handler and register with emitter.
   */
  initialize(): void {
    if (this.isInitialized) {
      return;
    }

    this.registerEmitter();
    this.isInitialized = true;
    AppLog.i('ActivityEventHandler initialized');
  }

  /**
   * Register with HarmonyOS emitter to receive events.
   */
  private registerEmitter(): void {
    emitter.on({ eventId: ActivityEventHandler.EVENT_ID }, (eventData) => {
      this.handleEmitterEvent(eventData);
    });
  }

  /**
   * Handle events from emitter.
   * 当 _emittingInsideEmit 为 true 时，说明此回调是由同进程的 emit() 触发的
   * emitter.emit() 同步回调，此时监听者已在 emit() 中被通知过，跳过以避免双重分发。
   */
  private handleEmitterEvent(eventData: emitter.EventData): void {
    try {
      // 防双重分发：如果正在 emit() 内部，跳过 emitter 回调的本地通知
      if (this._emittingInsideEmit) {
        return;
      }

      const rawData = eventData.data;
      if (!rawData) {
        AppLog.w('Received null event data from emitter');
        return;
      }
      const data = rawData as EmitterEventData;
      if (!data.type) {
        AppLog.w('Received invalid event data from emitter');
        return;
      }

      const event: ActivityEvent = {
        type: data.type as ActivityEventType,
        payload: data.payload ? JSON.parse(data.payload) : undefined
      };

      this.notifyListeners(event);
    } catch (error) {
      AppLog.et('Failed to handle emitter event', error as Error);
    }
  }

  /**
   * Emit an activity event.
   * 使用标记位防止双重分发：emit() 先通过 notifyListeners 直接通知本地监听者，
   * 然后通过 emitter.emit() 广播给其他组件。由于 emitter.on 回调在同进程中是同步触发的，
   * 设置 _emittingInsideEmit 标记让 handleEmitterEvent 跳过重复通知。
   */
  emit(event: ActivityEvent): void {
    // Add to queue for buffer overflow handling
    if (this.eventQueue.length >= this.maxQueueSize) {
      const dropped = this.eventQueue.shift();
      AppLog.w('Event queue overflow, dropping oldest event: ' + (dropped?.type ?? 'unknown'));
    }
    this.eventQueue.push(event);

    // Notify local listeners directly (synchronous, first delivery)
    this.notifyListeners(event);

    // Broadcast via emitter (triggers handleEmitterEvent in same process synchronously)
    // _emittingInsideEmit 标记防止 handleEmitterEvent 重复通知
    this._emittingInsideEmit = true;
    try {
      const eventData: emitter.EventData = {
        data: {
          type: event.type,
          payload: JSON.stringify(event.payload ?? {})
        }
      };
      emitter.emit({
        eventId: ActivityEventHandler.EVENT_ID,
        priority: emitter.EventPriority.HIGH
      }, eventData);
    } catch (error) {
      AppLog.et('Failed to emit event via emitter', error as Error);
    } finally {
      this._emittingInsideEmit = false;
    }
  }

  /**
   * Try to emit an event without blocking.
   * Returns true if the event was emitted successfully.
   */
  tryEmit(event: ActivityEvent): boolean {
    try {
      this.emit(event);
      return true;
    } catch (error) {
      AppLog.et('Failed to tryEmit event', error as Error);
      return false;
    }
  }

  /**
   * Notify all registered listeners for an event type.
   */
  private notifyListeners(event: ActivityEvent): void {
    const callbacks = this.listeners.get(event.type);
    if (callbacks) {
      callbacks.forEach(callback => {
        try {
          callback(event);
        } catch (error) {
          AppLog.et('Error in event listener for ' + event.type, error as Error);
        }
      });
    }
  }

  /**
   * Subscribe to events of a specific type.
   * @param type Event type to subscribe to
   * @param callback Function to call when event is received
   * @returns Unsubscribe function
   */
  subscribe(type: ActivityEventType, callback: ActivityEventCallback): () => void {
    if (!this.listeners.has(type)) {
      this.listeners.set(type, new Set());
    }
    this.listeners.get(type)!.add(callback);

    // Return unsubscribe function
    return () => {
      this.unsubscribe(type, callback);
    };
  }

  /**
   * Subscribe to all events.
   * @param callback Function to call when any event is received
   * @returns Unsubscribe function
   */
  subscribeAll(callback: ActivityEventCallback): () => void {
    const unsubscribers: (() => void)[] = [];

    // Subscribe to all known event types
    const eventTypes: ActivityEventType[] = [
      ActivityEventType.CHANGE_FULLSCREEN,
      ActivityEventType.LAUNCH_NATIVE_PLAYER,
      ActivityEventType.OPEN_URL,
      ActivityEventType.DOWNLOAD_FILE,
      ActivityEventType.REMOVE_DOWNLOAD,
      ActivityEventType.CAST_MESSAGE,
      ActivityEventType.REQUEST_BLUETOOTH_PERMISSION,
      ActivityEventType.OPEN_SETTINGS,
      ActivityEventType.SELECT_SERVER,
      ActivityEventType.EXIT_APP,
      ActivityEventType.OPEN_DOWNLOADS,
      ActivityEventType.UPDATE_MEDIA_SESSION,
      ActivityEventType.HIDE_MEDIA_SESSION,
      ActivityEventType.UPDATE_VOLUME
    ];

    for (const type of eventTypes) {
      unsubscribers.push(this.subscribe(type, callback));
    }

    // Return combined unsubscribe function
    return () => {
      for (const unsub of unsubscribers) {
        unsub();
      }
    };
  }

  /**
   * Unsubscribe from events of a specific type.
   */
  unsubscribe(type: ActivityEventType, callback: ActivityEventCallback): void {
    const callbacks = this.listeners.get(type);
    if (callbacks) {
      callbacks.delete(callback);
      if (callbacks.size === 0) {
        this.listeners.delete(type);
      }
    }
  }

  /**
   * Check if there are any listeners for a specific event type.
   */
  hasListeners(type: ActivityEventType): boolean {
    const callbacks = this.listeners.get(type);
    return callbacks !== undefined && callbacks.size > 0;
  }

  /**
   * Clear all listeners.
   */
  clear(): void {
    this.listeners.clear();
    this.eventQueue = [];
    AppLog.i('ActivityEventHandler cleared all listeners');
  }

  /**
   * Get the current event queue (for debugging).
   */
  getEventQueue(): ActivityEvent[] {
    return [...this.eventQueue];
  }

  /**
   * Set the maximum queue size.
   */
  setMaxQueueSize(size: number): void {
    this.maxQueueSize = size;
    // Trim queue if necessary
    while (this.eventQueue.length > this.maxQueueSize) {
      this.eventQueue.shift();
    }
  }

  /**
   * Destroy the event handler.
   */
  destroy(): void {
    this.clear();
    try {
      emitter.off(ActivityEventHandler.EVENT_ID);
    } catch (error) {
      AppLog.et('Failed to unregister emitter', error as Error);
    }
    this.isInitialized = false;
    AppLog.i('ActivityEventHandler destroyed');
  }
}

// ==================== Convenience Exports ====================

/**
 * Convenience function to subscribe to activity events.
 */
export const onActivityEvent = (
  type: ActivityEventType,
  callback: ActivityEventCallback
): (() => void) => {
  return ActivityEventHandler.getInstance().subscribe(type, callback);
};

/**
 * Convenience function to emit activity events.
 */
export const emitActivityEvent = (event: ActivityEvent): void => {
  ActivityEventHandler.getInstance().emit(event);
};

/**
 * Convenience function to try emit activity events.
 */
export const tryEmitActivityEvent = (event: ActivityEvent): boolean => {
  return ActivityEventHandler.getInstance().tryEmit(event);
};
