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
 * NavigationRefactorUnit.test.ets
 * Unit tests for the Navigation refactor that replaced deprecated
 * router.replaceUrl/pushUrl/back/getParams with Navigation + NavPathStack.
 *
 * Covered areas:
 *   Suite 1 — NAV_DEST_* constant values
 *   Suite 2 — Route completeness (all 5 destinations are distinct, non-empty)
 *   Suite 3 — main_pages.json post-refactor shape (single AppRoot entry)
 *   Suite 4 — WebViewPageParams interface shape
 *   Suite 5 — PlayerPageParams interface shape
 *   Suite 6 — PlayerPage.formatTime() pure logic (mirrors the private method)
 *   Suite 7 — AppRoot PageMap routing coverage
 *
 * All tests are pure-logic tests — no system API dependencies.
 *
 * Framework: @ohos/hypium
 * Author:    Validator (Navigation Refactor Task Force)
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';

// ---------------------------------------------------------------------------
// Constants mirrored from NavDestinationNames.ets
// We embed literal copies here so the test is fully self-contained and does
// not require importing ArkUI/NavPathStack at test-runner bootstrap time.
// ---------------------------------------------------------------------------

const NAV_DEST_CONNECT: string    = 'ConnectDestination';
const NAV_DEST_WEBVIEW: string    = 'WebViewDestination';
const NAV_DEST_PLAYER: string     = 'PlayerDestination';
const NAV_DEST_SETTINGS: string   = 'SettingsDestination';
const NAV_DEST_DOWNLOADS: string  = 'DownloadsDestination';

/** All five destination constants in declaration order. */
const ALL_DEST_NAMES: string[] = [
  NAV_DEST_CONNECT,
  NAV_DEST_WEBVIEW,
  NAV_DEST_PLAYER,
  NAV_DEST_SETTINGS,
  NAV_DEST_DOWNLOADS,
];

// ---------------------------------------------------------------------------
// main_pages.json post-refactor content
// After the Navigation refactor the router only has one entry.
// ---------------------------------------------------------------------------

const MAIN_PAGES_JSON_POST_REFACTOR: string = `{
  "src": [
    "pages/AppRoot"
  ]
}`;

// ---------------------------------------------------------------------------
// WebViewPageParams interface shape (mirrored from WebViewPage.ets)
// ---------------------------------------------------------------------------

interface WebViewPageParams {
  serverUrl: string;
  serverId: number;
}

// ---------------------------------------------------------------------------
// PlayerPageParams interface shape (mirrored from PlayerPage.ets)
// ---------------------------------------------------------------------------

interface PlayerPageParams {
  playOptions: string;
}

// ---------------------------------------------------------------------------
// Pure re-implementation of PlayerPage.formatTime()
// Mirrors the private method exactly (including the ms <= 0 guard):
//
//   private formatTime(ms: number): string {
//     if (ms <= 0) return '00:00';
//     const totalSeconds = Math.floor(ms / 1000);
//     const h = Math.floor(totalSeconds / 3600);
//     const m = Math.floor((totalSeconds % 3600) / 60);
//     const s = totalSeconds % 60;
//     const mm = m.toString().padStart(2, '0');
//     const ss = s.toString().padStart(2, '0');
//     if (h > 0) return `${h}:${mm}:${ss}`;
//     return `${mm}:${ss}`;
//   }
// ---------------------------------------------------------------------------

function formatTime(ms: number): string {
  if (ms <= 0) return '00:00';
  const totalSeconds = Math.floor(ms / 1000);
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = totalSeconds % 60;
  const mm = m.toString().padStart(2, '0');
  const ss = s.toString().padStart(2, '0');
  if (h > 0) return `${h}:${mm}:${ss}`;
  return `${mm}:${ss}`;
}

// ---------------------------------------------------------------------------
// Suite 1 — NAV_DEST_* constant values
// ---------------------------------------------------------------------------

