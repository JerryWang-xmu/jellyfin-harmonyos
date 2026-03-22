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
 * 偏好设置测试
 * 测试 AppPreferences 的读写功能
 */

import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import preferences from '@ohos.data.preferences';
import { AppPreferences, VideoPlayerType, ExternalPlayerPackage } from '../../../../main/ets/core/preferences/AppPreferences';

export default function PreferencesTest() {
  describe('AppPreferences', () => {
    let appPreferences: AppPreferences;
    let context: Context;

    beforeEach(async () => {
      context = getContext(this);
      appPreferences = new AppPreferences(context);
      await appPreferences.initialize();
    });

    afterEach(async () => {
      await appPreferences.clear();
    });

    /**
     * 测试默认值
     */
    it('should_have_default_values', () => {
      expect(appPreferences.videoPlayerType).assertEqual(VideoPlayerType.EXO_PLAYER);
      expect(appPreferences.ignoreWebViewChecks).assertFalse();
      expect(appPreferences.exoPlayerAllowSwipeGestures).assertTrue();
    });

    /**
     * 测试视频播放器类型设置
     */
    it('should_set_video_player_type', async () => {
      appPreferences.videoPlayerType = VideoPlayerType.WEB_PLAYER;
      await appPreferences.save();

      expect(appPreferences.videoPlayerType).assertEqual(VideoPlayerType.WEB_PLAYER);
    });

    /**
     * 测试 ExoPlayer 设置
     */
    it('should_set_exoplayer_settings', async () => {
      appPreferences.exoPlayerAllowSwipeGestures = false;
      appPreferences.exoPlayerAllowPressSpeedUp = false;
      appPreferences.exoPlayerRememberBrightness = true;
      appPreferences.exoPlayerBrightness = 0.5;
      await appPreferences.save();

      expect(appPreferences.exoPlayerAllowSwipeGestures).assertFalse();
      expect(appPreferences.exoPlayerAllowPressSpeedUp).assertFalse();
      expect(appPreferences.exoPlayerRememberBrightness).assertTrue();
      expect(appPreferences.exoPlayerBrightness).assertEqual(0.5);
    });

    /**
     * 测试外部播放器设置
     */
    it('should_set_external_player', async () => {
      appPreferences.externalPlayerApp = ExternalPlayerPackage.MPV;
      await appPreferences.save();

      expect(appPreferences.externalPlayerApp).assertEqual(ExternalPlayerPackage.MPV);
    });

    /**
     * 测试服务器和用户 ID
     */
    it('should_set_server_and_user_id', async () => {
      appPreferences.currentServerId = 1;
      appPreferences.currentUserId = 100;
      await appPreferences.save();

      expect(appPreferences.currentServerId).assertEqual(1);
      expect(appPreferences.currentUserId).assertEqual(100);
    });

    /**
     * 测试清除
     */
    it('should_clear_preferences', async () => {
      appPreferences.videoPlayerType = VideoPlayerType.WEB_PLAYER;
      appPreferences.ignoreWebViewChecks = true;
      await appPreferences.save();

      await appPreferences.clear();

      // 清除后应恢复默认值
      expect(appPreferences.videoPlayerType).assertEqual(VideoPlayerType.EXO_PLAYER);
      expect(appPreferences.ignoreWebViewChecks).assertFalse();
    });
  });
}
