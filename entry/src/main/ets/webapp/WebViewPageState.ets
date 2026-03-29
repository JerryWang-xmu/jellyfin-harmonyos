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
 * WebViewPageState - extracted state management for WebViewPage.
 *
 * Encapsulates PageLoadState state machine, fullscreen shim injection guard,
 * and non-reactive server connection properties. This class is unit-testable
 * independently of the ArkTS @Component decorator.
 */

/**
 * Page load status enumeration.
 */
export enum PageLoadStatus {
  LOADING = 'loading',
  LOADED = 'loaded',
  ERROR = 'error'
}

/**
 * PageLoadState - replaces three separate @State variables
 * (isLoading, loadError, loadErrorMsg) to eliminate dual re-renders on error.
 *
 * ArkTS does not support discriminated union types with object literals,
 * so so we use a class with an enum-based status field instead.
 */
export class PageLoadState {
  status: PageLoadStatus = PageLoadStatus.LOADING;
  message: string = '';

  constructor(status: PageLoadStatus = PageLoadStatus.LOADING, message: string = '') {
    this.status = status;
    this.message = message;
  }

  static loading(): PageLoadState {
    return new PageLoadState(PageLoadStatus.LOADING);
  }

  static loaded(): PageLoadState {
    return new PageLoadState(PageLoadStatus.LOADED);
  }

  static error(msg: string): PageLoadState {
    return new PageLoadState(PageLoadStatus.ERROR, msg);
  }

  isLoading(): boolean {
    return this.status === PageLoadStatus.LOADING;
  }

  isLoaded(): boolean {
    return this.status === PageLoadStatus.LOADED;
  }

  hasError(): boolean {
    return this.status === PageLoadStatus.ERROR;
  }

  getErrorMessage(): string {
    return this.hasError() ? this.message : '';
  }
}

/**
 * Static fullscreen shim script. Extracted as a constant so it is allocated
 * once rather than on every onPageEnd callback.
 *
 * This shim intercepts the browser-native requestFullscreen API and routes
 * fullscreen requests through the NativeInterface bridge, which triggers
 * screen rotation on the native side.
 */
export const FULLSCREEN_SHIM_SCRIPT: string =
  '(function(){' +
  'if(window.__jfFsBridged)return;' +
  'window.__jfFsBridged=true;' +
  // Intercept requestFullscreen - notify native before triggering browser fullscreen
  'var _origReq=HTMLElement.prototype.requestFullscreen;' +
  'HTMLElement.prototype.requestFullscreen=function(){' +
  'if(window.NativeInterface)window.NativeInterface.enableFullscreen();' +
  'return _origReq?_origReq.call(this):Promise.resolve();' +
  '};' +
  // Listen for fullscreenchange as fallback (exitFullscreen triggers disableFullscreen)
  'document.addEventListener("fullscreenchange",function(){' +
  'if(!window.NativeInterface)return;' +
  'if(document.fullscreenElement){window.NativeInterface.enableFullscreen();}' +
  'else{window.NativeInterface.disableFullscreen();}' +
  '});' +
  '})();';