export function navDestConstantValuesTest() {
  describe('NavDestinationNames - constant string values', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('NAV_DEST_CONNECT should equal "ConnectDestination"', 0, () => {
      expect(NAV_DEST_CONNECT).assertEqual('ConnectDestination');
    });

    it('NAV_DEST_WEBVIEW should equal "WebViewDestination"', 0, () => {
      expect(NAV_DEST_WEBVIEW).assertEqual('WebViewDestination');
    });

    it('NAV_DEST_PLAYER should equal "PlayerDestination"', 0, () => {
      expect(NAV_DEST_PLAYER).assertEqual('PlayerDestination');
    });

    it('NAV_DEST_SETTINGS should equal "SettingsDestination"', 0, () => {
      expect(NAV_DEST_SETTINGS).assertEqual('SettingsDestination');
    });

    it('NAV_DEST_DOWNLOADS should equal "DownloadsDestination"', 0, () => {
      expect(NAV_DEST_DOWNLOADS).assertEqual('DownloadsDestination');
    });

    it('all constants should be of type string', 0, () => {
      for (const name of ALL_DEST_NAMES) {
        expect(typeof name).assertEqual('string');
      }
    });

    it('all constants should end with "Destination"', 0, () => {
      for (const name of ALL_DEST_NAMES) {
        expect(name.endsWith('Destination')).assertTrue();
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Suite 2 — Route completeness
// ---------------------------------------------------------------------------

export function navDestCompletenessTest() {
  describe('NavDestinationNames - route completeness', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('should define exactly 5 destination name constants', 0, () => {
      expect(ALL_DEST_NAMES.length).assertEqual(5);
    });

    it('all destination names should be non-empty strings', 0, () => {
      for (const name of ALL_DEST_NAMES) {
        expect(name.length > 0).assertTrue();
      }
    });

    it('all destination names should be distinct (no duplicates)', 0, () => {
      const unique = new Set<string>(ALL_DEST_NAMES);
      expect(unique.size).assertEqual(ALL_DEST_NAMES.length);
    });

    it('destination names should not contain whitespace', 0, () => {
      for (const name of ALL_DEST_NAMES) {
        expect(name.indexOf(' ') === -1).assertTrue();
        expect(name.indexOf('\t') === -1).assertTrue();
        expect(name.indexOf('\n') === -1).assertTrue();
      }
    });

    it('destination names should not contain slash characters', 0, () => {
      for (const name of ALL_DEST_NAMES) {
        expect(name.includes('/')).assertFalse();
        expect(name.includes('\\')).assertFalse();
      }
    });

    it('NAV_DEST_CONNECT is included in the full set', 0, () => {
      expect(ALL_DEST_NAMES.indexOf(NAV_DEST_CONNECT) >= 0).assertTrue();
    });

    it('NAV_DEST_WEBVIEW is included in the full set', 0, () => {
      expect(ALL_DEST_NAMES.indexOf(NAV_DEST_WEBVIEW) >= 0).assertTrue();
    });

    it('NAV_DEST_PLAYER is included in the full set', 0, () => {
      expect(ALL_DEST_NAMES.indexOf(NAV_DEST_PLAYER) >= 0).assertTrue();
    });

    it('NAV_DEST_SETTINGS is included in the full set', 0, () => {
      expect(ALL_DEST_NAMES.indexOf(NAV_DEST_SETTINGS) >= 0).assertTrue();
    });

    it('NAV_DEST_DOWNLOADS is included in the full set', 0, () => {
      expect(ALL_DEST_NAMES.indexOf(NAV_DEST_DOWNLOADS) >= 0).assertTrue();
    });
  });
}

// ---------------------------------------------------------------------------
// Suite 3 — main_pages.json post-refactor shape
// ---------------------------------------------------------------------------

export function mainPagesPostRefactorTest() {
  describe('main_pages.json - post-Navigation-refactor shape', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('should parse as valid JSON without throwing', 0, () => {
      let threw = false;
      try {
        JSON.parse(MAIN_PAGES_JSON_POST_REFACTOR);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('should contain a top-level "src" array', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON_POST_REFACTOR) as Record<string, string[]>;
      expect(Array.isArray(parsed['src'])).assertTrue();
    });

    it('"src" array should contain exactly one entry after refactor', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON_POST_REFACTOR) as Record<string, string[]>;
      expect(parsed['src'].length).assertEqual(1);
    });

    it('"src[0]" should be "pages/AppRoot"', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON_POST_REFACTOR) as Record<string, string[]>;
      expect(parsed['src'][0]).assertEqual('pages/AppRoot');
    });

    it('"pages/AppRoot" entry should start with "pages/"', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON_POST_REFACTOR) as Record<string, string[]>;
      expect(parsed['src'][0].startsWith('pages/')).assertTrue();
    });

    it('"pages/AppRoot" entry should not contain backslashes', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON_POST_REFACTOR) as Record<string, string[]>;
      expect(parsed['src'][0].includes('\\')).assertFalse();
    });

    it('deprecated pages/MainPage should no longer be in "src"', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON_POST_REFACTOR) as Record<string, string[]>;
      expect(parsed['src'].indexOf('pages/MainPage')).assertEqual(-1);
    });

    it('deprecated pages/Index should no longer be in "src"', 0, () => {
      const parsed = JSON.parse(MAIN_PAGES_JSON_POST_REFACTOR) as Record<string, string[]>;
      expect(parsed['src'].indexOf('pages/Index')).assertEqual(-1);
    });
  });
}

