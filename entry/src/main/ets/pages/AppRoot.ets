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

import window from '@ohos.window';
import { App, getContext } from '../core/di/AppDependency';
import { ActivityEventType, ChangeFullscreenPayload } from '../core/event/ActivityEvent';
import { AppLog } from '../common/utils/Logger';
import {
  NAV_DEST_CONNECT,
  NAV_DEST_WEBVIEW,
  NAV_DEST_PLAYER,
  NAV_DEST_SETTINGS,
  NAV_DEST_DOWNLOADS
} from './NavDestinationNames';
import { ConnectPage } from '../setup/ConnectPage';
import { SettingsPage } from '../settings/SettingsPage';
import { DownloadsPage } from '../downloads/DownloadsPage';
import { WebViewPage, WebViewPageParams } from '../webapp/WebViewPage';
import { PlayerPage, PlayerPageParams } from '../player/ui/PlayerPage';

interface PlayerDestinationParam {
  playOptions: string;
}

interface WebViewDestinationParam {
  serverUrl: string;
  serverId: number;
}

@Entry
@Component
struct AppRoot {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  @State isInitializing: boolean = true;
  private unsubscribeTokens: Array<() => void> = [];
  private windowObj: window.Window | null = null;

  aboutToAppear() {
    App.setNavPathStack(this.navPathStack);
    this.subscribeToEvents();
    this.initializeApp();
  }

  aboutToDisappear() {
    this.unsubscribeTokens.forEach(fn => fn());
    this.unsubscribeTokens = [];
  }

  private subscribeToEvents(): void {
    const t1 = App.eventHandler.subscribe(ActivityEventType.SELECT_SERVER, () => {
      AppLog.i('AppRoot: SELECT_SERVER event received');
      this.navPathStack.replacePath({ name: NAV_DEST_CONNECT });
    });

    const t2 = App.eventHandler.subscribe(ActivityEventType.LAUNCH_NATIVE_PLAYER, (event) => {
      AppLog.i('AppRoot: LAUNCH_NATIVE_PLAYER event received');
      const playOptions: string = typeof event.payload === 'string'
        ? event.payload
        : JSON.stringify(event.payload);
      const playerParam: PlayerDestinationParam = { playOptions };
      this.navPathStack.pushPath({ name: NAV_DEST_PLAYER, param: playerParam as Object });
    });

    const t3 = App.eventHandler.subscribe(ActivityEventType.OPEN_SETTINGS, () => {
      AppLog.i('AppRoot: OPEN_SETTINGS event received');
      this.navPathStack.pushPath({ name: NAV_DEST_SETTINGS });
    });

    const t4 = App.eventHandler.subscribe(ActivityEventType.OPEN_DOWNLOADS, () => {
      AppLog.i('AppRoot: OPEN_DOWNLOADS event received');
      this.navPathStack.pushPath({ name: NAV_DEST_DOWNLOADS });
    });

    const t5 = App.eventHandler.subscribe(ActivityEventType.EXIT_APP, () => {
      AppLog.i('AppRoot: EXIT_APP event received');
      try {
        (getContext() as ESObject).terminateSelf();
      } catch (e) {
        AppLog.e('AppRoot: terminateSelf failed: %{public}s', JSON.stringify(e));
      }
    });

    const t6 = App.eventHandler.subscribe(ActivityEventType.CHANGE_FULLSCREEN, (event) => {
      AppLog.i('AppRoot: CHANGE_FULLSCREEN event received');
      const p = event.payload as ChangeFullscreenPayload;
      const isFullscreen: boolean = p?.isFullscreen ?? false;
      this.setFullscreen(isFullscreen);
    });

    this.unsubscribeTokens = [t1, t2, t3, t4, t5, t6];
  }

  private async initializeApp(): Promise<void> {
    try {
      const server = await App.apiController.loadSavedServer();
      if (server) {
        AppLog.i('AppRoot: saved server found, navigate to WebViewPage');
        const serverUrl: string = server.hostname;
        const serverId: number = server.id ?? 0;
        const webViewParam: WebViewDestinationParam = { serverUrl, serverId };
        this.navPathStack.replacePath({ name: NAV_DEST_WEBVIEW, param: webViewParam as Object });
      } else {
        AppLog.i('AppRoot: no saved server, navigate to ConnectPage');
        this.navPathStack.replacePath({ name: NAV_DEST_CONNECT });
      }
    } catch (err) {
      AppLog.e('AppRoot: initializeApp error: %{public}s', JSON.stringify(err));
      try {
        this.navPathStack.replacePath({ name: NAV_DEST_CONNECT });
      } catch { /* ignore */ }
    } finally {
      this.isInitializing = false;
    }
  }

  private async setFullscreen(isFullscreen: boolean): Promise<void> {
    try {
      if (!this.windowObj) {
        this.windowObj = await window.getLastWindow(getContext());
      }
      if (isFullscreen) {
        await this.windowObj.setWindowSystemBarEnable([]);
        await this.windowObj.setPreferredOrientation(window.Orientation.LANDSCAPE);
      } else {
        await this.windowObj.setWindowSystemBarEnable(['status', 'navigation']);
        await this.windowObj.setPreferredOrientation(window.Orientation.PORTRAIT);
      }
    } catch (e) {
      AppLog.e('AppRoot: setFullscreen error: %{public}s', JSON.stringify(e));
    }
  }

  @Builder
  PageMap(name: string, param: Object) {
    if (name === NAV_DEST_CONNECT) {
      ConnectPage()
    } else if (name === NAV_DEST_WEBVIEW) {
      WebViewPage({ webViewParams: param as WebViewPageParams })
    } else if (name === NAV_DEST_PLAYER) {
      PlayerPage({ playerParams: param as PlayerPageParams })
    } else if (name === NAV_DEST_SETTINGS) {
      SettingsPage()
    } else if (name === NAV_DEST_DOWNLOADS) {
      DownloadsPage()
    }
  }

  build() {
    Navigation(this.navPathStack) {
      if (this.isInitializing) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color($r('app.color.primary'))
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))
        .justifyContent(FlexAlign.Center)
      }
    }
    .navDestination(this.PageMap)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}
