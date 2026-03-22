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
 * Jellyfin HarmonyOS - AppDependency
 * Simple dependency injection container
 *
 * Replaces Koin DI from Android with a lightweight singleton-based approach
 * suitable for HarmonyOS application architecture.
 */

import common from '@ohos.app.ability.common';
import { AppPreferences, VideoPlayerType, ExternalPlayerPackage } from '../preferences/AppPreferences';
import { ActivityEventHandler } from '../event/ActivityEventHandler';
import { ActivityEvent, ActivityEventType } from '../event/ActivityEvent';
import { Logger, AppLog } from '../../common/utils/Logger';
import { JellyfinDatabase, getDatabase } from '../../data/database/JellyfinDatabase';
import { ApiClientController } from '../../api/ApiClientController';

// ==================== Enums ====================

/**
 * Application state enumeration.
 */
export enum AppState {
  UNINITIALIZED = 'uninitialized',
  INITIALIZING = 'initializing',
  READY = 'ready',
  ERROR = 'error'
}

// ==================== Interfaces ====================

/**
 * Interface for services that require initialization.
 */
export interface Initializable {
  initialize(): Promise<void>;
}

/**
 * Interface for services that can be destroyed.
 */
export interface Destroyable {
  destroy(): Promise<void>;
}

/**
 * Server entity.
 */
export interface ServerEntity {
  id?: number;
  hostname: string;
  lastUsedTimestamp: number;
}

/**
 * User entity.
 */
export interface UserEntity {
  id?: number;
  serverId: number;
  userId: string;
  accessToken?: string;
  lastLoginTimestamp: number;
}

// ==================== AppDependency Class ====================

/**
 * AppDependency provides singleton access to core application services.
 * Implements a simple service locator pattern for dependency injection.
 */
export class AppDependency {
  private static instance: AppDependency | null = null;

  // Core services
  private _context: common.UIAbilityContext | null = null;
  private _preferences: AppPreferences | null = null;
  private _eventHandler: ActivityEventHandler | null = null;
  private _database: JellyfinDatabase | null = null;
  private _apiController: ApiClientController | null = null;

  // Current server and user
  private _currentServer: ServerEntity | null = null;
  private _currentUser: UserEntity | null = null;

  // Navigation stack（由 AppRoot 注册，供事件回调驱动导航）
  private _navPathStack: NavPathStack | null = null;

  // State
  private _state: AppState = AppState.UNINITIALIZED;
  private _initError: Error | null = null;

  // Private constructor for singleton
  private constructor() {}

  /**
   * Get the singleton instance of AppDependency.
   */
  static getInstance(): AppDependency {
    if (!AppDependency.instance) {
      AppDependency.instance = new AppDependency();
    }
    return AppDependency.instance;
  }

  /**
   * Initialize all core services.
   * Must be called before accessing any services.
   * @param context Application UIAbility context
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this._state === AppState.READY) {
      AppLog.w('AppDependency already initialized');
      return;
    }

    if (this._state === AppState.INITIALIZING) {
      throw new Error('AppDependency is currently initializing');
    }

    this._state = AppState.INITIALIZING;
    this._context = context;
    this._initError = null;

    try {
      AppLog.i('Initializing AppDependency...');

      // Initialize preferences
      this._preferences = new AppPreferences(context);
      await this._preferences.initialize();
      AppLog.i('Preferences initialized');

      // Initialize event handler
      this._eventHandler = ActivityEventHandler.getInstance();
      this._eventHandler.initialize();
      AppLog.i('Event handler initialized');

      // Initialize database
      this._database = await getDatabase(context);
      AppLog.i('Database initialized');

      // Initialize ApiClientController
      this._apiController = new ApiClientController(
        this._preferences,
        this._database.serverDao,
        this._database.userDao
      );
      AppLog.i('ApiClientController initialized');

      this._state = AppState.READY;
      AppLog.i('AppDependency initialized successfully');
    } catch (error) {
      this._state = AppState.ERROR;
      const err = error as Error;
      this._initError = err;
      AppLog.et('Failed to initialize AppDependency', err);
      throw new Error('Failed to initialize AppDependency: ' + (err?.message ?? 'unknown error'));
    }
  }

  /**
   * Destroy all services and reset state.
   * Called when the application is terminating.
   */
  async destroy(): Promise<void> {
    AppLog.i('Destroying AppDependency...');

    // Clear event handler listeners
    if (this._eventHandler) {
      this._eventHandler.destroy();
    }

    // Save preferences
    if (this._preferences) {
      await this._preferences.save();
    }

    // Reset state
    this._context = null;
    this._preferences = null;
    this._eventHandler = null;
    this._database = null;
    this._apiController = null;
    this._currentServer = null;
    this._currentUser = null;
    this._navPathStack = null;
    this._state = AppState.UNINITIALIZED;
    this._initError = null;

    AppLog.i('AppDependency destroyed');
  }

  // ==================== State Accessors ====================

  /**
   * Get the current initialization state.
   */
  get state(): AppState {
    return this._state;
  }