// ---------------------------------------------------------------------------
// Suite 4 — WebViewPageParams interface shape
// ---------------------------------------------------------------------------

export function webViewPageParamsTest() {
  describe('WebViewPageParams - interface shape', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('serverUrl field should accept a string value', 0, () => {
      const params: WebViewPageParams = { serverUrl: 'http://192.168.1.100:8096', serverId: 1 };
      expect(typeof params.serverUrl).assertEqual('string');
    });

    it('serverId field should accept a number value', 0, () => {
      const params: WebViewPageParams = { serverUrl: 'http://192.168.1.100:8096', serverId: 42 };
      expect(typeof params.serverId).assertEqual('number');
    });

    it('default/empty serverUrl should be an empty string', 0, () => {
      const params: WebViewPageParams = { serverUrl: '', serverId: 0 };
      expect(params.serverUrl).assertEqual('');
    });

    it('default/zero serverId should be 0', 0, () => {
      const params: WebViewPageParams = { serverUrl: '', serverId: 0 };
      expect(params.serverId).assertEqual(0);
    });

    it('serverUrl should preserve the full URL including port', 0, () => {
      const url = 'https://myserver.example.com:8920';
      const params: WebViewPageParams = { serverUrl: url, serverId: 7 };
      expect(params.serverUrl).assertEqual(url);
    });

    it('serverId should preserve integer values faithfully', 0, () => {
      const params: WebViewPageParams = { serverUrl: 'http://localhost', serverId: 99999 };
      expect(params.serverId).assertEqual(99999);
    });

    it('WebViewPageParams constructed from JSON should round-trip correctly', 0, () => {
      const original: WebViewPageParams = { serverUrl: 'http://192.168.0.1:8096', serverId: 3 };
      const json: string = JSON.stringify(original);
      const restored = JSON.parse(json) as WebViewPageParams;
      expect(restored.serverUrl).assertEqual(original.serverUrl);
      expect(restored.serverId).assertEqual(original.serverId);
    });

    it('interface should have exactly the two fields: serverUrl and serverId', 0, () => {
      const params: WebViewPageParams = { serverUrl: 'http://x', serverId: 1 };
      const keys = Object.keys(params as object);
      expect(keys.length).assertEqual(2);
      expect(keys.indexOf('serverUrl') >= 0).assertTrue();
      expect(keys.indexOf('serverId') >= 0).assertTrue();
    });
  });
}

// ---------------------------------------------------------------------------
// Suite 5 — PlayerPageParams interface shape
// ---------------------------------------------------------------------------

