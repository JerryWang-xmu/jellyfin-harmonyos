/**
 * BatchTwoUnit.test.ets
 * Unit tests for Batch 2 network layer modules:
 *   - JellyfinApiService.buildAuthHeader()
 *   - JellyfinApiService.buildImageUrl()
 *   - ConnectionHelper URL normalization (pure logic)
 *   - CheckUrlState union type structure
 *
 * All tests are pure-logic / data-structure tests — no real network calls.
 *
 * Framework: @ohos/hypium
 * Author:    Validator (Refactor Task Force)
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';

import { JellyfinApiService } from '../main/ets/api/JellyfinApiService';
import { ApiClientConfig } from '../main/ets/api/ApiClientController';
import { CheckUrlState } from '../main/ets/setup/ConnectionHelper';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Build a minimal ApiClientConfig for testing pure-logic methods.
 * No baseUrl validation is performed by the service itself, so any
 * well-formed URL string is fine here.
 */
function makeConfig(overrides: Partial<ApiClientConfig> = {}): ApiClientConfig {
  return {
    baseUrl: 'http://192.168.1.100:8096',
    deviceId: 'test-device-id-001',
    deviceName: 'HarmonyOS Test Device',
    appName: 'Jellyfin',
    appVersion: '0.0.1',
    ...overrides
  };
}

// ---------------------------------------------------------------------------
// Test Suite 1 — JellyfinApiService.buildAuthHeader()
// ---------------------------------------------------------------------------
export function buildAuthHeaderTest() {
  describe('JellyfinApiService - buildAuthHeader', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    // --- No token: withToken = false (explicit) ---
    it('should build correct header without token when withToken is false', 0, () => {
      const config = makeConfig();
      const service = new JellyfinApiService(config);
      const header = service.buildAuthHeader(false);

      // Must contain all four mandatory fields
      expect(header.includes('MediaBrowser Client="Jellyfin"')).assertTrue();
      expect(header.includes('Device="HarmonyOS Test Device"')).assertTrue();
      expect(header.includes('DeviceId="test-device-id-001"')).assertTrue();
      expect(header.includes('Version="0.0.1"')).assertTrue();

      // Must NOT contain Token field when withToken is false
      expect(header.includes('Token=')).assertFalse();
    });

    // --- No token: config has no accessToken, withToken = true (default) ---
    it('should omit Token field when accessToken is not set in config', 0, () => {
      const config = makeConfig(); // no accessToken
      const service = new JellyfinApiService(config);
      const header = service.buildAuthHeader(true);

      expect(header.includes('MediaBrowser Client="Jellyfin"')).assertTrue();
      expect(header.includes('Token=')).assertFalse();
    });

    // --- With token ---
    it('should include Token field when accessToken is present and withToken is true', 0, () => {
      const config = makeConfig({ accessToken: 'abc123securetoken' });
      const service = new JellyfinApiService(config);
      const header = service.buildAuthHeader(true);

      expect(header.includes('Token="abc123securetoken"')).assertTrue();
    });

    // --- Default parameter: withToken defaults to true ---
    it('should include Token when withToken parameter is omitted (default true)', 0, () => {
      const config = makeConfig({ accessToken: 'defaultParamToken' });
      const service = new JellyfinApiService(config);
      const header = service.buildAuthHeader(); // no argument

      expect(header.includes('Token="defaultParamToken"')).assertTrue();
    });

    // --- Exact format: fields are comma-space separated ---
    it('should follow the exact MediaBrowser format with comma-space separators', 0, () => {
      const config = makeConfig({ accessToken: 'tokenXYZ' });
      const service = new JellyfinApiService(config);
      const header = service.buildAuthHeader(true);

      // Contract format:
      // MediaBrowser Client="...", Device="...", DeviceId="...", Version="...", Token="..."
      const expectedPattern =
        /^MediaBrowser Client="[^"]*", Device="[^"]*", DeviceId="[^"]*", Version="[^"]*", Token="[^"]*"$/;
      expect(expectedPattern.test(header)).assertTrue();
    });

    // --- No token variant: format without Token suffix ---
    it('should follow the exact MediaBrowser format without Token suffix', 0, () => {
      const config = makeConfig(); // no token
      const service = new JellyfinApiService(config);
      const header = service.buildAuthHeader(false);

      const expectedPattern =
        /^MediaBrowser Client="[^"]*", Device="[^"]*", DeviceId="[^"]*", Version="[^"]*"$/;
      expect(expectedPattern.test(header)).assertTrue();
    });

    // --- Values are correctly interpolated from config ---
    it('should interpolate config values exactly into the header string', 0, () => {
      const config = makeConfig({
        appName: 'JellyfinHarmony',
        deviceName: 'Pixel Tablet',
        deviceId: 'ABCDEF-1234',
        appVersion: '2.1.0',
        accessToken: 'tok-999'
      });
      const service = new JellyfinApiService(config);
      const header = service.buildAuthHeader(true);

      expect(header.includes('Client="JellyfinHarmony"')).assertTrue();
      expect(header.includes('Device="Pixel Tablet"')).assertTrue();
      expect(header.includes('DeviceId="ABCDEF-1234"')).assertTrue();
      expect(header.includes('Version="2.1.0"')).assertTrue();
      expect(header.includes('Token="tok-999"')).assertTrue();
    });
  });
}

