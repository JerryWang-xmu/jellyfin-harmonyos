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
 * Pure in-process event bus using Map<string, Set<Function>>.
 * Replaces the previous @ohos.events.emitter-based implementation to remove
 * the double-dispatch complexity (no more _emittingInsideEmit flag).
 * All communication is within the same process, so a simple listener map
 * is sufficient and more performant.
 */

import { ActivityEvent, ActivityEventType } from './ActivityEvent';
import { AppLog } from '../../common/utils/Logger';

// ==================== Types ====================

/**
 * Event handler callback type.
 */
export type ActivityEventCallback = (event: ActivityEvent) => void;

/**
 * Event handler map type.
 * Maps event type strings to a set of callback functions.
 * Using Set ensures duplicate subscriptions are ignored.
 */
type EventListenerMap = Map<string, Set<ActivityEventCallback>>;

// ==================== Constants ====================

/** Default maximum event queue size. */
const DEFAULT_MAX_QUEUE_SIZE: number = 100;

// ==================== ActivityEventHandler ====================

/**
 * ActivityEventHandler manages the emission and subscription of activity events.
 *
 * Pure in-process event bus. No dependency on @ohos.events.emitter --
 * all listeners are invoked synchronously during emit(), eliminating the
 * double-dispatch problem that previously required the _emittingInsideEmit flag.
 */
export class ActivityEventHandler {
  private static instance: ActivityEventHandler | null = null;

  /** Registered listeners, keyed by event type string. */
  private listeners: EventListenerMap = new Map();

  /** Bounded event queue for diagnostic / replay purposes. */
  private eventQueue: ActivityEvent[] = [];

  /** Maximum number of events retained in the queue. */
  private maxQueueSize: number = DEFAULT_MAX_QUEUE_SIZE;

  /** Whether initialize() has been called. Kept for API compatibility. */
  private isInitialized: boolean = false;

  /**
   * Constructor -- public so that unit tests can create fresh instances.
   * Production code should prefer ActivityEventHandler.getInstance().
   */
  constructor() {
    // Empty -- state is initialized at the field level.
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
   * Initialize the event handler.
   *
   * In this pure in-process implementation there is no external emitter to
   * register with, so this method only marks the handler as initialised.
   * It is kept for backward compatibility with call-sites that call initialize().
   */
  initialize(): void {
    if (this.isInitialized) {
      return;
    }
    this.isInitialized = true;
    AppLog.i('ActivityEventHandler initialized');
  }

  /**
   * Emit an activity event.
   *
   * 1. Enqueue the event (dropping the oldest if the queue is full).
   * 2. Notify every registered listener for this event type synchronously.
   *    Each listener is invoked in its own try/catch so that one failing
   *    listener cannot prevent others from receiving the event.
   */
  emit(event: ActivityEvent): void {
    // Enqueue with overflow handling
    if (this.eventQueue.length >= this.maxQueueSize) {
      const dropped = this.eventQueue.shift();
      AppLog.w('Event queue overflow, dropping oldest event: ' + (dropped?.type ?? 'unknown'));
    }
    this.eventQueue.push(event);

    // Notify listeners directly -- no external emitter, no double-dispatch.
    this.notifyListeners(event);
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
   *
   * Iterates over a snapshot of the listener set so that mutations
   * (subscribe / unsubscribe) during iteration do not cause issues.
   * Each callback is wrapped in try/catch to isolate failures.
   */
  private notifyListeners(event: ActivityEvent): void {
    const callbacks = this.listeners.get(event.type);
    if (!callbacks) {
      return;
    }

    // Iterate over an array snapshot so that reentrant subscribe/unsubscribe
    // during iteration is safe.
    const snapshot = Array.from(callbacks);
    for (const callback of snapshot) {
      try {
        callback(event);
      } catch (error) {
        AppLog.et('Error in event listener for ' + event.type, error as Error);
      }
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
   * Unsubscribe a specific callback from events of a specific type.
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
   * Alias for hasListeners -- backward compatibility.
   * Some existing call-sites and tests use hasSubscribers.
   */
  hasSubscribers(type: ActivityEventType): boolean {
    return this.hasListeners(type);
  }

  /**
   * Clear all listeners and the event queue.
   */
  clear(): void {
    this.listeners.clear();
    this.eventQueue = [];
    AppLog.i('ActivityEventHandler cleared all listeners');
  }

  /**
   * Get the current event queue (snapshot for debugging).
   */
  getEventQueue(): ActivityEvent[] {
    return [...this.eventQueue];
  }

  /**
   * Set the maximum queue size.
   * Trims the queue immediately if it exceeds the new limit.
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
   * Clears all listeners, the event queue, and resets the initialized flag.
   * After destroy the handler can be re-initialized if needed.
   */
  destroy(): void {
    this.clear();
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
