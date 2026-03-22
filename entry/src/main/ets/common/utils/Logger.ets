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
 * Jellyfin HarmonyOS - Logger
 * Migrated from jellyfin-android/JellyTree.kt (Timber tree)
 *
 * Uses HarmonyOS hilog for logging implementation.
 */

import hilog from '@ohos.hilog';

/**
 * Log priority levels (matching Android Log constants)
 */
export enum LogPriority {
  VERBOSE = 2,
  DEBUG = 3,
  INFO = 4,
  WARN = 5,
  ERROR = 6,
  FATAL = 7
}

/**
 * Logger class providing Timber-like logging API for HarmonyOS.
 * In debug builds, all logs are shown.
 * In release builds, only INFO and above are shown.
 */
export class Logger {
  private static readonly DOMAIN: number = 0x0000; // Log domain for Jellyfin
  private static readonly TAG: string = 'Jellyfin';
  private static isDebug: boolean = true; // TODO: Get from build config

  /**
   * Set debug mode. In debug mode, all log levels are output.
   */
  static setDebugMode(debug: boolean): void {
    Logger.isDebug = debug;
  }

  /**
   * Log verbose message.
   * Only shown in debug builds.
   */
  static v(tag: string | null, message: string, ...args: string[]): void {
    if (Logger.isDebug) {
      const finalTag = tag ?? Logger.TAG;
      hilog.debug(Logger.DOMAIN, finalTag, message, args);
    }
  }

  /**
   * Log debug message.
   * Only shown in debug builds.
   */
  static d(tag: string | null, message: string, ...args: string[]): void {
    if (Logger.isDebug) {
      const finalTag = tag ?? Logger.TAG;
      hilog.debug(Logger.DOMAIN, finalTag, message, args);
    }
  }

  /**
   * Log info message.
   * Always shown.
   */
  static i(tag: string | null, message: string, ...args: string[]): void {
    const finalTag = tag ?? Logger.TAG;
    hilog.info(Logger.DOMAIN, finalTag, message, args);
  }

  /**
   * Log warning message.
   * Always shown.
   */
  static w(tag: string | null, message: string, ...args: string[]): void {
    const finalTag = tag ?? Logger.TAG;
    hilog.warn(Logger.DOMAIN, finalTag, message, args);
  }

  /**
   * Log error message.
   * Always shown.
   */
  static e(tag: string | null, message: string, ...args: string[]): void {
    const finalTag = tag ?? Logger.TAG;
    hilog.error(Logger.DOMAIN, finalTag, message, args);
  }

  /**
   * Log error with throwable/error object.
   */
  static et(tag: string | null, message: string, error: Error | undefined): void {
    const finalTag = tag ?? Logger.TAG;
    const errorMsg = error ? message + ': ' + error.message : message;
    hilog.error(Logger.DOMAIN, finalTag, errorMsg);
    if (error?.stack && Logger.isDebug) {
      hilog.error(Logger.DOMAIN, finalTag, 'Stack trace: %{public}s', error.stack);
    }
  }

  /**
   * Log fatal message.
   * Always shown.
   */
  static wtf(tag: string | null, message: string, ...args: string[]): void {
    const finalTag = tag ?? Logger.TAG;
    hilog.fatal(Logger.DOMAIN, finalTag, message, args);
  }

  /**
   * Create a tagged logger instance for a specific component.
   */
  static withTag(tag: string): TaggedLogger {
    return new TaggedLogger(tag);
  }
}

/**
 * Tagged logger for a specific component.
 */
export class TaggedLogger {
  private tag: string;

  constructor(tag: string) {
    this.tag = tag;
  }

  v(message: string, ...args: string[]): void {
    Logger.v(this.tag, message, ...args);
  }

  d(message: string, ...args: string[]): void {
    Logger.d(this.tag, message, ...args);
  }

  i(message: string, ...args: string[]): void {
    Logger.i(this.tag, message, ...args);
  }

  w(message: string, ...args: string[]): void {
    Logger.w(this.tag, message, ...args);
  }

  e(message: string, ...args: string[]): void {
    Logger.e(this.tag, message, ...args);
  }

  et(message: string, error: Error | undefined): void {
    Logger.et(this.tag, message, error);
  }

  wtf(message: string, ...args: string[]): void {
    Logger.wtf(this.tag, message, ...args);
  }
}

// Pre-created loggers for common components
export const AppLog = Logger.withTag('App');
export const PlayerLog = Logger.withTag('Player');
export const WebViewLog = Logger.withTag('WebView');
export const NetworkLog = Logger.withTag('Network');
export const PrefLog = Logger.withTag('Preferences');