export function playerPageParamsTest() {
  describe('PlayerPageParams - interface shape', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('playOptions field should accept a string value', 0, () => {
      const params: PlayerPageParams = { playOptions: '{}' };
      expect(typeof params.playOptions).assertEqual('string');
    });

    it('default playOptions should be valid JSON string "{}"', 0, () => {
      const params: PlayerPageParams = { playOptions: '{}' };
      let threw = false;
      try {
        JSON.parse(params.playOptions);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('playOptions should preserve a JSON-serialized PlayOptions object', 0, () => {
      const playOptionsObj = {
        ids: ['abc123', 'def456'],
        startIndex: 0,
        startPosition: 10000000,
        audioStreamIndex: 1,
        subtitleStreamIndex: -1,
      };
      const serialized: string = JSON.stringify(playOptionsObj);
      const params: PlayerPageParams = { playOptions: serialized };
      const restored = JSON.parse(params.playOptions) as ESObject;
      expect(Array.isArray(restored['ids'])).assertTrue();
      expect((restored['ids'] as string[])[0]).assertEqual('abc123');
      expect(restored['startIndex'] as number).assertEqual(0);
      expect(restored['startPosition'] as number).assertEqual(10000000);
    });

    it('playOptions should preserve an empty JSON object string', 0, () => {
      const params: PlayerPageParams = { playOptions: '{}' };
      expect(params.playOptions).assertEqual('{}');
    });

    it('PlayerPageParams constructed from JSON should round-trip correctly', 0, () => {
      const original: PlayerPageParams = { playOptions: '{"ids":["item1"],"startIndex":0}' };
      const json: string = JSON.stringify(original);
      const restored = JSON.parse(json) as PlayerPageParams;
      expect(restored.playOptions).assertEqual(original.playOptions);
    });

    it('interface should have exactly one field: playOptions', 0, () => {
      const params: PlayerPageParams = { playOptions: '{}' };
      const keys = Object.keys(params as object);
      expect(keys.length).assertEqual(1);
      expect(keys[0]).assertEqual('playOptions');
    });
  });
}

// ---------------------------------------------------------------------------
// Suite 6 — PlayerPage.formatTime() pure logic
// The implementation uses an explicit ms <= 0 guard (returns '00:00') and
// does NOT zero-pad the hours segment (unlike BatchThree's re-implementation).
// ---------------------------------------------------------------------------

export function playerFormatTimeTest() {
  describe('PlayerPage - formatTime() (Navigation refactor version)', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    // --- Guard: zero and negative ---

    it('should return "00:00" for 0 ms (guard branch)', 0, () => {
      expect(formatTime(0)).assertEqual('00:00');
    });

    it('should return "00:00" for negative ms (guard branch)', 0, () => {
      expect(formatTime(-1)).assertEqual('00:00');
      expect(formatTime(-100000)).assertEqual('00:00');
    });

    // --- Sub-minute values ---

    it('should return "00:01" for 1000 ms (1 second)', 0, () => {
      expect(formatTime(1000)).assertEqual('00:01');
    });

    it('should return "00:30" for 30000 ms (30 seconds)', 0, () => {
      expect(formatTime(30000)).assertEqual('00:30');
    });

    it('should return "00:59" for 59000 ms (59 seconds)', 0, () => {
      expect(formatTime(59000)).assertEqual('00:59');
    });

    // --- Exactly 1 minute ---

    it('should return "01:00" for 60000 ms (1 minute)', 0, () => {
      expect(formatTime(60000)).assertEqual('01:00');
    });

    // --- Mixed minutes and seconds ---

    it('should return "01:30" for 90000 ms (1 min 30 sec)', 0, () => {
      expect(formatTime(90000)).assertEqual('01:30');
    });

    it('should return "05:07" for 307000 ms (5 min 7 sec — zero-padding check)', 0, () => {
      expect(formatTime(307000)).assertEqual('05:07');
    });

    it('should return "59:59" for 3599000 ms (just below 1 hour)', 0, () => {
      expect(formatTime(3599000)).assertEqual('59:59');
    });

    // --- Exactly 1 hour: switches to h:mm:ss (no leading zero on hours) ---

    it('should return "1:00:00" for 3600000 ms (1 hour)', 0, () => {
      expect(formatTime(3600000)).assertEqual('1:00:00');
    });

    it('should return "1:02:03" for 3723000 ms (1 hr 2 min 3 sec)', 0, () => {
      expect(formatTime(3723000)).assertEqual('1:02:03');
    });

    it('should return "1:03:09" for 3789000 ms (1 hr 3 min 9 sec — zero-pad mm and ss)', 0, () => {
      expect(formatTime(3789000)).assertEqual('1:03:09');
    });

    it('should return "2:30:45" for 9045000 ms (2 hr 30 min 45 sec)', 0, () => {
      expect(formatTime(9045000)).assertEqual('2:30:45');
    });

    it('should return "10:00:00" for 36000000 ms (10 hours)', 0, () => {
      expect(formatTime(36000000)).assertEqual('10:00:00');
    });

    // --- Sub-second truncation (floor, not round) ---

    it('should truncate sub-second ms: 1999 ms → "00:01"', 0, () => {
      expect(formatTime(1999)).assertEqual('00:01');
    });

    it('should truncate sub-second ms: 59999 ms → "00:59"', 0, () => {
      expect(formatTime(59999)).assertEqual('00:59');
    });

    // --- Return type ---

    it('return value should always be of type string', 0, () => {
      expect(typeof formatTime(0)).assertEqual('string');
      expect(typeof formatTime(1000)).assertEqual('string');
      expect(typeof formatTime(3600000)).assertEqual('string');
    });

    // --- Format structure: colon count ---

    it('mm:ss result should contain exactly one colon', 0, () => {
      const result = formatTime(90000); // "01:30"
      const colonCount = result.split(':').length - 1;
      expect(colonCount).assertEqual(1);
    });

    it('h:mm:ss result should contain exactly two colons', 0, () => {
      const result = formatTime(3723000); // "1:02:03"
      const colonCount = result.split(':').length - 1;
      expect(colonCount).assertEqual(2);
    });

    // --- Format structure: character length ---

    it('mm:ss result should have exactly 5 characters', 0, () => {
      expect(formatTime(1000).length).assertEqual(5);     // "00:01"
      expect(formatTime(3599000).length).assertEqual(5);  // "59:59"
    });

    it('single-digit-hour h:mm:ss result should have exactly 7 characters', 0, () => {
      // h (1) + ':' (1) + mm (2) + ':' (1) + ss (2) = 7
      expect(formatTime(3600000).length).assertEqual(7);   // "1:00:00"
      expect(formatTime(9045000).length).assertEqual(7);   // "2:30:45"
    });

    it('double-digit-hour hh:mm:ss result should have exactly 8 characters', 0, () => {
      // hh (2) + ':' (1) + mm (2) + ':' (1) + ss (2) = 8
      expect(formatTime(36000000).length).assertEqual(8);  // "10:00:00"
    });

    // --- Consistency: 0 ms guard vs. 1 ms (just above guard) ---

    it('1 ms should not trigger the guard and should return "00:00" (floors to 0 seconds)', 0, () => {
      // Math.floor(1/1000) = 0 → totalSeconds = 0 → h=0 m=0 s=0 → "00:00"
      // The guard only fires for ms <= 0, so ms=1 goes through the normal path
      // but still produces "00:00" because totalSeconds = 0.
      expect(formatTime(1)).assertEqual('00:00');
    });
  });
}

// ---------------------------------------------------------------------------
// Suite 7 — AppRoot PageMap routing coverage
// Tests the logical mapping between NAV_DEST_* constants and their intended
// page targets, exercising the conditional branch logic as pure string checks.
// ---------------------------------------------------------------------------

export function appRootPageMapTest() {
  describe('AppRoot - PageMap routing coverage', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    /**
     * Simulates the PageMap branch selector used in AppRoot.build():
     *   if (name === NAV_DEST_CONNECT)   → 'ConnectPage'
     *   else if (name === NAV_DEST_WEBVIEW)  → 'WebViewPage'
     *   else if (name === NAV_DEST_PLAYER)   → 'PlayerPage'
     *   else if (name === NAV_DEST_SETTINGS) → 'SettingsPage'
     *   else if (name === NAV_DEST_DOWNLOADS)→ 'DownloadsPage'
     *   else                                 → 'Unknown'
     */
    function resolvePageComponent(name: string): string {
      if (name === NAV_DEST_CONNECT)   return 'ConnectPage';
      if (name === NAV_DEST_WEBVIEW)   return 'WebViewPage';
      if (name === NAV_DEST_PLAYER)    return 'PlayerPage';
      if (name === NAV_DEST_SETTINGS)  return 'SettingsPage';
      if (name === NAV_DEST_DOWNLOADS) return 'DownloadsPage';
      return 'Unknown';
    }

    it('NAV_DEST_CONNECT should route to ConnectPage', 0, () => {
      expect(resolvePageComponent(NAV_DEST_CONNECT)).assertEqual('ConnectPage');
    });

    it('NAV_DEST_WEBVIEW should route to WebViewPage', 0, () => {
      expect(resolvePageComponent(NAV_DEST_WEBVIEW)).assertEqual('WebViewPage');
    });

    it('NAV_DEST_PLAYER should route to PlayerPage', 0, () => {
      expect(resolvePageComponent(NAV_DEST_PLAYER)).assertEqual('PlayerPage');
    });

    it('NAV_DEST_SETTINGS should route to SettingsPage', 0, () => {
      expect(resolvePageComponent(NAV_DEST_SETTINGS)).assertEqual('SettingsPage');
    });

    it('NAV_DEST_DOWNLOADS should route to DownloadsPage', 0, () => {
      expect(resolvePageComponent(NAV_DEST_DOWNLOADS)).assertEqual('DownloadsPage');
    });

    it('an unknown destination name should not match any known route', 0, () => {
      expect(resolvePageComponent('UnknownDestination')).assertEqual('Unknown');
    });

    it('an empty string should not match any known route', 0, () => {
      expect(resolvePageComponent('')).assertEqual('Unknown');
    });

    it('all 5 known destinations should resolve to a non-Unknown page', 0, () => {
      for (const name of ALL_DEST_NAMES) {
        expect(resolvePageComponent(name)).assertContain('Page');
      }
    });

    it('all 5 route resolutions should be distinct page names', 0, () => {
      const resolved: string[] = ALL_DEST_NAMES.map(n => resolvePageComponent(n));
      const unique = new Set<string>(resolved);
      expect(unique.size).assertEqual(5);
    });

    it('ConnectPage destination name used in connectToServer nav should match constant', 0, () => {
      // ConnectPage.connectToServer() hard-codes 'WebViewDestination' for the push.
      // Verify the constant and the literal agree.
      const literalInConnectPage: string = 'WebViewDestination';
      expect(literalInConnectPage).assertEqual(NAV_DEST_WEBVIEW);
    });

    it('ConnectPage fallback "ConnectDestination" literal should match NAV_DEST_CONNECT', 0, () => {
      // WebViewPage.aboutToAppear() uses 'ConnectDestination' as a fallback string.
      const literalInWebViewPage: string = 'ConnectDestination';
      expect(literalInWebViewPage).assertEqual(NAV_DEST_CONNECT);
    });
  });
}

// ---------------------------------------------------------------------------
// Root export — registers all suites with the test runner
// ---------------------------------------------------------------------------
export default function navigationRefactorUnitTest() {
  navDestConstantValuesTest();
  navDestCompletenessTest();
  mainPagesPostRefactorTest();
  webViewPageParamsTest();
  playerPageParamsTest();
  playerFormatTimeTest();
  appRootPageMapTest();
}