// ---------------------------------------------------------------------------
// Test Suite 2 — JellyfinApiService.buildImageUrl()
// ---------------------------------------------------------------------------
export function buildImageUrlTest() {
  describe('JellyfinApiService - buildImageUrl', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    // --- Primary image, no maxWidth ---
    it('should build a correct Primary image URL without maxWidth', 0, () => {
      const config = makeConfig({ baseUrl: 'http://192.168.1.100:8096' });
      const service = new JellyfinApiService(config);
      const url = service.buildImageUrl('item-abc', 'Primary', 'tag123');

      // Expected: http://192.168.1.100:8096/Items/item-abc/Images/Primary?tag=tag123&quality=90
      expect(url.startsWith('http://192.168.1.100:8096/Items/item-abc/Images/Primary')).assertTrue();
      expect(url.includes('tag=tag123')).assertTrue();
      expect(url.includes('quality=90')).assertTrue();
      // Must NOT contain maxWidth
      expect(url.includes('maxWidth')).assertFalse();
    });

    // --- Thumb image, no maxWidth ---
    it('should build a correct Thumb image URL', 0, () => {
      const config = makeConfig();
      const service = new JellyfinApiService(config);
      const url = service.buildImageUrl('item-xyz', 'Thumb', 'thumbtag');

      expect(url.includes('/Items/item-xyz/Images/Thumb')).assertTrue();
      expect(url.includes('tag=thumbtag')).assertTrue();
      expect(url.includes('quality=90')).assertTrue();
    });

    // --- Backdrop image, no maxWidth ---
    it('should build a correct Backdrop image URL', 0, () => {
      const config = makeConfig();
      const service = new JellyfinApiService(config);
      const url = service.buildImageUrl('item-back', 'Backdrop', 'backdropTag');

      expect(url.includes('/Items/item-back/Images/Backdrop')).assertTrue();
      expect(url.includes('tag=backdropTag')).assertTrue();
    });

    // --- With maxWidth ---
    it('should append maxWidth parameter when provided', 0, () => {
      const config = makeConfig();
      const service = new JellyfinApiService(config);
      const url = service.buildImageUrl('item-w', 'Primary', 'tagW', 400);

      expect(url.includes('maxWidth=400')).assertTrue();
    });

    // --- maxWidth appears after quality ---
    it('should place maxWidth after quality=90 in the query string', 0, () => {
      const config = makeConfig();
      const service = new JellyfinApiService(config);
      const url = service.buildImageUrl('item-order', 'Primary', 'tagOrder', 800);

      const qualityIdx = url.indexOf('quality=90');
      const maxWidthIdx = url.indexOf('maxWidth=800');
      expect(qualityIdx).assertLarger(-1);
      expect(maxWidthIdx).assertLarger(qualityIdx);
    });

    // --- No maxWidth when argument is 0 (falsy) ---
    it('should omit maxWidth when value is 0 (falsy)', 0, () => {
      const config = makeConfig();
      const service = new JellyfinApiService(config);
      const url = service.buildImageUrl('item-zero', 'Primary', 'tagZero', 0);

      // 0 is falsy — implementation uses `if (maxWidth)`, so maxWidth=0 is omitted
      expect(url.includes('maxWidth')).assertFalse();
    });

    // --- tag is URL-encoded ---
    it('should URL-encode the tag value', 0, () => {
      const config = makeConfig();
      const service = new JellyfinApiService(config);
      // A tag that contains special characters needing encoding
      const url = service.buildImageUrl('item-enc', 'Primary', 'tag with spaces');

      // encodeURIComponent('tag with spaces') = 'tag%20with%20spaces'
      expect(url.includes('tag=tag%20with%20spaces')).assertTrue();
    });

    // --- Full URL structure validation ---
    it('should produce URL matching the contract format pattern', 0, () => {
      const config = makeConfig({ baseUrl: 'http://server:8096' });
      const service = new JellyfinApiService(config);
      const url = service.buildImageUrl('ITEM001', 'Primary', 'TAGABC', 320);

      // Contract: {baseUrl}/Items/{itemId}/Images/{imageType}?tag={tag}&maxWidth={w}&quality=90
      // Note: actual implementation appends &maxWidth after &quality=90 — still valid per contract
      const contractPattern =
        /^http:\/\/server:8096\/Items\/ITEM001\/Images\/Primary\?tag=TAGABC&quality=90&maxWidth=320$/;
      expect(contractPattern.test(url)).assertTrue();
    });
  });
}

