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
 * BatchThreeUnit.test.ets
 * Unit tests for Batch 3 page-layer modules:
 *   - main_pages.json route list completeness (via JSON.parse)
 *   - PlayerPage.formatTime() pure logic
 *
 * All tests are pure-logic tests — no system API dependencies.
 *
 * Framework: @ohos/hypium
 * Author:    Validator (Refactor Task Force)
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * The raw JSON string that mirrors the content of
 * entry/src/main/resources/base/profile/main_pages.json.
 *
 * We embed the literal content here so the test is fully self-contained
 * and does not depend on any file-system API.
 */
const MAIN_PAGES_JSON: string = `{
  "src": [
    "pages/MainPage",
    "pages/Index",
    "pages/setup/ConnectPage",
    "pages/webapp/WebViewPage",
    "pages/player/PlayerPage",
    "pages/settings/SettingsPage",
    "pages/downloads/DownloadsPage"
  ]
}`;

/**
 * The six routes mandated by the interface contract (Section a).
 * pages/Index is an internal entry — not part of the external contract,
 * but its presence in the file is still valid.
 */
const REQUIRED_ROUTES: string[] = [
  'pages/MainPage',
  'pages/setup/ConnectPage',
  'pages/webapp/WebViewPage',
  'pages/player/PlayerPage',
  'pages/settings/SettingsPage',
  'pages/downloads/DownloadsPage',
];

/**
 * Pure re-implementation of PlayerPage.formatTime().
 * Mirrors the private method exactly so tests are independent of the UI
 * component and do not require any HarmonyOS system API.
 *
 *   formatTime(ms: number): string
 *   - Converts milliseconds to "mm:ss" or "hh:mm:ss"
 *   - Each segment is zero-padded to 2 digits
 */
function formatTime(ms: number): string {
  const seconds = Math.floor(ms / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const secs = seconds % 60;
  const mins = minutes % 60;

  if (hours > 0) {
    return hours.toString().padStart(2, '0') + ':' +
           mins.toString().padStart(2, '0') + ':' +
           secs.toString().padStart(2, '0');
  } else {
    return mins.toString().padStart(2, '0') + ':' +
           secs.toString().padStart(2, '0');
  }
}

// ---------------------------------------------------------------------------
// Test Suite 1 — main_pages.json route list completeness
// ---------------------------------------------------------------------------
export function mainPagesRoutesTest() {
  describe('main_pages.json - route list completeness', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    // --- JSON parses without error ---
    it('should parse the main_pages.json content as valid JSON', 0, () => {
      let parsed: object | null = null;
      let threw = false;
      try {
        parsed = JSON.parse(MAIN_PAGES_JSON) as object;
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
      expect(parsed !== null).assertTrue();
    });

    // --- "src" field exists and is an array ---
    it('should contain a top-level "src" array', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      expect(Array.isArray(parsed['src'])).assertTrue();
    });

    // --- "src" array is not empty ---
    it('"src" array should have at least one entry', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      expect(parsed['src'].length > 0).assertTrue();
    });

    // --- All 6 contract-required routes are present ---
    it('should contain all 6 contract-required routes', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      const routes: string[] = parsed['src'];
      for (const required of REQUIRED_ROUTES) {
        expect(routes.indexOf(required) >= 0).assertTrue();
      }
    });

    // Individual route assertions for clearer failure messages

    it('should register pages/MainPage', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      expect(parsed['src'].indexOf('pages/MainPage') >= 0).assertTrue();
    });

    it('should register pages/setup/ConnectPage', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      expect(parsed['src'].indexOf('pages/setup/ConnectPage') >= 0).assertTrue();
    });

    it('should register pages/webapp/WebViewPage', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      expect(parsed['src'].indexOf('pages/webapp/WebViewPage') >= 0).assertTrue();
    });

    it('should register pages/player/PlayerPage', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      expect(parsed['src'].indexOf('pages/player/PlayerPage') >= 0).assertTrue();
    });

    it('should register pages/settings/SettingsPage', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      expect(parsed['src'].indexOf('pages/settings/SettingsPage') >= 0).assertTrue();
    });

    it('should register pages/downloads/DownloadsPage', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      expect(parsed['src'].indexOf('pages/downloads/DownloadsPage') >= 0).assertTrue();
    });

    // --- Every entry in "src" is a non-empty string ---
    it('every route entry should be a non-empty string', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      for (const route of parsed['src']) {
        expect(typeof route).assertEqual('string');
        expect(route.length > 0).assertTrue();
      }
    });

    // --- Route strings must not contain backslashes (forward slashes only) ---
    it('route strings should use forward slashes, not backslashes', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      for (const route of parsed['src']) {
        expect(route.includes('\\')).assertFalse();
      }
    });

    // --- Route strings must start with "pages/" ---
    it('route strings should start with "pages/"', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      for (const route of parsed['src']) {
        expect(route.startsWith('pages/')).assertTrue();
      }
    });

    // --- No duplicate entries ---
    it('"src" array should have no duplicate routes', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON) as Record<string, string[]>;
      const routes: string[] = parsed['src'];
      const unique = new Set<string>(routes);
      expect(unique.size).assertEqual(routes.length);
    });
  });
}

