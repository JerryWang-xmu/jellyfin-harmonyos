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
 * WebViewPage Unit Tests
 * Tests for PageLoadState state machine, fullscreen shim injection guard,
 * and keyboard avoid mode configuration.
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';

import {
  PageLoadState,
  WebViewPageState,
  FULLSCREEN_SHIM_SCRIPT
} from '../../../../main/ets/webapp/WebViewPageState';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'WebViewPageTest';

export default function webViewPageTest() {
  describe('WebViewPage State Management Tests', () => {

    // ============ PageLoadState Initial State Tests ============

    /**
     * Test: Initial PageLoadState should be 'loading'
     */
    it('should start with loading state', 0, () => {
      const state = new WebViewPageState();
      expect(state.loadState.status).assertEqual('loading');
    });

    /**
     * Test: isLoading helper returns true for initial state
     */
    it('should report isLoading=true for initial state', 0, () => {
      const state = new WebViewPageState();
      expect(state.isLoading()).assertTrue();
    });

    /**
     * Test: hasError helper returns false for initial state
     */
    it('should report hasError=false for initial state', 0, () => {
      const state = new WebViewPageState();
      expect(state.hasError()).assertFalse();
    });

    /**
     * Test: getErrorMessage returns empty string for initial state
     */
    it('should return empty error message for initial state', 0, () => {
      const state = new WebViewPageState();
      expect(state.getErrorMessage()).assertEqual('');
    });

    // ============ PageLoadState Transitions Tests ============

    /**
     * Test: Transition from loading to loaded
     */
    it('should transition from loading to loaded', 0, () => {
      const state = new WebViewPageState();
      state.setToLoaded();
      expect(state.loadState.status).assertEqual('loaded');
      expect(state.isLoading()).assertFalse();
      expect(state.hasError()).assertFalse();
    });

    /**
     * Test: Transition from loading to error with message
     */
    it('should transition from loading to error with message', 0, () => {
      const state = new WebViewPageState();
      state.setToError('connection failed');
      expect(state.loadState.status).assertEqual('error');
      expect(state.hasError()).assertTrue();
      expect(state.getErrorMessage()).assertEqual('connection failed');
      expect(state.isLoading()).assertFalse();
    });

    /**
     * Test: Transition from loaded to loading (re-load scenario)
     */
    it('should transition from loaded back to loading for reload', 0, () => {
      const state = new WebViewPageState();
      state.setToLoaded();
      state.setToLoading();
      expect(state.loadState.status).assertEqual('loading');
      expect(state.isLoading()).assertTrue();
    });

    /**
     * Test: Transition from error to loading (retry scenario)
     */
    it('should transition from error to loading for retry', 0, () => {
      const state = new WebViewPageState();
      state.setToError('timeout');
      state.setToLoading();
      expect(state.loadState.status).assertEqual('loading');
      expect(state.isLoading()).assertTrue();
      expect(state.hasError()).assertFalse();
    });

    /**
     * Test: Error state carries correct message
     */
    it('should carry error message through error state', 0, () => {
      const state = new WebViewPageState();
      const msg = 'DNS resolution failed';
      state.setToError(msg);

      const ls = state.loadState as PageLoadState;
      expect(ls.status).assertEqual('error');
      if (ls.status === 'error') {
        expect(ls.message).assertEqual(msg);
      }
    });

    // ============ serverUrl / serverId Tests ============

    /**
     * Test: serverUrl and serverId are set correctly and are plain properties
     */
    it('should set serverUrl and serverId as plain non-reactive properties', 0, () => {
      const state = new WebViewPageState();
      state.serverUrl = 'https://jellyfin.example.com';
      state.serverId = 42;
      expect(state.serverUrl).assertEqual('https://jellyfin.example.com');
      expect(state.serverId).assertEqual(42);
    });

    /**
     * Test: serverUrl and serverId can be updated without triggering state changes
     */
    it('should allow updating serverUrl without affecting loadState', 0, () => {
      const state = new WebViewPageState();
      state.setToLoaded();
      state.serverUrl = 'https://other.server.com';
      // loadState should remain loaded
      expect(state.loadState.status).assertEqual('loaded');
    });

    // ============ Fullscreen Shim Injection Guard Tests ============

    /**
     * Test: shouldInjectFullscreenShim returns true initially
     */
    it('should allow first fullscreen shim injection', 0, () => {
      const state = new WebViewPageState();
      expect(state.shouldInjectFullscreenShim()).assertTrue();
    });

    /**
     * Test: shouldInjectFullscreenShim returns false after marking injected
     */
    it('should block second fullscreen shim injection', 0, () => {
      const state = new WebViewPageState();
      state.markFullscreenShimInjected();
      expect(state.shouldInjectFullscreenShim()).assertFalse();
    });

    /**
     * Test: Multiple calls to shouldInjectFullscreenShim return false after first injection
     */
    it('should block all subsequent shim injections after first', 0, () => {
      const state = new WebViewPageState();
      expect(state.shouldInjectFullscreenShim()).assertTrue();
      state.markFullscreenShimInjected();
      expect(state.shouldInjectFullscreenShim()).assertFalse();
      expect(state.shouldInjectFullscreenShim()).assertFalse();
      expect(state.shouldInjectFullscreenShim()).assertFalse();
    });

    /**
     * Test: Fullscreen shim script constant is non-empty
     */
    it('should provide non-empty FULLSCREEN_SHIM_SCRIPT constant', 0, () => {
      expect(FULLSCREEN_SHIM_SCRIPT.length).assertLargerThan(0);
    });

    /**
     * Test: Fullscreen shim script contains key marker
     */
    it('should contain __jfFsBridged marker in FULLSCREEN_SHIM_SCRIPT', 0, () => {
      expect(FULLSCREEN_SHIM_SCRIPT.indexOf('__jfFsBridged')).assertLargerThan(-1);
    });

    // ============ Load Timeout State Tests ============

    /**
     * Test: setToError with timeout message
     */
    it('should handle load timeout as error state', 0, () => {
      const state = new WebViewPageState();
      state.setToError('连接超时，请检查服务器地址');
      expect(state.hasError()).assertTrue();
      expect(state.getErrorMessage()).assertEqual('连接超时，请检查服务器地址');
    });

    // ============ PageLoadState Type Discrimination Tests ============

    /**
     * Test: loading state does not have message property accessible via getErrorMessage
     */
    it('should return empty message when in loading state', 0, () => {
      const state = new WebViewPageState();
      expect(state.getErrorMessage()).assertEqual('');
    });

    /**
     * Test: loaded state does not have message property accessible via getErrorMessage
     */
    it('should return empty message when in loaded state', 0, () => {
      const state = new WebViewPageState();
      state.setToLoaded();
      expect(state.getErrorMessage()).assertEqual('');
    });

    // ============ Full Lifecycle Simulation Tests ============

    /**
     * Test: Full lifecycle: loading -> loaded -> (user navigates) -> loading -> loaded
     */
    it('should handle full page load lifecycle', 0, () => {
      const state = new WebViewPageState();
      expect(state.loadState.status).assertEqual('loading');

      state.setToLoaded();
      expect(state.loadState.status).assertEqual('loaded');

      // User navigates within WebView
      state.setToLoading();
      expect(state.loadState.status).assertEqual('loading');

      state.setToLoaded();
      expect(state.loadState.status).assertEqual('loaded');
    });

    /**
     * Test: Full lifecycle: loading -> error -> (retry) -> loading -> loaded
     */
    it('should handle error-then-retry lifecycle', 0, () => {
      const state = new WebViewPageState();

      // Error on first load
      state.setToError('Network error');
      expect(state.hasError()).assertTrue();

      // User retries
      state.setToLoading();
      expect(state.isLoading()).assertTrue();
      expect(state.hasError()).assertFalse();

      // Success on retry
      state.setToLoaded();
      expect(state.loadState.status).assertEqual('loaded');
      expect(state.hasError()).assertFalse();
    });
  });
}