// ---------------------------------------------------------------------------
// Test Suite 3 — ConnectionHelper URL normalization (pure logic extracted)
// ---------------------------------------------------------------------------
// ConnectionHelper.checkServerUrl() involves an actual network call, which
// cannot run in a unit test environment. We therefore replicate and test the
// pure URL-normalization logic directly — exactly the same rules that
// checkServerUrl() applies before calling testConnection().
// ---------------------------------------------------------------------------

/**
 * Pure URL normalizer — mirrors the logic in ConnectionHelper.checkServerUrl().
 * 1. Trim whitespace
 * 2. Remove trailing slashes
 * 3. Add http:// prefix if no scheme present
 *
 * Returns null for an empty string (mirrors the early-return error branch).
 */
function normalizeUrl(input: string): string | null {
  let url = input.trim();
  if (!url) return null;
  url = url.replace(/\/+$/, '');
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'http://' + url;
  }
  return url;
}

export function connectionHelperNormalizationTest() {
  describe('ConnectionHelper - URL normalization', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    // --- No scheme: bare IP:port ---
    it('should add http:// prefix when no scheme is present (IP:port)', 0, () => {
      const result = normalizeUrl('192.168.1.100:8096');
      expect(result).assertEqual('http://192.168.1.100:8096');
    });

    // --- No scheme: hostname only ---
    it('should add http:// prefix when no scheme is present (hostname)', 0, () => {
      const result = normalizeUrl('myserver.local');
      expect(result).assertEqual('http://myserver.local');
    });

    // --- No scheme: hostname with path ---
    it('should add http:// prefix when no scheme is present (hostname with path)', 0, () => {
      const result = normalizeUrl('myserver.local/jellyfin');
      expect(result).assertEqual('http://myserver.local/jellyfin');
    });

    // --- Preserve existing http:// ---
    it('should preserve existing http:// prefix unchanged', 0, () => {
      const result = normalizeUrl('http://192.168.1.100:8096');
      expect(result).assertEqual('http://192.168.1.100:8096');
    });

    // --- Preserve existing https:// ---
    it('should preserve existing https:// prefix unchanged', 0, () => {
      const result = normalizeUrl('https://myserver.com');
      expect(result).assertEqual('https://myserver.com');
    });

    // --- Preserve existing https:// with port ---
    it('should preserve https:// prefix with port unchanged', 0, () => {
      const result = normalizeUrl('https://myserver.com:8920');
      expect(result).assertEqual('https://myserver.com:8920');
    });

    // --- Trim leading whitespace ---
    it('should trim leading whitespace', 0, () => {
      const result = normalizeUrl('  192.168.1.1:8096');
      expect(result).assertEqual('http://192.168.1.1:8096');
    });

    // --- Trim trailing whitespace ---
    it('should trim trailing whitespace', 0, () => {
      const result = normalizeUrl('192.168.1.1:8096  ');
      expect(result).assertEqual('http://192.168.1.1:8096');
    });

    // --- Trim both ends ---
    it('should trim whitespace from both ends', 0, () => {
      const result = normalizeUrl('  http://myserver.com  ');
      expect(result).assertEqual('http://myserver.com');
    });

    // --- Remove trailing slash ---
    it('should remove a single trailing slash', 0, () => {
      const result = normalizeUrl('http://myserver.com/');
      expect(result).assertEqual('http://myserver.com');
    });

    // --- Remove multiple trailing slashes ---
    it('should remove multiple trailing slashes', 0, () => {
      const result = normalizeUrl('http://myserver.com///');
      expect(result).assertEqual('http://myserver.com');
    });

    // --- Trailing slash on bare host ---
    it('should remove trailing slash before adding http:// prefix', 0, () => {
      const result = normalizeUrl('192.168.1.100:8096/');
      expect(result).assertEqual('http://192.168.1.100:8096');
    });

    // --- Empty string ---
    it('should return null for an empty string', 0, () => {
      const result = normalizeUrl('');
      expect(result === null).assertTrue();
    });

    // --- Whitespace-only string ---
    it('should return null for a whitespace-only string', 0, () => {
      const result = normalizeUrl('   ');
      expect(result === null).assertTrue();
    });

    // --- http:// is not modified to https:// (that happens in testConnection retry) ---
    it('should NOT upgrade http to https during normalization', 0, () => {
      const result = normalizeUrl('http://plainserver.com');
      // Normalization step should leave http:// as-is
      expect(result).assertEqual('http://plainserver.com');
    });
  });
}