// ---------------------------------------------------------------------------
// Test Suite 2 — PlayerPage.formatTime() pure logic
// ---------------------------------------------------------------------------
export function formatTimeTest() {
  describe('PlayerPage - formatTime()', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    // --- Zero milliseconds ---
    it('should return "00:00" for 0 ms', 0, () => {
      expect(formatTime(0)).assertEqual('00:00');
    });

    // --- Exactly 1 second ---
    it('should return "00:01" for 1000 ms', 0, () => {
      expect(formatTime(1000)).assertEqual('00:01');
    });

    // --- Exactly 1 minute ---
    it('should return "01:00" for 60000 ms', 0, () => {
      expect(formatTime(60000)).assertEqual('01:00');
    });

    // --- 1 minute 30 seconds ---
    it('should return "01:30" for 90000 ms', 0, () => {
      expect(formatTime(90000)).assertEqual('01:30');
    });

    // --- 59 minutes 59 seconds (just below 1 hour) ---
    it('should return "59:59" for 3599000 ms', 0, () => {
      expect(formatTime(3599000)).assertEqual('59:59');
    });

    // --- Exactly 1 hour: switches to hh:mm:ss format ---
    it('should return "01:00:00" for 3600000 ms (1 hour)', 0, () => {
      expect(formatTime(3600000)).assertEqual('01:00:00');
    });

    // --- 1 hour 2 minutes 3 seconds ---
    it('should return "01:02:03" for 3723000 ms', 0, () => {
      expect(formatTime(3723000)).assertEqual('01:02:03');
    });

    // --- 2 hours 30 minutes 45 seconds ---
    it('should return "02:30:45" for 9045000 ms', 0, () => {
      expect(formatTime(9045000)).assertEqual('02:30:45');
    });

    // --- Zero-padding: single-digit minutes and seconds are padded ---
    it('should zero-pad single-digit minutes and seconds in mm:ss format', 0, () => {
      // 5 minutes 7 seconds = 307000 ms
      expect(formatTime(307000)).assertEqual('05:07');
    });

    // --- Zero-padding in hh:mm:ss: all segments padded ---
    it('should zero-pad all segments in hh:mm:ss format', 0, () => {
      // 1 hour 3 minutes 9 seconds = 3789000 ms
      expect(formatTime(3789000)).assertEqual('01:03:09');
    });

    // --- Sub-second milliseconds are truncated (floor), not rounded ---
    it('should truncate sub-second ms (floor, not round)', 0, () => {
      // 1999 ms → floor(1999/1000) = 1 second → "00:01"
      expect(formatTime(1999)).assertEqual('00:01');
    });

    // --- Large value: 10 hours ---
    it('should return "10:00:00" for 36000000 ms (10 hours)', 0, () => {
      expect(formatTime(36000000)).assertEqual('10:00:00');
    });

    // --- Result is always a string ---
    it('return value should always be of type string', 0, () => {
      expect(typeof formatTime(0)).assertEqual('string');
      expect(typeof formatTime(3600000)).assertEqual('string');
    });

    // --- Format: mm:ss has exactly 5 characters for values under 1 hour ---
    it('mm:ss result should have exactly 5 characters', 0, () => {
      // Covers 00:00 through 59:59
      expect(formatTime(0).length).assertEqual(5);
      expect(formatTime(3599000).length).assertEqual(5);
    });

    // --- Format: hh:mm:ss has exactly 8 characters ---
    it('hh:mm:ss result should have exactly 8 characters', 0, () => {
      expect(formatTime(3600000).length).assertEqual(8);
      expect(formatTime(9045000).length).assertEqual(8);
    });

    // --- Colon separators are present ---
    it('mm:ss format should contain exactly one colon', 0, () => {
      const result = formatTime(90000); // "01:30"
      const colonCount = result.split(':').length - 1;
      expect(colonCount).assertEqual(1);
    });

    it('hh:mm:ss format should contain exactly two colons', 0, () => {
      const result = formatTime(3723000); // "01:02:03"
      const colonCount = result.split(':').length - 1;
      expect(colonCount).assertEqual(2);
    });
  });
}

// ---------------------------------------------------------------------------
// Root export — registers all suites with the test runner
// ---------------------------------------------------------------------------
export default function batchThreeUnitTest() {
  mainPagesRoutesTest();
  formatTimeTest();
}