  /**
   * Get the initialization error if any.
   */
  get initError(): Error | null {
    return this._initError;
  }

  /**
   * Check if the dependency container is ready.
   */
  isReady(): boolean {
    return this._state === AppState.READY;
  }

  /**
   * Check if initialized.
   */
  get isInitialized(): boolean {
    return this._state === AppState.READY;
  }

  // ==================== Service Accessors ====================

  /**
   * Get the application context.
   * @throws Error if not initialized
   */
  get context(): common.UIAbilityContext {
    this.ensureInitialized();
    return this._context!;
  }

  /**
   * Get the preferences service.
   * @throws Error if not initialized
   */
  get preferences(): AppPreferences {
    this.ensureInitialized();
    return this._preferences!;
  }

  /**
   * Get the event handler service.
   * @throws Error if not initialized
   */
  get eventHandler(): ActivityEventHandler {
    this.ensureInitialized();
    return this._eventHandler!;
  }

  /**
   * Get the database instance.
   * @throws Error if not initialized
   */
  get database(): JellyfinDatabase {
    this.ensureInitialized();
    return this._database!;
  }

  /**
   * Get the ApiClientController instance.
   * @throws Error if not initialized
   */
  get apiController(): ApiClientController {
    this.ensureInitialized();
    return this._apiController!;
  }

  // ==================== Server/User Management ====================

  /**
   * Get/set current server.
   */
  get currentServer(): ServerEntity | null {
    return this._currentServer;
  }

  set currentServer(server: ServerEntity | null) {
    this._currentServer = server;
    if (server && this._preferences) {
      this._preferences.currentServerId = server.id ?? null;
    }
  }

  /**
   * Get/set current user.
   */
  get currentUser(): UserEntity | null {
    return this._currentUser;
  }

  set currentUser(user: UserEntity | null) {
    this._currentUser = user;
    if (user && this._preferences) {
      this._preferences.currentUserId = user.id ?? null;
    }
  }

  /**
   * Check if logged in.
   */
  get isLoggedIn(): boolean {
    return this._currentServer !== null && this._currentUser !== null;
  }

  /**
   * 注册 Navigation 路径栈（由 AppRoot 在 aboutToAppear 中调用）
   */
  setNavPathStack(stack: NavPathStack): void {
    this._navPathStack = stack;
  }

  /**
   * 获取 Navigation 路径栈（供事件回调驱动导航）
   * @throws Error if not set
   */
  get navPathStack(): NavPathStack {
    if (!this._navPathStack) {
      throw new Error('NavPathStack not set. Call setNavPathStack() first.');
    }
    return this._navPathStack;
  }

  // ==================== Private Methods ====================

  /**
   * Ensure the container is initialized before accessing services.
   */
  private ensureInitialized(): void {
    if (this._state !== AppState.READY) {
      const message = this._state === AppState.ERROR
        ? 'AppDependency initialization failed: ' + (this._initError?.message ?? 'unknown error')
        : 'AppDependency not initialized. Call initialize() first.';
      throw new Error(message);
    }
  }

  // ==================== Convenience Methods ====================

  /**
   * Get the current video player type preference.
   */
  getVideoPlayerType(): VideoPlayerType {
    return this.preferences.videoPlayerType;
  }

  /**
   * Check if native player is preferred.
   */
  isNativePlayerPreferred(): boolean {
    return this.preferences.videoPlayerType === VideoPlayerType.EXO_PLAYER;
  }

  /**
   * Check if web player is preferred.
   */
  isWebPlayerPreferred(): boolean {
    return this.preferences.videoPlayerType === VideoPlayerType.WEB_PLAYER;
  }

  /**
   * Check if external player is preferred.
   */
  isExternalPlayerPreferred(): boolean {
    return this.preferences.videoPlayerType === VideoPlayerType.EXTERNAL_PLAYER;
  }

  /**
   * Get the server URL.
   */
  getServerUrl(): string | null {
    return this.preferences.instanceUrl;
  }

  /**
   * Check if a server is configured.
   */
  hasServerConfigured(): boolean {
    const url = this.preferences.instanceUrl;
    return url !== null && url.length > 0;
  }

  /**
   * Emit an activity event.
   */
  emitEvent(type: string, payload?: Object): void {
    const event: ActivityEvent = {
      type: type as ActivityEventType,
      payload: payload
    };
    this.eventHandler.emit(event);
  }

  /**
   * Clear all state.
   */
  async clear(): Promise<void> {
    this._currentServer = null;
    this._currentUser = null;
    await this._preferences?.clear();
    AppLog.i('AppDependency state cleared');
  }
}

// ==================== Global Access ====================

/**
 * Global singleton instance accessor.
 * Use this for convenient access throughout the application.
 */
export const App = AppDependency.getInstance();

/**
 * Quick access to preferences.
 */
export const getPreferences = (): AppPreferences => App.preferences;

/**
 * Quick access to event handler.
 */
export const getEventHandler = (): ActivityEventHandler => App.eventHandler;

/**
 * Quick access to context.
 */
export const getContext = (): common.UIAbilityContext => App.context;