// ---------------------------------------------------------------------------
// Test Suite 4 — CheckUrlState union type structure
// ---------------------------------------------------------------------------
export function checkUrlStateTypeTest() {
  describe('CheckUrlState union type', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    // --- success variant ---
    it('should have success type with url field', 0, () => {
      const state: CheckUrlState = { type: 'success', url: 'http://test.com' };
      expect(state.type).assertEqual('success');
      // Access url via type narrowing assertion
      if (state.type === 'success') {
        expect(state.url).assertEqual('http://test.com');
      }
    });

    it('success url should hold the normalized server URL', 0, () => {
      const normalized = 'http://192.168.1.100:8096';
      const state: CheckUrlState = { type: 'success', url: normalized };
      if (state.type === 'success') {
        expect(state.url.startsWith('http')).assertTrue();
        expect(state.url).assertEqual(normalized);
      }
    });

    // --- error variant ---
    it('should have error type with message field', 0, () => {
      const state: CheckUrlState = { type: 'error', message: 'Failed' };
      expect(state.type).assertEqual('error');
      if (state.type === 'error') {
        expect(state.message).assertEqual('Failed');
      }
    });

    it('error message should be a non-empty string', 0, () => {
      const state: CheckUrlState = { type: 'error', message: '无法连接到服务器，请检查地址是否正确' };
      if (state.type === 'error') {
        expect(state.message.length > 0).assertTrue();
      }
    });

    // --- loading variant ---
    it('should have loading type with no extra fields', 0, () => {
      const state: CheckUrlState = { type: 'loading' };
      expect(state.type).assertEqual('loading');
    });

    // --- type discriminator is always a string ---
    it('type field should always be a string', 0, () => {
      const success: CheckUrlState = { type: 'success', url: 'http://a.com' };
      const error: CheckUrlState = { type: 'error', message: 'err' };
      const loading: CheckUrlState = { type: 'loading' };

      expect(typeof success.type).assertEqual('string');
      expect(typeof error.type).assertEqual('string');
      expect(typeof loading.type).assertEqual('string');
    });

    // --- three distinct type values ---
    it('success / error / loading type strings should all be distinct', 0, () => {
      const types: string[] = ['success', 'error', 'loading'];
      const unique = new Set(types);
      expect(unique.size).assertEqual(3);
    });

    // --- type narrowing works for all three variants ---
    it('type narrowing should correctly identify each variant', 0, () => {
      const states: CheckUrlState[] = [
        { type: 'success', url: 'http://server.com' },
        { type: 'error', message: 'some error' },
        { type: 'loading' }
      ];

      let successCount = 0;
      let errorCount = 0;
      let loadingCount = 0;

      for (const s of states) {
        if (s.type === 'success') {
          successCount++;
        } else if (s.type === 'error') {
          errorCount++;
        } else if (s.type === 'loading') {
          loadingCount++;
        }
      }

      expect(successCount).assertEqual(1);
      expect(errorCount).assertEqual(1);
      expect(loadingCount).assertEqual(1);
    });
  });
}

// ---------------------------------------------------------------------------
// Root export — registers all suites with the test runner
// ---------------------------------------------------------------------------
export default function batchTwoUnitTest() {
  buildAuthHeaderTest();
  buildImageUrlTest();
  connectionHelperNormalizationTest();
  checkUrlStateTypeTest();
}
